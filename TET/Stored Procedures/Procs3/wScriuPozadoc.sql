--***
CREATE procedure wScriuPozadoc @sesiune varchar(50), @parXML xml 
as

declare @tip_antet char(2), @numar char(8), @data datetime, @tert char(13), @factura_antet char(13), 
	@subtip char(2), @tip char(2), @factura_stinga char(20), @cont_deb varchar(40), @tert_benef char(13), 
	@factura_dreapta char(20), @cont_cred varchar(40), @suma float, @valuta char(3), @curs float, @cotatva decimal(12,2), 
	@suma_valuta float, @cota_TVA float, @suma_TVA float, @explicatii char(50), 
	@lm char(9), @comanda char(20), @numar_pozitie int, @jurnal char(3), @data_facturii datetime, 
	@data_scadentei datetime, @tip_antetGrp char(2), @numarGrp char(13), @dataGrp datetime, 
	@ptupdate bit,@utilizator varchar(50),@diftva float,@contdifcurs varchar(40), @sumadifcurs float, @achitfact float, 
	@sir_numere_pozitii varchar(max), @sub char(9), @userASiS varchar(20), @jurnalProprietate varchar(3), 
	@docXMLIaPozadoc xml, @eroare xml, @Bugetari int, @indbug varchar(20), 
	@comanda_bugetari varchar(40),@o_cont_deb varchar(40), @NrDocFisc varchar(20), @NrDocFiscPrimit varchar(20), @fXML xml, 
	@tipPentruNr varchar(2),@ft int,@o_diftva float, @o_suma_TVA float, @o_indbug varchar(20),
	@CuDifCurs int, @contcheltdiffurn varchar(40), @contcheltdifben varchar(40), @contvendiffurn varchar(40), 
	@contvendifben varchar(40), @tertcudecvaluta int, @valutafactst char(3), @cursfactst float, 
	@soldvalutafactst float, @valutafactdr char(3), @cursfactdr float,@valfactdr float,
	@achitfactdr float,@achitvalutafactdr float,@soldvalutafactdr float, @cursachitvalutafact float,@tiptva int,@fara_luare_date int,
	@detaliipoz xml
BEGIN TRY
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	set @eroare=dbo.wfValidarePozadoc(@parXML)

	declare @mesaj varchar(200)	
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
	begin
		set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
		raiserror(@mesaj, 11, 1)
	end	
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozadocSP')
		exec wScriuPozadocSP @sesiune, @parXML output
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	exec luare_date_par 'GE','DIFINR', @CuDifCurs output, 0, ''
	exec luare_date_par 'GE','DIFCH',0,0,@contcheltdiffurn output
	exec luare_date_par 'GE','DIFVE',0,0,@contvendiffurn output
	exec luare_date_par 'GE','DIFCHB',0,0,@contcheltdifben output
	exec luare_date_par 'GE','DIFVEB',0,0,@contvendifben output
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	set @jurnalProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='JURNAL'), '')

	declare @iDoc int, @crspozadoc cursor
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	-->>>>>> START SCRIPT SPECIFIC SUBTIPULUI SF-sosire factura<<<<<<<--
	--daca subtip='SF', sosire factura, si nu este completat factura din 408 apelam macheta pentru sosire factura
	declare  @NrDocPrimit varchar(20), @NumarDocPrimit int, @an varchar(2), @plajaJos int, @plajaSus int, @id int, @apelDinProcedura int,
			@cod char(20) --?
	set @ptupdate=isnull(@parXML.value('(/row/row/@update)[1]', 'int'),0)
	set @subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'), '')
	set @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
	set @suma=isnull(@parXML.value('(/row/row/@suma)[1]', 'decimal(15,2)'),0)
	set @cotatva=isnull(@parXML.value('(/row/row/@cotatva)[1]', 'decimal(15,2)'),0)
	set @tiptva=isnull(@parXML.value('(/row/row/@tiptva)[1]', 'int'),0)
	set @factura_stinga=ISNULL(@parXML.value('(/row/row/@facturastinga)[1]', 'varchar(20)'), '')
	set @factura_dreapta=ISNULL(@parXML.value('(/row/row/@facturadreapta)[1]', 'varchar(20)'), '')
	set @cont_cred=ISNULL(@parXML.value('(/row/row/@contcred)[1]', 'varchar(40)'), '')
	set @valuta=ISNULL(@parXML.value('(/row/row/@valuta)[1]', 'varchar(40)'), '')
	set @curs=ISNULL(@parXML.value('(/row/row/@curs)[1]', 'float'), '')
	set @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), '') 
	set @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), '')
	set @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
	set @an=right(convert(char(4),year(@data)),2)
	SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
	if @parXML.exist('(/row/row/detalii)[1]')=1
		SET @detaliipoz = @parXML.query('(/row/row/detalii/row)[1]')


	if @subtip in ('SF') and @tip in ('SF') and @ptupdate<>1 and @apelDinProcedura=0
	begin
		--Validari
		if @factura_dreapta=''
		begin
			set @mesaj = 'Introduceti numarul facturii sosite!'
			raiserror(@mesaj, 11, 1)
		end
		if @cont_cred=''
		begin
			set @mesaj = 'Introduceti contul creditor (401)!'
			raiserror(@mesaj, 11, 1)
		end	
		if not exists (select 1 from conturi where cont=@cont_cred)
		begin
			set @mesaj = 'Introduceti un cont creditor valid (401)!'
			raiserror(@mesaj, 11, 1)
		end
	
		--Numerotare 
		if isnull(@numar, '')=''
			begin
				set @tipPentruNr='AD' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"AD"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
				set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
			
				exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output
			
				if @NrDocPrimit is null
					raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
				set @numar=@NrDocPrimit
			end
		--gata numerotare
	
		if isnull(@factura_stinga,'')<>'' and isnull(@suma,0)=0 
		--daca s-a introdus pe macheta factura din 408, si nu s-a introdus o suma, suma va fi egala cu soldul facturii
		begin
			select @suma=sold from facturi where factura=@factura_stinga and tert=@tert	
				
			if @parXML.value('(/row/row/@suma)[1]', 'decimal(15, 2)') is not null                          
				set @parXML.modify('replace value of (/row/row/@suma)[1] with sql:variable("@suma")') 
			else
				set @parXML.modify ('insert attribute suma {sql:variable("@suma")} into (/row/row)[1]') 
		end
					
		if isnull(@factura_stinga,'')=''
		begin
			DECLARE @dateInitializareSFIF XML	
			set @dateInitializareSFIF=
			(
				select 
					@tip as tip, @tert as tert, convert(char(10), @data, 101) as data, @lm as lm,
					CONVERT(decimal(15,2),@suma) as suma, 
					RTRIM(@numar) as numar, 
					@valuta as valuta,
					convert(decimal(15,4),@curs) as curs,
					@cotatva as cotatva,
					@tiptva as tiptva
					,rtrim(@factura_dreapta) as facturadreapta
					,rtrim(@cont_cred) as contcred,
					@detaliipoz detalii
				for xml raw ,root('row'), type
			)
				
			SELECT 'Operatie pentru sosire facturi'  nume, 'AD' codmeniu, 'D' tipmacheta, 'SF' tip,'YY' subtip,'O' fel,
				(SELECT @dateInitializareSFIF ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
			
			if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
				set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
			else
				set @parXML.modify ('insert attribute subunitate {sql:variable("@sub")} into (/row)[1]') 
		
			if @parXML.value('(/row/@numar)[1]', 'varchar(9)') is not null                          
				set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@numar")') 
			else
				set @parXML.modify ('insert attribute numar {sql:variable("@numar")} into (/row)[1]') 				
		
	
			-- pt initializare antet
			select @parXML for xml raw('dateAntet'), root('Mesaje')
				
			if @fara_luare_date<>'1'
			begin
				--pt initializare antet
				set @docXMLIaPozadoc = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tip) + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
				exec wIaPozadoc @sesiune=@sesiune, @parXML=@docXMLIaPozadoc 
			end
				
			return
		end
	end


	-->>>>>> STOP SCRIPT SPECIFIC SUBTIPURILOR SF-sosire factura, IF- intocmire factura<<<<<<<--

	set @crspozadoc = cursor local fast_forward for
	select isnull(tip, '') as tip, isnull(numar, '') as numar, isnull(data, '01/01/1901') as data, 
	upper(isnull(tert_antet, '')) as tert_antet, upper(isnull(factura_antet, '')) as factura_antet, 
	isnull(subtip, '') as subtip, upper(isnull(factura_stinga, '')) as factura_stinga, ISNULL(cont_deb, '') as cont_deb, ISNULL(o_cont_deb, '') as o_cont_deb,
	upper(isnull(tert_benef, isnull(tert_benef_antet, ''))) as tert_benef, 
	upper(isnull(factura_dreapta, '')) as factura_dreapta, ISNULL(cont_cred, '') as cont_cred, 
	isnull(suma, 0) as suma, upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(suma_valuta, 0) as suma_valuta, 
	isnull(cota_TVA, 0) as cota_TVA, isnull(suma_TVA, 0) as suma_TVA,o_suma_TVA as o_suma_TVA, isnull(explicatii, '') as explicatii, 
	upper(isnull(lm, '')) as lm, upper(isnull(comanda, '')) as comanda, isnull(indbug, '') as indbug, isnull(o_indbug, '') as o_indbug, 
	isnull(numar_pozitie, 0) as numar_pozitie, isnull(jurnal, '') as jurnal, isnull(data_facturii, '01/01/1901') as data_facturii, 
	isnull(data_scadentei, '01/01/1901') as data_scadentei,diftva,o_diftva,
	isnull(sumadifcurs, 0) as sumadifcurs, isnull(contdifcurs, '') as contdifcurs, isnull(achitfact, 0) as achitfact, 
	isnull(tiptva,0),isnull(ptupdate,0)
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(2) '../@tip', 
		numar char(8) '../@numar', 
		data datetime '../@data', 
		tert_antet char(13) '../@tert', 
		factura_antet char(20) '../@factura', 
		subtip char(2) '@subtip', 
		factura_stinga char(20) '@facturastinga', 
		cont_deb varchar(40) '@contdeb', o_cont_deb varchar(40) '@o_contdeb', 
		tert_benef char(13) '@tertbenef', 
		tert_benef_antet char(13) '../@tertbenef', 
		factura_dreapta char(20) '@facturadreapta', 
		cont_cred varchar(40) '@contcred', 
		suma float '@suma', 
		valuta char(3) '@valuta', 
		curs float '@curs', 
		suma_valuta float '@sumavaluta', 
		cota_TVA float '@cotatva', 
		suma_TVA float '@sumatva', 
		o_suma_TVA float '@o_sumatva', 
		explicatii char(50) '@explicatii', 
		lm char(9) '@lm', 
		comanda char(20) '@comanda', 
		indbug char(20) '@indbug', o_indbug char(20) '@o_indbug', 	
		numar_pozitie int '@numarpozitie', 
		jurnal char(3) '@jurnal', 
		data_facturii datetime '@datafacturii', 
		data_scadentei datetime '@datascadentei',
		diftva float '@diftva',o_diftva float '@o_diftva',
		sumadifcurs float '@sumadifcurs',
		contdifcurs varchar(40) '@contdifcurs', 
		achitfact float '@achitfact',
		tiptva int '@tiptva',
		ptupdate bit '@update'
	)

	open @crspozadoc
	fetch next from @crspozadoc into @tip_antet, @numar, @data, @tert, @factura_antet, 
		@subtip, @factura_stinga, @cont_deb, @o_cont_deb, @tert_benef, @factura_dreapta, @cont_cred, 
		@suma, @valuta, @curs, @suma_valuta, @cota_TVA, @suma_TVA, @o_suma_TVA, @explicatii, 
		@lm, @comanda, @indbug,@o_indbug, @numar_pozitie, @jurnal, @data_facturii, @data_scadentei,
		@diftva,@o_diftva,@sumadifcurs,@contdifcurs,@achitfact,@tiptva,@ptupdate
	
	select @tip_antetGrp=@tip_antet, @numarGrp=@numar, @dataGrp=@data, @sir_numere_pozitii=''
	set @ft=@@FETCH_STATUS
	while @ft=0
	begin
		if @jurnal='' set @jurnal=@jurnalProprietate
		set @comanda_bugetari=convert(char(20),@comanda)+isnull(@indbug,'')
			
		set @tip=(case when @subtip='FV' and abs(@suma_valuta)>=0.01 then 'FF' when @subtip='BV' and abs(@suma_valuta)>=0.01 then 'FB' else @subtip end)
		
		/*if @numar=''
			set @numar=(case when @tip in ('FF','SF','CB') then @factura_dreapta else @factura_stinga end)*/
		
		if @factura_antet='' and @ptupdate='0' and @tip='IF' 
		begin
				set @tipPentruNr='AP' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
				exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output, @NrDoc=@NrDocFiscPrimit output
				set @factura_antet=@NrDocFiscPrimit
		end
		if @numar='' or @numar=null and @ptupdate='0' and @tip='IF' 
		begin
				set @tipPentruNr='AD' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"AD"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
				exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output, @NrDoc=@NrDocFiscPrimit output
				set @numar=@NrDocFiscPrimit
		end
		if @factura_stinga='' and @tip in ('FB', 'IF', 'CO', 'C3', 'CF')
			set @factura_stinga=@factura_antet
		if @factura_dreapta='' and @tip in ('FF', 'FF', 'CB')
			set @factura_dreapta=@factura_antet		
		
		if @ptupdate='0'
		begin	
			if ISNULL(@suma,0)=0 -->daca nu se introduce suma pe macheta aceasta va fi determinata in functie de tipul documentului
				if  @tip in ('SF','IF')  -->sosire facturi si intocmire facturi
				begin
					select @suma=(case when achitat=0 then valoare else sold/(1+(TVA_11+TVA_22)/Valoare) end) 
						from facturi where factura=(case when @tip='IF' then @factura_dreapta else @factura_stinga end) and tert=@tert	
					select @suma_TVA=(case when achitat=0 then TVA_11+TVA_22 else sold-@suma end) from facturi where factura=(case when @tip='IF' then @factura_dreapta else @factura_stinga end) and tert=@tert	
				end
				else
				if @suma_TVA = 0 -- daca se completeaza suma tva, nu calculam @suma - se doreste TVA pe alt cont. 
					select @suma=isnull(MIN(abs(sold)),0) from facturi 
						where (factura=@factura_stinga and tert=@tert) or (factura=@factura_dreapta and tert=case when @tip='C3' then @tert_benef else @tert end) 
 		
			select @valfactdr=0, @achitfactdr=0, @achitvalutafactdr=0, @soldvalutafactdr=0, 
				@cursfactdr=0, @valutafactdr='', @valutafactst='', @cursfactst=0, @soldvalutafactst=0, 
				@tertcudecvaluta=0
			
			if @CuDifCurs=1 and @tip in ('CF','CB','CO','C3','SF','IF')
				select @tertcudecvaluta=isnull((select tert_extern from terti where Subunitate=@sub and tert=@tert),0)
			
			if @CuDifCurs=1 and @tip in ('CF','CB','SF','IF') and @tertcudecvaluta=1
			begin
				select @soldvalutafactst=round(Sold_valuta,2), @cursfactst=round(curs,4), @valutafactst=valuta
					from facturi where Subunitate=@sub and tip=(case when @tip in ('CF','SF') then 0x54 else 0x46 end) and Factura=@factura_stinga and tert=@tert
				select @valfactdr=round(Valoare,2), @achitfactdr=round(Achitat,2), @achitvalutafactdr=round(Achitat_valuta,2), @soldvalutafactdr=round(Sold_valuta,2), @cursfactdr=round(curs,4), @valutafactdr=valuta 
					from facturi where Subunitate=@sub and tip=(case when @tip in ('CF','SF') then 0x54 else 0x46 end) and Factura=@factura_dreapta and tert=@tert
				select @valfactdr=isnull(@valfactdr,0), @achitfactdr=isnull(@achitfactdr,0), 
					@achitvalutafactdr=isnull(@achitvalutafactdr,0), 
					@soldvalutafactdr=isnull(@soldvalutafactdr,0), @cursfactdr=isnull(@cursfactdr,0), 
					@valutafactdr=isnull(@valutafactdr,''), @valutafactst=isnull(@valutafactst,''), 
					@cursfactst=isnull(@cursfactst,0), @soldvalutafactst=isnull(@soldvalutafactst,0)
			end
									
			--->>> START TIP CO
			if @CuDifCurs=1 and @tip in ('CO') and @tertcudecvaluta=1
			begin
				select @soldvalutafactst=round(Sold_valuta,2), @cursfactst=round(curs,4), 
					@valutafactst=valuta
					from facturi where Subunitate=@sub and tip=(case when @tip='CO' then 0x54 else 0x46 end) 
					and Factura=@factura_stinga and tert=@tert
				select @valfactdr=round(Valoare,2), @achitfactdr=round(Achitat,2), 
					@achitvalutafactdr=round(Achitat_valuta,2), @soldvalutafactdr=round(Sold_valuta,2), 
					@cursfactdr=round(curs,4), @valutafactdr=valuta
					from facturi where Subunitate=@sub and tip=(case when @tip='CF' then 0x54 else 0x46 end) 
					and Factura=@factura_dreapta and tert=@tert
				select @valfactdr=isnull(@valfactdr,0), @achitfactdr=isnull(@achitfactdr,0), 
					@achitvalutafactdr=isnull(@achitvalutafactdr,0), 
					@soldvalutafactdr=isnull(@soldvalutafactdr,0), @cursfactdr=isnull(@cursfactdr,0), 
					@valutafactdr=isnull(@valutafactdr,''), @valutafactst=isnull(@valutafactst,''), 
					@cursfactst=isnull(@cursfactst,0), @soldvalutafactst=isnull(@soldvalutafactst,0)

			end
			--->>> END TIP CO
			
			--->>> START TIP C3
			if @CuDifCurs=1 and @tip in ('C3') and @tertcudecvaluta=1
			begin
				select @soldvalutafactst=round(Sold_valuta,2), @cursfactst=round(curs,4), 
					@valutafactst=valuta
					from facturi where Subunitate=@sub and tip=(case when @tip='C3' then 0x54 else 0x46 end) 
					and Factura=@factura_stinga and tert=@tert
				select @valfactdr=round(Valoare,2), @achitfactdr=round(Achitat,2), 
					@achitvalutafactdr=round(Achitat_valuta,2), @soldvalutafactdr=round(Sold_valuta,2), 
					@cursfactdr=round(curs,4), @valutafactdr=valuta
					from facturi where Subunitate=@sub and tip=(case when @tip='CF' then 0x54 else 0x46 end) 
					and Factura=@factura_dreapta and tert=@tert_benef
				select @valfactdr=isnull(@valfactdr,0), @achitfactdr=isnull(@achitfactdr,0), 
					@achitvalutafactdr=isnull(@achitvalutafactdr,0), 
					@soldvalutafactdr=isnull(@soldvalutafactdr,0), @cursfactdr=isnull(@cursfactdr,0), 
					@valutafactdr=isnull(@valutafactdr,''), @valutafactst=isnull(@valutafactst,''), 
					@cursfactst=isnull(@cursfactst,0), @soldvalutafactst=isnull(@soldvalutafactst,0)
			end
			--->>> END TIP C3

 			if @tip='SF' or @tip='CF' or @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='CB' and abs(@soldvalutafactdr)>=0.01 
 				select 
					@valuta= case when isnull(@valuta,'')='' or @tip='CB' then isnull(valuta,'') else @valuta end, 
					@curs=case when isnull(@curs,0)=0 or @tip='CB' then isnull(curs,0) else @curs end 
 				from facturi where Factura=@factura_stinga and tert=@tert
 			
 			if @tip='IF' or @tip='CB' or @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='CF' and abs(@soldvalutafactst)>=0.01 
 				select 
					@valuta=(case when isnull(@valuta,'')='' or @tip='CF' then isnull(valuta,'') else @valuta end), 
					@curs=(case when isnull(@curs,0)=0 or @tip='CF' then isnull(curs,0) else @curs end) 
 				from facturi where Factura=@factura_dreapta and tert=@tert

			-->>> START VALUTA,CURS TIP CO 				
 			if @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='CO' and abs(@soldvalutafactdr)>=0.01 
 				select	@valuta= case when isnull(@valuta,'')='' or @tip='CO' then isnull(valuta,'') else @valuta end, 
 						@curs=case when isnull(@curs,0)=0 or @tip='CO' then isnull(curs,0) else @curs end 
 				from facturi where Factura=@factura_stinga and tert=@tert
			--->>> END VALUTA,CURS TIP CO

			-->>> START VALUTA,CURS TIP C3 				
 			if @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='C3' and abs(@soldvalutafactdr)>=0.01 
 				select	@valuta= case when isnull(@valuta,'')='' or @tip='C3' then isnull(valuta,'') else @valuta end, 
 						@curs=case when isnull(@curs,0)=0 or @tip='C3' then isnull(curs,0) else @curs end 
 				from facturi where Factura=@factura_stinga and tert=@tert
			--->>> END VALUTA,CURS TIP C3

			declare @valminvalutacompensare float
			if @CuDifCurs=1 and @tertcudecvaluta=1 and (@tip='CF' and abs(@soldvalutafactst)>=0.01 or @tip='CB' and abs(@soldvalutafactdr)>=0.01)
			begin
				set @valminvalutacompensare=dbo.valoare_minima((case when @tip='CB' then -1 else 1 end)*@soldvalutafactst, (case when @tip in ('CF') then -1 else 1 end)*@soldvalutafactdr,0)
				select 
					@suma_valuta=(case when @suma_valuta=0 then @valminvalutacompensare else round(dbo.valoare_minima(@suma_valuta,@valminvalutacompensare,0),2) end),

					@suma=round((case when ABS(@suma- @suma_valuta*@curs )<0.5 then @suma else @suma_valuta*@curs end),2), 

					@achitfact=round((case when @valuta=(case when @tip in ('CF') then @valutafactst else @valutafactdr end) then @suma_valuta 
								else (case when @tip in ('CF') then @soldvalutafactst else @soldvalutafactdr end) end),2), 

					@cursachitvalutafact=round(@curs*@suma_valuta/@achitfact,4), 

					@contdifcurs=(case when isnull(@contdifcurs,'')='' then (case when @tip in ('CF') and @cursachitvalutafact>@cursfactst or @tip='CB' and @cursachitvalutafact<@cursfactdr 
						then (case when @contcheltdifben='' or @tip in ('CF') then @contcheltdiffurn else @contcheltdifben end) 
						else (case when @contvendifben='' or @tip in ('CF') then @contvendiffurn else @contvendifben end) end) else @contdifcurs end), 

					@sumadifcurs=round((case when isnull(@sumadifcurs,0)=0 then (case when @tip in ('CF') and @cursachitvalutafact<@cursfactst and abs(@suma_valuta-@achitvalutafactdr)<0.01 then @cursfactst*@achitfact-@suma 
							when @tip in ('CF') and @cursachitvalutafact>@cursfactst and abs(@suma_valuta-@achitvalutafactdr)<0.01 then @suma-@cursfactst*@achitfact 
							when (case when @tip in ('CF') then @cursfactst else @cursfactdr end)>@cursachitvalutafact then ((case when @tip in ('CF') then @cursfactst else @cursfactdr end)-@cursachitvalutafact)*@achitfact 
								else (@cursachitvalutafact-(case when @tip in ('CF') then @cursfactst else @cursfactdr end))*@achitfact end) 
						else @sumadifcurs end),2)

			end

			if @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='SF' and abs(@soldvalutafactst)>=0.01
			begin
				select 
					@suma_valuta=@soldvalutafactst,
					@suma=round((case when ABS(@suma- @suma_valuta*@curs )<0.5 then @suma else @suma_valuta*@curs end),2), 
					@achitfact=round((case when @valuta=@valutafactst then @suma_valuta else @soldvalutafactst end),2), 
					@cursachitvalutafact=@curs, --round(@curs*@suma_valuta/@achitfact,4), 
					@contdifcurs=(case when isnull(@contdifcurs,'')='' then (case when @cursachitvalutafact>@cursfactst then @contcheltdiffurn else @contvendiffurn end) else @contdifcurs end), 
					@sumadifcurs=round((case when isnull(@sumadifcurs,0)=0 then (case when @cursachitvalutafact<@cursfactst and abs(@suma_valuta-@achitfact)<0.01 
						then @cursfactst*@achitfact-@suma when @cursachitvalutafact>@cursfactst and abs(@suma_valuta-@achitfact)<0.01 then @suma-@cursfactst*@achitfact 
						when @cursfactst>@cursachitvalutafact then (@cursfactst-@cursachitvalutafact)*@achitfact 
						else (@cursachitvalutafact-@cursfactst)*@achitfact end) 
						else @sumadifcurs end),2)
			end

			if @CuDifCurs=1 and @tertcudecvaluta=1 and @tip='IF' and abs(@soldvalutafactdr)>=0.01
			begin
				select 
					@suma_valuta=@soldvalutafactdr,
					@suma=round((case when ABS(@suma- @suma_valuta*@curs )<0.5 then @suma else @suma_valuta*@curs end),2), 
					@achitfact=round((case when @valuta=@valutafactdr then @suma_valuta else @soldvalutafactdr end),2), 
					@cursachitvalutafact=@curs, --round(@curs*@suma_valuta/@achitfact,4), 
					@contdifcurs=(case when isnull(@contdifcurs,'')<>'' then @contdifcurs else 
						(case when @cursachitvalutafact<@cursfactdr then (case when @contcheltdifben='' then @contcheltdiffurn else @contcheltdifben end) 
							else (case when @contvendifben='' then @contvendiffurn else @contvendifben end) end) end), 
					@sumadifcurs=round((case when isnull(@sumadifcurs,0)<>0 then @sumadifcurs else 
						(case when @cursachitvalutafact<@cursfactdr and abs(@suma_valuta-@achitfact)<0.01 then @cursfactdr*@achitfact-@suma 
							when @cursachitvalutafact>@cursfactdr and abs(@suma_valuta-@achitfact)<0.01 then @suma-@cursfactdr*@achitfact 
							when @cursfactdr>@cursachitvalutafact then (@cursfactdr-@cursachitvalutafact)*@achitfact 
							else (@cursachitvalutafact-@cursfactdr)*@achitfact end) 
						 end),2)
			end

			if @CuDifCurs=1 and @tertcudecvaluta=1 and (@tip in ('CO','C3') and abs(@soldvalutafactst)>=0.01)
			begin
				set @valminvalutacompensare=dbo.valoare_minima(@soldvalutafactst, @soldvalutafactdr, 0)
				select 
					@suma_valuta=(case when @suma_valuta=0 then @valminvalutacompensare else round(dbo.valoare_minima(@suma_valuta,@valminvalutacompensare,0),2) end),
					@suma=round((case when ABS(@suma-@suma_valuta*@cursfactdr)<0.5 then @suma else @suma_valuta*@cursfactdr end),2), 
					@achitfact=round((case when @valuta=@valutafactdr then @suma_valuta else @soldvalutafactdr end),2), 
					@cursachitvalutafact=round(@cursfactdr*@suma_valuta/@achitfact,4), 
					@contdifcurs=(case when isnull(@contdifcurs,'')<>'' then @contdifcurs else (case when @cursachitvalutafact>@cursfactst then @contcheltdiffurn else @contvendiffurn end) end), 
					@sumadifcurs=round((case when isnull(@sumadifcurs,0)<>0 then @sumadifcurs else 
						(case when @cursachitvalutafact<@cursfactst and abs(@suma_valuta-@achitfact)<0.01 then @cursfactst*@achitfact-@suma 
							when @cursachitvalutafact>@cursfactst and abs(@suma_valuta-@achitfact)<0.01 then @suma-@cursfactst*@achitfact 
							when @cursfactst>@cursachitvalutafact then (@cursfactst-@cursachitvalutafact)*@achitfact 
							else (@cursachitvalutafact-@cursfactst)*@achitfact end) 
						 end),2)
			end
 		end
		
		-------------------Start Modificari bugetari-------------------------		
		--	scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
		if @Bugetari='1' and 1=0	
		begin 
			--daca indicatorul bugetar nu a fost introdus de utilizator atunci il generam automat
			if @indbug='' or (@ptupdate=1 and (@o_indbug=@indbug or ISNULL(@o_indbug,'')='') and @o_cont_deb<>@cont_deb) 
			begin
				if left(@cont_deb,1)in ('6') and @tip='FF'
					exec wFormezIndicatorBugetar @Cont=@cont_deb,@Lm=@lm,@Indbug=@indbug output				
			end
		end
		--------------------Stop Modificari Bugetari---------------------------
		
		set @comanda_bugetari=convert(char(20),@comanda)+(case when 1=0 then @indbug else '' end)
		----->>>>> start cod formare parametru xml pentru procedurile de scriere documente<<<<-----
		declare @parXmlpozadoc xml,@data_facturiiS char(10),@data_scadenteiS char(10),@data_expirariiS char(10),@dataS char(10)
		set @dataS=CONVERT(char(10),@data,101)
		set @data_facturiiS=CONVERT(char(10),@data_facturii,101)
		set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)
		
		if isnull(@numar,'')='' 
			raiserror('wScriuPozadoc: numar de document nealocat!! ',11,1)
		set @parXmlpozadoc = '<row/>'
		set @parXmlpozadoc.modify ('insert 
					(
					attribute tip {sql:variable("@tip")},
					attribute subtip {sql:variable("@subtip")},
					attribute numar {sql:variable("@numar")},
					attribute data {sql:variable("@dataS")},
					attribute tert {sql:variable("@tert")},
					attribute factura_stinga {sql:variable("@factura_stinga")},
					attribute cont_deb {sql:variable("@cont_deb")},
					attribute factura_dreapta {sql:variable("@factura_dreapta")},
					attribute cont_cred {sql:variable("@cont_cred")},
					attribute suma {sql:variable("@suma")},
					attribute valuta {sql:variable("@valuta")},
					attribute curs {sql:variable("@curs")},
					attribute suma_valuta {sql:variable("@suma_valuta")},	
					attribute cota_TVA {sql:variable("@cota_TVA")},
					attribute suma_tva {sql:variable("@suma_TVA")},
					attribute o_suma_tva {sql:variable("@o_suma_TVA")},
					attribute explicatii {sql:variable("@explicatii")},
					attribute numar_pozitie {sql:variable("@numar_pozitie")},					
					attribute update {sql:variable("@ptupdate")},
					attribute tert_benef {sql:variable("@tert_benef")},
					attribute lm {sql:variable("@lm")},
					attribute comanda_bugetari {sql:variable("@comanda_bugetari")},
					attribute utilizator {sql:variable("@userASiS")},
					attribute jurnal {sql:variable("@jurnal")} ,	
					attribute data_scadentei {sql:variable("@data_scadenteiS")},
					attribute data_facturii {sql:variable("@data_facturiiS")},
					attribute o_diftva {sql:variable("@o_diftva")},					
					attribute sumadifcurs {sql:variable("@sumadifcurs")},
					attribute contdifcurs {sql:variable("@contdifcurs")},
					attribute achitfact {sql:variable("@achitfact")},
					attribute tiptva {sql:variable("@tiptva")}
					)					
					into (/row)[1]')		

		if @diftva is not null
			set @parXmlpozadoc.modify ('insert (attribute diftva {sql:variable("@diftva")}) into (/row)[1]')		
		--->>>>stop cod formare parametru xml pentru procedurile de scriere documente<<<<-----
		
		exec wscriuAD @parXmlpozadoc output
		
		if @tip_antet=@tip_antetGrp and @numar=@numarGrp and @data=@dataGrp 
			set @sir_numere_pozitii=@sir_numere_pozitii+(case when @sir_numere_pozitii<>'' then ';' else '' end)+ltrim(str(@numar_pozitie))
	
		fetch next from @crspozadoc into @tip_antet, @numar, @data, @tert, @factura_antet, 
			@subtip, @factura_stinga, @cont_deb, @o_cont_deb, @tert_benef, @factura_dreapta, @cont_cred, 
			@suma, @valuta, @curs, @suma_valuta, @cota_TVA, @suma_TVA,@o_suma_TVA, @explicatii, 
			@lm, @comanda, @indbug,@o_indbug, @numar_pozitie, @jurnal, @data_facturii, @data_scadentei,
			@diftva,@o_diftva,@sumadifcurs,@contdifcurs,@achitfact,@tiptva,@ptupdate
		set @ft=@@FETCH_STATUS
	end

	/* Pentru bugetari se apeleaza procedura ce scrie in pozadoc.detalii, a indicatorului bugetar stabilit in mod unitar prin procedura indbugPozitieDocument. */
	if @bugetari=1 and @ptupdate=0
		and exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocument')
	begin
		declare @parXMLIndbug xml
		IF OBJECT_ID('tempdb..#indbugPozitieDoc') is not null drop table #indbugPozitieDoc
		create table #indbugPozitieDoc (furn_benef char(1), tabela varchar(20), idPozitieDoc int, indbug varchar(20))
		insert into #indbugPozitieDoc (furn_benef, tabela, idPozitieDoc)
		select '', 'pozadoc', @parXmlpozadoc.value('(/Inserate/row/@idpozadoc)[1]', 'int')

		set @parXMLIndbug=(select 1 as scriere for xml raw)
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXMLIndbug
	end
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozadocSP2')    
		exec wScriuPozadocSP2 '', @sub, @tip_antetGrp, @numarGrp, @dataGrp, @parXML   
	
	set @fara_luare_date=ISNULL(@parXML.value('(/row/@fara_luare_date)[1]', 'char(1)'), '0')
	if @fara_luare_date<>'1'
	begin
		set @docXMLIaPozadoc='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tip_antetGrp)+'" numar="'+rtrim(@numar)+'" data="'+convert(char(10), @dataGrp, 101)+'" '/*+'numerepozitii="'+@sir_numere_pozitii+'"'*/+'/>'
		exec wIaPozadoc @sesiune=@sesiune, @parXML=@docXMLIaPozadoc 
	end
	

end try
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--	
	
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch 
end catch
