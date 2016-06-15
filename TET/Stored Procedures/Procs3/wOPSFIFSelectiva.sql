
CREATE PROCEDURE wOPSFIFSelectiva @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE  @iDoc int, @utilizator varchar(20), @xml xml,@numar varchar(20),@data datetime, @mesaj varchar(250),
		@tip varchar(2),@numarAVANS varchar(20),@sub varchar(9), @gestiune varchar(13), @cod varchar(20), @tert varchar(13),
		@lm varchar(13), @factura varchar(20), @NrAvizeUnitar int,@NumarDocPrimit int,@idPlajaPrimit int, @detalii xml
	
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'),'')
	SET @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(13)'),'')
	SET @factura = isnull(@parXML.value('(/*/@factura)[1]', 'varchar(20)'),'')
	SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(13)'),'')
	SET @tip = isnull(@parXML.value('(/*/@tipDoc)[1]', 'varchar(2)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'),'')
	SET @cod = isnull(@parXML.value('(/*/@cod)[1]', 'varchar(20)'),'')
	SELECT @detalii = T.C.query('.') FROM @parXML.nodes('/parametri/detalii') AS T(C)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output  

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlFacturi') IS NOT NULL
		DROP TABLE #xmlFacturi
	
	SELECT factura as factura, facturaInit as facturaInit, tert as tert, convert(decimal(17,2),suma) as suma, numar as numar, subtip as subtip, valuta as valuta, curs as curs
		,selectat as selectat, factnoua as factnoua, lm, CONVERT(float,0) as val_tva, space(20) as cont_fact
	INTO #xmlFacturi
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		factura varchar(20) '@factura'
		,facturaInit varchar(20) '@facturaInit'
		,tert varchar(20) '@tert'
		,suma float '@suma' 
		,numar varchar(20) '@numar'
		,subtip varchar(2) '@subtip'
		,valuta varchar(3) '@valuta'
		,curs float '@curs'
		,selectat int '@selectat'
		,factnoua int '@factnoua'
		,lm varchar(13) '@lm'		
	)
	
	EXEC sp_xml_removedocument @iDoc 	

	--tratare valoare tva
	update 	f set val_tva=convert(decimal(17,2),((f.suma*100/(case when ff.Valoare+ff.TVA_22=0 then 10000000 else ff.Valoare+ff.TVA_22 end))*ff.TVA_22)/100), cont_fact=ff.cont_de_tert
	from #xmlFacturi f
		inner join facturi ff on ff.Factura=f.facturaInit and ff.Tert=f.tert and (ff.Tip=0x54 and @tip in ('RM','RS') or ff.Tip=0x46 and @tip in ('AP','AS'))

	if isnull(@numar, '')=''
	begin
		declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)
		set @tipPentruNr=@tip 
		if @NrAvizeUnitar=1 and @tip='AS' 
			set @tipPentruNr='AP' 
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output
		
		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
		
		set @numar=@NrDocPrimit
	end

	set @xml = 
		(
		SELECT @tip AS '@tip', @lm '@lm', @tert '@tert', convert(varchar(10),@data,101) as '@data', 
			@gestiune as '@gestiune',
			@numar as '@numar',@factura as '@factura',1 as '@apelDinProcedura',
			(SELECT @numar as '@numar',@cod '@cod', 
					(case when f.Suma<0.001 then -1 else 1 end) '@cantitate', 
					abs(convert(decimal(17,5),f.suma)-CONVERT(decimal(17,2),f.val_tva)) '@pvaluta',
					CONVERT(decimal(12,5),f.curs) as '@curs',
					f.valuta as '@valuta',
					f.facturaInit as '@codintrare',
					case when @tip in ('RM','RS') then'SF' else 'IF' end as '@subtip',
					CONVERT(decimal(17,2),f.val_tva) as '@sumatva', 
					f.cont_fact as '@contstoc'
				from #xmlFacturi f
				where abs(f.suma)>0.001
					and f.selectat=1
			FOR XML path, type)
		FOR XML path, type)

	SET @xml.modify('insert sql:variable("@detalii") into (/row)[1]') ;
	/*	Apelare wScriuPozdocSP (daca exista, pentru prelucrari in parXML), wScriuDoc sau wScriuDocBeta.	*/
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP')
		exec wScriuPozdocSP @sesiune=@sesiune, @parXML=@xml OUTPUT
	if exists (select * from sysobjects where name ='wScriuDoc')
		exec wScriuDoc @sesiune=@sesiune, @parXML=@xml OUTPUT
	else 
		if exists (select * from sysobjects where name ='wScriuDocBeta')
			EXEC wScriuDocBeta @sesiune=@sesiune, @parXML=@xml OUTPUT


END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPSFIFSelectiva)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
