# Nom fichier :        init.R
# version eda2.3 eda_dbeel
###############################################################################


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

