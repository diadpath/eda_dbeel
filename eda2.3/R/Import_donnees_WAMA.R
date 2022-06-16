# script d'import des données wama
###############################################################################

library(stringr)
library(RODBC)
library(stacomirtools)
library(tidyverse)

rivernetwork <- "RIOS"
source("common/init.r")
load(file=paste(datawd,"/dataEDAcommun/methodeprospection.Rdata",sep=""))
load(file=paste(datawd,"/dataEDAcommun/t_moyenprospection.Rdata",sep=""))   	
load(file=paste(datawd,"/dataEDAcommun/t_objectifpeche.Rdata",sep=""))



#channel=odbcConnectAccess2007("Wama.mdb",uid = "", pwd = "nsldgmi")

channel <- odbcConnectAccess2007(str_c(datawd,"/loire/data/Wama.mdb"),uid = "", pwd = "nsldgmi")


stations_FD <- readr::read_csv(str_c(datawd,"/loire/data/stations_FD_EDALoire.csv"))


t_ope <- sqlQuery(channel, "select * from Opera", errors = TRUE)
#colnames(t_ope) # Op_Id_PtPrelMetier
t_pois <- sqlQuery(channel, "select * from poisson", errors = TRUE)
#colnames(t_pois)
#query <- "select * from Reseaux , Sta_res, StaSandre 
#				where Sr_Id_Reseau =Id_Reseau 
#				and Sr_Id_Station=Id_Station"
sum(t_pois$espoi=='ANG') # 762
reseaux <- sqlQuery(channel, "select * from Reseaux", errors = TRUE)
stares <- sqlQuery(channel, "select * from Sta_res", errors = TRUE)
stasandre <- sqlQuery(channel,"select * from StaSandre", errors = TRUE)
peche <- sqlQuery(channel, "select * from Peche", errors = TRUE)

pec <- peche %>% mutate(lib24=as.character(lib24)) %>% 
		inner_join(libelle %>% select(Licod,Linom), by=c("lib24"="Licod")) %>%
		rename(methodeprospection=Linom) %>%
		mutate(lib25=as.character(lib25)) %>% 
		inner_join(libelle %>% select(Licod,Linom), by=c("lib25"="Licod")) %>%
		rename(moyenprospection=Linom) %>%
		mutate(lib27=as.character(lib27)) %>% 
		inner_join(libelle %>% select(Licod,Linom), by=c("lib27"="Licod")) %>%
		rename(materielprospection=Linom)
libelle <- sqlQuery(channel, "select * from Libelle", errors = TRUE)
libchp <- sqlQuery(channel, "select * from Libchp", errors = TRUE)
query <-		"select * from station"
station <- sqlQuery(channel, query, errors = TRUE)
sqlTables(channel)
# marche pas
#t_sta <- reseaux %>% right_join(stares, by=c("codereseau")) %>%
#		right_join(stasandre, by=c("stcod"="CdStationMesureEauxSurface")) %>%
save(t_ope,t_sta,t_pois,station,file=str_c(datawd,"/loire/data/sauvbasewama.Rdata"))


# les données avec un # ne sont que dans station, on filtre pour ne prendre que les stations où on a des opérations
t_sta <- station %>%
		filter(stcod%in%unique(t_ope[,c("stcod")])) # 179


#nrow(t_sta)
# nrow(stasandre)
# les colonnes à créer sont les suivantes  (utiliser dput(colnames(X))
c("sta_id", "sta_source", "sta_layername", "sta_cod", "sta_lib", 
		"sta_X", "sta_Y", "SRID")

# On sectionne les colonnes d'intérêt (mais voir limites ça pourrait valoir le coup de les garder)
# Les données sont dans deux colonnes différentes et il faut bricoler pour les ramener
t_sta2 <- t_sta %>% select(stcod, stlieu, stabs, stola, StAbs93, Stola93) %>%	
		rename(sta_cod=stcod, 
				sta_lib=stlieu,
				sta_X=stabs, 
				sta_Y=stola,
				sta_X2154 =StAbs93,
				sta_Y2154 = Stola93) %>%
		mutate(SRID= 27572)
# On ramène les données de lambert93 dans les corrdonnées autres avec le bon SRID
t_sta3 <- bind_rows(
		t_sta2 %>% filter(is.na(sta_X)|sta_X==0) %>% mutate(sta_X=sta_X2154, sta_Y=sta_Y2154, SRID=2154),
		t_sta2 %>% filter(!is.na(sta_X)&sta_X!=0)
)
# certaines coordonnées il manque juste 2 millions en Y
t_sta3[t_sta3$sta_Y<10^6 & !is.na(t_sta3$sta_Y),"sta_Y"] <- t_sta3[t_sta3$sta_Y<10^6 & !is.na(t_sta3$sta_Y),"sta_Y"] +2*10^6
# celui là on sait pas le corriger (20 million au lieu de 2 millions) TODO à chercher
t_sta3 <- t_sta3[t_sta3$sta_Y!=22773879, ]

t_sta3 <- t_sta3 %>% filter(sta_X!=-9 & sta_X!=0 & !is.na(sta_X))

t_sta3[t_sta3$SRID==2154 & t_sta3$sta_Y2154<5*10^6, "SRID"] <- "27572"
t_sta3$sta_id <- (max(stations_FD$sta_id)+1):(nrow(t_sta3)+max(stations_FD$sta_id))
t_sta3$sta_source <- "FD37"
t_sta3$sta_layername <- NA

st_sta3 <- bind_rows(
t_sta3 %>% filter(SRID==2154) %>% st_as_sf(coords = c("sta_X", "sta_Y"), crs = 2154) %>% st_transform(3035),
t_sta3 %>% filter(SRID==27572) %>% st_as_sf(coords = c("sta_X", "sta_Y"), crs = 27572) %>% st_transform(3035)
) %>% bind_cols(st_coordinates(.))
#c("sta_id", "sta_source", "sta_layername", "sta_cod", "sta_lib", 
#		"sta_X", "sta_Y", "SRID")


st_wama37 <- st_sta3
save(st_wama37, file=str_c(datawd,"/loire/data/st_wama37.Rdata"))
# ces données sont collées aux autres dans le script FDLoire_import.R
# pour essai :
#con = dbConnect(Postgres(),
#		dbname=baseODBCrios[1],
#		host="localhost",
#		port=5432,
#		user=baseODBCrios[2], 
#		password=baseODBCrios[3])
#st_write(st_sta2, con, "temp_sta_37")

plot(st_sta2)


#sqlTables(channel)[sqlTables(channel)$TABLE_TYPE=="TABLE",]
#query <- "select * from PointPrelMetier"
#t_ptPrel <- sqlQuery(channel, query, errors = TRUE)
#t_op <- killfactor(merge(t_ptPrel,t_ope,by.x="Id_PtPrelMetier",by.y="Op_Id_PtPrelMetier"))
#t_ops <- killfactor(merge(t_op,t_sta,by.x="Pm_Id_PointPrel",by.y="Sr_Id_PointPrel")) # operation ptprel station
#str(t_ops)
#write.table(t_ops,sep=";",file="c:/temp/tops.csv",row.names=FALSE)
save(t_ops,t_sta,t_pois,t_ope,file=str_c(datawdy,"sauvbase.Rdata"))
# load(file=str_c(datawdy,"sauvbase.Rdata"))
odbcCloseAll()

# Operations ------------------


t_ops2 <- t_ops[t_ops$ Sr_Id_Resea%in%c(1084,1412,771),c("CdStationMesureEauxSurface", "CodeSandreRdd","CdStationTemp","LbStationMesureEauxSurface","Pm_Id_PointPrel","Id_PtPrelMetier","Pm_Lieu", "Id_Reseau","CodeSandreRdd","Id_Opera","Op_code",
				"Op_Dtd","Op_Eau","Op_Hdb","Op_Lim","Op_Lng","Op_Lam","Op_Tmm","Op_Prf")]
t_ops2$Op_code=as.character(t_ops2$Op_code)
#t_pois[,"Po_Id_Opera"]
# ex(t_ops2[year(t_ops2$Op_Dtd)==2007,])
# ex(t_ops2[year(t_ops2$Op_Dtd)==2015,])
sta_ope_pois  <-  t_sta3 %>%		
									inner_join(t_ope, by = c("sta_cod"="stcod")) %>%
									rename(opcod = Opcod) %>%
									inner_join(pec, by="opcod") %>%
									inner_join(t_pois, by="opcod")

sta_ope  <-  t_sta3 %>%		
									inner_join(t_ope, by = c("sta_cod"="stcod")) %>%
									rename(opcod = Opcod) %>%
									inner_join(pec, by="opcod") 						
							

#c("op_id", "op_cod", "op_sta_id", "op_dat", "op_typ", "op_length", 
#									"op_width", "op_nbpass", "op_p1", "op_p2", "op_p3", "op_p4", 
#									"op_p5", "op_dens", "op_nbeel", "n_EPA", "n_LPM", "n_LPP", "sta_source"
#							)

peches_FD <-readr::read_csv(str_c(datawd,"/loire/data/peches_FD_EDALoire.csv"))
nbpas <- sta_ope_pois  %>% 
		filter(espoi=="ANG") %>%
		group_by(opcod, popas) %>%
		summarize(nb_eel=sum(poeff)) %>%
		tidyr::pivot_wider(values_from="nb_eel", names_from=popas, names_prefix ="op_p") %>%
		right_join(sta_ope %>% select(opcod,penbp), by="opcod") %>%
		mutate(op_p1=replace_na(op_p1,0),
				op_p2=ifelse(penbp==2,replace_na(op_p2,0), op_p2)) 

operationsWAMA <- data.frame(
		"op_id"=  (max(peches_FD$op_id)+1):(nrow(sta_ope)+max(peches_FD$op_id)),
		"op_cod" = sta_ope$opcod,
		"op_sta_id" = sta_ope$sta_id,
		"op_dat"  = sta_ope$opdtd,
		"op_typ"  = sta_ope$methodeprospection,
		"moyenprospection" = sta_ope$moyenprospection,
		"op_length" = sta_ope$oplng,
		"op_width" = sta_ope$oplam,
		"op_nbpas" = sta_ope$penbp,
		"op_p1"= nbpas$op_p1,
		"op_p2"= nbpas$op_p2,
		"op_p3"= NA, 
		"op_p4"= NA,	
		"op_p5"= NA, 
		"op_dens"=NA,
		"op_nbeel"=sum(nbpas$op_p1,nbpas$op_p2, na.rm=TRUE),
		"n_EPA"= sta_ope$Nb_Standard, 
		"n_LPM"= NA,
		"n_LPP"=NA, 
		"sta_source"="FD37"		
)
save(operationsWAMA,file=str_c(datawd,"/loire/data/operationsWAMA.Rdata"))

# Biometries ------------------

#c("ang_id", "ang_op_id", "ang_pas", "ang_lng", "ang_pds", "ang_samplenumber", 
#		"ang_silver", "ang_pect", "ang_eye_diam_vert", "ang_eye_diam_horiz", 
#		"ang_neuromast", "ang_constrast")


biometry_FD <- readr::read_csv(str_c(datawd,"/loire/data/bio_FD_EDALoire.csv"))
sta_ope_pois_ang <-  sta_ope_pois  %>% 
		filter(espoi=="ANG")

biometry_WAMA <- data.frame(
"ang_id"=(max(biometry_FD$ang_id)+1):(nrow(sta_ope_pois_ang)+max(biometry_FD$ang_id)),
"ang_op_id" = sta_ope_pois_ang$opcod, 
"ang_pas" = sta_ope_pois_ang$popas, 
"ang_lng" = sta_ope_pois_ang$polmi, 
"ang_pds"= ifelse(sta_ope_pois_ang$popds==0, NA, sta_ope_pois_ang$popds),
"ang_samplenumber" = NA, 
		"ang_silver" =NA, 
		"ang_pect" = NA, 
		"ang_eye_diam_vert" = NA, 
		"ang_eye_diam_horiz" = NA, 
		"ang_neuromast" = NA, 
		"ang_constrast" = NA)

biometry_WAMA$ang_pds[biometry_WAMA$ang_pds>=2500 & !is.na(biometry_WAMA$ang_pds)]<- 
		biometry_WAMA$ang_pds[biometry_WAMA$ang_pds>=2500 & !is.na(biometry_WAMA$ang_pds)]/10

with(biometry_WAMA,plot(ang_lng, ang_pds))

save(biometry_WAMA,file=str_c(datawd,"/loire/data/biometry_WAMA.Rdata"))
