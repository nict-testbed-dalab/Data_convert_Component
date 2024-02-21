CREATE OR REPLACE FUNCTION tb_gis_mobile_stations_interpolate(
    table_name text,
    id_column text,
    datetime_column text,
    location_column text,
    data_column_list text,
    p1_x float,
    p1_y float,
    p2_x float,
    p2_y float,
    p3_x float,
    p3_y float,
    p4_x float,
    p4_y float,
    start_datetime timestamp,
    end_datetime timestamp,
    freq text,
    method text
)
    RETURNS table(id text, datetime timestamp, longitude float, latitude float, datalist text[]) AS $$

import pandas

data_list = data_column_list.split()
if len(data_list) == 0:
    plpy.error("data_column_list is invalid")
    sys.exit(-1)

data_key_list = []
for idx, data in enumerate(data_list):
    data_key_list.append(data.lower() + "_datalist_" + str(idx))

column_str  = "\"" + id_column + "\" AS id, \"" + datetime_column + "\" AS datetime, ST_X(\"" + location_column + "\") AS longitude, ST_Y(\"" + location_column + "\") AS latitude, "
column_str += "\"" + data_list[0] + "\" AS " + data_key_list[0]

for i in range (1, len(data_list)):
    column_str += ", "
    column_str += "\"" + data_list[i] + "\" AS " + data_key_list[i]

location_str = str(p1_x) + " " + str(p1_y) + ", " + str(p2_x) + " " + str(p2_y) + ", " + str(p3_x) + " " + str(p3_y) + ", " + str(p4_x) + " " + str(p4_y) + ", " + str(p1_x) + " " + str(p1_y)

query  = "SELECT " + column_str + " from " + table_name + " "
query += "WHERE ST_Contains(ST_Transform(ST_GeomFromText('POLYGON((" + location_str + "))', 4326), 4326), \"" + location_column + "\") "
query += "AND \"" + datetime_column + "\" BETWEEN '" + start_datetime + "' AND '" + end_datetime + "';"

key_list = ["id", "datetime", "longitude", "latitude"]
key_list.extend(data_key_list)

data = []
try:
    data = plpy.execute(query)
except:
    plpy.error("select query execution is error")
    sys.exit(-1)

if len(data) == 0:
    return []

df_mobile = pandas.DataFrame.from_records(data)[key_list]

df_mobile['datetime'] = pandas.to_datetime(df_mobile['datetime'])
for i in range (2, len(key_list)):
    df_mobile[key_list[i]] = pandas.to_numeric(df_mobile[key_list[i]], errors="coerce")

order_num = 2
method_type = 'linear'
if method == 'spline':
    method_type = 'quadratic'
    order_num = 3

df_result = pandas.DataFrame([], columns=key_list)
df_dict = {}
for id_name, group in df_mobile.groupby('id'):
    grouped = group.groupby('datetime')
    work = grouped.first().reset_index()
    work.set_index('datetime', inplace=True)

    work_freq = work.asfreq(freq)
    if order_num > work_freq.count(numeric_only=True).min():
        method_type = 'linear'

    df_dict[id_name] = work_freq.interpolate(method=method_type)
    df_dict[id_name]['id'] = id_name
    df_result = pandas.concat([df_result, df_dict[id_name].reset_index()], axis=0, ignore_index=False)

df_result["datalist"] = df_result[data_key_list].values.tolist()
df_result.drop(columns=data_key_list, inplace=True)

return df_result.to_records(index=False)

$$ LANGUAGE plpython3u;
