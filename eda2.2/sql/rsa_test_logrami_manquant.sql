-- tous sont dans view electrofishing

select sta_id from rsa.station except select sta_id from rsa.view_electrofishing; --482

select distinct sta_id, sta_code from rsa.station order by sta_code;--1504
select sta_zone,count(*) from rsa.station group by sta_zone order by sta_zone;
"adr";57
"ap";184
"bn";246
"bzh";588
"gdl";60
"lcvlogrami";281
"lcvmp";35
"rmc";7
"vil";46

"adr";57
"ap";184
"bn";246
"bzh";588
"gdl";60
"lcvlogrami";281
"lcvmp";35
"rmc";7
"vil";46


select distinct sta_zone from rsa.view_electrofishing --=> pas de logrami
"adr"
"ap"
"bn"
"bzh"
"gdl"
"lcvmp"
"rmc"
"vil"


select distinct st_id from rht.ersw where source='rsa' ; 1100 => 1356

select distinct st_id from rht.ersw where source='bd_map' 


--- pourtant ils sont dans ang
# A tibble: 9 x 2
    ang_zone `n()`
       <chr> <int>
1        adr 18499
2         ap  5855
3         bn 16826
4        bzh 33166
5        gdl  8488
6 lcvlogrami  2135
7      lcvmp  3219
8        rmc   128
9        vil 12757



SELECT op_iaa.iaa_op_id AS op_id, op_iaa.iaa_zone AS op_zone, NULL::numeric AS op_longueur, NULL::numeric AS op_cs_largeurlameeau, 1 AS op_nbrpassage, op_iaa.iaa_ang AS nbp1, NULL::integer AS nbp2, NULL::integer AS nbp3, op_iaa.iaa_ang AS totalnumber, op_iaa.iaa_vue AS vue, op_iaa.iaa_npnt AS op_nbrsondage
		FROM rsa.op_iaa

select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub

order by sta_code; --2718

with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub

order by sta_code)


/*
recherche d'une station manquante en Bretagne bzh_338
*/
with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='bzh_338'

select * from rht.ersw where st_id='bzh_338'; -- elle est là avec une geom et une densite 0 ?
select * from rht.ersw where st_id='bn_231'; -- disparue
with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='bn_231'

with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='bzh_566'; -- OK 2016

with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='lcvlogrami_64'; -- ?

with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='lcvlogrami_76'; -- ?


select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
join 

with vue_ang as(
select op_zone||'_'||op_sta_id as sta_code, * from rsa.operation left join rsa.anguille_ang  on (ang_op_id, ang_zone)=(op_id,op_zone))
select * from vue_ang where sta_code='bn_231'

with vue_ang as(
select op_zone||'_'||op_sta_id as sta_code, * from rsa.operation left join rsa.anguille_ang  on (ang_op_id, ang_zone)=(op_id,op_zone))
select * from vue_ang where sta_code='bzh_365'; -- pas d'anguilles

select * from rht.ersw where st_id='bzh_365'; -- une station => pourquoi je la vois pas ? 

with view as (
select * from (
select sta_zone||'_'||sta_id as sta_code, * from rsa.view_electrofishing ) sub
order by sta_code)
select * from view where sta_code='bzh_365'

-- j'ai un nbp1 

/*
     st_id_bdmap id_drain   st_id length  fnode  tnode nextdownid noeudmer noeudsource cumnbbar distance_sea distance_source id_drainmer
11156         365   207593 bzh_365 3972.2 207986 207785     207547        0           0       22     108.8111         14.4308      212340
                                                                                                                                                                                                                                                               chemin
11156 212340.212258.212208.212085.211878.211865.211635.211584.211609.211555.211465.211442.211443.211486.211539.211527.211519.211520.211545.211389.211372.211227.211038.211007.210736.210685.210458.210139.210108.210005.209957.209871.209810.209784.209735.209754.209
      tjan_moy tjuil_moy d_source elev_mean sfbvu strahler surf_bv slope module   l    h catchment_area up_catchment_area art_11_13 art_14 arable_21
11156     4.99      17.7       15      41.6   7.5        2      64  4.18   0.62 5.7 0.29        7502500          63242500    177500      0   3222500
      permcrop_22 pasture_23 hetagr_24 forest_31 natural_32_33 wetlands_4 inwat_51 marwat_52 up_art_11_13 up_art_14 up_arable_21 up_permcrop_22
11156           0    1370000   1487500   1242500             0          0        0         0       580000         0     24092500              0
      up_pasture_23 up_hetagr_24 up_forest_31 up_natural_32_33 up_wetlands_4 up_inwat_51 up_marwat_52 cs_nbdams cs_height cs_heightp cs_heightp08
11156      11945000     16282500     10082500           232500             0           0            0        21      25.7   31.38972      31.5656
      cs_heightp12 cs_heightp15 cs_heightp2      uga zonegeo op_cd_objectifpeche ef_fishingmethod op_cd_moyenprospection op_numero annee
11156     34.92511     41.42292    56.62645 Bretagne    <NA>                  NA             9999                    853   bzh_407  2009
      ob_starting_date op_listeespecescibles ef_fished_length ef_nbpas op_nbrsondage op_cs_largeurlameeau op_surfaceechantillon
11156       2009-06-11                   NON               NA        1            30                   NA                    NA
                             st_lieudit st_abcisse st_ordonnee totalnumber NCS ot_efficacite ot_estestime nbp1 nbtotalclasstail moyenprospection
11156 Le Sedon à Guégon (Pont Morhan)    3388650     2836434           0  NA            NA         <NA>    0                0           A pied
      methodeprospection ef_wetted_area source length_km catchment_area_km relative_distance     work n150 n150_300 n300_450 n450_600 n600_750 n750
11156                iaa            375    rsa    3.9722            7.5025         0.8829067 176.0907   NA       NA       NA       NA       NA   NA
      d_150 d_150_300 d_300_450 d_450_600 d_600_750 d_750 d fUGA N Num Suivi CVlameeau month week id_bv id_bvverif2            facade
11156    NA        NA        NA        NA        NA    NA 0  Bre 1 711    27        NA     6   23  2123       FALSE Golfe de Gascogne
            methodeprospection2 distance_sea_dam op_id  largeur riverarea riverareakm
11156 indice abondance anguille         140.2008  9735 5.694784  22620.82  0.02262082
*/



--- pour les operations de logrami

select distinct op_zone  from rsa.operation 
select * from rsa.operation where op_zone='lcvlogrami';