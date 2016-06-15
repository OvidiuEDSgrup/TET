
CREATE PROCEDURE wIaStariContracte @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @f_denumire VARCHAR(50), @f_stare INT, @f_tipcontract VARCHAR(20), @docXML XML

	select
		@f_denumire = '%' + @parXML.value('(/*/@f_denumire)[1]', 'varchar(50)') + '%',
		@f_stare = @parXML.value('(/*/@f_stare)[1]', 'int'),
		@f_tipcontract = '%' + @parXML.value('(/*/@f_tipcontract)[1]', 'varchar(20)') + '%'

	SELECT DISTINCT tipContract
	INTO #tipuriContracte
	FROM StariContracte

	SET @docXML = 
	(
		SELECT 
			rtrim(tp.tipContract) tipcontract, (CASE tp.tipContract WHEN 'CB' THEN 'Contracte beneficiar' WHEN 'CF' THEN 'Contracte furnizori' WHEN 'CA' THEN 'Comenzi aprovizionare' WHEN 'CL' THEN 'Comenzi livrare' 
			WHEN 'CS' then 'Contracte servicii' when 'CT' then 'Comenzi transport' when 'PR' then 'Proforme' when 'RN' then 'Referate necesitate' END) AS dentipcontract, 1 AS _nemodificabil, 
			(
				SELECT 
					st.stare AS stare, rtrim(st.denumire) AS denumire, rtrim(tp.tipContract) dentipcontract, rtrim(tp.tipContract) tipcontract, st.idStare AS idStare, rtrim(st.culoare) as culoare,
					(case st.actaditional when '1' then 'Da' else 'Nu' end) as denactaditional, st.actaditional actaditional,
					(case st.inchisa when '1' then 'Da' else 'Nu' end) as deninchisa, st.inchisa inchisa,
					(case st.modificabil when '1' then 'Da' else 'Nu' end) as denmodificabil, st.modificabil modificabil,
					(case st.facturabil when '1' then 'Da' else 'Nu' end) as denfacturabil, st.facturabil facturabil,
					(case st.transportabil when '1' then 'Da' else 'Nu' end) as dentransportabil, st.transportabil transportabil
				FROM StariContracte st
				WHERE 
					st.tipContract = tp.tipContract AND
					(@f_stare IS NULL OR st.stare = @f_stare)AND 
					(@f_denumire IS NULL OR st.denumire LIKE @f_denumire)
				FOR XML raw, type
			)
			FROM #tipuriContracte tp
			WHERE 
				(@f_tipcontract IS NULL OR 
				(CASE tp.tipContract WHEN 'CB' THEN 'Contracte beneficiar' WHEN 'CF' THEN 'Contracte furnizori' WHEN 'CA' THEN 'Comenzi aprovizionare' WHEN 'CL' 
				THEN 'Comenzi livrare' WHEN 'CS' then 'Contracte servicii' when 'CT' then 'Comenzi transport' when 'PR' then 'Proforme' END) LIKE @f_tipcontract)
			FOR XML raw, root('Ierarhie')
	)

	IF @docXML IS NOT NULL
		SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	SELECT @docXML
	FOR XML path('Date')
