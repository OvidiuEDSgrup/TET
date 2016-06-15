
CREATE PROCEDURE wIaLansari @sesiune VARCHAR(50), @parXML XML
	AS
	DECLARE 
		@fltCod VARCHAR(20), @fltComanda VARCHAR(16), @fltDescriere VARCHAR(50), @fltDataJos DATETIME, @fltDataSus DATETIME, 
		@comanda VARCHAR(20), @fltCodProdus VARCHAR(50), @fltProdus VARCHAR(50), @fltTert VARCHAR(50), @fltcomanda_parinte varchar(20),
		@contract varchar(20), @fltStare varchar(100), @subunitate varchar(9)

	IF OBJECT_ID('tempdb.dbo.#stariComenzi') IS NOT NULL
		drop table #stariComenzi

	create table #stariComenzi (stare varchar(10), denumire varchar(500))
	insert into #stariComenzi  (stare, denumire)
	select 'S', 'Simulare' UNION
	select 'P', 'Pregatire' UNION
	select 'L', 'Lansata' UNION
	select 'A', 'Alocata' UNION
	select 'I', 'Inchisa'  UNION
	select 'N', 'Anulata'  UNION
	select 'B', 'Blocata'  
	
	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate OUTPUT

	SELECT
		@fltComanda = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_comanda)[1]', 'varchar(16)'), '%'), ' ', '%') + '%',
		@fltCodProdus = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_cod_produs)[1]', 'varchar(50)'), '%'), ' ', '%') + '%',
		@fltProdus = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_produs)[1]', 'varchar(50)'), '%'), ' ', '%') + '%',
		@fltTert = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(50)'), '%'), ' ', '%') + '%',
		@comanda = '%' + REPLACE(ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), '%'), ' ', '%') + '%',
		@fltcomanda_parinte  = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_comanda_parinte)[1]', 'varchar(20)'), '%'), ' ', '%') + '%',
		@contract = NULLIF(@parXML.value('(/*/@contract)[1]','varchar(20)'),''),
		@fltDataJos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1900'),
		@fltDataSus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/2050'),
		@fltStare = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_stare)[1]', 'varchar(20)'), '%'), ' ', '%') + '%'


	SELECT TOP 100 
		RTRIM(pt.cod) AS comanda, RTRIM(c.descriere) AS descriere, RTRIM(produs.cod) AS cod, 
		(CASE c.Tip_comanda WHEN 'P' THEN RTRIM(n.Denumire) WHEN 'X' THEN rtrim(tt.denumire) else rtrim(c.descriere) END) AS produs, 
		pt.id AS id, convert(CHAR(10), c.data_lansarii, 101) AS dataLansare, convert(CHAR(10), c.data_inchiderii, 101) AS 
		dataInchidere, convert(DECIMAL(10, 2), pt.cantitate) AS cantitate, RTRIM(n.um) AS um, isnull(RTRIM(c.Tip_comanda), 'S') AS tipL, 
		isnull(RTRIM(t.Denumire), 'intern') AS tert,  rtrim(t.tert) codtert,
		(CASE sa.stare  when  'I' THEN '#808080' when 'L' then '#FF0000' else '#000000' END) AS culoare,
		pparinte.cod as comanda_parinte, convert(varchar(10), convert(datetime, c.Numar_de_inventar),101) termen, pt.id as idLansare, 
		st.denumire denstare, rtrim(sa.stare) stare, rtrim(c.comanda_beneficiar) [contract],
		pt.detalii detalii
	FROM pozLansari pt
	LEFT JOIN pozlansari pparinte on pt.parinteTop=pparinte.id
	INNER JOIN comenzi c ON pt.cod = c.Comanda and c.Subunitate=@subunitate
	INNER JOIN pozTehnologii produs ON produs.id = pt.idp AND pt.tip = 'L' AND produs.tip = 'T'
	INNER JOIN tehnologii tt ON tt.cod = produs.cod
	OUTER APPLY (select top 1 stare from JurnalComenzi where idLansare=pt.id order by data desc) sa
	LEFT JOIN #stariComenzi st on st.stare=sa.stare
	LEFT JOIN nomencl n ON tt.codNomencl = n.Cod
	LEFT JOIN terti t ON t.Tert = c.Beneficiar and t.Subunitate=@subunitate
	WHERE pt.cod LIKE @fltComanda
		AND (RTRIM(n.Denumire) LIKE @fltProdus )
		AND (n.cod IS NULL OR n.cod LIKE @fltCodProdus)
		AND isnull(CONVERT(date, c.data_lansarii), @fltDataJos) BETWEEN @fltDataJos AND @fltDataSus
		AND pt.cod LIKE @comanda
		AND isnull(RTRIM(t.Denumire), 'intern') LIKE @fltTert
		and (pparinte.cod like @fltcomanda_parinte OR pt.cod like @fltcomanda_parinte)
		and (@contract is null or c.comanda_beneficiar = @contract)
		and (ISNULL(sa.stare,'') like @fltStare or ISNULL(st.denumire,'') like @fltStare)
	ORDER BY c.data_lansarii DESC
	FOR XML raw, root('Date')

	select 1 as areDetaliiXml for xml raw,root('Mesaje')
