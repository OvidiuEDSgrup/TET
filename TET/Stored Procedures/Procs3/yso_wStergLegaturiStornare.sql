
CREATE PROCEDURE yso_wStergLegaturiStornare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
begin tran 
	DECLARE @mesaj VARCHAR(400), @idContract INT, @idPozDocSursa INT, @idPozDocStorno INT, @docJurnal XML, @detaliiJurnal XML, @stare INT, 
		@tipS VARCHAR(2), @numarS VARCHAR(20), @dataS DATETIME, @explicJurnal varchar(100)
		,@tip varchar(2), @numar varchar(20), @data datetime

	select @tip = @parxml.value('(/*/@tip)[1]','varchar(2)')
		, @numar = @parxml.value('(/*/@numar)[1]','varchar(20)') 
		, @data = @parxml.value('(/*/@data)[1]','varchar(10)') 

	if OBJECT_ID('tempdb..#pozStorno') is not null drop table #pozStorno

	;with antet as (
		select idPozDocStorno = @parXML.value('(/*/@idPozDocStorno)[1]', 'int')
			, idPozDocSursa = @parXML.value('(/*/@idPozDocSursa)[1]', 'int')
			, tipS = @parXML.value('(/*/@tipS)[1]', 'varchar(2)')
			, numarS = @parXML.value('(/*/@numarS)[1]', 'varchar(20)')
			, dataS = @parXML.value('(/*/@dataS)[1]', 'datetime')
		)
	select a.tipS, a.dataS, a.numarS
		, isnull(p.col.value('(@idPozDocSursa)[1]','int'),a.idPozDocSursa) as idPozDocSursa
		, isnull(p.col.value('(@idPozDocStorno)[1]','int'),a.idPozDocStorno) as idPozDocStorno
	into #pozStorno
	from antet a--@parXML.nodes('/*') a(col)
		outer apply @parXML.nodes('/*/row') p(col)

	IF exists (select top(1) 1 from #pozStorno p where p.tipS IS NULL)
		RAISERROR ('Nu s-a putut identifica pozitia din document marcata pt stergere!', 11, 1)

	set @detaliiJurnal = (SELECT p.idPozDocSursa idPozDocSursa, p.idPozDocStorno idPozDocStorno from #pozStorno p FOR XML raw)
	set @explicJurnal='Stergere legatura cu '
		+stuff((select distinct ','+p.tipS+' '+p.numarS+' din '+CONVERT(varchar(10),p.dataS,103) from #pozStorno p for xml path('')),1,1,'')
	
	select @docJurnal=
		(select	
			@tip as tip,
			@numar as numar,
			convert(varchar(10),@data,101) as data,
			10 stare,
			@explicJurnal explicatii,
			@detaliiJurnal detalii
		for xml raw)

	exec wScriuJurnalDocument @sesiune=@sesiune, @parXML=@docJurnal OUTPUT
/*
	select l.* --*/ DELETE L
	FROM LegaturiStornare l join #pozStorno p on p.idPozDocStorno=l.idStorno and p.idPozDocSursa=l.idSursa

	commit tran
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wStergLegaturiStornare)'

	if @@trancount > 0
		rollback tran

	RAISERROR (@mesaj, 11, 1)
END CATCH
