
CREATE PROCEDURE wOPSFIFSelectivaAD @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE  @iDoc int, @utilizator varchar(20), @xml xml,@numar varchar(13),@data datetime, @mesaj varchar(250),
		@tip varchar(2),@numarAVANS varchar(8),@sub varchar(9), @gestiune varchar(13), @cod varchar(20), @tert varchar(13),
		@lm varchar(13), @factura varchar(20), @NrAvizeUnitar int,@NumarDocPrimit int,@idPlajaPrimit int,
		@facturadreapta varchar(20), @contcred varchar(40), @cotatva decimal(12,2), @tiptva int
	
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(13)'),'')
	SET @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(13)'),'')
	SET @factura = isnull(@parXML.value('(/*/@factura)[1]', 'varchar(20)'),'')
	SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(13)'),'')
	SET @tip = isnull(@parXML.value('(/*/@tipDoc)[1]', 'varchar(2)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'),'')
	SET @cod = isnull(@parXML.value('(/*/@cod)[1]', 'varchar(20)'),'')
	SET @facturadreapta = isnull(@parXML.value('(/*/@facturadreapta)[1]', 'varchar(20)'),'')
	SET @contcred = isnull(@parXML.value('(/*/@contcred)[1]', 'varchar(40)'),'')
	SET @cotatva = isnull(@parXML.value('(/*/@cotatva)[1]', 'decimal(12,2)'),24)
	SET @tiptva = isnull(@parXML.value('(/*/@tiptva)[1]', 'int'),0)


	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output  

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlFacturi') IS NOT NULL
		DROP TABLE #xmlFacturi
	
	SELECT factura as factura, facturaInit as facturaInit, tert as tert, convert(decimal(17,2),suma) as suma, 
			numar as numar, subtip as subtip, valuta as valuta, curs as curs,
			selectat as selectat, factnoua as factnoua, lm, CONVERT(float,0) as val_tva, facturadreapta as facturadreapta, contcred as contcred
	INTO #xmlFacturi
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		factura varchar(20) '@factura'
		,facturaInit varchar(20) '@facturaInit'
		,tert varchar(20) '@tert'
		,suma float '@suma' 
		,numar varchar(13) '@numar'
		,subtip varchar(2) '@subtip'
		,valuta varchar(3) '@valuta'
		,curs float '@curs'
		,selectat int '@selectat'
		,factnoua int '@factnoua'
		,lm varchar(13) '@lm'
		,facturadreapta varchar(20) '@facturadreapta'
		,contcred varchar(13) '@contcred'		
	)
	
	EXEC sp_xml_removedocument @iDoc 	

	--tratare valoare tva
	update 	f set val_tva=convert(decimal(17,2),((f.suma*100/(ff.Valoare+ff.TVA_22))*ff.TVA_22)/100)
	from #xmlFacturi f
		inner join facturi ff on ff.Factura=f.facturaInit and ff.Tert=f.tert and (ff.Tip=0x54 and @tip in ('SF') or ff.Tip=0x46 and @tip in ('IF'))

	if isnull(@numar, '')=''
		begin
			declare @an varchar(2), @plajaJos int, @plajaSus int, @id int, @fXML xml, @jurnal char(2), @tipPentruNr varchar(2),@NrDocPrimit varchar(20)
			set @jurnal=@an
			set @plajaJos=cast(@an+'000000' as Int)
			set @plajaSus=cast(@an+'999999' as Int)
			
			if not exists (select 1 from docfiscale where TipDoc='AD' and NumarInf=@plajaJos and NumarSup=@plajaSus 
							and id in (select id from asocieredocfiscale where TipAsociere='J' and Cod=@jurnal))
				begin
					
					insert into docfiscale (TipDoc, Serie, NumarInf, NumarSup, UltimulNr, SerieInNumar, meniu, subtip, descriere) 
							values ('AD', '', @plajaJos, @plajaSus, @plajaJos,0,null,null,null)
					set @id=(select id from docfiscale where TipDoc='AD' and NumarInf=@plajaJos and NumarSup=@plajaSus and UltimulNr=@plajaJos)
					insert into asocieredocfiscale (Id, TipAsociere, Cod, Prioritate) values (@id, 'J', @jurnal,0)
				end
				
			set @tipPentruNr='AD' 
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"AD"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
			set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
			
			exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output
			
			if @NrDocPrimit is null
				raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
			set @numar=@NrDocPrimit
		end
	
	set @xml = 
		(
		SELECT @tip AS '@tip', @lm '@lm', @tert '@tert', convert(varchar(10),@data,101) as '@data', 
			@gestiune as '@gestiune',
			@numar as '@numar',@factura as '@factura',1 as '@apelDinProcedura',
			(SELECT @numar as '@numar',
					convert(decimal(15,2),f.suma)-CONVERT(decimal(17,2),f.val_tva) '@suma',
					CONVERT(decimal(12,5),f.curs) as '@curs',
					f.valuta as '@valuta',
					f.facturaInit as '@facturastinga',
					@facturadreapta as '@facturadreapta',
					case when @tip='SF' then'SF' else 'IF' end as '@subtip',
					CONVERT(decimal(17,2),@cotatva) as '@cotatva',
					CONVERT(int,@tiptva) as '@tiptva',
					CONVERT(decimal(17,2),f.val_tva) as '@sumatva' 				
				from #xmlFacturi f
				where f.suma>0.001
					and f.selectat=1
			FOR XML path, type)
		FOR XML path, type)
		


--insert into test (detalii) values (@xml)

	exec wScriuPozadoc @sesiune=@sesiune, @parXML=@xml

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPSFIFSelectivaAD)'
	RAISERROR (@mesaj, 11, 1)
END CATCH


