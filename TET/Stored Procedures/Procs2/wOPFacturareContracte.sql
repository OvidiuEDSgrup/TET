-- procedura folosita pentru generarea de facturi din contracte/comenzi
CREATE PROCEDURE wOPFacturareContracte @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY

	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPFacturareContracteSP')
	begin
		exec wOPFacturareContracteSP @sesiune=@sesiune, @parXML=@parXML
		return
	end
	DECLARE 
		@docJurnal XML, @idContract INT, @tert VARCHAR(20), @lm VARCHAR(20), @gestiune VARCHAR(20), @grupa VARCHAR(20), @mesaj VARCHAR(400), 
		@explicatiiJurnal VARCHAR(60), @detaliiJurnal XML, @dataJos DATETIME, @dataSus DATETIME, @detaliiContract XML, @gestiune_primitoare VARCHAR(20), 
		@valuta VARCHAR(20), @curs FLOAT, @punct_livrare VARCHAR(20), @stare INT, @mijlocInterval datetime, @xml xml,
		@nrContracte int, @utilizator varchar(50), @cNrFact varchar(20), @numarFact int, @serieFact varchar(50), @idContractFiltrat int, @data_facturilor datetime,
		@formular varchar(50), @dataAzi datetime, @iDoc int, @fara_mesaje bit, @ddoc int, @xml_proc xml, @cuRezervari bit, @gestiuneRezervari varchar(20), @detalii xml,
		@tip varchar(2), @aviznefacturat bit, @numar_pozdoc varchar(20)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE','REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT

	SELECT
		@formular = isnull(@parXML.value('(/*/@nrform)[1]', 'varchar(50)'),''), -- codul formularului folosit pt. generare facturi
		@dataJos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'),'1901-01-01'), -- data inferioara pt. filtrare
		@dataSus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'),'2999-01-01'), -- data superioara pt. filtrare
		@data_facturilor = isnull(@parXML.value('(/*/@data_facturii)[1]', 'datetime'), convert(datetime, convert(char(10), getdate(), 101), 101)),
		@numar_pozdoc = NULLIF(@parXML.value('(/*/@numar_pozdoc)[1]', 'varchar(20)'),''),
		@valuta = ISNULL(@parXML.value('(/*/@valuta)[1]', 'varchar(20)'),''), -- filtru valuta
		@curs = @parXML.value('(/*/@curs)[1]', 'float'), -- cursul de facturare
		@fara_mesaje = ISNULL(@parXML.value('(//@fara_mesaje)[1]', 'bit'),0),
		@tip = ISNULL(@parXML.value('(//@tipdoc)[1]', 'varchar(2)'),'AP'),
		@aviznefacturat = isnull(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'),0)

	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitii') IS NOT NULL
		DROP TABLE #xmlPozitii
	
	SELECT 
		isnull(idContract,idContractAntet) as idContract, 
		idPozContract, 
		numar_contract,
		cod,
		convert(decimal(17,5),pret) as pret, 
		CONVERT(decimal(12,2),discount) as discount,
		isnull(defacturat, cantitate) as cantitate, 
		valuta as valuta,
		convert(decimal(12,5),curs) as curs, 
		cod_specific as cod_specific, 
		NULLIF(cod_intrare,'') cod_intrare, 
		tert,
		gestiune,
		comanda,
		detalii
	INTO #xmlPozitii
	FROM OPENXML(@iDoc, '/*/DateGrid/row')
	WITH
	(
		detalii xml 'detalii/row',
		idContractAntet int '../../@idContract',
		idContract int '@idContract',
		idPozContract	int '@idPozContract',
		numar_contract varchar(20) '@numar_contract',
		cod varchar(20) '@cod',
		cod_intrare varchar(20) '@codintrare',
		cantitate FLOAT '@cantitate',
		defacturat FLOAT '@defacturat',
		pret FLOAT '@pret',
		discount FLOAT '@discount',
		valuta varchar(3) '@valuta',
		curs float '@curs',
		tert varchar(3) '@tert',
		cod_specific varchar(20) '@cod_specific',
		comanda varchar(20) '@comanda',
		gestiune varchar(20) '@gestiune'
	)
	
	EXEC sp_xml_removedocument @iDoc 			
	-- tabela cu contractele facturate
	declare @contracte table(
		idContract int primary key, 
		nrFactura varchar(20), -- numar factura aferent contractului
		idJurnal int ,-- id-ul din tabela de jurnale aferent operatiei curente
		valuta varchar(3),
		curs float,
		numar_contract varchar(20),
		tert varchar(13),
		gestiune varchar(20)
	)
	
	--punem intr-o tabela contractele de pe care se va factura
	insert into @contracte(idContract, valuta, curs, numar_contract, tert, gestiune)
	select idContract, max(valuta), max(curs), max(numar_contract),max(tert), max(gestiune)
	from #xmlPozitii
	group by idContract

	alter table #xmlPozitii add idLinie int identity
	set @xml = 
	(
		SELECT 
			'1' AS subunitate, @tip AS tip,CONVERT(VARCHAR(10), @data_facturilor, 101) data, c.loc_de_munca lm,c.tert tert,'1' AS fara_luare_date,'1' as returneaza_inserate, 
				nullif(@numar_pozdoc,'') as numar, rtrim(c.punct_livrare) as punctlivrare, rtrim(c.gestiune) as gestiune, @aviznefacturat as aviznefacturat, @detalii detalii, isnull(@curs, cf.curs) as curs,
			(
				SELECT 
					p.cod cod, p.cod_specific AS barcod, isnull(p.gestiune, c.gestiune) gestiune, p.cod_intrare codintrare,
					convert(DECIMAL(15, 2), (case when @cuRezervari =1 and n.tip<>'S' then prez.cantitate else p.cantitate end)) cantitate,p.pret as pvaluta,p.discount as discount,
					p.idPozContract as idpozcontract, prez.idPozDoc idpozdocrezervare,		
					(case when isnull(p.valuta,'')<>'' then p.valuta else null end) as valuta, (case when ISNULL(p.valuta,'')<>'' then convert(decimal(12,5),isnull(@curs, p.curs)) else null end) as curs,
					idLinie idlinie, cf.idJurnal as idjurnalcontract, p.detalii, p.comanda comanda
				from #xmlPozitii p
				INNER JOIN Nomencl n on n.cod=p.cod
				LEFT JOIN LegaturiContracte lc on lc.idPozContract=p.idPozContract and @cuRezervari=1
				LEFT JOIN PozDoc prez on  prez.tip='TE' and prez.gestiune_primitoare=@gestiuneRezervari and prez.idPozDoc=lc.idPozDoc
				where p.idContract=cf.idContract and (@cuRezervari = 0 OR prez.idPozDoc is not null or n.tip ='S')
				FOR XML raw,type
			)
		from @contracte cf
		inner join contracte c on c.idContract=cf.idContract
		FOR XML raw,root('Date')
	)
	if exists (select * from sysobjects where name ='wScriuDoc')
		exec wScriuDoc @sesiune=@sesiune, @parXML=@xml OUTPUT
	else 
	if exists (select * from sysobjects where name ='wScriuDocBeta')
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@xml OUTPUT
	else 
		raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc(beta).', 16, 1)

	
	EXEC sp_xml_preparedocument @ddoc OUTPUT, @xml
	IF OBJECT_ID('tempdb..#xmlPozitiiReturnate') IS NOT NULL
		DROP TABLE #xmlPozitiiReturnate
	
	SELECT
		idlinie, idPozDoc
	INTO #xmlPozitiiReturnate
	FROM OPENXML(@ddoc, '/row/docInserate/row')
	WITH
	(
		idLinie int '@idlinie',
		idPozDoc	int '@idPozDoc'

	)
	EXEC sp_xml_removedocument @ddoc 

	--generare inregistrari contabile
	if object_id('tempdb.dbo.#DocDeContat') is not null drop table #DocDeContat
	CREATE TABLE #DocDeContat (subunitate varchar(20),tip varchar(2),numar varchar(20),data datetime) 
	insert into #DocDeContat (subunitate,tip,numar,data)
	select distinct subunitate,tip,numar,data
	from pozdoc pd 
		inner join #xmlPozitiiReturnate x on x.idPozDoc=pd.idPozdoc
	where subunitate='1' and tip='AP' and data=@data_facturilor
	exec faInregistrariContabile @dinTabela=2
		
	create table #Legaturi (a bit)
	exec CreazaDiezLegaturi

	insert into #Legaturi (idPozContract, idPozDoc)
	select
		it.idPozContract, pr.idPozDoc
	from #xmlPozitii it
	JOIN #xmlPozitiiReturnate pr on pr.idlinie=it.idLinie
	
	set @xml_proc= (select 'Generare factura' explicatii for xml raw)
	exec wOPTrateazaLegaturiSiStariContracte @sesiune=@sesiune, @parXML=@xml_proc	


	IF @fara_mesaje=0
		select 
			'Au fost generate '+convert(varchar, count(*))+' facturi.' textMesaj,'Finalizare generare facturi' titluMesaj
		from @contracte
		where exists (select 1 from #xmlPozitiiReturnate)
		for xml raw, root('Mesaje')
	
	-- generez formularele
	if len(@formular)>0
	begin
		set @xml = 
		(
			select 
				@formular as formular, convert(char(10), @dataJos, 101) as datajos, convert(char(10), @dataSus, 101) as datasus, 
				(select c.nrFactura as factura, CONVERT(CHAR(10), @data_facturilor, 101) data_facturii from @contracte c for xml raw,type) facturi 
			for xml raw
		)
		exec wOPListareFacturi @sesiune=@sesiune,@parXML=@xml	
	end
END TRY

begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
