DECLARE /*date de identificare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @eroare VARCHAR(250),@factura VARCHAR(20),@numardoc VARCHAR(8),
		@NrAvizeUnitar INT, @lm VARCHAR(13),@idPozDoc INT
		
SELECT --/*sp @numardoc AS facturadoc ,@numardoc AS numardoc, CONVERT(CHAR(10),@data,101) AS dataFactDoc
		--isnull(d.Factura,@numardoc) AS facturadoc 
		--	,isnull(d.Numar,@numardoc) AS numardoc
		--	,CONVERT(CHAR(10),isnull(d.Data,@data),101) AS dataFactDoc
		--	,p.idPozDoc,s.*,d.idPozDoc
			d.*
	FROM pozdoc p
		left JOIN LegaturiStornare s on s.idSursa=p.idPozDoc 
		left JOIN pozdoc d on d.idPozDoc=s.idStorno
	--WHERE p.Subunitate=@sub AND p.tip=@tip
	--	AND p.data=@data AND p.Numar=@numar
	where p.Numar='9411029' 
	
select * from pozdoc p where p.Numar='9411029'