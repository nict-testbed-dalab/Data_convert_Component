CREATE FUNCTION tb_gis_amedas_interpolate(target text, p1_x float, p1_y float, p2_x float, p2_y float, p3_x float, p3_y float, p4_x float, p4_y float, st timestamp, et timestamp, gr text, proc text) 
    RETURNS table(id integer, datetime timestamp, lng float, lat float, data float) AS $$

import pandas

location_str = str(p1_x) + " " + str(p1_y) + ", " + str(p2_x) + " " + str(p2_y) + ", " + str(p3_x) + " " + str(p3_y) + ", " + str(p4_x) + " " + str(p4_y) + ", " + str(p1_x) + " " + str(p1_y)
query_code  = "SELECT prefnumber, ST_Y(location) AS longitude, ST_X(location) AS latitude from t_amedas_code_data "
query_code += "WHERE ST_Contains(ST_Transform(ST_GeomFromText('POLYGON((" + location_str + "))', 4326), 4326), ST_SetSRID(ST_POINT(ST_Y(location), ST_X(location)), 4326));"

amedas_location = {}

for row in plpy.cursor(query_code):
    amedas_location[str(row['prefnumber'])] = { 'lng': float(row['longitude']), 'lat' : float(row['latitude']) }

amedas_location_keys = amedas_location.keys()

if len(amedas_location_keys) == 0:
    return []

pref_list = ",".join(amedas_location_keys)

query  = "SELECT t_amedas_data.prefnumber, datetime, " + target + " from t_amedas_code_data, t_amedas_data "
query += "WHERE t_amedas_data.prefnumber = t_amedas_code_data.prefnumber "
query += "AND t_amedas_data.prefnumber in (" + pref_list + ") "
query += "AND datetime BETWEEN '" + st + "' AND '" + et + "';"

amedas_data = []
for row in plpy.cursor(query):
    amedas_data.append([row['prefnumber'], row['datetime'], row[target]])

if len(amedas_data) == 0:
    return []

df = pandas.DataFrame(amedas_data, columns=['id', 'datetime', 'data'])
df['id'] = df['id'].astype(str)
df['datetime'] = pandas.to_datetime(df['datetime'])
df['data'] = pandas.to_numeric(df['data'], errors="coerce")

method_type = 'linear'
order_num = 1
if proc == 'spline':
    method_type = 'spline'
    order_num = 2

df_result = pandas.DataFrame([], columns=['id', 'datetime', 'data'])
for id_name, group in df.groupby('id'):
    group.set_index('datetime', inplace=True)
    if group['data'].count() <= order_num :
        df_work = group.asfreq(gr)
    else :
        df_work = group.resample(gr).interpolate(method=method_type, order=order_num)

    df_work['id'] = id_name
    df_result = pandas.concat([df_result, df_work.reset_index()], axis=0, ignore_index=False) 

rsv = []
for data in df_result.iterrows():
    rsv.append([data[1]['id'], data[1]['datetime'], amedas_location[data[1]['id']]['lng'], amedas_location[data[1]['id']]['lat'], data[1]['data']])

return ( (r[0], r[1], r[2], r[3], r[4]) for r in rsv )

$$ LANGUAGE plpython3u;