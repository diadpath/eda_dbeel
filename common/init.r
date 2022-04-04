# Nom fichier :        init.R
# Projet :             EDA/EDAcommun
#
# EDA2.0 
# ONEMA, IAV, IRSTEA

###############################################################################

# initiation des parametres en fonctions des utilisateurs
#rm(list=ls(all=TRUE))
# le fichier XML doit se trouver dans le répertoire d'EDA qui est chargé au départ

# fonction de chargement des packages seulement pour XML le reste sera dans libraries

# this function should be used instead of 'require'. It allows to install the package if necessary
load_library=function(necessary) {
	if(!all(necessary %in% installed.packages()[, 'Package']))
		install.packages(necessary[!necessary %in% installed.packages()[, 'Package']], dep = T)
	for(i in 1:length(necessary))
		library(necessary[i], character.only = TRUE)
}

load_library("XML")
load_library("stringr")
load_library("gplots") # necessaire pour faire les echelles de couleurs d'un des graphe
# Ce fichier doit ?tre ? la racine de EDA
if (rivernetwork== "RIOS")
{
filexml <- "EDAload23.xml"
} else {
filexml <- "EDAload.xml"	
}
doc = xmlInternalTreeParse(filexml)
doc=xmlRoot(doc)   # vire les infos d'ordre generales
tableau_config = xmlSApply(doc, function(x) xmlSApply(x, xmlValue)) # renvoit une liste


les_bases<-tableau_config[2]
datawd=tableau_config[["Utilisateur"]][["datawd"]]
pgwd=tableau_config[["Utilisateur"]][["pgwd"]]
shpwd=tableau_config[["Utilisateur"]][["shpwd"]]
imgwd=tableau_config[["Utilisateur"]][["imgwd"]]
baseODBCOracle=c(tableau_config[["base"]][["lienODBCOracle"]],tableau_config[["base"]][["uidOracle"]],tableau_config[["base"]][["pwdOracle"]])
baseODBC=c(tableau_config[["base"]][["lienODBCBar"]],tableau_config[["base"]][["uidBar"]],tableau_config[["base"]][["pwdBar"]])
baseODBCccm=c(tableau_config[["base"]][["lienODBCccm"]],tableau_config[["base"]][["uidccm"]],tableau_config[["base"]][["pwdccm"]])
baseODBCdbeel=c(tableau_config[["base"]][["lienODBCdbeel"]],tableau_config[["base"]][["uiddbeel"]],tableau_config[["base"]][["pwddbeel"]])
baseODBCrht=c(tableau_config[["base"]][["lienODBCrht"]],tableau_config[["base"]][["uidrht"]],tableau_config[["base"]][["pwdrht"]])
baseODBCdevalpomi=c(tableau_config[["base"]][["lienODBCdevalpomi"]],tableau_config[["base"]][["uiddevalpomi"]],tableau_config[["base"]][["pwddevalpomi"]])
baseODBCrios=c(tableau_config[["base"]][["lienODBCrios"]],tableau_config[["base"]][["uidrios"]],tableau_config[["base"]][["pwdrios"]])

setwd(pgwd)
# loading RODBC connection classes
#setGeneric("connect",def=function(object,...) standardGeneric("connect"))
setGeneric("loaddb",def=function(object,...) standardGeneric("loaddb"))
setGeneric("loaddb2",def=function(object,...) standardGeneric("loaddb2"))
setGeneric("loadrdata",def=function(object,...) standardGeneric("loadrdata"))
#setGeneric("loaddbdebit",def=function(object,...) standardGeneric("loaddbdebit"))
setGeneric("import_column",def=function(object,...) standardGeneric("import_column"))
setGeneric("import_columns",def=function(object,...) standardGeneric("import_columns"))
setGeneric("pretty_table",def=function(object,...) standardGeneric("pretty_table"))
setGeneric("insert_into",def=function(object,...) standardGeneric("insert_into"))
setGeneric("display",def=function(object,...) standardGeneric("display"))
setGeneric("cumulated_dam_impact",def=function(object,...) standardGeneric("cumulated_dam_impact"))
setGeneric("cumulated_dam_impact2",def=function(object,...) standardGeneric("cumulated_dam_impact2"))
setGeneric("distance_sea",def=function(object,...) standardGeneric("distance_sea"))
setGeneric("distance_sea_fromnodes",def=function(object,...) standardGeneric("distance_sea_fromnodes"))
setGeneric("distance_source",def=function(object,...) standardGeneric("distance_source"))
setGeneric("pass_joined_column",def=function(object,...) standardGeneric("pass_joined_column"))
setGeneric("loaddb_all",def=function(object,...) standardGeneric("loaddb_all"))
setGeneric("loaddb_width",def=function(object,...) standardGeneric("loaddb_width"))
setGeneric("upstream_area",def=function(object,...) standardGeneric("upstream_area"))
setGeneric("upstream_segments",def=function(object,...) standardGeneric("upstream_segments"))
setGeneric("stream_order",def=function(object,...) standardGeneric("stream_order"))
setGeneric("bassin_area",def=function(object,...) standardGeneric("bassin_area"))
setGeneric("viewvector",def=function(object,...) standardGeneric("viewvector"))
setGeneric("calculatedensities",def=function(object,...) standardGeneric("calculatedensities"))
setGeneric("distance_upstream_between_stations",def=function(object,...) standardGeneric("distance_upstream_between_stations"))
setGeneric("map",def=function(object,...) standardGeneric("map"))
setGeneric("loadshp",def=function(object,...) standardGeneric("loadshp"))
setGeneric("decale",def=function(object,...) standardGeneric("decale"))
setGeneric("exportshape",def=function(object,...) standardGeneric("exportshape"))
setGeneric("segment_mortality",def=function(object,...) standardGeneric("segment_mortality"))
setGeneric("result_for_a_drain",def=function(object,...) standardGeneric("result_for_a_drain"))
setGeneric("turbine_mortality",def=function(object,...) standardGeneric("turbine_mortality"))
setGeneric("save_to_maria",def=function(object,...) standardGeneric("save_to_maria"))
setGeneric("silvering_stages",def=function(object,...) standardGeneric("silvering_stages"))
setGeneric("plot_categorical",def=function(object,...) standardGeneric("plot_categorical"))
setGeneric("loaddbflow",def=function(object,...) standardGeneric("loaddbflow"))
source("EDACCM/libraries.r")
#source("EDACCM/ConnexionODBC.r") # now loaded from stacomirtools
#source("EDACCM/RequeteODBC.r")
#source("EDACCM/RequeteODBCwhere.r")
#source("EDACCM/RequeteODBCwheredate.r")


source("EDACCM/BaseEda.R")
if(rivernetwork!="RIOS" & rivernetwork!="RHT"){
source("EDACCM/BaseEdaCCM.R")
source("EDACCM/BaseEdaCCMRiversegments.R")
source("EDACCM/BaseEdaCCMRiversegmentsROE.R")
source("EDACCM/BaseEdaCCMRiversegmentstemp.R")
source("EDACCM/BaseEdaCCMRiversegmentsbdmap.R")
source("EDACCM/BaseEdaCCMRiversegmentsdbeel.R")
source("EDACCM/BaseEdaCCMRiversegmentsgeol.R")
source("EDACCM/BaseEdamodel.R")
source("EDACCM/BaseEdaCCMRiversegmentsclc.R")
source("EDACCM/BaseEdaCCMlakes.R")
source("EDACCM/utilitaires.r") # version d�bugg�e de progress
source("EDACCM/fonctions_graphiques.r")
source("EDACCM/prediction_functions.R")
}
# chargement des fonctions n�cessaires pour les requ�tes
# fonction de connection � la base pour envoi d'une requ�te sql
source("EDACCM/fn_sql_0.r")
#fonction pour lire les objects de type sql, et renvoyer une requ�te
source("EDACCM/fn_sql_readsql.R")
# transformation du vecteur de codes g�n�riques en liste qui puisse �tre comprise
# en sql
# source("EDACCM/vector_to_listsql.r")
# pour pouvoir passer un argument en t�te de script en sweave
if (!exists("rivernetwork")){
rivernetwork<-select.list(c("CCM","RHT","RIOS"),title="Select your river network",multiple=FALSE)
}
if(rivernetwork=="RHT"){
	source("EDARHT/BaseEdaRHT.r")
	source("EDARHT/BaseEdaRHTRiversegments.r")
	source("EDARHT/BaseEdaRHTRiversegmentsROE.r")
	source("EDARHT/BaseEdaRHTRiversegmentsbdmap.r")
	source("EDARHT/BaseEdaRHTmodel.r")
	source("EDARHT/RHTAnalyse.r")
	source("EDARHT/RHTAnalyseERS.r")
	source("EDARHT/prediction_functions.R")
	source("EDARHT/analyse_22_data_functions.R")
	source("EDARHT/analyse_21_functions_ers.R")
	source("EDARHT/BaseEdaRHTpate.R")
	source("EDARHT/BaseEdaRHTpatedebit.R")
	source("EDARHT/BaseEdaRHTpatefrance.R")
	source("EDARHT/BaseEdaRHTpatedeval.R")
	source("EDARHT/function_PATE.R")
}
if(rivernetwork=="RIOS"){
  source("EDA_Rios/BaseEdaRios.R")
  source("EDA_Rios/BaseEdaRiosRiversegments.R")
  source("EDA_Rios/BaseEdaDams.R")
  source("EDA_Rios/BaseEdaRiosRiversegmentsDam.R")
  source("EDA_Rios/BaseEdaRiosRiversegmentsDbeel.R")
  source("EDA_Rios/BaseEdaRiosRiversegmentsDbeelSilver.R")
#  source("EDA_Rios/BaseEdaRiosRiversegmentsgeobs.R")
	source("EDA_Rios/BaseEdaRiosRiversegmentsDamTurb.R")
}

options(stringsAsFactors=FALSE)

options(width=150)
getUsername <- function(){
	name <- Sys.info()[["user"]]
	return(name)
}
if(getUsername() == 'cedric.briand')
{
	options(sqldf.RPostgreSQL.user = userlocal, 
			sqldf.RPostgreSQL.password = passwordlocal,
			sqldf.RPostgreSQL.dbname = "eda2.3",
			sqldf.RPostgreSQL.host = "localhost",# 1.100.1.6 w3.eptb-vilaine.fr
			sqldf.RPostgreSQL.port = 5432)
}
#if(getUsername() == 'mpa
#{
#	options(sqldf.RPostgreSQL.user = "postgres", 
#			sqldf.RPostgreSQL.password = passwordlocal,
#			sqldf.RPostgreSQL.dbname = "ouvragelb",
#			sqldf.RPostgreSQL.host = "w3.eptb-vilaine.fr", 
#			sqldf.RPostgreSQL.port = 5432)
#}
if(getUsername() == 'mmateo')
{
	options(sqldf.RPostgreSQL.user = "postgres", 
			sqldf.RPostgreSQL.password = passwordlocal,
			sqldf.RPostgreSQL.dbname = "eda2.3",
			sqldf.RPostgreSQL.host = "localhost", 
			sqldf.RPostgreSQL.port = 5432)
}

if(getUsername() == 'soizic.fabre')
{
	options(sqldf.RPostgreSQL.user = "postgres", 
			sqldf.RPostgreSQL.password = passwordlocal,
			sqldf.RPostgreSQL.dbname = "eda2.3",
			sqldf.RPostgreSQL.host = "localhost", 
			sqldf.RPostgreSQL.port = 5432)
}

if(getUsername() == 'cboulenger')
{
	options(sqldf.RPostgreSQL.user = "postgres", 
			sqldf.RPostgreSQL.password = passwordlocal,
			sqldf.RPostgreSQL.dbname = "eda2.3",
			sqldf.RPostgreSQL.host = "localhost", 
			sqldf.RPostgreSQL.port = 5432)
}
if(getUsername() == 'lbeaulaton')
{
	load_library("getPass")
	options(sqldf.RPostgreSQL.user = "lolo", 
			sqldf.RPostgreSQL.password = getPass("postgresql pwd"),
			sqldf.RPostgreSQL.dbname = "eda2.3",
			sqldf.RPostgreSQL.host = "localhost", 
			sqldf.RPostgreSQL.port = 5432)
}
if(getUsername() == 'user')
{
	options(sqldf.RPostgreSQL.user = "postgres", 
			sqldf.RPostgreSQL.password = passworddistant,
			sqldf.RPostgreSQL.dbname = "eda2",
			sqldf.RPostgreSQL.host = "w3.eptb-vilaine.fr", #1.100.1.6 #109.2.236.82
			sqldf.RPostgreSQL.port = 5432)
}