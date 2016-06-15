-- procedura folosita pentru generarea de facturi din contracte.
CREATE PROCEDURE wOPPISelectiva @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @iDoc int, @utilizator varchar(20), @xml xml, @tip varchar(2), @cont varchar(40), @numar varchar(13),@data datetime, @mesaj varchar(250),
		@tert varchar(13), @efect varchar(20), @tipED varchar(2), @tipOperatiune varchar(2), @numarAVANS varchar(10), 
		@sub varchar(9), @bugetari int, @CtAvFurn varchar(40),@CtAvBen varchar(40), @detalii_antet xml, @detalii xml,@lm varchar(20),@jurnal varchar(20)
		,@tipdoc varchar(2) --Poate fi AD de la Alte Documente
	
	SET @tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),'')
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(13)'),'')
	SET @cont = isnull(@parXML.value('(/*/@cont)[1]', 'varchar(40)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'),'')
	SET @lm= isnull(@parXML.value('(/*/@lm)[1]', 'varchar(20)'),'')
	SET @jurnal= isnull(@parXML.value('(/*/@jurnal)[1]', 'varchar(20)'),'')
-->	pentru efecte
	SET @efect = isnull(@parXML.value('(/*/@efect)[1]', 'varchar(20)'),'')
	SET @tipED = isnull(@parXML.value('(/*/@tipEd)[1]', 'varchar(2)'),'')
	SET @tipOperatiune = isnull(@parXML.value('(/*/@tipOperatiune)[1]', 'varchar(2)'),'')
	SET @tipdoc= isnull(@parXML.value('(/*/@tipdoc)[1]', 'varchar(2)'),'')
-->	detalii antet (unde se pastreaza la efecte datele acestora)
	IF @parXML.exist('(/*/detalii/row)[1]') = 1
		SET @detalii_antet = @parXML.query('(/*/detalii/row)[1]')
-->	detalii pozitii (pentru eventualele informatii de introdus in pozplin.detalii)
	IF @parXML.exist('(/*/*/*/detalii/row)[1]') = 1
		SET @detalii = @parXML.query('(/*/*/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	exec luare_date_par 'GE','CFURNAV',0,0,@CtAvFurn output
	exec luare_date_par 'GE','CBENEFAV',0,0,@CtAvBen output

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output  
	exec luare_date_par 'GE', 'BUGETARI', @bugetari OUTPUT, 0, ''
-->	citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlFacturi') IS NOT NULL
		DROP TABLE #xmlFacturi
	
	SELECT factura as factura, facturaInit as facturaInit, tert as tert, contFactura, convert(decimal(17,2),suma) as suma, numar as numar, subtip as subtip, marca, decont, 
		valuta as valuta, curs as curs, selectat as selectat, factnoua as factnoua, lm, jurnal, detalii
	INTO #xmlFacturi
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		factura varchar(20) '@factura'
		,facturaInit varchar(20) '@facturaInit'
		,tert varchar(20) '@tert'
		,contFactura varchar(40) '@cont'
		,marca varchar(6) '@marca'
		,decont varchar(40) '@decont'
		,suma float '@suma' 
		,numar varchar(13) '@numar'
		,subtip varchar(2) '@subtip'
		,valuta varchar(3) '@valuta'
		,curs float '@curs'
		,selectat int '@selectat'
		,factnoua int '@factnoua'
		,lm varchar(13) '@lm'
		,jurnal varchar(20) '@jurnal'
		,detalii xml 'detalii/row'
	)
	

	if @tipdoc='AD' and @tipoperatiune='PF'
	begin
		
		insert into SelectieFacturiPtCompensari(utilizator,tip,tert,factura,suma,valuta,curs)
		select @utilizator,'F',tert,factura,suma,valuta,curs from #xmlFacturi 
		where selectat=1

		declare @suma float,@curs float,@valuta varchar(3)
		select @suma=sum(suma),@valuta=max(valuta),@curs=max(curs)
		from #xmlFacturi 
		where selectat=1

		truncate table #xmlFacturi 
		declare @dateInitializare xml
		set @dateInitializare=
		(
			select 'IB' as tipOperatiune, 'AD' as tipdoc,RTRIM(@tert) as tert, convert(char(10), @data, 101) as data, RTRIM(@lm) as lm, 
				CONVERT(decimal(17,5),@suma) as suma, 
				RTRIM(@numar) as numar, RTRIM(@jurnal) as jurnal, 
				@valuta as valuta,
				@curs as curs
			for xml raw ,root('row')
		)

		SELECT 'Operatie pentru plati/incasari facturi.'  nume, 'PI' codmeniu, 'D' tipmacheta, 'RE' tip,'PI' subtip, 'O' fel,
			(SELECT @dateInitializare) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

	end

	if @tipdoc='AD' and @tipoperatiune='IB'
	begin
		insert into SelectieFacturiPtCompensari(utilizator,tip,tert,factura,suma,valuta,curs)
		select @utilizator,'B',tert,factura,suma,valuta,curs from #xmlFacturi 
		where selectat=1
		
		truncate table #xmlFacturi 
		exec ScriuCompensareSelectiva @sesiune,@parxml

		return
	end

	/*
	end
	if 123123 and am selectat beneficiari
		fa in scriuadoc
		return
	end
	*/

	/*if exists (select 1 from #xmlFacturi where ISNULL(factura,'')='' and isnull(suma,0)<>0)
		raiserror('Coloana factura trebuie sa fie completata pe toate randurile care au sume!',11,1)
	*/
	-- daca sunt avansuri, identificam numarul urmator de avans
	if exists (select 1 from #xmlFacturi where factura='AVANS')
		select top 1 @numarAVANS='AV'+convert(varchar(20),isnull(max(substring(rtrim(ltrim(factura)),3,len(rtrim(ltrim(factura)))-2)),0)+1) 
		from facturi 
		where subunitate=@sub and tert=@tert 
			and factura like 'AV%' 
			and isnumeric(substring(rtrim(ltrim(factura)),3,len(rtrim(ltrim(factura)))-2))>0

	if isnull(@numar,'')='' and 1=0
	begin
			declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)
			set @tipPentruNr='IB' 
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		
			exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocPrimit output
		
			if isnull(@NrDocPrimit,0)=0
					raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			set @numar=@NrDocPrimit
			update #xmlFacturi set numar=@numar
	end

	set @xml = 
		(
		SELECT 
			@cont as cont, left(@tipOperatiune,1) as tipefect,
			CONVERT(varchar(10),@data,101) as data, @tert as tert,
			@tipED as tip, rtrim(@efect) as efect, @detalii_antet as detalii, 1 as apelDinProcedura,
			(
				SELECT 
					rtrim(f.tert) as tert,
					rtrim(f.numar) as numar,
					rtrim(f.contFactura) as contcorespondent,
					case when f.factura='AVANS' then @numarAVANS else (case when f.factnoua=1 then f.factura else f.facturaInit end) end as factura,
					rtrim(f.marca) as marca,
					rtrim(f.decont) as decont,
					case when isnull(f.valuta,'')='' then convert(decimal(17,2),f.suma) else 0 end as suma,
					case when isnull(f.valuta,'')<>'' then convert(decimal(17,2),f.suma) else 0 end as sumavaluta,
					f.subtip as subtip,
					CONVERT(decimal(12,5),f.curs) as curs,
					rtrim(f.valuta) as valuta,
					rtrim(f.lm) as lm, rtrim(jurnal) as jurnal, detalii as detalii
				from #xmlFacturi f
				where abs(f.suma)>0.001
					and f.selectat=1
				for xml raw,type
				)
			for xml raw,type)

	exec wScriuPlin @sesiune=@sesiune, @parXML=@xml output

	/*	pentru bugetari se apeleaza si aici wScriuPozplinSP2 pentru cazul operatiunilor prin 482 */
	if @bugetari=1 and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozplinSP2')
		exec wScriuPozplinSP2 '', @sub, @tip, @cont, @data, @parXML

	--tratare pozitii generate pentru avans
	if exists (select 1 from #xmlFacturi where factura='AVANS')
		/*not exists(select 1 from #xmlFacturi where isnull(valuta,'')!='') and */	--	tratat sa completeze contul de avans si la facturile in valuta
	begin
		update pozplin set cont_corespondent=(case when left(plata_incasare,1)='P' then @CtAvFurn else @CtAvBen end)
			where subunitate=@sub and cont=@cont and data=@data and numar=@numar and tert=@tert and factura=@numarAVANS
		update pozplin set tva22= suma*24.00/124.00, tva11=24.00
			where subunitate=@sub and cont=@cont and data=@data and numar=@numar and tert=@tert and factura=@numarAVANS and left(plata_incasare,1)='I'
	end

	/* apelare procedura specifica */
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPISelectivaSP2')
		exec wOPPISelectivaSP2 @sesiune=@sesiune, @parXML=@parXML
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPISelectiva)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
