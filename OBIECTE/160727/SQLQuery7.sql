CREATE TABLE #yso_PreturiIntrarePozDoc
(idPozDoc int PRIMARY KEY NONCLUSTERED, subunitate varchar(9), data datetime, cod varchar(20), 
	gestiune varchar(20), cod_intrare varchar(20), yso_pret_intrare float, nivel int)
	
EXEC yso_wIaPreturiIntrarePozDoc
