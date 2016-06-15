-- procedura folosita pentru generarea de Deconturi din contracte.
CREATE PROCEDURE wOPPIRepartizarePlataDecont @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @iDoc int, @utilizator varchar(20), @xml xml, @tip varchar(2), @cont varchar(40), @numar varchar(13),@data datetime, @mesaj varchar(250), 
		@marca varchar(6), @decont varchar(40), @tert varchar(13), @tipOperatiune varchar(2), @sub varchar(9), @bugetari int, @lmsediu varchar(9)
	
	SET @tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),'')
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(13)'),'')
	SET @cont = isnull(@parXML.value('(/*/@cont)[1]', 'varchar(40)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'),'')
	SET @marca = isnull(@parXML.value('(/*/@marca)[1]', 'varchar(6)'),'')
	SET @decont = isnull(@parXML.value('(/*/@decont)[1]', 'varchar(40)'),'')
	SET @lmsediu = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(9)'),'')
	SET @tipOperatiune = isnull(@parXML.value('(/*/@tipOperatiune)[1]', 'varchar(2)'),'')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output  
	exec luare_date_par 'GE', 'BUGETARI', @bugetari OUTPUT, 0, ''

-->	citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlDeconturi') IS NOT NULL
		DROP TABLE #xmlDeconturi
	
	SELECT marca, decont, cont, contcorespondent, convert(decimal(17,2),suma) as suma, numar as numar, subtip as subtip, 
		factura as factura, tert as tert, valuta as valuta, curs as curs, selectat as selectat, lm, expl, detalii
	INTO #xmlDeconturi
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		factura varchar(20) '@factura'
		,tert varchar(20) '@tert'
		,cont varchar(40) '@cont'
		,contcorespondent varchar(40) '@contcorespondent'
		,marca varchar(6) '@marca'
		,decont varchar(40) '@decont'
		,suma float '@suma' 
		,numar varchar(13) '@numar'
		,subtip varchar(2) '@subtip'
		,valuta varchar(3) '@valuta'
		,curs float '@curs'
		,selectat int '@selectat'
		,lm varchar(13) '@lm'
		,expl varchar(50) '@expl'
		,detalii xml 'detalii/row'
	)
	
	EXEC sp_xml_removedocument @iDoc

	update #xmlDeconturi set detalii.modify('insert attribute lmalternativ {sql:column("lm")} into (/row)[1]'), lm=@lmsediu
	where detalii.value('(/row/@lmalternativ)[1]','varchar(9)') is null
		and (@lmsediu<>'' and left(@lmsediu,1)<>left(lm,1) and left(lm,1)<>'' /*or subtip='IA' or expl='Plata dif. decont'*/)

	set @xml = 
		(
		SELECT 
			@cont as cont, CONVERT(varchar(10),@data,101) as data, rtrim(@marca) as marca, rtrim(@decont) as decont,  
			@tip as tip, 1 as apelDinProcedura,
			(
				SELECT 
					rtrim(d.numar) as numar,
					rtrim(d.contcorespondent) as contcorespondent,
					rtrim(d.marca) as marca,
					rtrim(d.decont) as decont,
					(case when isnull(d.valuta,'')='' then convert(decimal(17,2),d.suma) else 0 end) as suma,
					(case when isnull(d.valuta,'')<>'' then convert(decimal(17,2),d.suma) else 0 end) as sumavaluta,
					d.subtip as subtip,
					CONVERT(decimal(12,5),d.curs) as curs,
					rtrim(d.valuta) as valuta,
					rtrim(d.lm) as lm, detalii as detalii
				from #xmlDeconturi d
				where abs(d.suma)>0.001
					and d.selectat=1
				for xml raw,type
				)
			for xml raw,type)

	exec wScriuPlin @sesiune=@sesiune, @parXML=@xml output

	/*	DE VAZUT DACA TREBUIE APELAT AICI. Pare ca ar trebui intrucat se cere generarea documentelor prin 482 (la unele ABA) 
		Pentru bugetari s-a apelat aici wScriuPozplinSP2 pentru cazul operatiunilor prin 482 si la wOPPISelectiva */
	if @bugetari=1 and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozplinSP2')
		exec wScriuPozplinSP2 '', @sub, @tip, @cont, @data, @parXML

	-->generare inregistrari contabile (pentru cazul in care se genereaza pozitii dinspre macheta de deconturi, pe conturile 531 / 770)
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub, @Tip='PI', @Numar=@cont, @Data=@data
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPIRepartizarePlataDecont)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
