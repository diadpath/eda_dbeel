-----------------------------------------
-- DATA DICTIONARY OF OBSTACLES IN DBEEL
-----------------------------------------

/*
Relate the attributes of the dbeel database to the attributes created in the sudoang templates.
For that, a table (translate_names) is created in order to join both attributes.
Then, we will 
*/

create table sudoang.translate_names (
   dbeelcol TEXT,
   sudoangcol text,
   french_description text,
   english_description text,
   spanish_description TEXT,
   portugese_description TEXT);

-- DAMS data
INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
 ('op_id', 'obs_id', 'Identifiant', 'Identifier', 'Identificador', default),
 ('op_placename', 'obs_name', 'Nom', 'Name', 'Nombre', default),
 ('op_op_id', 'obs_parent_id', 'Identifiant du barrage principal', 'Parent dam identifier', 'Identificador de la presa principal', default),
 ('x' , 'X', 'Coordonnées X', 'Coordinates X', 'Coordenadas X', default),
 ('y' , 'Y', 'Coordonnées Y', 'Coordinates Y', 'Coordenadas Y', default),
 ('srid' , 'SRID', 'Code SRID pour identifier le système de coordonnées', 'SRID code to identify the coordinate system', 'Código SRID que permite identificar el sistema de coordenadas',default),
 ('po_obstruction_height', 'obs_height', 'Hauteur', 'Water denivelation', 'Dimensiones en altura del salto de agua', default),
 ('po_downs_pb', 'obs_downs_pb', 'Problème d expertise pour la migration vers l aval', 'Expertise problem for downstream migration', '¿Existe un problema para la migración aguas abajo? (Opinión de experto)', default),
 ('po_downs_water_depth', 'obs_downs_water_depth', 'Profondeur de l eau près du barrage', 'Water depth close to the dam', 'Profundidad del agua cerca de la presa', default),
 ('po_presence_eel_pass', 'obs_presence_eel_pass', 'Présence de passage pour l anguille', 'Presence of an eel pass', 'Presencia de paso para anguila', default),
 --('obs_impact', 'obs_impact', 'Il y a un impact', 'There is an impact', 'Existe un impacto', default), -- TO DO
 ('po_method_perm_ev', 'obs_method_perm_ev', 'Méthode d évaluation de la perméabilité à l impact', 'Permeability/ impact evaluation method', 'Método de evaluación de permeabilidad del impacto', default);
 
INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('op_gis_layername', 'datasource','Souce des données', 'Source of data', 'Fuente de datos', 'Fonte de dados'),
('op_gislocation', 'id','identifiant', 'indentifier', 'identificador', 'identificador');


DELETE FROM sudoang.translate_names WHERE dbeelcol='obs_impact';

ALTER TABLE sudoang.translate_names ADD COLUMN id serial PRIMARY KEY;


INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('po_no_obstruction_passability', 'obs_impact','score de franchissement', 'passability score', 'nota de pasabilidad', 'pontuação de passabilidade');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('basin', 'basin','bassin hydrographique', 'hydrographic basin', 'cuenca hidrográfica', 'Bacia hidrográfica');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('country', 'country','pays', 'hydrographic basin', 'País', 'País');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('fishway_type', 'fishway_type','Type de passe', 'Type of pass', 'Tipo de paso', 'Tipos de Escada de peixes');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('emu', 'emu','UGA', 'emu', 'emu', 'emu');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('altitudem', 'altitudem','altitude (m)', 'altitude (m)', 'altitud (m)', 'altitude (m)');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('distanceseam', 'distanceseam','distance à la mer (m)', 'distance to the sea (m)', 'distancia al mar (m)', '
distância para o mar (m)');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('googlemapscoods', 'googlemapscoods','Coordonnées dans Google maps', 'Coordinates in Google Maps', 'Coordenadas en Google maps', 'Coordenadas no Google maps');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('ot_no_obstruction_type', 'ot_no_obstruction_type', 'Type d obstruction physique', 'Type of physical obstruction', 'Tipo de obstruccion fisica', 'Tipo de obstrução física');

INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('comment_update', 'comment_update', 'Commentaire actualisé sur les différences constatées dans les données', 'Updated comment on the differences found in the data', 
'Comentario actualizado las diferencias encontradas en los datos', 'Comentário actualizado sobre as diferenças encontradas nos dados');


-- POWER PLANT data
INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('hpp_ob_id', 'dam_id', 'Identifiant du barrage', 'Dam identifier', 'Identificador de la presa', 'Identificador da barragem'),
('hpp_name', 'dam_name', 'Nom de la centrale hydroélectrique', 'Name of hydropower plant', 'Nombre de la central hidroeléctrica', 
	'Nome da central hidroeléctrica'),
('hpp_main_grid_or_production', 'Connecté au réseau principal (= 1) ou produit et vendu (= 2)', 'main-grid or production', 
	'Connected to the main grid or produced and sell', 'Conectada a la red principal y ser de autoconsumo (= 1), 
		o producirla y venderla a la red eléctrica (= 2)', 'Ligado à rede principal e ser autoconsumível (= 1), ou produzir e vender à rede (= 2)'),
('hpp_presence_bypass', 'dam_presence_bypass', 'Présence d un système de dérivation', 'Presence of bypass system', 
	'Presencia de canales de derivación', 'Presença de sistema de derivação'),
('hpp_total_flow_bypass', 'dam_total_flow_bypass', 'Débit dans le système de dérivation', 'Flow in the bypass', 
	'Caudal en el canal de derivación', 'Fluxo na derivação'),
('hpp_orient_flow_no_id', 'dam_orient_flow', 'Orientation du barrage par rapport au débit', 'Orientation of dam respect to flow', 
	'Orientación de la presa respecto al caudal del río', 'Orientação da barragem em relação ao caudal do rio'),
('hpp_presence_of_bar_rack', 'dam_presence_of_bar_rack', 'Présence de grilles en amont des turbines', 'Presence of bar rack', 
	'Presencia de rejillas aguas arriba de las turbinas', 'Presença das grelhas a montante das turbinas'),
('hpp_bar_rack_space', 'turb_rack_bar_space', 'Espace libre entre les barres des grilles', 'Free spacing between the bars of the grid', 
	'Espacio libre que queda entre las barras de las rejillas', 'Espaço livre deixado entre as barras das grelhas'),
('hpp_surface_bar_rack', 'dam_surface_bar_rack', 'Surface des grilles', 'Surface area of bar rack', 
	'Área de la superficie de las rejillas', 'Superfície das grelhas'),
('hpp_inclination_bar_rack', 'dam_inclination_bar_rack', 'Inclinaison des grilles par rapport au fond', 'Inclination of bar rack respect to bottom', 
	'Inclinación de las rejillas respecto al suelo', 'Inclinação do suporte de barras respeito ao fundo'),
('hpp_presence_bypass_trashrack', 'dam_presence_bypass_trashrack', 'Présence de canaux dans les réseaux', 'Presence of a bypass system on the trashrack', 
	'Presencia de canales (o tuberías de toma de agua) en las rejillas', 'Presença de canais (ou tubos de entrada de água) nas grelhas'),
('hpp_nb_trashrack_bypass', 'dam_nb_trashrack_bypass', 'Nombre de grilles dans les canaux', 'Number of trashrack bypass(es)', 
	'Número de rejillas en los canales', 'Número de grelhas nos canais'),
('hpp_turb_max_flow', 'dam_turb_max_flow', 'Débit maximal turbiné par le barrage', 'Maximum dam turbine flow', 
	'Caudal máximo turbinado por la presa', 'Caudal máximo turbinado pela barragem'),
('hpp_reserved_flow', 'dam_reserved_flow', 'Débit minimum obligatoire qui ne passe pas par les turbines', 'Mandatory min flow not going through the turbines', 
	'Mínimo caudal obligatorio que no pasa por las turbinas', 'Fluxo mínimo obrigatório que não passa através das turbinas'),
('hpp_flow_trashrack_bypass', 'dam_flow_trashrack', 'Débit à travers les grilles dans les canaux inclus dans le débit obligatoire', 
	'Flow in the trashrack bypass(es) included in the mandatory flow ', 
	'Caudal que pasa a través de las rejillas en los canales incluido en el caudal obligatorio', 
	'Caudal através das grelhas nos canais incluídos no caudal obrigatório'),
('hpp_max_power', 'dam_max_power', 'Puissance brute maximale du système', 'Maximum raw power systems', 'Potencia máxima bruta de los sistemas', 
	'Potência máxima bruta do sistema'),
('hpp_nb_turbines', 'dam_nb_turbines', 'Nombre de turbines', 'Number of turbines', 'Número de turbinas', 'Número de turbinas'),
('hpp_id', default, 'Identifiant de la centrale hydroélectrique generée par sudoang', 'Hydropower plant identifier generated by sudoang', 
	'Identificador de la central hidroeléctrica generada por sudoang', 'Identificador da central eléctrica gerada por sudoang'),
('hpp_orientation_bar_rack', default, 'Orientation de grilles en amont des turbines', 'Orientation of bar rack', 
	'Orientación de rejillas aguas arriba de las turbinas', 'Orientação das grelhas a montante das turbinas'),
('hpp_id_original', default, 'Identifiant de la centrale hydroélectrique original', 'Original hydropower plant identifier', 
	'Identificador de la central hidroeléctrica original', 'Identificador da central eléctrica original'),
('hpp_source', default, 'Fournisseur de données françaises (ICE/ROE)', 'French data provider (ICE/ROE)', 'Proveedor de datos francés (ICE/ROE)', 
	'Provedor de dados francês (ICE/ROE)'); -- 21 rows


-- TURBINES data
INSERT INTO sudoang.translate_names (dbeelcol, sudoangcol, french_description, english_description, spanish_description, portugese_description)
VALUES
('turb_turbine_type_no_id', 'turb_type', 'Type des turbine', 'Type of turbine', 'Tipo de turbina', 'Tipo de turbina'),
('turb_id', 'typt_id', 'Identifiant de la turbine', 'Turbine identifier', 'Identificador de la turbina', 'Identificador da turbina'),
('turb_hpp_id', default, 'Identifiant de la centrale hydroélectrique', 'Hydropower plant identifier', 
	'Identificador de la central hidroeléctrica', 'Identificador da central eléctrica'),
('turb_in_service', 'turb_in_service', 'Turbine en service', 'Turbine in service', 'Turbina en servicio', 'Turbina em serviço'),
('turb_max_power', 'turb_max_power', 'Puissance maximale de la turbine', 'Maximum power of turbine', 
	'Máxima potencia de la turbina', 'Potência máxima da turbina'),
('turb_min_working_flow', 'turb_min_working_flow', 'Débit minimum d exploitation', 'Minimum working flow', 
	'Mínimo caudal de funcionamiento', 'Caudal mínimo de funcionamento'),
('turb_hpp_height', 'turb_dam_height', 'Hauteur de chute exploitée par la turbine à la vitesse de fonctionnement nominale', 'Height of turbine', 
	'Altura de caída operada por la turbina en régimen nominal de funcionamiento', 
	'Altura de queda operada pela turbina à velocidade nominal de operação'),
('turb_diameter', 'turb_diameter', 'Diamètre de la turbine', 'Turbine diameter', 'Diámetro de la turbina', 'Diâmetro da turbina'),
('turb_rotation_speed', 'turb_rotation_speed', 'Vitesse de rotation des turbines', 'Turbine rotation speed', 
	'Velocidad de rotación de la turbina', 'Velocidade de rotação da turbina'),
('turb_nb_blades', 'turb_nb_blades', 'Nombre de pales de la turbine', 'Number of blades in the turbine', 
	'Número de palas, álabes o cucharas de la turbina', 'Número de pás na turbina'),
('turb_max_turbine_flow', 'turb_max_turbine_flow', 'Débit maximal de fonctionnement de la turbine', 'Maximum turbine flow', 
	'Caudal máximo del funcionamiento de la turbina', 'Caudal máximo de funcionamento da turbina'),
('turb_description', 'turb_description', 'Description des autres éléments', 'Description of other elements', 
	'Descripción de otros elementos', 'Descrição de outros elementos'); -- 12 rows
