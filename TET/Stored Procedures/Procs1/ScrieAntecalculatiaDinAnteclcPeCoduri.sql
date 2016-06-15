
CREATE PROCEDURE [dbo].[ScrieAntecalculatiaDinAnteclcPeCoduri] @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'ScrieAntecalculatiaDinAnteclcPeCoduriSP'	AND type = 'P')
BEGIN
	EXEC ScrieAntecalculatiaDinAnteclcPeCoduriSP @sesiune = @sesiune, @parXML = @parXML OUTPUT
	RETURN
END

DECLARE 
	@numar VARCHAR(20), @data DATETIME, @elem VARCHAR(20), @id INT, @userASiS VARCHAR(50), @procent FLOAT, @mesaj VARCHAR(500), 
	@valuta VARCHAR(10), @curs FLOAT, @detalii XML, @tert varchar(20)

BEGIN TRY
	SET @numar = ISNULL(@parXML.value('(/row/@numarDoc)[1]', 'varchar(20)'), '')
	SET @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
	SET @id = @parXML.value('(/row/@id)[1]', 'int')
	SET @valuta = @parXML.value('(/row/@valuta)[1]', 'varchar(10)')
	SET @curs = @parXML.value('(/row/@curs)[1]', 'float')
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	IF @numar = ''
	BEGIN
		DECLARE @NrDocFisc VARCHAR(20), @fXML XML

		SET @fXML = '<row/>'
		SET @fXML.modify('insert attribute tipmacheta {"AT"} into (/row)[1]')
		SET @fXML.modify('insert attribute tip {"AT"} into (/row)[1]')
		SET @fXML.modify('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')

		EXEC wIauNrDocFiscale @fXML, @NrDocFisc OUTPUT

		IF ISNULL(@NrDocFisc, 0) <> 0
			SET @numar = LTrim(RTrim(CONVERT(VARCHAR(20), @NrDocFisc)))
		
		set @parXML.modify('delete (/row/@numar)[1]')
		set @parXML.modify('insert attribute numar {sql:variable("@numar")} into (/row)[1]')
	END

	IF @id IS NULL --Trebuie inserate elemente
	BEGIN
		INSERT INTO dbo.pozAntecalculatii (tip, cod, cantitate, pret, idp, detalii)
		SELECT 'A', @numar, 1, isnull(TP, 0), pt.id, @detalii
		FROM anteclcpecoduri a
		INNER JOIN tehnologii t on t.cod=a.cod
		INNER JOIN dbo.pozTehnologii pt ON pt.tip = 'T' AND pt.cod = t.cod

		INSERT INTO dbo.antecalculatii (Cod, Data, Pret, valuta, curs, idPoz, numar)
		SELECT a.cod, @data, isnull(a.TP, 0), @valuta, @curs, pa.id, @numar
		FROM anteclcpecoduri a
		INNER JOIN tehnologii t on t.cod=a.cod
		INNER JOIN dbo.pozTehnologii pt ON pt.tip = 'T'	AND pt.cod = t.cod
		INNER JOIN dbo.pozAntecalculatii pa ON pa.tip = 'A'
			AND pa.cod = @numar
			AND pa.idp = pt.id

		IF OBJECT_ID('tempdb..#temp_tehn') IS NOT NULL
			drop table #temp_tehn

		;with tmptehn(cod, tip, cantitate, pret, id, parinteTop)
		as
		(
			select
				p.cod,p.tip,convert(float, 1), p.pret,p.id, p.id
			from pozTehnologii p 
			INNER JOIN pozAntecalculatii pa on p.tip='T' and p.id=pa.idp and pa.tip='A' and pa.cod=@numar
			UNION ALL

			select
				p.cod, p.tip, t.cantitate*p.cantitate, p.pret,(case when p.tip='R' then (select id from pozTehnologii where tip='T' and cod=p.cod)  else p.id end), t.parinteTop
			from  PozTehnologii p 
			JOIN tmptehn t on p.idp=t.id
		)

		select
			tip, cod, cantitate, parinteTop
		into #temp_tehn
		from tmptehn where tip in ('M','O')
		
		IF OBJECT_ID('tempdb..#preturi') IS NOT NULL
			drop table #preturi

		create table #preturi (cod varchar(20), nestlevel int)
		exec CreazaDiezPreturi

		insert into #preturi(cod,nestlevel)
		select distinct cod,@@nestlevel
		from #temp_tehn where tip='M'

		exec wIaPreturiAntecalcul @sesiune,@parXML

		/*Adaugarea materialelor si a manoperei din Tehnologie*/
		INSERT INTO dbo.pozAntecalculatii (tip, cod, cantitate, pret, idp, parinteTop)
		SELECT ptTehn.tip, ptTehn.cod, sum(ptTehn.cantitate), (CASE WHEN ptTehn.tip = 'M' THEN max(p.pret_vanzare) ELSE max(c.Tarif) END), pa.id AS idp, pa.id AS parinteTop
		FROM anteclcpecoduri a
		INNER JOIN tehnologii t on t.cod=a.cod		
		INNER JOIN dbo.pozTehnologii pt ON pt.tip = 'T'	AND pt.cod = t.cod
		INNER JOIN dbo.pozAntecalculatii pa ON pa.tip = 'A'
			AND pa.cod = @numar
			AND pa.idp = pt.id
		INNER JOIN #temp_tehn ptTehn ON ptTehn.tip IN ('M', 'O')  and ptTehn.parinteTop = pt.id
		LEFT JOIN #preturi p on p.cod=ptTehn.cod and ptTehn.tip='M'
		LEFT OUTER JOIN dbo.nomencl n ON ptTehn.tip = 'M'
			AND n.cod = ptTehn.cod
		LEFT OUTER JOIN catop c ON ptTehn.tip = 'O'
			AND ptTehn.cod = c.Cod
		group by  ptTehn.cod,ptTehn.tip, pa.id

	END --else facem update in tabela antecalculatii cu pretul nou

	BEGIN
		UPDATE dbo.Antecalculatii
		SET Antecalculatii.Pret = dbo.anteclcpeCoduri.TP
		FROM dbo.anteclcpeCoduri
		WHERE dbo.Antecalculatii.idAntec = @id
			AND dbo.anteclcpeCoduri.cod = dbo.Antecalculatii.cod

		UPDATE dbo.pozAntecalculatii
		SET dbo.pozAntecalculatii.Pret = dbo.anteclcpeCoduri.TP
		FROM dbo.anteclcpeCoduri, pozantecalculatii, dbo.Antecalculatii
		WHERE Antecalculatii.idAntec = @id
			AND dbo.anteclcpeCoduri.cod = dbo.Antecalculatii.cod
			AND pozantecalculatii.id = dbo.Antecalculatii.idPoz
	END

	/*Pentru elementele TIPUL E - facem o parcurgere in bucla cu insertul aferent*/
	DECLARE @nF INT, @cSQL VARCHAR(8000)

	DECLARE @cursorelem CURSOR
	set @cursorelem = cursor local fast_forward for
	SELECT element, valoare_implicita
	FROM ##tmpElemAntec
	ORDER BY pas

	OPEN @cursorelem

	FETCH NEXT
	FROM @cursorelem
	INTO @elem, @procent

	SET @nF = @@FETCH_STATUS

	WHILE @nF = 0
	BEGIN
		SET @cSQL = 'insert into pozAntecalculatii(tip ,cod ,cantitate ,pret ,idp ,parinteTop)
		select ''E'',''' + rtrim(
				@elem) + ''',' + CONVERT(VARCHAR(max), @procent) + ',a.' + rtrim(@elem) + 
			',pa.id,pa.id
			FROM anteclcpecoduri a
		INNER JOIN tehnologii t on t.cod=a.cod
		INNER JOIN dbo.pozTehnologii pt ON pt.tip=''T'' AND pt.cod=t.cod
		INNER JOIN dbo.pozAntecalculatii pa ON pa.tip=''A'' AND pa.cod=''' 
			+ @numar + ''' AND pa.idp=pt.id'


		EXEC (@cSQL)

		FETCH NEXT
		FROM @cursorelem
		INTO @elem, @procent

		SET @nF = @@FETCH_STATUS
	END

	EXEC wStergAntecalculatiiVechi @sesiune = @sesiune, @parXML = @parXML
END TRY
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
