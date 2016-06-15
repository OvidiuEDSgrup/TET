--***
create procedure [dbo].[wScriuPozdocSP] @sesiune varchar(50), @parXML xml output
as

declare @tip char(2), @numar char(8), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @data_facturii datetime, @data_scadentei datetime, @lm char(9),  @lmprim char(9), 
	@numar_pozitie int, @cod char(20), @codcodi char(20), @cantitate float, @pret_valuta float, @cod_intrare char(13), @codiPrim varchar(13),
	@pret_amanunt float, @cota_TVA float, @suma_tva float, @tva_valuta float, @tipTVA int, @comanda char(20), @cont_stoc char(13), @pret_stoc float, 
	@valuta char(3), @curs float, @locatie char(30), @locatieStoc char(30), @contract char(20), @lot char(13), @data_expirarii datetime, @data_expirarii_stoc datetime, 
	@explicatii char(30), @jurnal char(3), @cont_factura char(13), @discount float, @punct_livrare char(5), 
	@barcod char(30), @cont_corespondent char(13), @DVI char(25), @categ_pret int, @cont_intermediar char(13), @cont_venituri char(13), @TVAnx float, 
	@nume_delegat char(30), @serie_buletin char(10), @numar_buletin char(10), @eliberat_buletin char(30), @mijloc_transport char(30), @nr_mijloc_transport char(20), @data_expedierii datetime, @ora_expedierii char(6), @observatii char(200), @punct_livrare_expeditie char(5), 
	@IesFaraStoc int, @tipGrp char(2), @numarGrp char(8), @dataGrp datetime, @sir_numere_pozitii varchar(max), @sub char(9), @docXMLIaPozdoc xml, 
	@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3), 
	@stare int, @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @codi_stoc char(13), @stoc float, @cant_desc float, @nr_poz_out int, 
	@eroare xml, @mesaj varchar(254), @Bugetari int, @TabelaPreturi int, @indbug varchar(20), @comanda_bugetari varchar(40), @accizecump float, @ptupdate int, 
	@NrAvizeUnitar int ,@prop1 varchar(20),@prop2 varchar(20),@serie varchar(20),@subtip varchar(2),@termenscadenta int,@Serii int,
	@zilescadenta int,@facturanesosita bit,@aviznefacturat bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(20),@suprataxe float,@o_suma_TVA float, 
	@rec_factura_existenta char(8), @data_rec_fact_exist datetime, @fetch_crspozdoc int, @TEACCODI int,@text_alfa2 varchar(30),-->campul alfa 2 din text_pozdoc
	@o_pret_amanunt float,@o_pret_valuta float,@adaos decimal(12,2),@numarpozitii int, @detalii xml,@binar varbinary(128),
	@docInserted xml, @returneaza_inserate bit, @fara_luare_date varchar(1),@NumarDocPrimit int,@idPlajaPrimit int,@lDeschidereMachetaPreturi int,
	@idJurnalContract int, @idPozContract int, @docJurnalContracte xml, @apelDinProcedura int
	
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
exec luare_date_par 'GE','PRETURI', @TabelaPreturi output, 0, ''
exec luare_date_par 'GE', 'SERII', @Serii output, 0, '' -- lucreaza cu serii
exec luare_date_par 'UC', 'TEACCODI', @TEACCODI output, 0, '' -- TE cu acelasi cod intrare la primitor 
exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output
exec luare_date_par 'GE', 'DMPRET', @lDeschidereMachetaPreturi  output, 0, ''

begin try

	set @docInserted=''
	set @fara_luare_date=ISNULL(@parXML.value('(/row/@fara_luare_date)[1]', 'char(1)'), '0')
	set @returneaza_inserate=ISNULL(@parXML.value('(/row/@returneaza_inserate)[1]', 'bit'), 0)

	--BEGIN TRAN
	
	-- aceasta apelare se va modifica - se vor folsi proceduri de validare, care vor da direct raiserror. 
	--set @eroare = dbo.wfValidarePozdoc(@parXML)
	--if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
	--	begin
	--	set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
	--	raiserror(@mesaj, 11, 1)
	--	end
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	select @gestProprietate='', @clientProprietate='', @lmProprietate='', @jurnalProprietate=''
	select @gestProprietate=(case when cod_proprietate='GESTIUNE' then valoare else @gestProprietate end), 
		@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else @clientProprietate end), 
		@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else @lmProprietate end), 
		@jurnalProprietate=(case when Cod_proprietate='JURNAL' then Valoare else @jurnalProprietate end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA', 'JURNAL') and valoare<>''
	
	if ISNULL(@stare,'')=''
		set @stare=3
		
	exec luare_date_par 'GE', 'FARASTOC', @IesFaraStoc output, 0, ''

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozdocSP cursor for
	select tip, upper(numar), data, 
	upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else @gestProprietate end)) as gestiune, 
	(case when isnull(gestiune_primitoare_pozitii, '')<>'' then gestiune_primitoare_pozitii else isnull(gestiune_primitoare_antet, '') end) as gestiune_primitoare, 
	upper((case when isnull(tert, '')<>'' then tert when tip in ('AP', 'AS') then @clientProprietate else '' end)) as tert, 
	upper(isnull(factura_pozitii, isnull(factura_antet, ''))) as factura, 
	isnull(datafact, isnull(data, '01/01/1901')) as datafact, isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))) as datascad, 
	(case when isnull(lm_pozitii, '')<>'' then lm_pozitii when isnull(lm_antet, '')<>'' then lm_antet else @lmProprietate end) as lm, 
	isnull(lmprim_antet, '') as lmprim, 
	isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod,
	upper(isnull(codcodi,isnull(cod,''))) as codcodi,
	isnull(cantitate, 0) as cantitate, pret_valuta, isnull(tip_TVA,0) as tipTVA, 
	
	zilescadenta as zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta
	isnull(facturanesosita,0),--bifa de factura nesosita
	isnull(aviznefacturat,0),--bifa de aviz nefacturat
	
	upper(isnull(cod_intrare, '')) as cod_intrare, upper(isnull(codiPrim, '')) as codiPrim,isnull(pret_amanunt, 0) as pret_amanunt, cota_TVA, suma_TVA, TVA_valuta, 
	upper(case when isnull(comanda_pozitii, '')<>'' then comanda_pozitii else isnull(comanda_antet, '') end) as comanda, 
	(case when isnull(indbug_pozitii, '')<>'' then indbug_pozitii else isnull(indbug_antet, '') end) as indbug, 
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
	isnull(dvi, '') as dvi, isnull(categ_pozitii, isnull(categ_antet, 0)) as categ_pret, 
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
		detalii xml 'detalii',
		tip char(2) '../@tip', 
		numar char(8) '../@numar',
		data datetime '../@data',
		gestiune_antet char(9) '../@gestiune',
		gestiune_primitoare_antet char(13) '../@gestprim', 
		tert char(13) '../@tert',
		factura_antet char(20) '../@factura',
		datafact datetime '../@datafacturii',
		datascad datetime '../@datascadentei',
		lm_antet char(9) '../@lm',
		lmprim_antet char(9) '../@lmprim',
		comanda_antet char(20) '../@comanda', 
		indbug_antet char(20) '../@indbug', 
		cont_factura_antet char(13) '../@contfactura', 
		cont_corespondent_antet char(13) '../@contcorespondent', 
		cont_venituri_antet char(13) '../@contvenituri', 
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
		tip_TVA int '../@tiptva',
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
		codcodi char(33) '@codcodi',
		factura_pozitii char(20) '@factura',
		cantitate decimal(17, 5) '@cantitate',
		pret_valuta decimal(14, 5) '@pvaluta', 
		pret_amanunt decimal(14, 5) '@pamanunt', 
		cod_intrare char(13) '@codintrare',	
		codiPrim char(13) '@codiPrim',		
		cota_TVA decimal(5, 2) '@cotatva', 
		suma_TVA decimal(15, 2) '@sumatva', 
		TVA_valuta decimal(15, 2) '@tvavaluta', 
		gestiune_pozitii char(9) '@gestiune', 
		gestiune_primitoare_pozitii char(13) '@gestprim', 
		lm_pozitii char(9) '@lm', 
		comanda_pozitii char(20) '@comanda', 
		indbug_pozitii char(20) '@indbug', 
		cont_de_stoc char(13) '@contstoc', 
		pret_de_stoc float '@pstoc', 
		valuta char(3) '@valuta', 
		curs float '@curs', 
		locatie char(30) '@locatie', 
		contract_pozitii char(20) '@contract', 
		lot char(13) '@lot', 
		data_expirarii datetime '@dataexpirarii', 
		explicatii_pozitii char(30) '@explicatii', 
		jurnal char(3) '@jurnal', 
		cont_factura_pozitii char(13) '@contfactura', 
		discount float '@discount', 
		punct_livrare_pozitii char(5) '@punctlivrare', 
		barcod char(30) '@barcod', 
		cont_corespondent_pozitii char(13) '@contcorespondent', 
		DVI char(25) '@dvi',
		categ_pozitii int '@categpret', 
		cont_intermediar char(13) '@contintermediar', 
		cont_venituri_pozitii char(13) '@contvenituri',
		tva_neexigibil_pozitii float '@tvaneexigibil',
		accizecump float '@accizecump', 
		ptupdate int '@update' ,
		adaos decimal(12,2) '@adaos',
		
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

	open crspozdocSP
	fetch next from crspozdocSP into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert, 
		@factura, @data_facturii, @data_scadentei, @lm,@lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,
		@zilescadenta,@facturanesosita,@aviznefacturat,
		@cod_intrare, @codiPrim, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc, 
		@valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount, 
		@punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx, 
		@accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, 
		@nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,@detalii,@numarpozitii,
		@idjurnalContract, @idPozContract, @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos
	set @fetch_crspozdoc=@@fetch_status
	
--/*sp
	declare @procid int=@@procid, @objname sysname
		, @gestimplicita varchar(10)
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
	
	select top 1 @gestimplicita=p.Valoare from proprietati p 
	where p.Valoare<>'' and p.Cod=@userASiS and p.Tip='UTILIZATOR' 
			and p.Cod_proprietate='GESTIUNEIMPLICITA' and p.Valoare_tupla='' 
	order by p.Valoare 
	
--sp*/
	while @fetch_crspozdoc= 0
	begin
--/*startsp
		declare @nrliniexml int
		set @nrliniexml=isnull(@nrliniexml,0)+1
		SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
		
		if @cantitate-FLOOR(@cantitate) > convert(float,0) 
			and (select tip from nomencl where cod = @cod) not in ('S', 'R', 'F') and @apelDinProcedura = 0 --and @ptupdate <> 1
			and @tip in ('CM', 'TE', 'AP', 'AS', 'AC', 'AE', 'DF', 'PF', 'CI') and @cod_intrare = ''
			raiserror('Nu se pot opera documente de iesire din stoc ce au cantitati cu fractiuni dintr-un intreg (zecimale)! Va rugam sa corectati cantitatea!',11,1)
		
		if @cantitate<convert(float,0) 
			and (select tip from nomencl where cod = @cod) not in ('S', 'R', 'F') 
			and @tip in ('CM', 'TE', 'AP', 'AS', 'AC', 'AE', 'DF', 'PF', 'CI') 
			and OBJECT_ID('tempdb..#yso_wOPStornareDocument') is null
			raiserror('Nu se pot opera documente de retur fara a specifica documentul initial! Va rugam sa folositi operatia de stornare de pe documentul initial!',11,1)
--stopsp*/			
		if year(@data_facturii)<1921
			set @data_facturii=@data --convert(char(10),GETDATE(),101)
		if YEAR(@data_scadentei)<1921
			set @data_scadentei=@data_facturii
		if @lm=''
			set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')
		
		declare @lmimplicit varchar(10)
		select top 1 @lmimplicit=loc_de_munca from gestcor g 
			inner join proprietati p on p.Valoare=g.Gestiune and p.Cod=@userASiS and p.Tip='UTILIZATOR' 
				and p.Cod_proprietate='GESTIUNE' and p.Valoare_tupla='' 
		where gestiune in (@gestiune,@gestiune_primitoare) and g.Loc_de_munca<>''
		order by case g.Gestiune when @gestiune then 1 else 2 end
		
		if @tip='TE' and @lm<>ISNULL(@lmimplicit,'') and ISNULL(@lmimplicit,'')<>'' and ISNULL(@lm,'')=''
			if @parXML.value('(/row/row/@lm)[1]','varchar(9)') is null
				set @parXML.modify ('insert attribute lm {sql:variable("@lmimplicit")} into (/row/row)[1]')
			else
				if @parXML.value('(/row/row/@lm)[1]','varchar(9)')<>@lmimplicit
					set @parXML.modify('replace value of (/row/row/@lm)[1] with sql:variable("@lmimplicit")')			    
					
		if @tip='AS' and isnull(@gestiune,'')<>ISNULL(@gestimplicita,'') and ISNULL(@gestimplicita,'')<>'' 
			if @parXML.value('(/row/row/@gestiune)[1]','varchar(9)') is null
				set @parXML.modify ('insert attribute gestiune {sql:variable("@gestimplicita")} into (/row/row)[1]')
			else
				if @parXML.value('(/row/row/@gestiune)[1]','varchar(9)')<>@gestimplicita
					set @parXML.modify('replace value of (/row/row/@gestimplicita)[1] with sql:variable("@gestimplicita")')			    
					
		--daca pe macheta exista campul zilescadenta atunci datascadentei se calculeaza din zilele scadenta, altfel sa ia campul data scadentei
		if @zilescadenta is not null 
			set @data_scadentei=DATEADD(day,@zilescadenta,@data)
		
		if CHARINDEX('|',@codcodi,1)>0 and @codcodi<>@cod
		begin
		set @cod=isnull((select substring(@codcodi,1,CHARINDEX('|',@codcodi,1)-1)),@cod)
		set @cod_intrare=isnull((select substring(@codcodi,CHARINDEX('|',@codcodi,1)+1,LEN(@codcodi))),@cod_intrare)
		end
		
		if isnull(@numar, '')='' and (@aviznefacturat=1 OR @cont_factura like rtrim(@ContAvizNefacturat)+'%')
		begin
			declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)
			set @tipPentruNr=@tip 
			if @NrAvizeUnitar=1 and @tip='AS' 
				set @tipPentruNr='AP'
			set @tipPentruNr='AN' 
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
			
			exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output
			
			if @NrDocPrimit is null
				raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
			set @numar=@NrDocPrimit
			
			if @parXML.value('(/row/@numar)[1]','varchar(20)') is null
				set @parxml.modify ('insert attribute numar {sql:variable("@numar")} into (/row)[1]')
			else
				set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")')
		end

		--Aici va trebui regandit un pic conceptul de calcul automat al TVA-ului
		if @cota_tva is null and  /* (Andrei ...asa a trebuit la arges,am vb cu d-ul Ghita)isnull(@cota_tva,0)=0 and*/ @tip in ('AP', 'AS', 'AC')
			set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)
		
		if @cota_tva is null and @tip in ('RM','RC','RS') --ar trebui pusa in general indiferent de tip
			set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)
		
		if @cota_TVA is null
			set @cota_TVA=0
		-- gata calcul automat al TVA-ului		
--/*sp
		if @tip='AP' and ISNULL(@zilescadenta,0)=0 
		begin
			select @zilescadenta=c.scadenta from con c where c.Subunitate=@sub and c.tip='BK' and c.contract=@contract 
				and (c.tert='' or c.tert=@tert )--and c.data=@data
			if ISNULL(@zilescadenta,0)=0
				select @zilescadenta=convert(int, isnull(it.discount, 0)) 
				from terti t inner join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator='' 
				where t.Subunitate=@sub and t.tert=@tert 
			set @zilescadenta=ISNULL(@zilescadenta,0)
			if @parXML.value('(/row/@zilescadenta)[1]','int') is null
				set @parxml.modify ('insert attribute zilescadenta {sql:variable("@zilescadenta")} into (/row)[1]')
			else
				set @parXML.modify('replace value of (/row/@zilescadenta)[1] with sql:variable("@zilescadenta")')
		end	
		
		declare @contrimpl varchar(20)
		
		if isnull(@contrimpl,'')='' and isnull(@contract, '')=''
			select top 1 @contrimpl=c.Contract from con c 
			where c.Subunitate=@sub and c.Tert=@tert and c.Tip='BF'
			order by c.Data desc, c.Contract desc
		
		declare @discmax float=0, @grupa varchar(13)
			
		select @grupa=n.grupa, @tip_nom=n.Tip from nomencl n where n.Cod=@cod
		
		if @tip in ('AP','AC','AS') and @contract='' and ISNULL(@contrimpl,'')<>'' 
		begin
			if @parXML.value('(/row/@contract)[1]','varchar(20)') is null
				set @parXML.modify ('insert attribute contract {sql:variable("@contrimpl")} into (/row)[1]')
			else--if @parXML.value('(/row/@lm)[1]','varchar(20)')<>@contrimpl
				set @parXML.modify('replace value of (/row/@contract)[1] with sql:variable("@contrimpl")')	
			set @contract=@contrimpl
			
			select top 1 @discmax=p.Discount
				--(case 
				--when isnull(@discount,0)>0 and isnull(p.Discount,0)>0 then dbo.valoare_minima(@discount,p.Discount,@discount)
				--else ISNULL(@discount,0)+ISNULL(p.Discount,0) end)
			from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=@contract
				AND p.Tert= @tert and p.Mod_de_plata='G' and @grupa like RTRIM(p.Cod)+'%' 
			order by p.Cod desc, p.Discount desc
			
			if isnull(@discount,0)=0
				set @discount=@discmax
		end
		
		if @tip='AP' and @subtip='AV' and isnull(@pret_valuta,0)<>0 and @cod not in ('AVANS','DISC AVANS','STORNO AVANS') 
			raiserror('Nu se poate opera pretul decat pe un cod de articol tip Avans ! ',11,1)
		
		if @tip in ('AP','AC') and @cantitate<0
		begin
			declare @ErrorMessage nvarchar(max)
			
			--if OBJECT_ID('tempdb..#gesttransfer') is null
			--begin
			--	create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
			--	exec creeazaGestiuniTransfer
			--end

			set @ErrorMessage=null
			select @ErrorMessage=isnull(@ErrorMessage,'Urmatoarele produse nu pot fi stornate pt. ca nu au fost vandute printr-un document din gestiunea si clientul completate:')
				+CHAR(13)+RTRIM(n.Denumire)+' ('+RTRIM(n.cod)+')'
			from nomencl n 
			outer apply (select top (1) * from pozdoc t where t.Subunitate=@sub and t.Cod=n.Cod and t.Tert=@tert --and t.Pret_de_stoc<t.Pret_vanzare
					and t.gestiune=@gestiune and t.Tip in ('AP','AC') and t.Cantitate>0 and t.Data<=@data order by t.Data desc) s 
			where n.Cod=@cod and n.Tip not in ('R','S')
				and @cantitate<0 and s.Cod is null
				
			if @ErrorMessage is not null
				raiserror(@errormessage,11,1)
		end
		
		if @tip='TE' and ISNULL(@comanda,'')<>''
			if not exists (select 1 from comenzi c where c.Comanda=@comanda)
				insert comenzi (Subunitate,Tip_comanda,Comanda,Descriere,Beneficiar,Art_calc_benef,Comanda_beneficiar,Loc_de_munca_beneficiar
					,Data_inchiderii,Data_lansarii,Grup_de_comenzi,Loc_de_munca,Starea_comenzii,Numar_de_inventar,detalii)
				select top 1 t.Subunitate,'P',t.Tert,t.Denumire,t.Tert,'','',''
					,GETDATE(),GETDATE(),0,@lm,'L','',null from terti t where t.Tert=@comanda
--sp*/	
		if @tip in ('AP', 'AS', 'AC') and (@pret_valuta is null or @pret_valuta=0) -- or @discount is null)
		begin
			--set @categ_pret=(case when isnull(@categ_pret,0)=0 then 1 else @categ_pret end)
			declare @dXML xml, @doc_in_valuta int
			set @dXML = '<row/>'
			set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
			--set @dXML.modify ('insert attribute data {sql:variable("@data")} into (/row)[1]')
			declare @dstr char(10)
			set @dstr=convert(char(10),@data,101)			
			set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')
			set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
			set @dXML.modify ('insert attribute comandalivrare {sql:variable("@contract")} into (/row)[1]')
			set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')
			set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)
			set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')
			if @pret_valuta=0 set @pret_valuta=null
			exec wIaPretDiscount @dXML, @pret_valuta output, null--, @discount output
			
			--declare @discsuma float
			--set @discsuma=@parXML.value('(/row/row/@discsuma)[sql:variable("@nrliniexml")][1]','float')
			
			select @pret_valuta=isnull(@pret_valuta, 0), @discount=isnull(@discount, 0)--, @discsuma=ISNULL(@discsuma,0)
		
			if @tip='AP' and @pret_valuta>=0.001 and @discount=0
			begin
				declare @disc_dec decimal(5,2), @pret_valuta_dec decimal(17,5)
				set @disc_dec=isnull(@parXML.value('(/row/@discount)[1]','float'),0)
				--set @pret_valuta=@pret_valuta-@discsuma
				--set @parXML.modify('replace value of (/row/row/@pvaluta)[1] with sql:variable("@pret_valuta")')
				--if @discsuma>0 and @discsuma<@pret_valuta 
				--	set @discount=100*(1-(@pret_valuta-@discsuma)/@pret_valuta)
									
				select @pret_valuta_dec=@pret_valuta, @disc_dec= case @discount when 0 then @disc_dec else @disc_dec end
				if @parXML.value('(/row/row/@discount)[sql:variable("@nrliniexml")][1]','float') is null
					set @parxml.modify ('insert attribute discount {sql:variable("@disc_dec")} into (/row/row)[sql:variable("@nrliniexml")][1]')
				else
					set @parXML.modify('replace value of (/row/row/@discount)[sql:variable("@nrliniexml")][1] with sql:variable("@disc_dec")')
					
				if @parXML.value('(/row/row/@pvaluta)[sql:variable("@nrliniexml")][1]','float') is null
					set @parxml.modify ('insert attribute pvaluta {sql:variable("@pret_valuta_dec")} into (/row/row)[sql:variable("@nrliniexml")][1]')
				else
					set @parXML.modify('replace value of (/row/row/@pvaluta)[sql:variable("@nrliniexml")][1] with sql:variable("@pret_valuta_dec")')
			end
		end
	
		if @tip in ('TE') and (abs(@pret_amanunt)<0.00001 or isnull(@discount,0)>0)
		begin  
			select @discount=isnull(@discount,0)
			if abs(@pret_amanunt)<0.00001  
			begin
				declare @categPretProprietate int
				set @categPretProprietate=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestiune), @categ_pret)  
				set @pret_amanunt=isnull((select top 1 pret_cu_amanuntul from preturi where cod_produs=@cod and um=@categPretProprietate order by data_inferioara desc), 0)  
			end
			declare @pret_amanunt_disc decimal(17,5)
			set @pret_amanunt_disc=@pret_amanunt*(1-@discount/100)
			if @parXML.value('(/row/row/@pamanunt)[sql:variable("@nrliniexml")][1]','float') is null
				set @parxml.modify ('insert attribute pamanunt {sql:variable("@pret_amanunt_disc")} into (/row/row)[sql:variable("@nrliniexml")][1]')
			else
				set @parXML.modify('replace value of (/row/row/@pamanunt)[sql:variable("@nrliniexml")][1] with sql:variable("@pret_amanunt_disc")')
		end
		
		
		if @tip in ('TE','AP','AC','AS') and @discount>0
		begin
			declare @grupadiscmax varchar(13), @errdiscmax varchar(max)			
			if ISNULL(@discmax,0)=0
				select top 1 @discmax=CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) 
					else null end, @grupadiscmax=rtrim(pr.Cod) from proprietati pr 
				where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' 
					and @grupa like RTRIM(pr.Cod)+'%'
				order by pr.cod desc, pr.Valoare desc
				
			set @errdiscmax='Discountul introdus depaseste maximul de '+RTRIM(CONVERT(decimal(10,3),@discmax))
				+' admis pe grupa '+rtrim(@grupa)
			
			if @grupa=''
				select 'Atentie: nu este completata grupa pt acest articol. '
				+'Completati grupa pentru a valida discountul (wScriuPozDocSP).' as textMesaj
				, 'Functionare nerecomandata' as titluMesaj
				for xml raw,root('Mesaje')
			else
			begin
				if @discmax is null
					select 'Atentie: nu este configurat discountul maxim pe grupa acestui articol. '
					+'Configurati proprietatea DISCMAX pe grupa pentru a valida discountul (wScriuPozDocSP).' as textMesaj
					, 'Functionare nerecomandata' as titluMesaj
					for xml raw,root('Mesaje')
				else
					if @discount>@discmax
						raiserror(@errdiscmax,11,1)
			end
		end
     
		if @tip in (/*'CM',*/ 'AP'/*, 'AS', 'AE'*/, 'AC', 'TE'/*, 'DF', 'PF', 'CI'*/) 
		begin
		
			set @tip_gestiune_filtru_stoc = (case when @tip in ('PF', 'CI') then 'F' else '' end)
			set @tip_nom=isnull((select tip from nomencl where cod=@cod), '')

			--declare @CuTranzactii int
			--exec luare_date_par 'GE','TRANZACT', @CuTranzactii output, 0, ''--se citeste parametrul care spune daca se lucreaza cu tanzactii sau nu
			--set @CuTranzactii=ISNULL(@CuTranzactii,0)
			--if @CuTranzactii=1--daca se lucreaza cu tranzactii incepem o tranzactie pentru spargerea pe coduri de intrare
			--	Begin transaction SpargereCoduriIntrare
			
			if abs(@cantitate)>=0.00001
			begin
				if isnull(@codiPrim,'')='' and isnull(@parXML.value('(/row/row/@codiprimitor)[sql:variable("@nrliniexml")][1]','varchar(13)'),'')<>''
				begin
					set @codiPrim=isnull(@parXML.value('(/row/row/@codiprimitor)[sql:variable("@nrliniexml")][1]','varchar(13)'),'')
					if @parXML.value('(/row/row/@codiPrim)[sql:variable("@nrliniexml")][1]','varchar(13)') is null
						set @parxml.modify ('insert attribute codiPrim {sql:variable("@codiPrim")} into (/row/row)[sql:variable("@nrliniexml")][1]')
					else
						set @parXML.modify('replace value of (/row/row/@codiPrim)[sql:variable("@nrliniexml")][1] with sql:variable("@codiPrim")')
				end
--/*startsp		
				declare @msgErr varchar(2048),@lRezStocBK bit, @cListaGestRezStocBK CHAR(200), @stocgest float=0
					, @dencod varchar(200),@cant float=0, @tipcod varchar(1)
				
				if OBJECT_ID('tempdb..#pozdocstoc') is null 
						select 	cod=@cod, cant=@cantitate into #pozdocstoc
				else
				begin 
					update #pozdocstoc set @cant=isnull(cant,0), cant=@cant+@cantitate where cod=@cod
					if @@ROWCOUNT<=0
						insert #pozdocstoc values (@cod,@cantitate)
				end
				set @cant=isnull(@cant,0)+@cantitate 
				
				EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

				select @stocgest=SUM(s.stoc)--, @dencod=max(n.Denumire), @tipcod=max(n.Tip)
				FROM stocuri s 
					right join nomencl n on n.Cod=s.Cod
				WHERE n.Cod=@cod and (s.Stoc is null or s.Subunitate=@Sub AND s.Tip_gestiune NOT IN ('F','T') 
					and s.Cod_gestiune=@gestiune AND s.Stoc>=0.001 AND (isnull(@contract,'')=''
						or @lRezStocBK=0 
						or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')=0
						or s.contract=@contract))
				--GROUP BY n.Cod
				--having isnull(SUM(s.Stoc),0)<MAX(p.Cant_aprobata-p.Cant_realizata)

				if isnull(@stocgest,0)+(case @ptupdate when 1 then ISNULL(@cantitate,0) else 0 end)<@cant 
				begin
					select @msgErr='Stoc insuficient la articolul: '+
						+RTRIM(n.Denumire)+' ('+RTRIM(@cod)+')'
						+', lipsa: '+ rtrim(CONVERT(decimal(10,2),@cant-isnull(@stocgest,0)))
						,@tipcod=n.Tip
					from nomencl n where n.Cod=@cod
					
					if @tipcod<>'S'
						raiserror(@msgErr,16,1)
				end

				declare @valFactura float, @soldmaxim float, @sold float, @zileScadDepasite bit, @pret_vanzare float
				
				if @tip='TE'
					set @pret_vanzare=convert(DECIMAL(17, 5), @pret_amanunt / (1.00 + isnull(@cota_TVA, 0) / 100))
				else if @tip in ('AP','AC')
					set @pret_vanzare=isnull(@pret_valuta, 0)* (1 - @discount / 100)
					
				select @cantitate=ISNULL(@cantitate,0), @pret_vanzare=ISNULL(@pret_vanzare,0), @cota_TVA=ISNULL(@cota_TVA,0)
					,@valFactura=isnull(@valFactura, 0)
				
				select	@valFactura=@valFactura+round(convert(DECIMAL(17, 3),@Cantitate * @pret_vanzare)*(1+@cota_TVA/100),2)
				
				if @valFactura > 0.001
				begin
					declare @xml xml
					set @xml=(select @tert tert for xml raw)
					exec wIaSoldTert @sesiune='', @parXML=@xml output
					
					-- procedura returneaza null daca nu trebuie validat soldul
					if @xml is not null
					begin 
						set @msgErr=''
						select	@sold=@xml.value('(/row/@sold)[1]','float'),
								@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
								@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
						
						if @zileScadDepasite=1
							set @msgErr = isnull(@msgErr+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
						
						if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@valFactura>@soldmaxim
							set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
								+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
								+CHAR(13)+ 'Soldul anterior este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
								+CHAR(13)+ 'Valoarea pozitiei (modificarii) curente '+ CONVERT(varchar(30), convert(decimal(12,2), @valFactura)) + ' RON.'
						
						if len(@msgErr)>0
						begin
							raiserror(@msgErr,11,1)
						end
					end
				end
--stopsp*/	
				if OBJECT_ID('tempdb..#pozdocstoc') is not null 
					drop table #pozdocstoc
			end
			/*stopsp*/
			
		end		

		IF @tip='TE' and isnull(@locatie,'')='' 
		begin
			declare @locatie_detalii varchar(30), @locatie_detalii_antet varchar(30),
				@den_locatie_detalii varchar(100), @den_locatie_detalii_antet varchar(100)
			select @locatie_detalii=@parXML.value('(/row/row/detalii/row/@locatie)[sql:variable("@nrliniexml")][1]','varchar(30)')
				, @locatie_detalii_antet=@parXML.value('(/row/detalii/row/@locatie)[1]','varchar(30)')
				, @den_locatie_detalii=@parXML.value('(/row/row/detalii/row/@denLocatie)[sql:variable("@nrliniexml")][1]','varchar(100)')
				, @den_locatie_detalii_antet=@parXML.value('(/row/detalii/row/@denLocatie)[1]','varchar(100)')
	
			if isnull(@locatie_detalii,'')='' 
			begin
				if isnull(@locatie_detalii_antet,'')=''
					select @locatie_detalii_antet=rtrim(d.Cod_tert)+REPLICATE(' ',13-LEN(rtrim(d.Cod_tert)))+ISNULL(rtrim(d.Gestiune_primitoare),'')
					from doc d where d.Subunitate=@sub and d.Tip='AP' and d.Data=@data and d.Numar=@numar
			
				if ISNULL(@locatie_detalii_antet,'')<>''
				begin
					set @locatie_detalii=@locatie_detalii_antet
					set @den_locatie_detalii=@den_locatie_detalii_antet
					
					if @detalii is null -- daca nu am nod detalii deloc il pun aici pt mai departe
						--@parXML.exist('/row/row[sql:variable("@nrPozXML")]/detalii/row')=0
					begin
						set @parXML=CONVERT(XML,CONVERT(varchar(max),@parXML)
									+CONVERT(varchar(max)
										,(select locatie=RTRIM(@locatie_detalii) for xml RAW, root('detalii'))))
						set @parXML.modify('insert /*[2]  into (/row/row[sql:variable("@nrliniexml")])[1]')
						set @parXML.modify('delete /*[2]')
						set @detalii = convert(xml, (select locatie=RTRIM(@locatie_detalii), denLocatie=RTRIM(@locatie_detalii_antet) for xml RAW, root('detalii')))
					end
					
					if @parXML.value('(/row/row/detalii/row/@locatie)[sql:variable("@nrliniexml")][1]','varchar(30)') is null
						set @parxml.modify ('insert attribute locatie {sql:variable("@locatie_detalii")} into (/row/row/detalii/row)[sql:variable("@nrliniexml")][1]')
					else
						set @parXML.modify('replace value of (/row/row/detalii/row/@locatie)[sql:variable("@nrliniexml")][1] with sql:variable("@locatie_detalii")')		
					
					if @parXML.value('(/row/row/detalii/row/@denLocatie)[sql:variable("@nrliniexml")][1]','varchar(100)') is null
						set @parxml.modify ('insert attribute denLocatie {sql:variable("@den_locatie_detalii")} into (/row/row/detalii/row)[sql:variable("@nrliniexml")][1]')
					else
						set @parXML.modify('replace value of (/row/row/detalii/row/@denLocatie)[sql:variable("@nrliniexml")][1] with sql:variable("@den_locatie_detalii")')		
				end
			end
			
			if isnull(@locatie_detalii,'')<>'' 
				and isnull((select top (1) isnull(g.detalii.value('(/row/@custodie)[1]','int'),0) from gestiuni g where g.Subunitate=@sub 
					and (g.Cod_gestiune=@gestiune and @cantitate>=0.001 or g.Cod_gestiune=@gestiune_primitoare and @cantitate<=-0.001)),0)=1
					
				if @parXML.value('(/row/row/@locatie)[sql:variable("@nrliniexml")][1]','varchar(30)') is null
					set @parxml.modify ('insert attribute locatie {sql:variable("@locatie_detalii")} into (/row/row)[sql:variable("@nrliniexml")][1]')
				else
					set @parXML.modify('replace value of (/row/row/@locatie)[sql:variable("@nrliniexml")][1] with sql:variable("@locatie_detalii")')		
		end
		
		fetch next from crspozdocSP into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert, 
			@factura, @data_facturii, @data_scadentei, @lm,@lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,
			@zilescadenta,@facturanesosita,@aviznefacturat,
			@cod_intrare, @codiPrim, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc, 
			@valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount, 
			@punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx, 
			@accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, 
			@nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,@detalii,@numarpozitii,
			@idjurnalContract, @idPozContract, @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos
		set @fetch_crspozdoc=@@fetch_status	
	end
end try
begin catch
	set @mesaj =ERROR_MESSAGE()+' (wScriuPozdocSP)'
end catch

begin try 
declare @cursorStatus int
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozdocsp' and session_id=@@SPID )
if @cursorStatus=1 
	close crspozdocsp 
if @cursorStatus is not null 
	deallocate crspozdocsp 
end try 
begin catch end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch


if len(@mesaj)>0
	raiserror(@mesaj, 11, 1)
else
	return 0
