# Data_convert_Component
データ変換等、処理機能

## 概要
WebGISアプリで利用するデータの変換や、時系列データを利用する際の前処理として補間、集約などを行うためのコンポーネントです。

### 機能一覧
#### PostgreSQLのPL/Pythonでのユーザ定義関数
- アメダスデータ向け補間処理関数
- アメダスデータ向け集約処理関数
- 固定観測局データ向け補間処理関数
- 固定観測局データ向け集約処理関数

- ゴミ収集車データ向け補間処理関数
- ゴミ収集車データ向け集約処理関数
- 移動観測局データ向け補間処理関数
- 移動観測局データ向け集約処理関数

### ユーザ定義関数導入方法
- 環境はUbuntu 20.04.3 LTSにPostgreSQL 12、python3がインストールされている環境を想定しています。  

1. postgresユーザでPostgreSQLへの接続する。
```
$ sudo -i -u postgres
$ psql
```
2. plpython3uを有効化する。確認結果にplpython3uが含まれていることを確認する。
```
-- 有効化
postgres=# CREATE EXTENSION plpython3u;

-- 以下でplpython3uの有効／無効の確認
postgres=# select lanname from pg_language;

  lanname   
------------
 internal   
 c          
 sql        
 plpgsql    
 plpython3u 
```

3. ユーザ定義関数内で利用するPythonのライブラリを追加する。
```
$ sudo -i -u postgres
$ sudo pip3 install [利用ライブラリ]
```
なお、本リポジトリで準備している関数は以下のライブラリを使用しています。  
・pandas  
・SciPy  

4. ユーザ定義関数を追加する。
```
postgres=# CREATE FUNCTION ....
```

SQLファイルを実行する場合は以下。
```
$ sudo -i -u postgres
$ psql -f [SQLファイル]
```

また、UDFを追加したユーザと別のユーザが利用する際に、権限の付与が必要な場合、以下で実行権限が付与できます。
```
postgres =#grant EXECUTE on FUNCTION [追加したUDF] to [利用するユーザ名];
```

### 補間集約ユーザ定義関数

#### アメダスデータ向け補間処理関数
アメダスデータについて、指定した時間粒度に応じて補間処理を行います。なおアメダスデータは以下のカラムが含まれる形式を想定しています。

  * アメダス観測局テーブル(t_amedas_code_data)

|カラム名|説明|
| ---- | ---- |
|prefnumber|アメダス観測局のコード|
|location|geometry型で格納した緯度、経度| 

  * アメダスデータテーブル(t_amedas_data)

|カラム名|説明|
| ---- | ---- |
|prefnumber|アメダス観測局のコード | 
|datetime|データの観測時刻|
|その他の前処理対象のカラム|アメダスデータは10分間隔で収集される|

  * 形式  
```
tb_gis_amedas_interpolate(target_data text, point1_x float, point1_y float, point2_x float, point2_y float, point3_x float, point3_y float, point4_x float, point4_y float,
                        start_date timestamp, end_date timestamp, granularity text, proc_type text) 
```

  * 引数  
 
|引数|説明|フォーマット|備考|
| ---- | ---- | ---- | ---- |
|target_data|前処理対象のカラム名|英数字| t_amedas_dataのデータ処理対象にするカラム名|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|granularity |時間粒度|S、T|pandasのresample()で指定可能な値|
|proc_type|前処理の方法|linear、spline|linearは線形補間、splineは2次スプライン補間|


  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|アメダス観測局のID|
|datetime|前処理済みデータの時刻|
|longitude|アメダス観測局の経度|
|latitude|アメダス観測局の緯度|
|data|前処理済みのデータ|


#### アメダスデータ向け集約処理関数
アメダスデータについて、指定した時間粒度に応じて集約処理を行います。

  * 形式  
```
tb_gis_amedas_aggregate(target_data text, point1_x float, point1_y float, point2_x float, point2_y float, point3_x float, point3_y float, point4_x float, point4_y float,
                        start_date timestamp, end_date timestamp, granularity text, proc_type text) 
```


  * 引数
 
|引数|説明|フォーマット|備考|
| ---- | ---- | ---- | ---- |
|target_data|前処理対象のカラム名|英数字| t_amedas_dataのデータ処理対象にするカラム名|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|granularity |時間粒度|H、D、W、MS|pandasのresample()で指定可能な値|
|proc_type|前処理の方法|min、max、ave||


  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|アメダス観測局のID|
|datetime|前処理済みデータの時刻|
|longitude|アメダス観測局の経度|
|latitude|アメダス観測局の緯度|
|data|前処理済みのデータ|


#### 固定観測局データ向け補間処理関数 (tb_gis_fixed_stations_interpolate)  
位置が変化しない観測局データについて、指定した時間粒度に応じて補間処理を行います。観測局のテーブル構成については以下を想定しています。

  * 固定観測局の観測局情報に関するテーブル
 
|カラム名|説明|
| ---- | ---- |
|観測局ID(カラム名は引数で指定)|観測局の識別番号| 
|観測局座標(カラム名は引数で指定)|geometry型で格納した緯度、経度| 

  * 固定観測局の観測データに関するテーブル
 
|カラム名|説明|
| ---- | ---- |
|観測局ID(カラム名は引数で指定)|観測局の識別番号| 
|観測時刻(カラム名は引数で指定)|データの観測時刻|
|その他の前処理対象のカラム|数値データが格納されていること| 

  * 形式  
```
tb_gis_fixed_stations_interpolate(
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
```

  * 引数
 
|引数|説明|フォーマット|備考|
| ---- | ---- | ---- | ---- |
|station_table_name|観測局情報に関するテーブル名|英数字||
|data_table_name|観測データに関するテーブル|英数字||
|id_column|観測局IDのカラム名|英数字||
|datetime_column|観測時刻のカラム名|英数字||
|location_column|観測局座標のカラム名|英数字||
|data_column_list|前処理対象のカラム名|半角スペース区切りの英数字|data_table_nameのカラム名を半角スペース区切りで1つ以上指定する|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|freq |時間粒度|S、T、H、D、W、MS|pandasのresample()で指定可能な値の内、データ収集間隔より小さいもの|
|method|前処理の方法|linear、spline|linearは線形補間、splineは2次スプライン補間|

  * 例  
```
tb_gis_fixed_stations_interpolate("station_info", "station_data", "id", "datetime", "location", "temp humidity wind", 
                                  139.5, 35.8, 139.6, 35.8, 139.6, 35.7, 139.5, 35.7, 
                                  "2022-12-01 10:00:00", "2022-12-01 12:00:00", "1T", "spline")
```

  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|観測局の識別番号|
|datetime|前処理済みデータの時刻|
|longitude|観測局の経度|
|latitude|観測局の緯度|
|datalist|data_column_listで指定したデータの前処理済みデータのリスト|


#### 固定観測局向け集約処理関数
位置が変化しない観測局データについて、指定した時間粒度に応じて集約処理を行います。

  * 形式  
```
tb_gis_fixed_stations_aggregate(
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
```

  * 引数
 
|引数|説明|フォーマット||
| ---- | ---- | ---- | ---- |
|station_table_name|観測局情報に関するテーブル名|英数字||
|data_table_name|観測データに関するテーブル|英数字||
|id_column|観測局IDのカラム名|英数字||
|datetime_column|観測時刻のカラム名|英数字||
|location_column|観測局座標のカラム名|英数字||
|data_column_list|前処理対象のカラム名|半角スペース区切りの英数字|data_table_nameのカラム名を半角スペース区切りで1つ以上指定する|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|freq|時間粒度|S、T、H、D、W、MS|pandasのresample()で指定可能な値の内、データ収集間隔より大きいもの|
|method|前処理の方法|min、max、ave||

  * 例  
```
tb_gis_fixed_stations_aggregate("station_info", "station_data", "id", "datetime", "location", "temp", 
                                139.5, 35.8, 139.6, 35.8, 139.6, 35.7, 139.5, 35.7, 
                                "2022-12-01 10:00:00", "2022-12-01 20:00:00", "30T", "ave")
```

  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|観測局の識別番号|
|datetime|前処理済みデータの時刻|
|longitude|観測局の経度|
|latitude|観測局の緯度|
|datalist|data_column_listで指定したデータの前処理済みデータのリスト|


#### 日進市ごみ収集車データ向け補間処理関数
日進市ごみ収集車データについて、指定した時間粒度に応じて補間処理を行います。なおごみ収集車データは以下のカラムが含まれる形式を想定しています。

  * 日進市ごみ収集車データテーブル(t_nisshin_garbage_data)
 
|カラム名|説明|
| ---- | ---- |
|IDENTIFIER|ごみ収集車の識別番号| 
|location|geometry型で格納したごみ収集車の緯度、経度| 
|datetime|データの観測時刻|
|COURSE|ごみ収集車の向き| 
|SPEED|ごみ収集車の速度| 
|その他の前処理対象のカラム|収集間隔は不定、最小間隔はおよおそ1秒、ごみ収集中のみ観測を実施| 


  * 形式  
```
tb_gis_garbagetruck_interpolate(target_data text, point1_x float, point1_y float, point2_x float, point2_y float, point3_x float, point3_y float, point4_x float, point4_y float,
                                start_date timestamp, end_date timestamp, granularity text, proc_type text) 
```

  * 引数
 
|引数|説明|フォーマット|備考|
| ---- | ---- | ---- | ---- |
|target_data|前処理対象のカラム名|英数字|データ処理対象にするt_nisshin_garbage_dataのカラム名|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|granularity |時間粒度|S|pandasのresample()で指定可能な値|
|proc_type|前処理の方法|linear、spline|linearは線形補間、splineは2次スプライン補間|


  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|ごみ収集車の識別番号|
|datetime|前処理済みデータの時刻|
|lng|ごみ収集車の経度|
|lat|ごみ収集車の緯度|
|direction|ごみ収集車の向き|
|speed|ごみ収集車の速度|
|data|前処理済みのデータ|


#### 日進市ごみ収集車データ向け集約処理関数
日進市ごみ収集車データを指定した時間粒度に応じて集約処理を行います。

  * 形式  
```
tb_gis_garbagetruck_aggregate(target_data text, point1_x float, point1_y float, point2_x float, point2_y float, point3_x float, point3_y float, point4_x float, point4_y float,
                              start_date timestamp, end_date timestamp, granularity text, proc_type text) 
```


  * 引数
 
|引数|説明|フォーマット|備考|
| ---- | ---- | ---- | ---- |
|target_data|前処理対象のカラム名|英数字|データ処理対象にするt_nisshin_garbage_dataのカラム名|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|granularity |時間粒度|H、D、W、MS|pandasのresample()で指定可能な値|
|proc_type|前処理の方法|min、max、ave|緯度、経度は実測値を使用する|


  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|ごみ収集車の識別番号|
|datetime|前処理済みデータの時刻|
|lng|ごみ収集車の経度|
|lat|ごみ収集車の緯度|
|direction|ごみ収集車の向き|
|speed|ごみ収集車の速度|
|data|前処理済みのデータ|


#### 移動観測局データ向け補間処理関数
時間経過で移動する観測局データについて、指定した時間粒度に応じて補間処理を行います。観測局データは以下の構成を想定しています。

  * 移動観測局データに関するテーブル
 
|カラム名|説明|
| ---- | ---- |
|移動体ID(カラム名は引数で指定)|移動観測局の識別番号| 
|移動体座標(カラム名は引数で指定)|geometry型で格納した移動観測局の緯度、経度| 
|観測時刻(カラム名は引数で指定)|データの観測時刻|
|その他の前処理対象のカラム|数値データが格納されていること| 

  * 形式  
```
tb_gis_mobile_stations_interpolate(
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
```

  * 引数
 
|引数|説明|フォーマット||
| ---- | ---- | ---- | ---- |
|data_table_name|移動体データに関するテーブル|英数字||
|id_column|移動体IDのカラム名|英数字||
|datetime_column|観測時刻のカラム名|英数字||
|location_column|移動体座標のカラム名|英数字||
|data_column_list|前処理対象のカラム名|半角スペース区切りの英数字|data_table_nameのカラム名を半角スペース区切りで1つ以上指定する|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|freq |時間粒度|S、T、H、D、W、MS|pandasのresample()で指定可能な値の内、データ収集間隔より小さいもの|
|method|前処理の方法|linear、spline|linearは線形補間、splineは2次スプライン補間|

  * 例  
```
tb_gis_mobile_stations_interpolate("mobile_data", "id", "datetime", "location", "direction speed", 
                                   139.5, 35.8, 139.6, 35.8, 139.6, 35.7, 139.5, 35.7, 
                                   "2022-12-01 10:00:00", "2022-12-01 20:00:00", "30S", "spline")
```

  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|移動観測局の識別番号|
|datetime|前処理済みデータの時刻|
|longitude|移動観測局の経度|
|latitude|移動観測局の緯度|
|datalist|data_column_listで指定したデータの前処理済みデータのリスト|


#### 移動観測局データ向け集約処理関数
時間経過で移動する観測局データについて、指定した時間粒度に応じて集約処理を行う。

  * 形式  
```
tb_gis_mobile_stations_aggregate(
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
```

  * 引数
 
|引数|説明|フォーマット||
| ---- | ---- | ---- | ---- |
|data_table_name|移動体データに関するテーブル|英数字||
|id_column|移動体IDのカラム名|英数字||
|datetime_column|観測時刻のカラム名|英数字||
|location_column|移動体座標のカラム名|英数字||
|data_column_list|前処理対象のカラム名|半角スペース区切りの英数字|data_table_nameのカラム名を半角スペース区切りで1つ以上指定する|
|point1_x|前処理対象の領域における右上の経度|数値|139.4|
|point1_y|前処理対象の領域における右上の緯度|数値|35.7|
|point2_x|前処理対象の領域における左上の経度|数値|139.5|
|point2_y|前処理対象の領域における左上の緯度|数値|35.75|
|point3_x|前処理対象の領域における左下の経度|数値|139.6|
|point3_y|前処理対象の領域における左下の緯度|数値|35.8|
|point4_x|前処理対象の領域における右下の経度|数値|139.3|
|point4_y|前処理対象の領域における右下の緯度|数値|35.85|
|start_date|前処理期間の開始日時|YYYY-MM-DD HH:MM:SS|2022-12-01 01:00:00|
|end_date|前処理期間の終了日時|YYYY-MM-DD HH:MM:SS|2022-12-01 03:00:00|
|freq |時間粒度|S、T、H、D、W、MS|pandasのresample()で指定可能な値の内、データ収集間隔より大きいもの|
|method|前処理の方法|min、max、ave|集約処理をを最小値、最大値、平均値で行う、緯度、経度、向き、速度は実測値を使用する|

  * 例  
```
tb_gis_mobile_stations_aggregate("mobile_data", "id", "datetime", "location", "direction speed", 
                                 139.5, 35.8, 139.6, 35.8, 139.6, 35.7, 139.5, 35.7, 
                                 "2022-12-01 10:00:00", "2022-12-01 20:00:00", "10T", "ave")
```

  * 返却値
 
|項目名|内容|
| ---- | ---- |
|id|移動観測局の識別番号|
|datetime|前処理済みデータの時刻|
|longitude|移動観測局の経度|
|latitude|移動観測局の緯度|
|datalist|data_column_listで指定したデータの前処理済みデータのリスト|

