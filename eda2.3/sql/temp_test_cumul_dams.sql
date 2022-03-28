SELECT * from france.rn_rna where idsegment ='FR210149'



-- this function returns the distance at which the dam lies according to the downstream point in percentage.
WITH quellejolieselection as (
SELECT view_obstruction.*, 
rn.geom FROM france.join_obstruction_rn  jo
JOIN france.rn on rn.idsegment=jo.idsegment
JOIN sudoang.view_obstruction on jo.op_id = ob_op_id
where jo.idsegment='FR210149')

SELECT 
1-ST_LineLocatePoint(ST_GeometryN(geom,1),ST_ClosestPoint(geom,the_geom)) 
from quellejolieselection


SELECT * FROM sudoang.view_obstruction limit 10

-- subpath('Top.Child1.Child2',0,-1) Top.Child1 (-1 removes the last segment)
With questcequonseclate as(
 SELECT idsegment as idsegmentsource FROM france.rn where idsegment in ('FR210026','FR210323')),

    downstreamjoin As (
 select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  questcequonseclate.idsegmentsource  
  from france.rn 
 JOIN questcequonseclate On rn.idsegment=questcequonseclate.idsegmentsource
 order by questcequonseclate.idsegmentsource)

 SELECT j.op_id, j.position_ouvrage_segment, downstreamjoin.* FROm downstreamjoin 
 JOIN france.join_obstruction_rn j on j.idsegment=downstreamjoin.vecteurchemin



