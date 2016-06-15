--***
create procedure [dbo].[wScriuPozdoc] @sesiune varchar(50), @parXML xml OUTPUT
as

declare @userASiS varchar(20), @fara_luare_date varchar(1),@sub varchar(20), @tip char(2), @numar char(20), @data datetime, @tipGrp char(2), @numarGrp char(20), @dataGrp datetime, 
	@sir_numere_pozitii varchar(max), @subtip varchar(2), @ptupdate int, @apelDinProcedura int, @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), 
	@jurnalProprietate varchar(3), 	@NrAvizeUnitar int, @NumarDocPrimit int, @gestiune char(9), @gestiune_primitoare varchar(40), @cod char(20), @cantitate decimal(17,5), @cod_intrare char(13), 
	@pret_valuta decimal(17,5), @tert char(13), @suma_tva decimal(15,2), @lm char(9), @valuta char(3), @curs float, @docXMLIaPozdoc xml, @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20), 
	@eroare xml, @mesaj varchar(max), @tip_doc varchar(2), @jurnal varchar(20), @factura char(20), @rec_factura_existenta char(20), @data_rec_fact_exist datetime, @cursorStatus int, @lDeschidereMachetaPreturi int,
	@parXmlScriereIntrari xml, @parXmlScriereIesiri xml, @searchText varchar(50), @lenNumar int, @deschidereRepCI bit, @contcorespondent varchar(40), @tip_TVA int,@asociereconf varchar(20)

begin try
/** 
	Cristy: Rog a se lasa prima apelarea procedurii 
		wScriuPozDocSP
	Nu scrieti alte linii inainte de asta
*/
--	Lucian: Am mutat apelul wScriuPozdocSP inainte de wScriuDoc - sa se excute wScriuPozdoc si daca exista wScriuPozdocSP. De regula wScriuPozdocSP doar modifica @parXML.
--	Am repus in try catch, intrucat daca se da eroare in SP sa nu se execute restul procedurii
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP')
	exec wScriuPozdocSP @sesiune, @parXML output

if isnull(@parXML.value('(/row/@_return)[1]', 'int'),0)=1 --flag ca in SP am comandat "RETURN"
	RETURN


EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE', 'DMPRET', @lDeschidereMachetaPreturi  output, 0, ''
exec luare_date_par 'GE', 'CANTI', @deschidereRepCI  output, 0, ''

select 
	@gestProprietate='', @clientProprietate='', @lmProprietate='', @jurnalProprietate=''
select 
	@gestProprietate=(case when cod_proprietate='GESTIUNE' then valoare else @gestProprietate end), 
	@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else @clientProprietate end), 
	@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else @lmProprietate end), 
	@jurnalProprietate=(case when Cod_proprietate='JURNAL' then Valoare else @jurnalProprietate end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA', 'JURNAL') and valoare<>''
	
set @searchText=ISNULL(@parXML.value('(//@_cautare)[1]', 'varchar(200)'), '')
set @fara_luare_date=ISNULL(@parXML.value('(//@fara_luare_date)[1]', 'char(1)'), '0')
set @tip_TVA=ISNULL(@parXML.value('(/row/@tiptva)[1]', 'int'), 0)
set @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
set @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'char(20)'), '')
set @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
set @subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'), '')
set @ptupdate=isnull(@parXML.value('(/row/row/@update)[1]', 'int'),0)
set @cod=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'char(20)'), '')
set @gestiune=ISNULL(@parXML.value('(/row/row/@gestiune)[1]', 'char(9)'), '')
if @gestiune=''
	set @gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'char(9)'), '')
if @gestiune=''
	set @gestiune=@gestProprietate
set @gestiune_primitoare=ISNULL(@parXML.value('(/row/row/@gestprim)[1]', 'varchar(40)'), '')
if @gestiune_primitoare=''
	set @gestiune_primitoare=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(40)'), '')
set @cantitate=isnull(@parXML.value('(/row/row/@cantitate)[1]', 'decimal(17,5)'),0)
set @cod_intrare=ISNULL(@parXML.value('(/row/row/@codintrare)[1]', 'char(13)'), '')
set @pret_valuta=isnull(@parXML.value('(/row/row/@pvaluta)[1]', 'decimal(14,5)'),0)
set @tert=ISNULL(@parXML.value('(/row/@tert)[1]', ' char(13)'), '') 
set @factura=ISNULL(@parXML.value('(/row/@factura)[1]', ' char(20)'), '') 
set @suma_tva=isnull(@parXML.value('(/row/row/@sumatva)[1]', 'decimal(15,2)'),0)
set @lm=ISNULL(@parXML.value('(/row/row/@lm)[1]', 'char(9)'), '') 
set @jurnal=ISNULL(@parXML.value('(/row/@jurnal)[1]', 'varchar(20)'), '') 
set @asociereconf=@parXML.value('(/row/@asociereconf)[1]', 'varchar(20)')
if @lm=''
	set @lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'char(9)'), '')
set @valuta=ISNULL(@parXML.value('(/row/row/@valuta)[1]', 'char(3)'), '') 
if @valuta=''
	set @valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'char(3)'), '') 

set @curs=isnull(@parXML.value('(/row/row/@curs)[1]', 'float'),0)
if @curs=0
	set @curs=isnull(@parXML.value('(/row/@curs)[1]', 'float'),0)
set @curs=convert(decimal(12,4),@curs)
set @contcorespondent=ISNULL(@parXML.value('(/row/row/@contcorespondent)[1]', 'varchar(40)'), '')

SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
if @lm=''
	set @lm=@lmProprietate

-- daca se modifica codul pe pozitie se reseteaza contul de stoc
if @parXML.value('(/row/row/@o_cod)[1]', 'char(20)') is not null and @parXML.value('(/row/row/@o_cod)[1]', 'char(20)')!=@cod 
	and @parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)') is not null and @tip in ('RM','RS','PP')
begin
	set @parXML.modify('delete (/row/row/@contstoc)[1]') 
	--select @parxml
end
--


if @numarGrp is null
	select @tipGrp=@tip, @numarGrp=@numar, @dataGrp=@data, @sir_numere_pozitii=''
-- variabila folosita pt. filtrarea tipului de document in tabelele doc/pozdoc, pentru ca sa nu facem multe case-uri
set @tip_doc=(case when @tip in ('RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)
if @parXML.exist('(/row/@tipinit)') = 0 
	set @parXML.modify ('insert attribute tipinit {sql:variable("@tip")} into (/row)[1]')
set @parXML.modify('replace value of (/row/@tip)[1] with sql:variable("@tip_doc")') 

set @lenNumar=(SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id 
			where tbl.name='pozdoc' and clmns.name= 'numar') 
if len(rtrim(@numar))>@lenNumar
begin
	set @mesaj='Numarul de document trebuie sa aiba maxim '+convert(varchar(3),@lenNumar)+' caractere!'
	raiserror(@mesaj, 16, 1)
end

/** Se va deschide macheta de multiselect la operare documente de iesire fara cod intrare completat, doar daca aceasta macheta exista. */
if @cantitate >= 0 and (select tip from nomencl where cod = @cod) not in ('S', 'R', 'F') and @ptupdate <> 1 and @apelDinProcedura = 0
	and @tip_doc in ('CM', 'TE', 'AP', 'AS', 'AC', 'AE', 'DF', 'PF', 'CI') and @cod_intrare = ''
	and ISNULL(@deschidereRepCI,0) = 1
begin
	
	if isnull(@numar, '')=''
	begin
		set @fXML = (select @tip tip, @userASiS utilizator, @lm lm, @jurnal jurnal,@asociereconf asociereconf for xml raw)		
		exec wIauNrDocFiscale @parXML = @fXML, @NrDoc = @NrDocPrimit output, @Numar = @NumarDocPrimit output
		
		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
		
		set @numar = @NrDocPrimit
	end

	declare @docInitializareIesire xml,
		--> variabile locale
		@datafacturiiIesire datetime, @datascadenteiIesire datetime, @punctlivrareIesire varchar(50),
		@aviznefacturatIesire bit, @comandaIesire varchar(50), @detaliiAntetDocIesire xml,
		@detaliiPozDocIesire xml
	
	select @datafacturiiIesire = @parXML.value('(/row/@datafacturii)[1]', 'datetime'),
		@datascadenteiIesire = @parXML.value('(/row/@datascadentei)[1]', 'datetime'),
		@punctlivrareIesire = isnull(@parXML.value('(/row/@punctlivrare)[1]', 'varchar(50)'), ''),
		@aviznefacturatIesire = isnull(@parXML.value('(/row/@aviznefacturat)[1]', 'bit'), 0),
		@comandaIesire = isnull(@parXML.value('(/row/@comanda)[1]', 'varchar(50)'), '')
	
	if @parXML.exist('(/row/detalii/row)[1]') = 1
		set @detaliiAntetDocIesire = @parXML.query('(/row/detalii/row)[1]')
	if @parXML.exist('(/row/row/detalii/row)[1]') = 1
		set @detaliiPozDocIesire = @parXML.query('(/row/row/detalii/row)[1]')

	set @docInitializareIesire =
	(
		select @tip as tip, convert(char(10), @data, 101) as data,
			@tip_TVA as tiptva,
			RTRIM(@numar) as numar,
			RTRIM(@lm) AS lm,
			RTRIM(@cod) as cod,
			RTRIM(@cantitate) as cantitate,
			RTRIM(@gestiune) as gestiune,
			RTRIM(@gestiune_primitoare) as gestprim,
			RTRIM(@tert) as tert,
			RTRIM(@factura) as factura,
			RTRIM(@comandaIesire) as comanda,
			RTRIM(@punctlivrareIesire) as punctlivrare,
			@datafacturiiIesire as datafacturii,
			@datascadenteiIesire as datascadentei,
			RTRIM(@valuta) as valuta,
			CONVERT(decimal(15,4), @curs) as curs,
			@aviznefacturatIesire as aviznefacturat,
			CONVERT(decimal(17,5), @pret_valuta) as pvaluta,
			RTRIM(@contcorespondent) as contcorespondent,
			@detaliiAntetDocIesire as detaliiAntet,
			@detaliiPozDocIesire as detalii
		for xml raw, root('row')
	)

	SELECT 'Repartizare cant. la iesiri' AS nume, 'RCI' AS codmeniu, 'O' AS tipmacheta,
		(SELECT @docInitializareIesire) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

	if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
			set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
		else
			set @parXML.modify ('insert attribute subunitate {sql:variable("@sub")} into (/row)[1]') 
		
		if @parXML.value('(/row/@numar)[1]', 'varchar(20)') is not null                          
			set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")') 
		else
			set @parXML.modify ('insert attribute numar {sql:variable("@numar")} into (/row)[1]') 				

		-- pt initializare antet
		select @parXML for xml raw('dateAntet'), root('Mesaje')
				
		if @fara_luare_date <> '1'
		begin
			--pt initializare antet
			set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tip) + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
			exec wIaPozdoc @sesiune = @sesiune, @parXML = @docXMLIaPozdoc 
		end

	return
end

-->	Mutat aici partea de SF/IF pentru a putea fi apelata si in cazul in care se executa wScriuDoc. Mai sus se citesc variabilele necesare acestei operatii
-->>>>>> START SCRIPT SPECIFIC SUBTIPURILOR SF-sosire factura, IF- intocmire factura<<<<<<<--
--daca subtip='SF' sau 'IF', sosire factura sau intocmire factura si nu este completat factura din 408 apelam macheta pentru sosire.intocmire factura
if @subtip in ('IF','SF') and @tip_doc in ('AP','AS','RM','RS') and @ptupdate<>1  and @apelDinProcedura=0
begin
	if @cantitate=0--pentru if si sf cantitatea va fi intotdeauna 1
		set @cantitate=1
				
	if isnull(@cod_intrare,'')<>''--daca s-a introdus pe macheta factura din 408, si nu s-a introdus o suma, suma va fi egala cu soldul facturii
		and isnull(@pret_valuta,0)=0
	begin
		select @pret_valuta=sold from facturi where factura=@cod_intrare and tert=@tert	
				
		--tratare valoare tva
		select @suma_TVA=convert(decimal(15,2),((@pret_valuta*100/(ff.Valoare+ff.TVA_22))*ff.TVA_22)/100)
		from facturi ff 
		where ff.Factura=@cod_intrare and ff.Tert=@tert and (ff.Tip=0x54 and @tip_doc in ('RM','RS') or ff.Tip=0x46 and @tip_doc in ('AP','AS'))

		set @pret_valuta=convert(decimal(17,5),@pret_valuta)-@suma_TVA

		if @pret_valuta<0
			select @cantitate=-1, @pret_valuta=abs(@pret_valuta)

		if @parXML.value('(/row/row/@cantitate)[1]', 'decimal(17, 5)') is not null                          
			set @parXML.modify('replace value of (/row/row/@cantitate)[1] with sql:variable("@cantitate")') 
		else
			set @parXML.modify ('insert attribute cantitate {sql:variable("@cantitate")} into (/row/row)[1]') 

		if @parXML.value('(/row/row/@sumatva)[1]', 'decimal(15, 2)') is not null                          
			set @parXML.modify('replace value of (/row/row/@sumatva)[1] with sql:variable("@suma_TVA")') 
		else
			set @parXML.modify ('insert attribute sumatva {sql:variable("@suma_TVA")} into (/row/row)[1]') 

		if @parXML.value('(/row/row/@pvaluta)[1]', 'decimal(14, 5)') is not null                          
			set @parXML.modify('replace value of (/row/row/@pvaluta)[1] with sql:variable("@pret_valuta")') 
		else
			set @parXML.modify ('insert attribute pvaluta {sql:variable("@pret_valuta")} into (/row/row)[1]') 
	end
					
	if isnull(@cod_intrare,'')=''
	begin
		if isnull(@numar, '')=''
		begin
			exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
			set @tipPentruNr=@tip 

			if @NrAvizeUnitar=1 and @tip='AS' 
				set @tipPentruNr='AP' 

			set @fXML  = (select @tipPentruNr tip, @userASiS utilizator, @lm lm, @jurnal jurnal,@asociereconf asociereconf for xml raw)		
			exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output
		
			if @NrDocPrimit is null
				raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
		
			set @numar=@NrDocPrimit
			set @parXML.modify('delete (/row/@numar)[1]')	
			set @parXML.modify('insert attribute numar {sql:variable("@numar")} into (/row)[1]')	
		end

		DECLARE 
			@dateInitializareSFIF XML	

		set @parXML.modify('delete (/row/row/@suma)[1]')	
		set @parXML.modify('insert attribute suma {sql:variable("@pret_valuta")} into (/row/row)[1]')
		set @parXML.modify('delete (/row/row/@tip)[1]')	
		set @parXML.modify('insert attribute tip {sql:variable("@tip")} into (/row/row)[1]')
		/*set @dateInitializareSFIF=
		(
			select @tip as tip, @tert as tert, convert(char(10), @data, 101) as data, @lm as lm,
				CONVERT(decimal(17,5),@pret_valuta) as suma, 
				RTRIM(@numar) as numar, 
				RTRIM(@factura) as factura, 
				@valuta as valuta,
				convert(decimal(15,4),@curs) as curs,
				@cod as cod,
				1 as cantitate,
				@gestiune as gestiune, 
				@parXML.value('(/row/row/@flm)[1]', 'int') as flm
			for xml raw ,root('row')
		)*/
		select
			@dateInitializareSFIF = @parXML
			
				
		SELECT 'Operatie pentru intocmire/sosire facturi'  nume, 'DO' codmeniu, 'D' tipmacheta, 'RM' tip,'YY' subtip,'O' fel,
			(SELECT @dateInitializareSFIF ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
			
		if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
			set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
		else
			set @parXML.modify ('insert attribute subunitate {sql:variable("@sub")} into (/row)[1]') 
		
		if @parXML.value('(/row/@numar)[1]', 'varchar(20)') is not null                          
			set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")') 
		else
			set @parXML.modify ('insert attribute numar {sql:variable("@numar")} into (/row)[1]') 				

		-- pt initializare antet
		select @parXML for xml raw('dateAntet'), root('Mesaje')
				
		if @fara_luare_date<>'1'
		begin
			--pt initializare antet
			set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tip) + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
			exec wIaPozdoc @sesiune=@sesiune, @parXML=@docXMLIaPozdoc 
		end
				
		return
	end
end
-->>>>>> STOP SCRIPT SPECIFIC SUBTIPURILOR SF-sosire factura, IF- intocmire factura<<<<<<<--

/* Tratam daca cumva e pozitie de promotie-> se executa procedura care face asta separat*/
	IF @tip = 'AP' and @subtip='PR'
	begin
		set @parXML.modify('insert attribute _document {"aviz"} into (/row)[1]')
		exec wOPTrateazaPromotie @sesiune=@sesiune, @parXML=@parXML OUTPUT

		if @fara_luare_date<>'1'
			exec wIaPozdoc @sesiune=@sesiune, @parXML=@parXML 		
		return
	end

if (@tip_doc='RM' and @subtip in ('MF','MM') or @tip='TE' /*and @subtip='TR'*/) and exists (select 1 from sysobjects where [type]='P' and [name]='wPregatireMFdinCG')
begin
	declare @parXMLprimit xml
	set @parXMLprimit=@parXML
	exec wPregatireMFdinCG @sesiune, @parXML output
end


if @tip_doc in ('RM', 'RS', 'RC') and not exists (select 1 from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar=@numar) 
	begin
		set @rec_factura_existenta=(select max(numar) from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar<>@numar) 
		set @data_rec_fact_exist=(select max(data) from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar=@rec_factura_existenta) 
	end

if exists (select * from sysobjects where name ='wScriuDoc') 
begin
	exec wScriuDoc @sesiune, @parXML OUTPUT
	if nullif(@numarGrp,'') is null
	begin
		declare @idPozDocReturnat int
		set @idPozDocReturnat=@parXML.value('(/row/docInserate/row/@idPozDoc)[1]', 'int')
		select @tipGrp=tip, @numarGrp=numar, @dataGrp=data from pozdoc where idpozdoc=@idPozDocReturnat
	end
end
else /*Incepe Vechiul wScriuPozDoc de baza*/
begin
	declare @data_facturii datetime, @data_scadentei datetime, @lmprim char(9), 
		@numar_pozitie int, @codcodi char(35), @codiPrim varchar(13),
		@pret_amanunt float, @cota_TVA float, @tva_valuta float, @tipTVA decimal(12,2), @comanda char(20), @cont_stoc varchar(40), @pret_stoc float, 
		@locatie char(30), @locatieStoc char(30), @contract char(20), @lot char(13), @data_expirarii datetime, @data_expirarii_stoc datetime, 
		@explicatii char(30), @cont_factura varchar(40), @discount float, @punct_livrare char(5), 
		@barcod char(30), @cont_corespondent varchar(40), @DVI char(25), @categ_pret int, @cont_intermediar varchar(40), @cont_venituri varchar(40), @TVAnx float, 
		@nume_delegat char(30), @serie_buletin char(10), @numar_buletin char(10), @eliberat_buletin char(30), @mijloc_transport char(30), @nr_mijloc_transport char(20), 
		@data_expedierii datetime, @ora_expedierii char(6), @observatii char(200), @punct_livrare_expeditie char(5), 
		@IesFaraStoc int, 
		@stare int, @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @codi_stoc char(13), @stoc float, @cant_desc float, @nr_poz_out int, 
		@Bugetari int, @TabelaPreturi int, @indbug varchar(20), @comanda_bugetari varchar(40), @accizecump float, 
		@prop1 varchar(20),@prop2 varchar(20),@serie varchar(20),@termenscadenta int,@Serii int,
		@zilescadenta int,@facturanesosita bit,@aviznefacturat bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(40),@suprataxe float,@o_suma_TVA float, 
		@fetch_crspozdoc int, @TEACCODI int,@text_alfa2 varchar(30),-->campul alfa 2 din text_pozdoc
		@o_pret_amanunt float,@o_pret_valuta float,@adaos decimal(12,2),@numarpozitii int, @detalii xml,@binar varbinary(128),
		@docInserted xml, @returneaza_inserate bit,@idPlajaPrimit int,
		@idJurnalContract int, @idPozContract int, @docJurnalContracte xml, @detalii_antet xml
	
	
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
	exec luare_date_par 'GE','PRETURI', @TabelaPreturi output, 0, ''
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, '' -- lucreaza cu serii
	exec luare_date_par 'UC', 'TEACCODI', @TEACCODI output, 0, '' -- TE cu acelasi cod intrare la primitor 
	exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output

	begin try
		-------------------------------------------------------------------------------------------
		set @docInserted=''
		set @returneaza_inserate=ISNULL(@parXML.value('(/row/@returneaza_inserate)[1]', 'bit'), 0)

		if ISNULL(@stare,'')=''
			set @stare=3
		
		exec luare_date_par 'GE', 'FARASTOC', @IesFaraStoc output, 0, ''

		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
		declare crspozdoc cursor for
		select 
			tip, upper(numar), data,upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else @gestProprietate end)) as gestiune, 
			(case when isnull(gestiune_primitoare_pozitii, '')<>'' then gestiune_primitoare_pozitii else isnull(gestiune_primitoare_antet, '') end) as gestiune_primitoare, 
			upper((case when isnull(tert, '')<>'' then tert when tip in ('AP', 'AS') then @clientProprietate else '' end)) as tert, 
			upper(isnull(factura_pozitii, isnull(factura_antet, ''))) as factura, 
			isnull(datafact, isnull(data, '01/01/1901')) as datafact, isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))) as datascad, 
			(case when isnull(lm_pozitii, '')<>'' then lm_pozitii when isnull(lm_antet, '')<>'' then lm_antet else @lmProprietate end) as lm, 
			isnull(lmprim_antet, '') as lmprim, 
			isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod,
			upper(isnull(codcodi,isnull(cod,''))) as codcodi,
			isnull(cantitate, 0) as cantitate, pret_valuta, coalesce(tip_TVA_pozitii,tip_TVA_antet,0) as tipTVA,	
			zilescadenta as zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta
			isnull(facturanesosita,0),--bifa de factura nesosita
			isnull(aviznefacturat,0),--bifa de aviz nefacturat
	
			upper(isnull(cod_intrare, '')) as cod_intrare, upper(isnull(codiPrim, '')) as codiPrim,isnull(pret_amanunt, 0) as pret_amanunt, cota_TVA, suma_TVA, TVA_valuta, 
			upper(case when isnull(comanda_pozitii, '')<>'' then comanda_pozitii else isnull(comanda_antet, '') end) as comanda, 
			isnull(indbug_pozitii, '') as indbug, 
			isnull(cont_de_stoc, '') as cont_stoc, isnull(pret_de_stoc, 0) as pret_stoc, 
	
			---datele, curs si valuta, completate in pozitii sunt mai tari decat cele din antet
			---(totusi este recomandata configurarea de introducere curs si valuta din antet)
			upper(isnull(isnull(valuta,valuta_antet),'')) as valuta,
			convert(decimal(12,4),isnull(isnull(curs,curs_antet),0)) as curs,	

			upper(isnull(locatie, '')) as locatie,
			upper((case when isnull(contract_pozitii, '')<>'' then contract_pozitii else isnull(contract_antet, '') end)) as [contract], 
			upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901'), 
			(case when isnull(explicatii_pozitii, '')<>'' then explicatii_pozitii else isnull(explicatii_antet, '') end) as explicatii, 
			(case when isnull(isnull(jurnal, jurnalantet),'')<>'' then isnull(jurnal, jurnalantet) else @jurnalProprietate end) as jurnal,
			(case when isnull(cont_factura_pozitii, '')<>'' then cont_factura_pozitii else /*isnull(*/cont_factura_antet/*, '')*/ end) as cont_factura, 
			discount, 
			(case when isnull(punct_livrare_pozitii, '')<>'' then punct_livrare_pozitii else isnull(punct_livrare_antet, '') end) as punct_livrare, 
			isnull(barcod, '') as barcod, 
			(case when isnull(cont_corespondent_pozitii, '')<>'' then cont_corespondent_pozitii when tip in ('AI', 'AE', 'AF') then /*isnull(*/cont_corespondent_antet/*, '')*/ else '' end) as cont_corespondent, 
			isnull(nullif(left(dvi,13),''), isnull(numardvi, '')) as dvi, isnull(categ_pozitii, isnull(categ_antet, 0)) as categ_pret, 
			/*isnull(*/cont_intermediar/*, '')*/ as cont_intermediar, 
			isnull((case when isnull(cont_venituri_pozitii, '')<>'' then cont_venituri_pozitii else /*isnull(*/cont_venituri_antet/*, '')*/ end),'') as cont_venituri, 
			isnull(tva_neexigibil_pozitii, tva_neexigibil_antet) as tva_neexigibil, 
			isnull(accizecump, 0) as accizecump, 
			upper(isnull(nume_delegat, '')) as nume_delegat, upper(isnull(serie_buletin, '')) as serie_buletin, 
			isnull(numar_buletin, '') as numar_buletin, upper(isnull(eliberat_buletin, '')) as eliberat_buletin, 
			upper(isnull(mijloc_transport, '')) as mijloc_transport, upper(isnull(nr_mijloc_transport, '')) as nr_mijloc_transport, 
			isnull(data_expedierii, data) as data_expedierii, isnull(ora_expedierii, '000000') as ora_expedierii, 
			isnull(observatii, '') as observatii, isnull(punct_livrare_expeditie, '') as punct_livrare_expeditie, 
			isnull(ptupdate,0) as ptupdate ,
			stare as stare,detalii as detalii,
			detalii_antet as detalii_antet,
			numarpozitii as numarpozitii,--numar de pozitii din doc, este utilizat in validare unicitate document->sa ramana fara isnull(...)
	
			isnull(idJurnalContract,0) as idJurnalContract,
			isnull(idPozContract,0) as idPozContract,
	
			--campuri din tabela textpozdoc
			rtrim(ltrim(text_alfa2)) as text_alfa2,
	
			--proprietati pt serii
			isnull(prop1,'') as prop1,
			isnull(prop2,'') as prop2,
			isnull(serie,'') as serie,
			isnull(subtip,'') as subtip,
			o_suma_TVA,o_pret_valuta,o_pret_amanunt,adaos
	
			from OPENXML(@iDoc, '/row/row')
			WITH 
			(
				detalii_antet XML '../detalii/row',
				detalii xml 'detalii',
				tip char(2) '../@tip', 
				numar char(20) '../@numar',
				data datetime '../@data',
				gestiune_antet char(9) '../@gestiune',
				gestiune_primitoare_antet char(13) '../@gestprim', 
				tert char(13) '../@tert',
				factura_antet char(20) '../@factura',
				datafact datetime '../@datafacturii',
				datascad datetime '../@datascadentei',
				lm_antet char(9) '../@lm',
				lmprim_antet char(9) '../@lmprim',
				numardvi varchar(30) '../@numardvi',
				comanda_antet char(20) '../@comanda', 
				indbug_antet char(20) '../@indbug', 
				cont_factura_antet varchar(40) '../@contfactura', 
				cont_corespondent_antet varchar(40) '../@contcorespondent', 
				cont_venituri_antet varchar(40) '../@contvenituri', 
				explicatii_antet char(30) '../@explicatii', 
				punct_livrare_antet char(5) '../@punctlivrare',
				categ_antet char(5) '../@categpret',
				tva_neexigibil_antet float '../@tvaneexigibil',
				contract_antet char(20) '../@contract', 
				nume_delegat char(30) '../@numedelegat', 
				serie_buletin char(10) '../@seriabuletin', 
				numar_buletin char(10) '../@numarbuletin', 
				eliberat_buletin char(30) '../@eliberat', 
				mijloc_transport char(30) '../@mijloctp', 
				nr_mijloc_transport char(20) '../@nrmijloctp', 
				data_expedierii datetime '../@dataexpedierii', 
				ora_expedierii char(6) '../@oraexpedierii', 
				observatii char(200) '../@observatii', 
				punct_livrare_expeditie char(5) '../@punctlivrareexped', 
				tip_TVA_antet int '../@tiptva',
				zilescadenta int '../@zilescadenta',--zilele de scadenta->data_scadentei se va calcula din zilele de scadenta
				facturanesosita bit '../@facturanesosita',--bifa pentru facturi nesosite, dc este pusa atunci contul facturii va fi 408(furnizori-facturi nesosite)
				aviznefacturat bit '../@aviznefacturat',--bifa pentru avize nefacturate, dc este pusa atunci contul facturii va fi luat din parametrii(cont beneficiari avize nefacturate)
				jurnalantet char(3) '../@jurnal', 
				---cursul si valuta din antet
				valuta_antet varchar(3) '../@valuta' , 
				curs_antet varchar(14) '../@curs',
				numarpozitii int	'../@numarpozitii',--numar de pozitii din doc, este utilizat in validare unicitate document
		
				stare smallint '../@stare',
		
				---pozitii-----
				numar_pozitie int '@numarpozitie',
				cod char(20) '@cod',
				codcodi char(35) '@codcodi',
				factura_pozitii char(20) '@factura',
				cantitate decimal(17, 5) '@cantitate',
				pret_valuta decimal(14, 5) '@pvaluta', 
				pret_amanunt decimal(14, 5) '@pamanunt', 
				cod_intrare char(13) '@codintrare',	
				codiPrim char(13) '@codiprimitor',		
				cota_TVA decimal(5, 2) '@cotatva', 
				suma_TVA decimal(15, 2) '@sumatva', 
				TVA_valuta decimal(15, 2) '@tvavaluta', 
				gestiune_pozitii char(9) '@gestiune', 
				gestiune_primitoare_pozitii varchar(40) '@gestprim', 
				lm_pozitii char(9) '@lm', 
				comanda_pozitii char(20) '@comanda', 
				indbug_pozitii char(20) '@indbug', 
				cont_de_stoc varchar(40) '@contstoc', 
				pret_de_stoc float '@pstoc', 
				valuta char(3) '@valuta', 
				curs float '@curs', 
				locatie char(30) '@locatie', 
				contract_pozitii char(20) '@contract', 
				lot char(13) '@lot', 
				data_expirarii datetime '@dataexpirarii', 
				explicatii_pozitii char(30) '@explicatii', 
				jurnal char(3) '@jurnal', 
				cont_factura_pozitii varchar(40) '@contfactura', 
				discount float '@discount', 
				punct_livrare_pozitii char(5) '@punctlivrare', 
				barcod char(30) '@barcod', 
				cont_corespondent_pozitii varchar(40) '@contcorespondent', 
				DVI char(25) '@dvi',
				categ_pozitii int '@categpret', 
				cont_intermediar varchar(40) '@contintermediar', 
				cont_venituri_pozitii varchar(40) '@contvenituri',
				tva_neexigibil_pozitii float '@tvaneexigibil',
				accizecump float '@accizecump', 
				ptupdate int '@update' ,
				adaos decimal(12,2) '@adaos',
				tip_TVA_pozitii decimal(12,2) '@tiptva',
		
				-- trimise din modulul contracte
				idJurnalContract int '@idjurnalcontract', 
				idPozContract int '@idpozcontract', 
		
				--campuri din tabela textpozdoc
				text_alfa2 varchar(30) '@text_alfa2',
		
				---proprietati pt serii
				prop1 char(20) '@prop1',
				prop2 char(20) '@prop2',
				serie char(20) '@serie',
				subtip char(20) '@subtip', 
		
				o_suma_TVA decimal(15, 2) '@o_sumatva' ,
				o_pret_amanunt decimal(14, 5) '@o_pamanunt',
				o_pret_valuta decimal(14, 5) '@o_pvaluta'
			)

			open crspozdoc
			fetch next from crspozdoc into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert, 
				@factura, @data_facturii, @data_scadentei, @lm, @lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,
				@zilescadenta,@facturanesosita,@aviznefacturat,
				@cod_intrare, @codiPrim, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc, 
				@valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount, 
				@punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx, 
				@accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, 
				@nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,@detalii,@detalii_antet,@numarpozitii,
				@idjurnalContract, @idPozContract, @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos
			set @fetch_crspozdoc=@@fetch_status
		while @fetch_crspozdoc= 0
		begin
			if @cod='' and @barcod<>''
				select top 1 @cod=rtrim(Cod_produs) from codbare where Cod_de_bare=@barcod			
			if year(@data_facturii)<1921
				set @data_facturii=@data --convert(char(10),GETDATE(),101)
			if YEAR(@data_scadentei)<1921
				set @data_scadentei=@data_facturii
			if @lm=''
				set @lm=isnull((select rtrim(max(loc_de_munca)) from gestcor where gestiune=@gestiune), '')
			if @lm=''
				set @lm =isnull((select rtrim(max(loc_munca)) from infotert where subunitate = @sub and identificator <> '' and tert = @tert), '')
		
			set @comanda_bugetari=convert(char(20),@comanda)
			if @tip = 'RN' set @tip = 'RM' -- tratam tipul RN(receptiile care au pe poz cantitate<0) la fel ca tip RM
		
			--daca pe macheta exista campul zilescadenta atunci datascadentei se calculeaza din zilele scadenta, altfel sa ia campul data scadentei
			if isnull(@zilescadenta,0)>0 
				set @data_scadentei=DATEADD(day,@zilescadenta,@data_facturii)
		
			if CHARINDEX('|',@codcodi,1)>0 and @codcodi<>@cod
			begin
			set @cod=isnull((select substring(@codcodi,1,CHARINDEX('|',@codcodi,1)-1)),@cod)
			set @cod_intrare=isnull((select substring(@codcodi,CHARINDEX('|',@codcodi,1)+1,LEN(@codcodi))),@cod_intrare)
			end
		
			if isnull(@numar, '')=''
			begin
				select @tipPentruNr=@tip 
				if @NrAvizeUnitar=1 and @tip='AS' 
					set @tipPentruNr='AP' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
				set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
				set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
				set @fXML.modify ('insert attribute asociereconf {sql:variable("@asociereconf")} into (/row)[1]')
			
				exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output
			
				if @NrDocPrimit is null
					raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
				Select @numar=@NrDocPrimit, @numarGrp=@NrDocPrimit
				
			end

			/** Aici va trebui regandit un pic conceptul de calcul automat al TVA-ului */
			if @cota_tva is null and  /* (Andrei ...asa a trebuit la arges,am vb cu d-ul Ghita)isnull(@cota_tva,0)=0 and*/ @tip in ('AP', 'AS', 'AC')
				set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)
		
			if @cota_tva is null and @tip in ('RM','RC','RS') --ar trebui pusa in general indiferent de tip
				set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)

			/*Completare cota TVA = 0, pentru documente fara factura in conditiile setarii [X]Ignorare inregistrare prin 4428 la receptii / avize fara factura.*/
			declare @ignor4428Document int
			select @ignor4428Document=isnull((case when parametru='NEEXDOCFF' then val_logica else @ignor4428Document end),0)
			from par where Tip_parametru='GE' and Parametru in ('NEEXDOCFF')

			if @ignor4428Document=1 and @ptUpdate=0 and (@tip in ('RM','RS') and @facturanesosita=1 or @tip in ('AP','AS') and @aviznefacturat=1)
				select @cota_tva=0
		
			if @cota_TVA is null
				set @cota_TVA=0
		
			/* 
				@o_suma_TVA e null daca nu exista in form-ul din pozitii. Daca nu exista in form, setam @suma_tva null pt a fi recalculat.
				pentru a nu recalcula suma, am putea adauga un atribut in xml (@suma_tva_user="1") prin o operatie specifica de modificare tva, care sa salveze suma ceruta de user.
			*/
			if @ptupdate=1 AND @o_suma_TVA is null 
				set @suma_tva=null 
			-------------------- gata calcul automat al TVA-ului	------------------------	
		
			if (@tip in ('RM', 'RS', 'AI', 'TE') and abs(@pret_amanunt)<0.00001) /*Pentru pret cu amanunt la stocuri - intrari */
				or (@tip in ('AP', 'AS', 'AC') and (@pret_valuta is null or @pret_valuta=0))  /*Pentru pret vanzare la iesiri */
			begin
				/*
				declare @dXML xml, @doc_in_valuta int
				set @dXML = '<row/>'
				set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
				declare @dstr char(10)
				set @dstr=convert(char(10),@data,101)			
				set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')
				set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
				set @dXML.modify ('insert attribute comandalivrare {sql:variable("@contract")} into (/row)[1]')
				set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')
				set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)
				set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')
				if @pret_valuta=0 set @pret_valuta=null*/
				create table #preturi(cod varchar(20),nestlevel int)
				insert into #preturi
				select @cod,@@NESTLEVEL
			
				exec CreazaDiezPreturi

				/**
					La "intrari" vom alter putin @parXML asa incat sa nu trimitem "variabile" pentru determinarea pretului care tin de iesiri
						Ex: Tert, Punct liv., Contract, etc

					Vom crea o "copie" @parXML pentru ca modificarile din continul lui sa aiba efect doar in wIaPreturi nu si aici in procedura
				**/
				declare @parXMLPreturi xml
				select @parXMLPreturi= @parXML

				IF @tip in ('RM','RS','AI','TE')
				BEGIN 
					set @parXMLPreturi.modify('delete (/row/@tert)[1]')
					set @parXMLPreturi.modify('delete (/row/@punctlivrare)[1]')
					set @parXMLPreturi.modify('delete (/row/@idContract)[1]')
					set @parXMLPreturi.modify('delete (/row/@comandalivrare)[1]')
				END

				exec wIaPreturi @sesiune=@sesiune, @parXML=@parXMLPreturi
			
				if (@tip in ('AP', 'AS', 'AC') and (@pret_valuta is null or @pret_valuta=0))
					/* Daca se opereaza pretul sau discountul il lasam pe acela */
					select top 1 
						@pret_valuta=(case when ISNULL(@pret_valuta,0)=0 then pret_vanzare else @pret_valuta end ),
						@discount=(case when ISNULL(@discount,0)=0 then discount else @discount end)
					from #preturi
				else if (@tip in ('RM', 'RS', 'AI', 'TE') and abs(@pret_amanunt)<0.00001)
					select top 1 @pret_amanunt=pret_amanunt
					from #preturi

				drop table #preturi
			end
		
			select @pret_valuta=isnull(@pret_valuta, 0), @discount=isnull(@discount, 0)
		
			if @tip='DF'
			begin
				if isnull(@lm,'')=''
					set @lm=isnull((select max(Loc_de_munca) from personal where Marca=@gestiune_primitoare),'')
				if @comanda_bugetari is null or @comanda_bugetari='' 
					set @comanda_bugetari=isnull((select max(Centru_de_cost_exceptie) from infopers where Marca=@gestiune_primitoare),'')
			end

			if @tip='AF' or @tip='PF' or @tip='CI'
			begin
				if isnull(@lm,'')='' 
					set @lm=isnull((select max(Loc_de_munca) from personal where Marca=@gestiune),'')
			end
				
			if @tip='RM' and @adaos is not null and @adaos>0
			begin
				set @pret_amanunt=round(round(@pret_valuta*(100+@adaos)/100,2)*(100+@cota_tva)/100,2)
				if @parXML.value('(/row/row/@pamanunt)[1]', 'decimal(12,2)') is not null                  
					set @parXML.modify('replace value of (/row/row/@pamanunt)[1] with sql:variable("@pret_amanunt")')                
			end

			if @tip in ('AC','AP','AS','RM','RS') and @subtip='AA' and isnull(@cod_intrare,'')='' 
				set @cod_intrare='AV'+replace(convert(char(5),@data,103),'/','')+right(convert(char(10),@data,103),2)

			---->>>>>>>>>>>>>>>Cod specific lucrului pe serii<<<<<<<<<<<<<<<<<<<----
			if @subtip='SE' --daca subtipul este 'SE' suntem pe pozitie de serie, si atunci citim date din linie
				begin			
				set @cod=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'), '')
				set @cod_intrare=isnull(ISNULL(@parXML.value('(/row/linie/@codintrare)[1]', 'varchar(13)'), @parXML.value('(/row/linie/@codintrareS)[1]', 'varchar(13)')),'')
				set @numar_pozitie=ISNULL(@parXML.value('(/row/linie/@numarpozitie)[1]', 'int'), '')			
				set @pret_valuta=ISNULL(@parXML.value('(/row/linie/@pvalutaS)[1]','float'),0)
				set @pret_stoc=ISNULL(@parXML.value('(/row/linie/@pstocS)[1]','float'),0)
				end

			if isnull(@serie,'')='' and (select MAX(um_2) from nomencl where cod=@cod)='Y'---formare serie pe baza celor 2 proprietati---	
				set @serie=(case when @prop1<>'' and @prop2<>'' then rtrim(ltrim(@prop1))+','+RTRIM(ltrim(@prop2))when  @prop1<>'' and @prop2='' then @prop1 else''end)
		
			 ---pt coduri care au acelasi pret de stoc, aceasi gestiune se pastreaza codul de intrare chiar dc au serii diferite (pentru intrari) 
			if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0	and @tip in ('PP','RM') 
			   and ISNULL(@cod_intrare,'')=''   
				begin
					set @cod_intrare=isnull((select max(cod_intrare) from pozdoc where subunitate=@sub and tip=@tip and numar=@Numar and data=@Data 
															  and gestiune=@Gestiune and cod=@Cod and pret_de_stoc=@pret_stoc
															  and pret_valuta=@pret_valuta
																			 ),'')
					set @numar_pozitie=isnull((select MAX(numar_pozitie) from pozdoc where subunitate=@sub and tip=@tip and numar=@Numar and data=@Data
															  and Cod_intrare=@cod_intrare ),'')  
				end                                                           
			--->>>>>>>>>>>>>>>>>>Sfarsit cod specific lucrului pe serii<<<<<<<<<<<<<<-----------	
		
		
			if @tip='RS' and @DVI='' 
				set @DVI=(select MAX(Denumire) from terti where Subunitate=@sub and tert=@tert)
			/** Accize cumparare = in cazul receptiilor cantitatea de pe factura **/
			if @tip in ('RM', 'RC') and @accizecump=0
				set @accizecump=@cantitate		
			
			if isnull(@numar,'')='' 
				raiserror('Pe acest tip de document nu au fost definite plaje de numere!(wScriuPozdoc) ',11,1)	

			if @factura='' and @tip in ('RM', 'RS') 
				set @factura=@numar
     
			----->>>>> start cod formare parametru xml pentru procedurile de scriere intrari<<<<-----
			declare @data_facturiiS char(10),@data_scadenteiS char(10),@data_expirariiS char(10),@dataS char(10)
		
			if @tip in ('RM', 'RS', 'RC', 'AI', 'PP', 'AF')-->daca suntem pe tipuri specifice documentelor de intrare
			begin
				set @dataS=CONVERT(char(10),@data,101)
				set @data_facturiiS=CONVERT(char(10),@data_facturii,101)
				set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)
				set @data_expirariiS=CONVERT(char(10),isnull(@data_expirarii,@data_expirarii_stoc),101)
				declare @sumatv decimal(15,4)
				set @sumatv=convert(decimal(15,4),@suma_tva)						
		
				set @parXmlScriereIntrari =CONVERT(xml, '<row>'+isnull(convert(varchar(max),@detalii),'') + '</row>')
				set @parXmlScriereIntrari.modify ('insert 
						(					
						attribute tip {sql:variable("@tip")},
						attribute subtip {sql:variable("@subtip")},
						attribute numar {sql:variable("@numar")},
						attribute data {sql:variable("@dataS")},
						attribute tert {sql:variable("@tert")},
						attribute factura {sql:variable("@factura")},
						attribute data_facturii {sql:variable("@data_facturiiS")},
						attribute data_scadentei {sql:variable("@data_scadenteiS")},
						attribute cont_factura {sql:variable("@cont_factura")},
						attribute gestiune {sql:variable("@gestiune")},
						attribute gestiune_primitoare {sql:variable("@gestiune_primitoare")},
						attribute cod {sql:variable("@cod")},
						attribute cod_intrare {sql:variable("@cod_intrare")},
						attribute cont_stoc {sql:variable("@cont_stoc")},
						attribute locatie {sql:variable("@locatie")},
						attribute cantitate {sql:variable("@cantitate")},
						attribute valuta {sql:variable("@valuta")},
						attribute curs {sql:variable("@curs")},
						attribute pret_valuta {sql:variable("@pret_valuta")},
						attribute discount {sql:variable("@discount")},
						attribute pret_amanunt {sql:variable("@pret_amanunt")},
						attribute pret_stoc {sql:variable("@pret_stoc")},
						attribute lm {sql:variable("@lm")},
						attribute comanda_bugetari {sql:variable("@comanda_bugetari")},
						attribute jurnal {sql:variable("@jurnal")} ,
						attribute contract {sql:variable("@contract")},
						attribute DVI {sql:variable("@DVI")},
						attribute stare {sql:variable("@stare")},
						attribute barcod {sql:variable("@barcod")},
						attribute tipTVA {sql:variable("@tipTVA")},
						attribute data_expirarii {sql:variable("@data_expirariiS")},
						attribute utilizator {sql:variable("@userASiS")},
						attribute serie {sql:variable("@serie")},
						attribute cota_TVA {sql:variable("@cota_TVA")},
						attribute suma_tva {sql:variable("@suma_tva")},
						attribute numar_pozitie {sql:variable("@numar_pozitie")},
						attribute accizecump {sql:variable("@accizecump")},
						attribute lot {sql:variable("@lot")},
						attribute cont_corespondent {sql:variable("@cont_corespondent")},
						attribute cont_venituri {sql:variable("@cont_venituri")},
						attribute cont_intermediar {sql:variable("@cont_intermediar")},
						attribute suprataxe {sql:variable("@suprataxe")},
						attribute update {sql:variable("@ptupdate")},
						attribute text_alfa2 {sql:variable("@text_alfa2")},
						attribute explicatii {sql:variable("@explicatii")}
						)					
						into (/row)[1]')	
				--->>>>stop cod formare parametru xml pentru procedurile de scriere intrari<<<<-----
	
				if @tip in ('RM', 'RS', 'RC')
				begin
					if @facturanesosita=1
					begin
						declare @ctFurnRecNesosite varchar(40)
						set @ctFurnRecNesosite=nullif((select rtrim(val_alfanumerica) from par where tip_parametru='GE' and parametru='CTFURECNE'),'')	--citit din parametrii contul facturii nesosite
						set @cont_factura=(case when ISNULL(@ctFurnRecNesosite,'')='' then '408' else @ctFurnRecNesosite end) --daca este pusa bifa de factura nesosita, contul facturii va fi cel din parametrii (daca este completat), altfel 408.
						set @parXmlScriereIntrari.modify('replace value of (/row/@cont_factura)[1] with sql:variable("@cont_factura")')
					end
					exec wScriuReceptie @parXmlScriereIntrari=@parXmlScriereIntrari output
				
					if @Bugetari=1 -->pentru bugetari, se scrie si indicatorul bugetar -- vezi ca este si la iesiri ceva similar
					begin
						set @cont_stoc=@parXmlScriereIntrari.value('(/row/@cont_stoc)[1]', 'varchar(40)')
						--	scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
						if left(@cont_stoc,1)='6' and isnull(@indbug,'')='' and 1=0 -->pentru receptii este nevoie de indicator bugetar doar daca contul de stoc este de clasa 6
						begin
							--formare indicator bugetar->atasat contului de venituri
							set @numar_pozitie=@parXmlScriereIntrari.value('(/row/@numar_pozitie)[1]', 'int')
							exec wFormezIndicatorBugetar @Cont=@cont_stoc,@Lm=@lm,@Indbug=@indbug output 
							set @comanda_bugetari=left(@comanda,20)+@indbug	
							--scriere indicator bugetar in pozdoc
							update pozdoc set comanda=@comanda_bugetari where subunitate=@sub and tip=@tip and data=@data and numar=@numar and numar_pozitie=@numar_pozitie 
						end 
					end	
				end
			
				if @tip='AI'
				begin
					if  isnull(@curs,0)<>0 and ISNULL(@valuta,'')<>'' and ISNULL(@pret_valuta,0)<>0
					begin
						set @pret_stoc=@pret_valuta*@curs	--se calculeaza pretul de stoc in functie de valuta,curs si pretul valuta
						set @parXmlScriereIntrari.modify('replace value of (/row/@pret_stoc)[1] with sql:variable("@pret_stoc")') 
					end
					exec wScriuAI @parXmlScriereIntrari=@parXmlScriereIntrari output
				end
			
				if @tip='PP'
				begin	
					if  isnull(@curs,0)<>0 and ISNULL(@valuta,'')<>'' and ISNULL(@pret_valuta,0)<>0
					begin
						set @pret_stoc=@pret_valuta*@curs	--se calculeaza pretul de stoc in functie de valuta,curs si pretul valuta
						set @parXmlScriereIntrari.modify('replace value of (/row/@pret_stoc)[1] with sql:variable("@pret_stoc")') 
					end
					exec wScriuPP @parXmlScriereIntrari=@parXmlScriereIntrari output			
				end	
				
				if @tip='AF'
				begin
					exec wScriuAF @parXmlScriereIntrari=@parXmlScriereIntrari
				end
			
				IF @returneaza_inserate = 1
					SET @docInserted = CONVERT(XML, convert(VARCHAR(max), @docInserted) + convert(VARCHAR(max), @parXmlScriereIntrari.query('/Inserate/row')))
			
				if @idPozContract>0 -- operatii de facut cand se scrie o pozitie din modulul contracte
				begin
					if @idJurnalContract=0 -- daca nu s-a trimis idJurnal, jurnalizam aici operatia.
					begin
						SELECT @docJurnalContracte = 
							(SELECT 
								idContract idContract, 
								GETDATE() data, 
								'Generare '+@tip explicatii 
							from PozContracte where idPozContract=@idPozContract
							FOR XML raw )
						EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnalContracte OUTPUT
						SET @idJurnalContract = @docJurnalContracte.value('(/*/@idJurnal)[1]', 'int')
					end
				
					INSERT INTO LegaturiContracte (idJurnal, idPozContract, IdPozDoc)
					SELECT 
						@idJurnalContract, 
						@idPozContract, 
						PD.r.value('(@idPozDoc)[1]', 'int') idPozDoc
					FROM @parXmlScriereIntrari.nodes('/Inserate/row') PD(r)
				end
			end
			--stop scriere intrari
			
			if @tip in ('CM', 'AP', 'AS', 'AC', 'AE', 'TE', 'DF', 'PF', 'CI')--daca suntem pe tip specific documente de iesire
			begin
		
				set @tip_gestiune_filtru_stoc = (case when @tip in ('PF', 'CI') then 'F' else '' end)
				set @tip_nom=isnull((select tip from nomencl where cod=@cod), '')

				declare @CuTranzactii int
				exec luare_date_par 'GE','TRANZACT', @CuTranzactii output, 0, ''--se citeste parametrul care spune daca se lucreaza cu tanzactii sau nu
				set @CuTranzactii=ISNULL(@CuTranzactii,0)
				if @CuTranzactii=1--daca se lucreaza cu tranzactii incepem o tranzactie pentru spargerea pe coduri de intrare
					Begin transaction SpargereCoduriIntrare
				while abs(@cantitate)>=0.00001
				begin
					-- initializez cod intrare din XML(daca exista in xml)
					select @codi_stoc = @cod_intrare, @stoc = @cantitate, @locatieStoc = null, @data_expirarii_stoc = null, @nr_poz_out=@numar_pozitie
				
					if @numar_pozitie=0 and @codi_stoc='' and @cantitate>=0.00001 and @tip_nom not in ('R', 'S', 'F')
					begin
						exec iauPozitieStoc 
							@Cod=@cod, @TipGestiune=null, @Gestiune=null, @Data=null, 
							@CodIntrare=@codi_stoc output, @PretStoc=null, @Stoc=@stoc output, @ContStoc=null, @DataExpirarii=@data_expirarii_stoc output, 
							@TVAneex=null, @PretAm=null, @Locatie=@locatieStoc output, @Serie=null, 
							@FltTipGest=@tip_gestiune_filtru_stoc, @FltGestiuni=@gestiune, @FltExcepGestiuni=null, @FltData=@data, 
							@FltCont=null, @FltExcepCont=null, 
							@FltDataExpirarii=@data_expirarii, -- daca se trimite ca parametru sa se filtreze dupa el 
							@FltLocatie = @locatie, /* initial se folosea @locatie si la citire din XML si la luare pozitie stoc(acum avem @locatieStoc). */
							@FltLM=null, @FltComanda=null, @FltCntr=null, @FltFurn=null, @FltLot=null, 
							@FltSerie=@serie, @OrdCont=null, @OrdGestLista=null
						
							set @codi_stoc=isnull(@codi_stoc, '')
					end
					else -- pentru iesiri cu cantitati negative, daca nu am gasit pozitie stoc, generam aici un cod de intrare...
					if isnull(@codi_stoc,'')='' and @cantitate < 0.00001
					begin
					--	if @tip='TE' -- la TE cu cantitati negative cautam pozitie de stoc in gestiunea primitoare
					--		exec iauPozitieStoc 
					--		@Cod=@cod, @TipGestiune=null, @Gestiune=null, @Data=null, 
					--		@CodIntrare=@codi_stoc output, @PretStoc=null, @Stoc=@stoc output, @ContStoc=null, @DataExpirarii=@data_expirarii_stoc output, 
					--		@TVAneex=null, @PretAm=null, @Locatie=@locatieStoc output, @Serie=null, 
					--		@FltTipGest=@tip_gestiune_filtru_stoc, @FltGestiuni=@gestiune_primitoare, @FltExcepGestiuni=null, @FltData=@data, 
					--		@FltCont=null, @FltExcepCont=null, 
					--		@FltDataExpirarii=@data_expirarii, -- daca se trimite ca parametru sa se filtreze dupa el 
					--		@FltLocatie = @locatie, /* initial se folosea @locatie si la citire din XML si la luare pozitie stoc(acum avem @locatieStoc). */
					--		@FltLM=null, @FltComanda=null, @FltCntr=null, @FltFurn=null, @FltLot=null, 
					--		@FltSerie=@serie, @OrdCont=null, @OrdGestLista=null
					
					--	if isnull(@codi_stoc,'')=''
						-- de analizat cum merge pe gestiuni tip 'A'
						select	@codi_stoc = isnull(dbo.cautareCodIntrare(@Cod, @gestiune, @tip+rtrim(@numar), null, null, null, null, 0, 0, '1901-01-01', '1901-01-01', '', '', '', '', '', ''),
														@tip+rtrim(@numar)),/*functia nu prea returneaza cod intrare valid; punem tip+numar...*/
								@stoc = @cantitate,
								@locatieStoc = @locatie,
								@data_expirarii_stoc = @data_expirarii
					end
				
					set @cant_desc=(case when abs(@cantitate)-abs(@stoc)>=0.00001 then @stoc else @cantitate end)
					set @cantitate=@cantitate-@cant_desc
					if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP1')
						exec wScriuPozdocSP1 @tip, @codi_stoc, @gestiune, @cod, @cont_corespondent  output
					
					if @tip in ('AP', 'AS', 'AC')
						begin
							-- daca suma TVA operata este semnificativ diferita de cea anterior calculata se forteaza recalcularea: 
							-- (@tvavaluta este folosit in macheta de Avize pentru a putea fi modificata Suma TVA)
							if @ptupdate=1 --and isnull(@tva_valuta,0)=0 and abs(isnull(@suma_tva,0)-isnull(@o_suma_TVA,0))>0.05 
								set @suma_tva=null 
							if @tip<>'AP'
							begin
								set @pret_amanunt=(case when @tip in ('AS','AC') and ISNULL(@pret_amanunt,0)>0 then @pret_amanunt else null end)
								set @pret_valuta=(case when @tip in ('AS','AC') and ISNULL(@pret_valuta,0)>0 then @pret_valuta else isnull(@pret_amanunt,0)/(1.00+@cota_TVA/100) end)
							end
							select @categ_pret=sold_ca_beneficiar
							from terti
							where @TabelaPreturi=1 and isnull(@categ_pret,0)=0 and @Tert<>'' and subunitate=@sub and tert=@Tert
							-- sa puna categoria de pret=1 daca era zero (oricum, asa e tratata):
							set @categ_pret=(case when isnull(@categ_pret,0)=0 then 1 else @categ_pret end)
							if @data_scadentei=@data_facturii
							  begin  
							   set @termenscadenta=coalesce(
								/* Aici se va citi din contract - campul detalii.xml*/
								nullif((select discount from infotert where subunitate=@sub and tert=@tert and Identificator=''),0),
								nullif((select val_numerica from par where tip_parametru='GE' and parametru='SCADENTA'),0),
								0)
							   set @data_scadentei=DATEADD(d,@termenscadenta,@data_facturii)  
							  end 
						  
							if @aviznefacturat=1 and @tip in ('AP','AS')--daca este pusa bifa pentru aviz nefacturat atunci contul de factura va fi luat din parametrii(cont beneficiar aviz nefacturat)
								set @cont_factura= @ContAvizNefacturat  
						end
				
					-------------start pt cod formare parametru xml pentru procedurile de scriere iesiri---------
					set @dataS=CONVERT(char(10),@data,101)
					set @data_facturiiS=CONVERT(char(10),@data_facturii,101)
					set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)
					set @data_expirariiS=
							case when @tip='DF' and @data_expirarii<>'1901-01-01' 
									then CONVERT(char(10),@data_expirarii,101)
								else CONVERT(char(10),isnull(@data_expirarii_stoc,@data_expirarii),101)	
							end
		
					set @parXmlScriereIesiri = '<row/>'
					set @parXmlScriereIesiri =CONVERT(xml, '<row>'+isnull(convert(varchar(max),@detalii),'') + '</row>')
					set @parXmlScriereIesiri.modify ('insert 
							(
							attribute tip {sql:variable("@tip")},
							attribute subtip {sql:variable("@subtip")},
							attribute numar {sql:variable("@numar")},
							attribute data {sql:variable("@dataS")},
							attribute tert {sql:variable("@tert")},
							attribute punct_livrare {sql:variable("@punct_livrare")},					
							attribute factura {sql:variable("@factura")},
							attribute data_facturii {sql:variable("@data_facturiiS")},
							attribute data_scadentei {sql:variable("@data_scadenteiS")},
							attribute cont_factura {sql:variable("@cont_factura")},
							attribute gestiune {sql:variable("@gestiune")},
							attribute cod {sql:variable("@cod")},
							attribute cod_intrare {sql:variable("@codi_stoc")},
							attribute codiPrim {sql:variable("@codiPrim")},
							attribute locatie {sql:variable("@locatieStoc")},
							attribute locatieprim {sql:variable("@locatie")},
							attribute cantitate {sql:variable("@cant_desc")},
							attribute valuta {sql:variable("@valuta")},
							attribute curs {sql:variable("@curs")},
							attribute pret_valuta {sql:variable("@pret_valuta")},
							attribute discount {sql:variable("@discount")},
							attribute pret_amanunt {sql:variable("@pret_amanunt")},
							attribute lm {sql:variable("@lm")},
							attribute comanda_bugetari {sql:variable("@comanda_bugetari")},
							attribute jurnal {sql:variable("@jurnal")} ,
							attribute contract {sql:variable("@contract")},
							attribute stare {sql:variable("@stare")},
							attribute barcod {sql:variable("@barcod")},
							attribute tipTVA {sql:variable("@tipTVA")},
							attribute data_expirarii {sql:variable("@data_expirariiS")},
							attribute utilizator {sql:variable("@userASiS")},
							attribute serie {sql:variable("@serie")},
							attribute cota_TVA {sql:variable("@cota_TVA")},
							attribute suma_tva {sql:variable("@suma_tva")},
							attribute numar_pozitie {sql:variable("@nr_poz_out")},
							attribute cont_corespondent {sql:variable("@cont_corespondent")},
							attribute cont_stoc {sql:variable("@cont_stoc")},
							attribute cont_venituri {sql:variable("@cont_venituri")},
							attribute cont_intermediar {sql:variable("@cont_intermediar")},
							attribute suprataxe {sql:variable("@suprataxe")},
							attribute update {sql:variable("@ptupdate")},
							attribute explicatii {sql:variable("@explicatii")},
							attribute gestiune_primitoare {sql:variable("@gestiune_primitoare")},
							attribute TVAnx {sql:variable("@TVAnx")},
							attribute text_alfa2 {sql:variable("@text_alfa2")},
							attribute categ_pret {sql:variable("@categ_pret")}
							)					
							into (/row)[1]')
						------------stop pt cod formare parametru xml pentru procedurile de scriere iesiri---------
					
						if @tip in ('AP', 'AS', 'AC')
							exec wScriuAviz @parXmlScriereIesiri=@parXmlScriereIesiri output
						
						if @tip='CM'
							exec wScriuCM @parXmlScriereIesiri=@parXmlScriereIesiri output
					
						if @tip='AE'
							exec wScriuAE @parXmlScriereIesiri=@parXmlScriereIesiri output
					
						if @tip='TE'
							exec wScriuTE @parXmlScriereIesiri=@parXmlScriereIesiri OUTPUT
							
						if @tip='DF'
							exec wScriuDF @parXmlScriereIesiri=@parXmlScriereIesiri output
						
						if @tip='PF'
							exec wScriuPF @parXmlScriereIesiri=@parXmlScriereIesiri output
					
						if @tip='CI'
							exec wScriuCI @parXmlScriereIesiri=@parXmlScriereIesiri output
						
						if @tip in ('AP', 'AS', 'AC', 'DF', 'CM', 'CI', 'AE') and @Bugetari=1  and isnull(@indbug,'')='' and 1=0 -- se putea face in SP2 sau ceva procedura pt. Bugetari; se poate folosi idPozdoc, in loc de numar_pozitie 
						-- scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
						-- vezi ca este la intrari ceva similar
						begin
							--formare indicator bugetar->atasat contului de venituri sau corespondent
							set @numar_pozitie=@parXmlScriereIesiri.value('(/row/@numar_pozitie)[1]', 'int')
							set @cont_venituri=@parXmlScriereIesiri.value('(/row/@cont_venituri)[1]', 'varchar(40)')
							set @cont_corespondent=@parXmlScriereIesiri.value('(/row/@cont_corespondent)[1]', 'varchar(40)')
							declare @contb varchar(40)
							select @contb=(case when @tip in ('AP', 'AS', 'AC', 'DF') then @cont_venituri else @cont_corespondent end)
							exec wFormezIndicatorBugetar @Cont=@contb,@Lm=@lm,@Indbug=@indbug output 
							set @comanda_bugetari=left(@comanda,20)+@indbug	
							
							--setare context info pentru completare indicator bugetar pe documente definitive
							set @binar=cast('specificebugetari' as varbinary(128))
							set CONTEXT_INFO @binar 		    
							--scriere indicator bugetar in pozdoc
							update pozdoc set comanda=@comanda_bugetari where subunitate=@sub and tip=@tip and data=@data and numar=@numar and numar_pozitie=@numar_pozitie 
							set CONTEXT_INFO 0x00
						end
					
						IF @returneaza_inserate = 1
							SET @docInserted = CONVERT(XML, convert(VARCHAR(max), @docInserted) + convert(VARCHAR(max), @parXmlScriereIesiri.query('/Inserate/row')))
					
						if @idPozContract>0 -- operatii de facut cand se scrie o pozitie din modulul contracte
						begin
							if @idJurnalContract=0 -- daca nu s-a trimis idJurnal, jurnalizam aici operatia.
							begin
								SELECT @docJurnalContracte = 
									(SELECT 
										idContract idContract,GETDATE() data, 'Generare '+@tip explicatii 
									from PozContracte where idPozContract=@idPozContract
									FOR XML raw )
								EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnalContracte OUTPUT
								SET @idJurnalContract = @docJurnalContracte.value('(/*/@idJurnal)[1]', 'int')
							end
						
							-- salvez legatura intre pozitia din pozdoc si pozitia din contract facturata
							INSERT INTO LegaturiContracte (idJurnal, idPozContract, IdPozDoc)
							SELECT 
								@idJurnalContract, 
								@idPozContract, 
								PD.r.value('(@idPozDoc)[1]', 'int') idPozDoc
							FROM @parXmlScriereIesiri.nodes('/Inserate/row') PD(r)
						end
					end--stop spargere pe coduri de intrare
			
				if @CuTranzactii=1--daca se lucreaza cu tranzactii inchidem tranzactia pentru spargerea pe coduri de intrare
					commit transaction SpargereCoduriIntrare
			
			end--stop scriere iesiri

			if not exists (select 1 from anexadoc where subunitate=@sub and tip=@tip and numar=@numar and data=@data and tip_anexa='')
				insert anexadoc
					(Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin, Eliberat, Mijloc_de_transport, Numarul_mijlocului,
						 Data_expedierii, Ora_expedierii, Observatii, Punct_livrare, Tip_anexa)
				values
					(@sub, @tip, @numar, @data, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, @nr_mijloc_transport, 
						@data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, '')

			fetch next from crspozdoc into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert, 
				@factura, @data_facturii, @data_scadentei, @lm, @lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,
				@zilescadenta,@facturanesosita,@aviznefacturat,
				@cod_intrare, @codiPrim, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc, 
				@valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount, 
				@punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx, 
				@accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, 
				@nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,@detalii,@detalii_antet,@numarpozitii,
				@idjurnalContract, @idPozContract, @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos
			set @fetch_crspozdoc=@@fetch_status	
		end

		/** Daca se doreste returnare idPozDoc-urilor inserate **/	
		if @returneaza_inserate='1' and @parXML is not null and @docInserted is not null
		begin
			/** Se pun toate randurile intr-o radacina (docInserate) care va fi inserata in @parXML. Functioneaza si pe SQL 2005 prin acesta abordare
				ParXML va avea forma urmatoare:
				<row ... >
					<row .../>
					<row .../>
					<docInserate>
						<row .../>
						<row .../>
					</docInserate>
				</row>
			*/
			set @docInserted= (select @docInserted for xml RAW('docInserate'))
			select @parXML= CONVERT(XML,CONVERT(varchar(max),@parXML)+CONVERT(varchar(max),@docInserted))
			set @parXML.modify('insert /*[2]  into /*[1]')
			set @parXML.modify('delete /*[2]')
		end

		/** Se scriu detaliile si IDul de plaja primit in tabela DOC prin update in acest moment **/
		if (@idPlajaPrimit IS NOT NULL or @detalii_antet IS NOT NULL)
		begin
			--> deoarece nivelurile inferioare sunt pierdute la trimiterea detaliilor antet din frame (cazul orto - sisteme) le salvez inainte:
			if @detalii_antet.exist('row/*')=0	--> daca exista nivele inferioare venite dinspre frame presupun ca e tratat corect si nu mai salvez cele din doc:
				and @detalii_antet is not null
			begin
				declare @nivxmlinferioare xml, @comandaSql nvarchar(4000)
				select @nivxmlinferioare=detalii.query('row/*')
				from doc d where Subunitate=@sub and numar=@numar and tip=@tip and Data=@data

				if len(convert(varchar(max), @nivxmlinferioare))>0
				begin
					-- compatibilitate 2005 -> sql dinamic. Eroarea apare la dezvoltari speicifce pe care nu le tratam in SQL2005, deci nu intra prin dynamic SQL.
					set @comandaSql='set @detalii_antet.modify(''insert sql:variable("@nivxmlinferioare") into (/row)[1]'')'
				
					exec sp_executesql @statement=@comandaSql, @params=N'@detalii_antet xml output, @nivxmlinferioare xml', 
						@detalii_antet = @detalii_antet output, @nivxmlinferioare=@nivxmlinferioare
				end
			end
			
			update doc set 
				detalii=(case when @detalii_antet IS NOT NULL then @detalii_antet end ),
				idplaja=(case when @idPlajaPrimit IS NOT NULL then @idPlajaPrimit end)
			where Subunitate=@sub and numar=@numar and tip=@tip and Data=@data
		end
	end try
	begin catch

		if @CuTranzactii=1--daca se lucreaza cu tranzactii si exista deschisa tranzactia de spargere coduri dam rollback
			and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'SpargereCoduriIntrare')
			ROLLBACK TRAN SpargereCoduriIntrare

		if @NumarDocPrimit is not null and not exists(select 1 from docfiscalerezervate where idPlaja=@idPlajaPrimit)
				and not exists (select 1 from doc where Subunitate=@sub and numar=@numar and tip=@tip and Data=@data) -- daca nu exista acest document 
			insert into docfiscalerezervate(idPlaja,numar,expirala) select @idPlajaPrimit,@NumarDocPrimit,getdate() where NULLIF(@idPlajaPrimit ,0) IS NOT NULL

		set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozdoc' and session_id=@@SPID )
		if @cursorStatus=1 
			close crspozdoc 
		if @cursorStatus is not null 
			deallocate crspozdoc 

		set @mesaj =ERROR_MESSAGE()+' (wScriuPozdoc)'
		raiserror(@mesaj,16,1)
	end catch

	begin try 
		set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozdoc' and session_id=@@SPID )
		if @cursorStatus=1 
			close crspozdoc 
		if @cursorStatus is not null 
			deallocate crspozdoc 
	end try 
	begin catch end catch

	begin try 
		exec sp_xml_removedocument @iDoc 
	end try 
	begin catch end catch
end
/*Gata Vechiul wScriuPozDoc de baza*/

/** 
	Procedura de mai jos este apelata pentru Receptii de mijloace fixe (subtip=MF), Modificari de valoare mijloace fixe prin achizitii de la furnizori (subtip=MM), 
	Transfer spre gestiune de tip I si Transfer retur dintr-o gestiune de tip I (subtip=TR) a unui obiect de inventar 
**/
if (@tip_doc='RM' and @subtip in ('MF','MM') or @tip='TE' and (isnull((select tip_gestiune from gestiuni where Subunitate=@sub and Cod_gestiune=@gestiune_primitoare),'')='I'
		or @subtip='TR' and isnull((select tip_gestiune from gestiuni where Subunitate=@sub and Cod_gestiune=@gestiune),'')='I')) 
	and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuMFdinCG')
begin
	declare @numarDocMF varchar(20)
	/*	Completare numar doc. in parXML-ul (initial) ce se trimite la wScriuMFdinCG. */
	select @numarDocMF=ISNULL(nullif(@parXML.value('(/row/@numar)[1]', 'varchar(20)'),''),@numar), 
		@returneaza_inserate=ISNULL(@parXML.value('(/row/@returneaza_inserate)[1]', 'bit'), 0)
	if @parXMLprimit.value('(/row/@numar)[1]', 'varchar(20)')=''
		set @parXMLprimit.modify('replace value of (/row/@numar)[1] with sql:variable("@numarDocMF")') 
	if @parXMLprimit.value('(/row/@numar)[1]', 'varchar(20)') is null
		set @parXMLprimit.modify ('insert (attribute numar {sql:variable("@numarDocMF")}) into (/row)[1]')
	set @parXML=@parXMLprimit

	exec wScriuMFdinCG @sesiune, @parXML 
end

/* Pentru bugetari se apeleaza procedura ce scrie in pozdoc.detalii, a indicatorului bugetar stabilit in mod unitar prin procedura indbugPozitieDocument. */
if @bugetari=1 and @ptupdate=0 and exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocument')
	and not exists (select * from sysobjects where name ='wScriuDoc') 
begin
	declare @parXMLIndbug xml
	IF OBJECT_ID('tempdb..#indbugPozitieDoc') is not null drop table #indbugPozitieDoc
	create table #indbugPozitieDoc (furn_benef char(1), tabela varchar(20), idPozitieDoc int, indbug varchar(20))
	insert into #indbugPozitieDoc (furn_benef, tabela, idPozitieDoc)
	select '', 'pozdoc', isnull(@parXmlScriereIntrari.value('(/Inserate/row/@idPozDoc)[1]', 'int'),isnull(@parXmlScriereIesiri.value('(/Inserate/row/@idPozDoc)[1]', 'int'),
		@parXml.value('(/row/docInserate/row/@idPozDoc)[1]', 'int')))

	set @parXMLIndbug=(select 1 as scriere for xml raw)
	exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXMLIndbug
end

-- procedura specifica apelata dupa scrierea documentului
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP2')
	exec wScriuPozdocSP2 @sesiune, @sub, @tipGrp, @numarGrp, @dataGrp, @parXML

DECLARE @dateInitializare XML	
--daca se adauga o pozitie pe un RM care are dvi, deschidem macheta pentru DVI pentru refacere repartizare taxe vamale
if @tip_doc='RM' and exists(select 1 from pozdoc where Subunitate=@sub and tip='RM' and Numar=@numar and data=@data and isnull(Numar_DVI,'')<>'')
begin
	set @dateInitializare=
	(
		select convert(char(10), @data, 101) as data, @numar as numar, /*@tert as tert,*/ @tip as tip
		for xml raw ,root('row')
	)
	SELECT 'Pe aceasta receptie au fost introduse taxe vamale, este necesara actualizarea lor la fiecare modificare a receptiei.'  nume, 'DO' codmeniu, 'D' tipmacheta, @tip tip,'DV' subtip,'O' fel, convert(char(10), @data, 101) as data, @numar as numar, --@tert as tert,
	(SELECT @dateInitializare ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
end
	
-->in cazul in care se exista pozitii de prestari pe receptie, se apeleaza procedura de repartizare prestari pe pozitiile receptiei
if @tip_doc='RM' and exists (select 1 from pozdoc where tip in ('RP','RZ') and Subunitate=@sub and Numar=@numar and data=@data)
	exec repartizarePrestariReceptii 'RM', @numar, @data	

if @fara_luare_date<>'1'
begin
	declare @tipptIa varchar(2),@numarptIa varchar(20),@dataPtIa datetime
	select @tipptIa=@tip,--@parXML.value('(/row/@tip)[1]', 'varchar(2)')),
		@numarptIa=ISNULL(nullif(@parXML.value('(/row/@numar)[1]', 'varchar(20)'),''),@numar),
		@dataPtIa=@parXML.value('(/row/@data)[1]', 'datetime')
	SET @docXMLIaPozdoc = (select rtrim(@sub) subunitate, rtrim(@tipptIa) tip, rtrim(@numarptIa) numar, convert(char(10), @dataPtIa, 101) data, @searchText _cautare for xml raw)
	exec wIaPozdoc @sesiune=@sesiune, @parXML=@docXMLIaPozdoc 
	
	if @rec_factura_existenta is not null
		select 'Acest numar de factura exista pe receptia '+RTRIM(ISNULL(@rec_factura_existenta,''))+' din '+ISNULL(CONVERT(char(10),@data_rec_fact_exist,103),'')+'!' as textMesaj for xml raw, root('Mesaje')

	if @tip_doc='RM' and @lDeschidereMachetaPreturi=1 and @apelDinProcedura=0
	begin
		declare @ptIdPozdoc int
		if @ptupdate=1
			set @ptIdPozdoc=@parXML.value('(/row/row/@idpozdoc)[1]', 'int')
		else
			set @ptIdPozdoc=isnull(@parXmlScriereIntrari.value('(/Inserate/row/@idPozDoc)[1]', 'int'),@parXml.value('(/row/docInserate/row/@idPozDoc)[1]', 'int'))

		--DECLARE @dateInitializare XML
		SET @dateInitializare='<row><row idpozdoc="'+ltrim(str(@ptidpozdoc))+'" /></row>'

		SELECT 'Modificare pret' nume, 'DO' codmeniu, 'D' tipmacheta, @tip tip,'MP' subtip,'O' fel,
			(SELECT @dateInitializare ) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')	
	end
end
end try
begin catch 
	set @mesaj=ERROR_MESSAGE()+' (wScriuPozdoc)'
	raiserror(@mesaj, 11, 1) 
end catch