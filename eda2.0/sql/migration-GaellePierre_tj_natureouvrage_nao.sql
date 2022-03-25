INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_datedebut,nao_datefin)
	SELECT nao_nov_code,nao_ouv_id,nao_datedebut,nao_datefin
	FROM tj_natureouvrage_nao1;