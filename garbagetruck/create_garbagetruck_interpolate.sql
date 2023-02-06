CREATE FUNCTION tb_gis_garbagetruck_interpolate(target text, p1_x float, p1_y float, p2_x float, p2_y float, p3_x float, p3_y float, p4_x float, p4_y float, st timestamp, et timestamp, gr text, proc text)
     RETURNS table(id text, datetime timestamp, lng float, lat float, direction float, speed float, data text) AS $$

import pandas

location_str = str(p1_x) + " " + str(p1_y) + ", " + str(p2_x) + " " + str(p2_y) + ", " + str(p3_x) + " " + str(p3_y) + ", " + str(p4_x) + " " + str(p4_y) + ", " + str(p1_x) + " " + str(p1_y)
query  = "SELECT *, ST_X(location) AS longitude, ST_Y(location) AS latitude from t_nisshin_garbage_data "
query += "WHERE ST_Contains(ST_Transform(ST_GeomFromText('POLYGON((" + location_str + "))', 4326), 4326), location) "
query += "AND datetime BETWEEN '" + st + "' AND '" + et + "';"

car_location = []
car_data = []

for row in plpy.cursor(query):
    car_location.append([str(row['IDENTIFIER']), row['datetime'], float(row['longitude']), float(row['latitude']), row['COURSE'], row['SPEED']])
    car_data.append([str(row['IDENTIFIER']), row['datetime'], row[target]])

if len(car_location) == 0:
    return []

df_location = pandas.DataFrame(car_location, columns=['id', 'datetime', 'lng', 'lat', 'direction', 'speed'])
df_location['datetime'] = pandas.to_datetime(df_location['datetime'])
df_location['direction'] = pandas.to_numeric(df_location['direction'], errors="coerce")
df_location['speed'] = pandas.to_numeric(df_location['speed'], errors="coerce")

df_location_dict = {}
for id_name, group in df_location.groupby('id'):
    grouped = group.groupby('datetime')  
    work = grouped.first().reset_index()

    work.set_index('datetime', inplace=True)
    df_location_dict[id_name] = work.resample(gr).interpolate()
    df_location_dict[id_name]['id'] = id_name
    df_location_dict[id_name] = df_location_dict[id_name].reset_index()

df_data = pandas.DataFrame(car_data, columns=['id', 'datetime', 'data'])
df_data['datetime'] = pandas.to_datetime(df_data['datetime'])
df_data['data'] = pandas.to_numeric(df_data['data'], errors="coerce")

method_type = 'linear'
order_num = 1
if proc == 'spline':
    method_type = 'spline'
    order_num = 2

df_data_dict = {}
for id_name, group in df_data.groupby('id'):
    grouped = group.groupby('datetime')  
    work = grouped.first().reset_index()

    work.set_index('datetime', inplace=True)
    df_data_dict[id_name] = work.resample(gr).interpolate(method=method_type, order=order_num)
    df_data_dict[id_name]['id'] = id_name
    df_data_dict[id_name] = df_data_dict[id_name].reset_index()

df_result = pandas.DataFrame([], columns=['id', 'datetime', 'lng', 'lat', 'direction', 'speed', 'data'])
for id_name in df_location_dict.keys():
    df = pandas.merge(df_location_dict[id_name], df_data_dict[id_name], on=['id', 'datetime'])
    df_result = pandas.concat([df_result, df], axis=0, ignore_index=False)

return ( (r[1]['id'], r[1]['datetime'], r[1]['lng'], r[1]['lat'], r[1]['direction'], r[1]['speed'], r[1]['data']) for r in df_result.iterrows() )

$$ LANGUAGE plpython3u;