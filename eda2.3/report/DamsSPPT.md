---
title: "Cumul des hauteurs d'ouvrage - base sudoang Spain Portugal"
author: "Cedric and Maria and Mathilde"
date: "07 november 2019"
output: 
  html_document:
    number_sections: true
---







# Importing data





## Calculating the distance projection for all segments

The [dbeel_view_obstruction](http://w3.eptb-vilaine.fr:8080/traceda/browser/eda/EDAcommun/sql/sudoang/dbeel_view_obstruction.sql) script creates a view of all dams in the sudoang area
**sudoang.view_obstruction** and creates the projection table for all countries
**france.join_obstruction_rn**, **spain.join_obstruction_rn** and **portugal.join_obstruction_rn**


```sql
DROP TABLE IF EXISTS spain.join_obstruction_rn;
CREATE TABLE spain.join_obstruction_rn as(
  
   with projection as (	
               SELECT r.idsegment, 
               op_id,               						
		geom,
		st_distance(r.geom,d.the_geom) as distance ,
        1-ST_LineLocatePoint(ST_GeometryN(r.geom,1),ST_ClosestPoint(r.geom,d. the_geom)) AS position_ouvrage_segment

		FROM spain.rn r
		JOIn sudoang.dbeel_obstruction_place  d
		ON st_dwithin(r.geom, d.the_geom,0.01)
		order by idsegment, distance desc)
SELECT distinct on (op_id) op_id, idsegment, position_ouvrage_segment  from projection
);
--20606 18s
```


<img src="C:/workspace/EDAdata/report2.3/images/distance_dam_spain.jpg" title="Projection of dams on segments with distance from the dowstream part of the segment (view_join_obstruction_rn) " alt="Projection of dams on segments with distance from the dowstream part of the segment (view_join_obstruction_rn) " width="400px" />

<img src="C:/workspace/EDAdata/report2.3/images/downstream_dam_from_segment_PT9621.png" title="Map showing the dams located downstream from idsegment PT9621 " alt="Map showing the dams located downstream from idsegment PT9621 " width="6500px" />

## Calculating all dams located downstream from one riversegment

The script is located there
[dbeel_view_obstruction](http://w3.eptb-vilaine.fr:8080/traceda/browser/eda/EDAcommun/sql/sudoang/dbeel_view_obstruction.sql)
All dams located downstream from one river segment are associated with this
river segment


```sql
# Portugal

DROP TABLE IF EXISTS portugal.join_obstruction_rn_downstream; CREATE TABLE
portugal.join_obstruction_rn_downstream as( WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as
vecteurchemin,   rn.idsegment AS idsegmentsource  
  from portugal.rn )  SELECT j.op_id,  j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin  JOIN portugal.join_obstruction_rn j ON
j.idsegment=downstreamjoin.vecteurchemin ); --217489 rows affected, 02:18
minutes execution time. SELECT * FROM portugal.join_obstruction_rn_downstream
where idsegmentsource='PT9621' ;

# dbeel_rivers

DROP TABLE IF EXISTS dbeel_rivers.join_obstruction_rn_downstream; CREATE TABLE
dbeel_rivers.join_obstruction_rn_downstream as( WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as
vecteurchemin,   rn.idsegment AS idsegmentsource  
  from dbeel_rivers..rn )  SELECT j.op_id,  j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin  JOIN portugal.join_obstruction_rn j ON
j.idsegment=downstreamjoin.vecteurchemin


# spain

DROP TABLE IF EXISTS spain.join_obstruction_rn_downstream; CREATE TABLE
spain.join_obstruction_rn_downstream as( WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as
vecteurchemin,   rn.idsegment AS idsegmentsource  
  from france.rn )  SELECT j.op_id,  j.position_ouvrage_segment,  downstreamjoin.*
FROm downstreamjoin  JOIN france.join_obstruction_rn j ON
j.idsegment=downstreamjoin.vecteurchemin );
```

The table joining segments and dams is formatted as following :


<html><head><style>table {border: medium solid #6495ed;border-collapse: collapse;width: 100%;} th{font-family: monospace;border: thin solid #6495ed;padding: 5px;background-color: #D0E3FA;background-image: url(sky.jpg);}td{font-family: sans-serif;border: thin solid #6495ed;padding: 5px;text-align: center;background-color: #ffffff;}.odd{background:#e8edff;}img{padding:5px; border:solid; border-color: #dddddd #aaaaaa #aaaaaa #dddddd; border-width: 1px 2px 2px 1px; background-color:white;}</style></head><body><table><tr><th colspan="4">select * from portugal.join_obstruction_rn_downstream limit 10</th></tr><tr><th>op_id</th><th>position_ouvrage_segment</th><th>vecteurchemin</th><th>idsegmentsource</th></tr><tr class="odd"><td>e36567c1-46bf-40a3-956e-f009a7887950</td><td>0,8388772288</td><td>PT27939</td><td>PT95884</td></tr>
<tr><td>5d32529c-33f2-43c7-b3b0-03fcc488227a</td><td>0,7060498951</td><td>PT94869</td><td>PT95900</td></tr>
<tr class="odd"><td>dd503433-3284-467a-851e-0ebdb142b3c9</td><td>0,1534516105</td><td>PT48634</td><td>PT9621</td></tr>
<tr><td>5fd89d5e-97a2-47b2-a910-cdcff188558b</td><td>0,1919817742</td><td>PT9832</td><td>PT9621</td></tr>
<tr class="odd"><td>5ff7bd6c-bee2-4a26-8158-80160ba96844</td><td>0,7741356929</td><td>PT9766</td><td>PT9621</td></tr>
<tr><td>4cc6bfd8-7cc6-482a-be68-d644f74a14a8</td><td>0,4381541402</td><td>PT48211</td><td>PT9621</td></tr>
<tr class="odd"><td>f4b30616-2197-41af-8d83-fc6cb571b54c</td><td>0,7961669318</td><td>PT47947</td><td>PT9621</td></tr>
<tr><td>e926497e-6b41-4141-a7c1-8a874e0587ab</td><td>0,5166282925</td><td>PT47948</td><td>PT9621</td></tr>
<tr class="odd"><td>aea98208-fd9c-4e47-9ec8-7c26d278b90a</td><td>0,3891534331</td><td>PT47627</td><td>PT9621</td></tr>
<tr><td>dfd0c148-4a11-4cff-bf3b-d997bbf554b9</td><td>0,5840848276</td><td>PT47716</td><td>PT9621</td></tr>
</table></body></html>







