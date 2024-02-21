CREATE OR REPLACE FUNCTION tb_gis_fixed_stations_aggregate(
    station_table_name text,
    data_table_name text,
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

location_str = str(p1_x) + " " + str(p1_y) + ", " + str(p2_x) + " " + str(p2_y) + ", " + str(p3_x) + " " + str(p3_y) + ", " + str(p4_x) + " " + str(p4_y) + ", " + str(p1_x) + " " + str(p1_y)

query  = "SELECT \"" + id_column + "\" AS id, ST_X(\"" + location_column + "\") AS longitude, ST_Y(\"" + location_column + "\") AS latitude "
query += "FROM \"" + station_table_name + "\" "
query += "WHERE ST_Contains(ST_Transform(ST_GeomFromText('POLYGON((" + location_str + "))', 4326), 4326), \"" + location_column + "\");"

data = []
try:
    data = plpy.execute(query)
except:
    plpy.error("select station query execution is error")
    sys.exit(-1)

if len(data) == 0:
    return []

df_station = pandas.DataFrame.from_records(data)[['id', 'longitude', 'latitude']]

id_list = ",".join(df_station['id'].astype(str).values)

column_str  = "\"" + id_column + "\" AS id, \"" + datetime_column + "\" AS datetime, "
column_str += "\"" + data_list[0] + "\" AS " + data_key_list[0]

for i in range (1, len(data_list)):
    column_str += ", "
    column_str += "\"" + data_list[i] + "\" AS " + data_key_list[i]


location_str = str(p1_x) + " " + str(p1_y) + ", " + str(p2_x) + " " + str(p2_y) + ", " + str(p3_x) + " " + str(p3_y) + ", " + str(p4_x) + " " + str(p4_y) + ", " + str(p1_x) + " " + str(p1_y)

query  = "SELECT " + column_str + " FROM " + data_table_name + " "
query += "WHERE \"" + id_column + "\" in (" + id_list + ") "
query += "AND \"" + datetime_column + "\" BETWEEN '" + start_datetime + "' AND '" + end_datetime + "';"

key_list = ['id', 'datetime']
key_list.extend(data_key_list)

data = []
try:
    data = plpy.execute(query)
except:
    plpy.error("select query execution is error")
    sys.exit(-1)

if len(data) == 0:
    return []

df_data = pandas.DataFrame.from_records(data)[key_list]

df_data['datetime'] = pandas.to_datetime(df_data['datetime'])
for i in range (2, len(key_list)):
    df_data[key_list[i]] = pandas.to_numeric(df_data[key_list[i]], errors="coerce")

df_result = pandas.DataFrame([], columns=key_list)
df_dict = {}
for id_name, group in df_data.groupby('id'):
    grouped = group.groupby('datetime')
    work = grouped.first().reset_index()
    work.set_index('datetime', inplace=True)

    if method == 'max':
        df_dict[id_name] = work.resample(freq).max()
    elif method == 'min':
        df_dict[id_name] = work.resample(freq).min()
    else :
        df_dict[id_name] = work.resample(freq).mean()

    df_dict[id_name]['id'] = id_name
    df_result = pandas.concat([df_result, df_dict[id_name].reset_index()], axis=0, ignore_index=False)

df_result["datalist"] = df_result[data_key_list].values.tolist()
df_result.drop(columns=data_key_list, inplace=True)
df_result = df_result.merge(df_station, on='id').reindex(columns=['id', 'datetime', 'longitude', 'latitude', 'datalist'])

return df_result.to_records(index=False)

$$ LANGUAGE plpython3u;
