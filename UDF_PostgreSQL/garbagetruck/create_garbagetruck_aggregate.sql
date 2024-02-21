CREATE OR REPLACE FUNCTION tb_gis_garbagetruck_aggregate_2(
    target_colomn text,
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
     RETURNS table(id text, datetime timestamp, lng float, lat float, direction float, speed float, data text) AS $$

import pandas

query  = "SELECT * FROM tb_gis_mobile_stations_aggregate('t_nisshin_garbage_data', 'IDENTIFIER', 'datetime', 'location', 'COURSE SPEED " + target_colomn + "', "
query += str(p1_x) + "," + str(p1_y) + "," + str(p2_x) + "," + str(p2_y) + "," + str(p3_x) + "," + str(p3_y) + "," + str(p4_x) + "," + str(p4_y) + ", "
query += "'" + start_datetime + "', '" + end_datetime + "', '" + freq + "', '" + method + "');"

data = []
try:
    data = plpy.execute(query)
except:
    plpy.error("query execution is error")
    sys.exit(-1)

if len(data) == 0:
    return []

df_mobile = pandas.DataFrame.from_records(data)[['id', 'datetime', 'longitude', 'latitude', 'datalist']]

df_mobile['direction'] = df_mobile['datalist'].str[0]
df_mobile['speed'] = df_mobile['datalist'].str[1]
df_mobile['data'] = df_mobile['datalist'].str[2]
df_mobile.drop(columns=['datalist'], inplace=True)

return df_mobile.to_records(index=False)

$$ LANGUAGE plpython3u;
