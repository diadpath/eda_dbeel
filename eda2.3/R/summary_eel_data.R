# Name : summary_eel_data.R
# Date : 17/08/2023
# Authors: Maria Mateo & Cedric Briand
# R 4.1.1
#
# The following script summarizes database for the data paper
#
###############################################################################

library(dplyr)
library(sf)
library(RPostgreSQL)
library(sqldf)


# -- Set worknig directory ---- ####

ddatawd <- paste0("C:/workspace/EDAdata/report2.3/data/")
dataproc <- paste0("c:/use/escritorio/zenodo_electrofishing_data")

# -- Read data ----  ####

# Connect to the database
con = dbConnect(RPostgres::Postgres(),
		dbname="eda2.3",
		host="localhost",
		port=5432,
		user= "postgres",
		password= "postgres")

# 	Rivers
rn_rna <- dbGetQuery(con, "select * FROM dbeel_rivers.rn_rna")

# 	Electrofishing
load(file = paste0(ddatawd, "frsppt_12_2020.Rdata")) # 47484 M
# write.csv(frsppt, paste0(dataproc, "/frsppt.csv"))

# load(file = paste0(ddatawd,"vvv.Rdata"))
load(file = paste0(ddatawd, "table_ind.Rdata")) # 47484 M

# load(file = paste0(ddatawd, "rios_spain.RData"))

# 	Obstacles
dams <- read.csv("c:/use/escritorio/zenodo_obstacle_data/obstacles.csv")
#		In Qgis, buffer 50m to the riversegments, and intersect with dams.csv (from zenodo)
#		To have basin, country and codesea information
dams_rn <- st_read("c:/use/escritorio/zenodo_obstacle_data/obstacles_rn/obstacles.shp")



# -- Summarize RIVERS ----  ####

Manche <- rn_rna[rn_rna$emu %in% c("FR_Sein", "FR_Arto") | rn_rna$basin %in% c("côtiers de la rance (nc) au trieux (c) [J1]",
				"côtiers du trieux (nc) à la pointe de bloscon [J2]", "côtiers du couesnon (c) à la rance (c) [J0]"),]

NorthSea <- rn_rna[rn_rna$emu %in% c("FR_Meus", "FR_Rhin"),]

rivers <- rn_rna[!(rn_rna$idsegment %in% c(Manche$idsegment, NorthSea$idsegment)),]

rivers %>%
		group_by(codesea, country) %>%
		summarise(count_sta = n_distinct(idsegment),
				length = sum(lengthm)/1000,
				riversurface = sum(wettedsurfacem2, na.rm = TRUE)/10^6,
				othersurface = sum(wettedsurfaceotherm2, na.rm = TRUE)/10^6)

#nb_rios <- rios@data %>%
#		group_by(codesea) %>%
#		summarise(count_sta = n_distinct(idsegment))



# -- Summarize STATIONS ----  ####

#	1. Number of stations and operations

# 		Verifying that the results between vvv and frsspt are the same!
#		frsppt dataframe refers to projected and cleaned reults
#frsppt %>%
#		group_by(country) %>%
#		summarise(count_sta = n_distinct(op_id),
#				count_op = n_distinct(ob_id))
#
#vvv$survey$portugal

sta_manche <- frsppt[frsppt$emu %in% c("FR_Sein", "FR_Arto") | frsppt$basin %in% c("côtiers de la rance (nc) au trieux (c) [J1]",
				"côtiers du trieux (nc) à la pointe de bloscon [J2]", "côtiers du couesnon (c) à la rance (c) [J0]"),]

sta_north <- frsppt[frsppt$emu %in% c("FR_Meus", "FR_Rhin"),]

frsppt_ex <- frsppt[!(frsppt$idsegment %in% c(sta_manche$idsegment, sta_north$idsegment)),]

#		By Ocean and country
frsppt_ex%>%
		group_by(codesea, country) %>%
		summarise(count_sta = n_distinct(op_id),
				count_op = n_distinct(ob_id))


sta_north[sta_north$ef_nbpas==1,] %>%
		group_by(codesea, country) %>%
		summarise(count_op = n_distinct(ob_id))

sta_north[sta_north$ef_nbpas>1 | is.na(sta_north$ef_nbpas),] %>%
		group_by(codesea, country) %>%
		summarise(count_op = n_distinct(ob_id))


#		By EMU (table 1 in draft)
nb_station <- frsppt %>%
		group_by(emu) %>%
		summarise(count_sta = n_distinct(op_id),
				count_op = n_distinct(ob_id))


#	2. Number of operations and eels sampled
ind_manche <- table_ind[table_ind$emu %in% c("FR_Sein", "FR_Arto") | table_ind$basin %in% c("côtiers de la rance (nc) au trieux (c) [J1]",
				"côtiers du trieux (nc) à la pointe de bloscon [J2]", "côtiers du couesnon (c) à la rance (c) [J0]"),]

ind_north <- table_ind[table_ind$emu %in% c("FR_Meus", "FR_Rhin"),]

ind_ex <- table_ind[!(table_ind$idsegment %in% c(ind_manche$idsegment, ind_north$idsegment)),]

#		By Ocean and country
ind_manche %>%
		group_by(codesea, country) %>%
		summarise(count_sta = n_distinct(op_id),
				count_op = n_distinct(ob_id),
				count_pass = n_distinct(ef_nbpas, na.rm = TRUE),
				nb_eels = n())

#		By EMU (table 1 in draft)
nb_station2 <- ind_ex %>%
		group_by(emu) %>%
		summarise(count_sta = n_distinct(op_id),
				count_op = n_distinct(ob_id),
				count_pass = n_distinct(ef_nbpas, na.rm = TRUE),
				nb_eels = n())

#	Do we need the range of years?
#years_frsppt <- frsppt %>%
#		group_by(emu) %>%
#		distinct(year) %>%
#		arrange(emu, year)
# write.csv(years_frsppt, paste0(dataproc, "/years_frsppt.csv"))



# -- Summarize OBSTACLES ----  ####

# nrow(dams_rn)				116825
# n_distinct(dams_rn$op_id)	106399
# names(dams_rn)	

dams_manche <- dams_rn[dams_rn$emu %in% c("FR_Sein", "FR_Arto") | dams_rn$basin %in% c("côtiers de la rance (nc) au trieux (c) [J1]",
				"côtiers du trieux (nc) à la pointe de bloscon [J2]", "côtiers du couesnon (c) à la rance (c) [J0]"),]

dams_north <- dams_rn[dams_rn$emu %in% c("FR_Meus", "FR_Rhin"),]

dams_final <- dams_rn[!(dams_rn$idsegment %in% c(dams_manche$idsegment, dams_north$idsegment)),]


summary_dams <- dams_final %>% 
		st_set_geometry(NULL) %>%
		group_by(codesea, country, obstruct_1) %>%
		summarise(count_sta = n_distinct(op_id))

summary_dams_m <- dams_manche %>% 
		st_set_geometry(NULL) %>%
		group_by(codesea, country, obstruct_1) %>%
		summarise(count_sta = n_distinct(op_id))

summary_dams_n <- dams_north %>% 
		st_set_geometry(NULL) %>%
		group_by(codesea, country, obstruct_1) %>%
		summarise(count_sta = n_distinct(op_id))

summary_dams2 <- rbind(summary_dams, summary_dams_m, summary_dams_n)
# fwrite(summary_dams2, "c:/use/escritorio/zenodo_obstacle_data/obstacles_rn/summary_dams.csv")

##	Searching the op_id of obstacles with the idsegment
#sp <- dbGetQuery(con, "select * FROM spain.view_join_obstruction_rn")
#fr <- dbGetQuery(con, "select * FROM france.join_obstruction_rn")
#pt <- dbGetQuery(con, "select * FROM portugal.join_obstruction_rn")
## op_id; idsegment
#nrow(sp); n_distinct(sp$op_id)
#nrow(fr); n_distinct(fr$op_id)
#nrow(pt); n_distinct(pt$op_id)
##	Merging with dams csv (from zenodo)
#dams_pt <- merge(dams, pt[, c("op_id", "idsegment")], by = "op_id")
#dams_fr <- merge(dams, fr[, c("op_id", "idsegment")], by = "op_id")
#dams_sp <- merge(dams, sp[, c("op_id", "idsegment")], by = "op_id")
#
#dams_manche <- dams_fr[dams_fr$idsegment %in% Manche$idsegment,]
#dams_north <- dams_fr[dams_fr$idsegment %in% NorthSea$idsegment,]
#
#dams_fr2 <- dams_fr[!(dams_fr$idsegment %in% c(Manche$idsegment, NorthSea$idsegment)),]
#
#final_dams <- rbind(dams_pt,dams_fr2,dams_sp)
#
##	The codesea is still missing!
##		There aren't all the dams!
#final_dams %>%
#		group_by(country) %>%
#		summarise(count_sta = n_distinct(op_id))


# -- Info about dist to Gibraltar ----  ####

dist_gib <- merge() 



#	1. Plots

png(str_c(imgwd,"density_per_country.png"),7,7,units="in",res=300)
ggplot(frsppt)+
		stat_density(aes(x=log(densCS),fill=country),position="dodge",alpha=0.5) +
		scale_fill_manual(values=c("FR"=bluesudo,"SP"=orangesudo,"PT"=greensudo)) +
		theme_bw()
# Lower densities in France
dev.off()

png(str_c(imgwd,"density_per_country_per_method.png"),7,7,units="in",res=300)
ggplot(frsppt)+
		stat_density(aes(x=log(densCS),fill=country),position="dodge",alpha=0.5) +
		scale_fill_manual(values=c("FR"=bluesudo,"SP"=orangesudo,"PT"=greensudo)) +
		facet_wrap( ~ ef_fishingmethod) +
		theme_bw()
# Lower densities in France
dev.off()

png(str_c(imgwd,"densityplot_of_density_per_data_provider.png"),7,7,units="in",res=300)
frsppt[frsppt$densCS>0 &!is.na(frsppt$densCS),] %>% 
		left_join(frsppt[frsppt$densCS>0 &!is.na(frsppt$densCS),] %>%
						group_by(data_provider) %>% 
						summarize("count"=n())) %>%
		ggplot()+
		stat_density(aes(x=densCS, fill= country), alpha=0.7)+
		scale_x_continuous(limits=c(0,2)) +
		facet_wrap( ~  data_provider + count , scales="free")  +		
		scale_fill_manual(values=c("FR"=bluesudo,"SP"=orangesudo,"PT"=greensudo)) +
		theme_bw() +
		theme(panel.grid.major = element_blank(),
				panel.grid.minor = element_blank(),
				strip.background = element_blank(),
				panel.border = element_rect(colour = "black"))
dev.off()


frsppt$imputed_area <- is.imputed(frsppt$ef_wetted_area)

png(str_c(imgwd,"density_altitude_transport_imputedarea.png"),7,7,units="in",res=300)
p <- ggplot(frsppt, aes(altitudem, densCS))
p + geom_point(aes(colour = country),size=0.5) +
		scale_colour_manual(values=c("FR"=bluesudo,"SP"=orangesudo,"PT"=greensudo)) +
		facet_grid(imputed_area~ transport)	+		
		theme_bw() +
		theme(	panel.grid.minor = element_blank(),
				strip.background = element_blank(),
				panel.border = element_blank())
dev.off()

png(str_c(imgwd,"density_altitude_dams_imputedarea.png"),7,7,units="in",res=300)
p <- ggplot(frsppt, aes(cs_height_10_n, densCS)) +
		geom_point(aes(colour = country),size=0.5) +
		scale_colour_manual(values=c("FR"=bluesudo,"SP"=orangesudo,"PT"=greensudo)) +
		facet_wrap(~ transport)	+		
		theme_bw() +
		theme(	panel.grid.minor = element_blank(),
				strip.background = element_blank(),
				panel.border = element_blank())
print(p)
dev.off()


x11()
frsppt2 <- subset(frsppt, cumheightdam>200 & densCS>0)
p <- ggplot(frsppt2, aes(distanceseam, altitudem))
p + geom_point(aes(colour = densCS*100))+facet_wrap(~ country) # Low densities except one point in Spain!



# Nb of operations per EMU
tt <- as.data.frame(table(frsppt$emu))
colnames(tt) <- c("emu", "nb")

x11()
ggplot(tt) + geom_col(aes(x=emu, y=nb)) + theme_bw() + coord_flip()

# -------load the files for EMU and country and save them ---------------------------------------------------
library("ggspatial")



dsn <-  paste0("PG:dbname='wgeel' host='localhost' port ='5432'",
		" user='", userlocal,
		"' password='", passwordlocal,"'")

#map of country
query <- "SELECT cou_code,cou_country, geom  
		FROM REF.tr_country_cou WHERE cou_code IN ('FR','ES','PT') "
cou <- st_read(dsn= dsn,  layer="country",query=query)
#plot(st_geometry(cou), xlim=c(-7,11.5),ylim=c(36,53))

# map of emus
query <- "SELECT * FROM REF.tr_emu_emu WHERE emu_cou_code  IN ('FR','ES','PT') AND emu_wholecountry=FALSE"
emu <- st_read(dsn= dsn, layer="i don't want no warning" , query=query)

# gets the centerpoints coordinates for the emus

query <- "SELECT emu_nameshort, st_centroid(geom) as geom FROM REF.tr_emu_emu WHERE emu_cou_code  IN ('FR','ES','PT') AND emu_wholecountry=FALSE"
emu_c <- st_read(dsn= dsn,  layer="emu",query=query)
# plot(st_geometry(emu))
# plot(emu_c, add=TRUE)

save(emu,cou,emu_c, file=str_c(ddatawd,"emu_cou.Rdata"))

load(file=str_c(ddatawd,"emu_cou.Rdata"))

op_id_c <- frsppt %>% filter(!is.na(emu)) %>% select (op_id, emu, country) %>% 
		distinct() %>%
		dplyr::rename("emu_nameshort"="emu")%>%
		group_by(emu_nameshort, country) %>% 
		summarize(n=n(), .groups = "drop")
unique(emu_c$emu_nameshort)
print(op_id_c, n=100)
op_id_sf <- merge(emu_c,op_id_c, by="emu_nameshort")
print(op_id_sf, n=100)
op_id_sf  <- cbind(op_id_sf,st_coordinates(op_id_sf))
op_id_sf[which(op_id_sf$emu_nameshort=='PT_Port'& op_id_sf$country=='PT'),c("X","Y")] <- c(-8.33,39.48)
cols <- c("FR" = bluesudo, "SP" = orangesudo,"PT"=greensudo)

png(filename=str_c(imgwd,"number_stations.png"),width = 8, height = 8, units = 'in', res = 300)
ggplot(data = emu) +  geom_sf(fill= "antiquewhite") +
		geom_point(aes(x=X, y=Y, size=n , col=country), data=op_id_sf, alpha=0.7)+
		scale_colour_manual(values=cols)+
		scale_size_continuous(range=c(0.5,15)) +
		xlab("Longitude") + 
		ylab("Latitude") + 
		ggtitle("Number of stations")+ 
		ggspatial::annotation_scale(location = "bl", width_hint = 0.5) +
		ggspatial::annotation_north_arrow(location = "tr", which_north = "true", 
				pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"),
				style = ggspatial::north_arrow_fancy_orienteering) +
		coord_sf(xlim=c(-10,11.5),ylim=c(32,53))+
		theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
				panel.background = element_rect(fill = "white"))
dev.off()
# Operations ---------------------------------------

ob_id_c <- frsppt %>% filter(!is.na(emu)) %>% select (ob_id, emu, country) %>% 
		dplyr::rename("emu_nameshort"="emu")%>%
		group_by(emu_nameshort, country) %>% 
		summarize(n=n())
ob_id_sf <- merge(emu_c,ob_id_c, by="emu_nameshort")
ob_id_sf  <- cbind(ob_id_sf,st_coordinates(op_id_sf))
ob_id_sf[which(ob_id_sf$emu_nameshort=='PT_Port'& ob_id_sf$country=='PT'),c("X","Y")] <- c(-8.33,39.48)
png(filename=str_c(imgwd,"number_operations.png"),width = 8, height = 8, units = 'in', res = 300)
g0 <-ggplot(data = emu) +  geom_sf(fill= "cornsilk") +
		geom_point(aes(x=X, y=Y, size=n , col=country), data=ob_id_sf, alpha=0.9)+
		scale_colour_manual(values=cols)+
		scale_size_continuous(range=c(0.5,15)) +
		xlab("Longitude") + 
		ylab("Latitude") + 
		ggtitle("Number of operations")+ 
		ggspatial::annotation_scale(location = "bl", width_hint = 0.5) +
		ggspatial::annotation_north_arrow(location = "tr", which_north = "true", 
				pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"),
				style = ggspatial::north_arrow_fancy_orienteering) +
		coord_sf(xlim=c(-10,11.5),ylim=c(32,53))+
		theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
				panel.background = element_rect(fill = "white"))
print(g0)
dev.off()


# Number of data per provider -----------------------------------------------------------------

dapr <- sqldf("SELECT * FROM dbeel.data_provider join dbeel.establishment on dp_et_id=et_id")

# estalishment station count
es_st_c <- frsppt %>% filter(!is.na(data_provider)) %>% select (data_provider,op_id) %>% 
		distinct() %>%
		group_by(ob_dp_name) %>% 
		summarize(n=n()) %>% 
		left_join(dapr,by=c("ob_dp_name"="dp_name"))%>%
		mutate(et_establishment_name=recode(et_establishment_name,"ONEMA"="AFB")) %>%	
		tidyr::unite(col="es", c("et_establishment_name","ob_dp_name"), sep=', ', remove = FALSE) %>%
		arrange(es) %>%
		select(es,n) %>%ex() # exported to excel, pasted into powerpoint

es_op_c <- frsppt %>% filter(!is.na(ob_dp_name)) %>% select (ob_dp_name,ob_id) %>% 
		distinct() %>%
		group_by(ob_dp_name) %>% 
		summarize(n=n()) %>% 
		left_join(dapr,by=c("ob_dp_name"="dp_name"))%>%
		mutate(et_establishment_name=recode(et_establishment_name,"ONEMA"="AFB")) %>%	
		tidyr::unite(col="es", c("et_establishment_name","ob_dp_name"), sep=', ', remove = FALSE) %>%
		arrange(es) %>%
		select(es,n) %>%ex() # exported to excel, pasted into powerpoint

# exported to (eda2.3/table/table_summary_number_op_st.xlsx)


# animation --(DOES NOT WORK WITH MAP BUT SAVE CODE FOR LATER) --------------------------------------------------

require(gganimate)
require(ggspatial)

ob_id_cy <- frsppt %>% filter(!is.na(emu)) %>% select (ob_id, emu, country, year) %>%
		mutate(year=ifelse(is.na(year),2010,year))%>%
		mutate(year=ifelse(year>2019,2019,year))%>%		
		mutate(decade= round(year/10)*10)%>%				
		dplyr::rename("emu_nameshort"="emu")%>%
		group_by(emu_nameshort, country,decade) %>% 
		summarize(n=n())
ob_id_cysf <- merge(emu_c,ob_id_cy, by="emu_nameshort")
ob_id_cysf  <- cbind(ob_id_cysf,st_coordinates(ob_id_cysf))
ob_id_cysf[which(ob_id_cysf$emu_nameshort=='PT_Port'& ob_id_cysf$country=='PT'),c("X","Y")] <- c(-8.33,39.48)
range(ob_id_cy$decade)

g <-    ggplot(data = ob_id_cysf) +  geom_sf(fill= "antiquewhite", data=emu) +
		geom_point(aes(x=X, y=Y, size=n , col=country), alpha=0.7)+
		scale_colour_manual(values=cols)+
		scale_size_continuous(range=c(0.5,15)) +
		xlab("Longitude") + 
		ylab("Latitude") +
		annotation_scale(location = "bl", width_hint = 0.5) +
		annotation_north_arrow(location = "tr", which_north = "true", 
				pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"),
				style = north_arrow_fancy_orienteering) +
		coord_sf(xlim=c(-10,11.5),ylim=c(32,53))+
		theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
				panel.background = element_rect(fill = "white"))	


# this works but for some reasons takes ages to get the code working for maps =>
ggplot(mtcars, aes(factor(cyl), mpg)) + 
		geom_boxplot() + 
		# Here comes the gganimate code
		transition_states(
				cyl,
				transition_length = 1,
				state_length = 0.5
		) +
		enter_fade() + 
		exit_shrink() +
		ease_aes('sine-in-out')


# this is also too long !!!!

g +  transition_time(decade)
ggtitle(
				'Filter: {closest_filter}',
				subtitle = '{closest_expression}'
		) +
		exit_recolour(colour = 'grey') +
		exit_shrink(size = 0.5)+
		ease_aes('linear')
# anim_save()	


# DENSITY
# loading Spain and Portugal sf format ------------------
baselec <- new("BaseEdaRios",
		zonegeo=c("Spain","Portugal"),
		baseODBC = "baseODBCrios",
		schema = "sudoang", 		
		table = "view_electrofishing_frozen",
		prkey="ob_id")
baselec <- loadshp(baselec,geom="the_geom")
shpsppt <- baselec@shp
shpsppt <- shpsppt[st_coordinates(shpsppt)[,1]<5000000,] # an outlier
shpsppt$ob_id <- toupper(shpsppt$ob_id)

# loading France sf format---------------------------
baseODBCrht[1] <- "eda2.2"
baselecfr <- new("BaseEdaRios",
		zonegeo = c("France"),
		baseODBC = "baseODBCrht",
		schema = "rht", 		
		table = "ers_full_2017",
		prkey = "op_numero")
baselecfr <- loadshp(baselecfr, geom="geom")
shpfr <- baselecfr@shp
shpfr <- rename(shpfr,"ob_id"="op_numero")
shp <- rbind(shpsppt,shpfr)
shp <- shp[!st_is_empty(shp),,drop=FALSE]

# to join a sf class, use the merge method from sf
frsppt_shp <- merge(shp,frsppt, by="ob_id") # 41409 M
test <- frsppt_shp[!is.na(frsppt_shp$densCS),] # 41123 obs. of  49 variables
test$densCS <- test$densCS*100 # Indiv * 100m2
# Old graph using sp and bubble function (best so far)
library(sp)
x11()
#bubble(as(test,"Spatial"), "densCS", 
#		#col=c(orangesudo, bluesudo), 
#		col=ifelse(test$densCS <= .05, orangesudo, bluesudo),
#col=ifelse(test$densCS >= .3, orangesudo, 
#		ifelse(test$densCS >= .005, greensudo, bluesudo)),
#maxsize = 1, 
#		key.entries =  c(0, 0.05, 0.1, 0.3, 0.5, 5), 
#		main="", xlab="", ylab="") 

plot(test["densCS"], 
		bg=rev(heat.colors(5))[cut(test$densCS,breaks=c(0, 5, 10, 30, 50, 500),labels=FALSE)],
		col="grey", pch=21, axes=FALSE, main = NA)

legend("topleft", legend = c("0", "0 - 5", "5 - 10", "10 - 30", "30 - 50", "50 - 500"),
		pch= 21, 
		col = "grey",
		pt.bg= c("white", rev(heat.colors(5))),
		bty = "n",
		title="Density (eel.100m2)")
