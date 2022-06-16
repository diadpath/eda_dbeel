# script d'import des données wama
###############################################################################

library(stringr)
library(RODBC)
library(stacomirtools)

rivernetwork <- "RIOS"
source("common/init.r")

#channel=odbcConnectAccess2007("Wama.mdb",uid = "", pwd = "nsldgmi")

channel <- odbcConnectAccess2007(str_c(datawd,"/loire/data/Wama.mdb"),uid = "", pwd = "nsldgmi")







query <- "select * from Opera"
t_ope <- sqlQuery(channel, query, errors = TRUE)
#colnames(t_ope) # Op_Id_PtPrelMetier
query <- "select * from poisson"
t_pois <- sqlQuery(channel, query, errors = TRUE)
#colnames(t_pois)
#query <- "select * from Reseaux , Sta_res, StaSandre 
#				where Sr_Id_Reseau =Id_Reseau 
#				and Sr_Id_Station=Id_Station"
query <-		"select * from Reseaux"
reseaux <- sqlQuery(channel, query, errors = TRUE)
query <-		"select * from Sta_res"
stares <- sqlQuery(channel, query, errors = TRUE)
query <-		"select * from StaSandre"
stasandre <- sqlQuery(channel, query, errors = TRUE)
query <-		"select * from station"
station <- sqlQuery(channel, query, errors = TRUE)
sqlTables(channel)
# marche pas
#t_sta <- reseaux %>% right_join(stares, by=c("codereseau")) %>%
#		right_join(stasandre, by=c("stcod"="CdStationMesureEauxSurface")) %>%


t_sta <- station %>%
	filter(stcod%in%unique(t_ope[,c("stcod")])) # 179


#nrow(t_sta)
# nrow(stasandre)

c("sta_id", "sta_source", "sta_layername", "sta_cod", "sta_lib", 
		"sta_X", "sta_Y", "SRID")

str(t_sta)
 t_sta %>% select(stcod, stlieu, stabs,
				 stola) %>%
		rename(sta_cod=stcod, 
				sta_lib=stlieu,
				sta_X=stabs, 
				sta_Y=stola) %>%
		filter(!is.na(stabs))
st_sta2 <-		st_as_sf(x = t_sta2, coords = c("sta_X", "sta_Y"), crs = 27572) %>% 
  st_transform(crs = 3035) %>% 
  mutate(SRID = 3035)
plot(st_sta2)
		
		
#sqlTables(channel)[sqlTables(channel)$TABLE_TYPE=="TABLE",]
		query <- "select * from PointPrelMetier"
t_ptPrel <- sqlQuery(channel, query, errors = TRUE)
t_op <- killfactor(merge(t_ptPrel,t_ope,by.x="Id_PtPrelMetier",by.y="Op_Id_PtPrelMetier"))
t_ops <- killfactor(merge(t_op,t_sta,by.x="Pm_Id_PointPrel",by.y="Sr_Id_PointPrel")) # operation ptprel station
#str(t_ops)

write.table(t_ops,sep=";",file="c:/temp/tops.csv",row.names=FALSE)
save(t_ops,t_sta,t_pois,t_ope,file=str_c(datawdy,"sauvbase.Rdata"))
# load(file=str_c(datawdy,"sauvbase.Rdata"))
odbcCloseAll()


t_ops2 <- t_ops[t_ops$ Sr_Id_Resea%in%c(1084,1412,771),c("CdStationMesureEauxSurface", "CodeSandreRdd","CdStationTemp","LbStationMesureEauxSurface","Pm_Id_PointPrel","Id_PtPrelMetier","Pm_Lieu", "Id_Reseau","CodeSandreRdd","Id_Opera","Op_code",
				"Op_Dtd","Op_Eau","Op_Hdb","Op_Lim","Op_Lng","Op_Lam","Op_Tmm","Op_Prf")]
t_ops2$Op_code=as.character(t_ops2$Op_code)
#t_pois[,"Po_Id_Opera"]
# ex(t_ops2[year(t_ops2$Op_Dtd)==2007,])
# ex(t_ops2[year(t_ops2$Op_Dtd)==2015,])
sta_ope_pois  <-  merge(t_ops2,t_pois,by.x="Id_Opera",by.y="Po_Id_Opera")
sta_ope_pois  <-  sta_ope_pois[sta_ope_pois$Po_CdTAxon==2038,]#12576 lignes



