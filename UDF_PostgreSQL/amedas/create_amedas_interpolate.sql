CREATE OR REPLACE FUNCTION tb_gis_amedas_interpolate(
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
    RETURNS table(id integer, datetime timestamp, lng float, lat float, data float) AS $$

import pandas

query  = "SELECT * FROM tb_gis_fixed_stations_interpolate('t_amedas_code_data', 't_amedas_data', 'prefnumber', 'datetime', 'location', '" + target_colomn + "', "
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

df_amedas = pandas.DataFrame.from_records(data)[['id', 'datetime', 'longitude', 'latitude', 'datalist']]

df_amedas['data'] = df_amedas['datalist'].str[0]
df_amedas.drop(columns=['datalist'], inplace=True)

return df_amedas.to_records(index=False)

$$ LANGUAGE plpython3u;
