--***
create procedure wScriuReceptie @parXmlScriereIntrari xml output
as
begin try
	
	declare 
		@Tip char(2),@Numar char(20),@Data datetime ,@Tert char(13),@Fact char(20),@DataFact datetime,@DataScad datetime,@CtFact varchar(40),
		@Gest char(9),@Cod char(20),@CodIntrare char(13),@CtStoc varchar(40),@Locatie char(30),
		@Cantitate float,@Valuta char(3),@Curs float,@PretFurn float,@Discount float,@PretAmPrim float,@LM char(9),@Comanda char(40),
		@ComAprov char(20),@Jurnal char(3),@DVI char(30),@Stare int,@Barcod char(30),@TipTVA int,@DataExp datetime,@Utilizator char(10),@Serie char(20),
		@NrPozitii int ,@Valoare float ,@ValTVA float,@Lot varchar(13),@DiscSuma float,@ValValuta float,@TotCant float,@NrPozitie int ,@CotaTVA float,
		@PozitieNoua int,@SumaTVA float ,@update bit,@subtip varchar(2),@mesaj varchar(200),@Explicatii varchar(30), @text_alfa2 varchar(30), @detalii xml,
		@docInserate XML,@ContTvaPrimit varchar(40),
		@Sb char(9),@TLit int,@TLitR int,@Accize int,@CtAccize varchar(40),@Ct378 varchar(40),@AnGest378 int,@AnGr378 int,@Ct4428 varchar(40),@AnGest4428 int,
		@DVE int,@AccImpDVI int,@CodVam int,@Bug int,@RotPretV int,@SumaRotP float,@PAmFaraTVAnx int,@SCom int,@SFurn int,@CotaTVAGen float,
		@TipN char(1),@CotaTVAN float,@PAmN float,@GrN char(13),@GreutN float,@TipTert int,@PStoc float,@TVAnx float,@CtAdPrim varchar(40),@CtTVAnxPrim varchar(40),
		@Grupa char(13),@AccCump float,@StersPozitie int, @Serii int,
		@comandaSql nvarchar(max), @areDetalii bit,  @dataoperarii datetime, @oraoperarii varchar(50)
		
	set @NrPozitie=0
	set @PozitieNoua=0
	set @SumaTVA =0	
	
	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIntrari
		
	select 
		@Numar=isnull(numar,''),@Data=data,@Tert=ISNULL(tert,''),@Fact=factura, @DataFact=data_facturii,@DataScad=data_scadentei,
		@CtFact=cont_factura,@Gest=gestiune, @Cod=cod, @CodIntrare=cod_intrare, @CtStoc=cont_stoc, @PStoc=pret_stoc, 
		@Locatie=locatie, @Cantitate= cantitate, @Valuta=valuta,@Curs=curs,@PretFurn=pret_valuta,
		@Discount=discount,@PretAmPrim=pret_amanunt,@LM=lm, @Comanda=comanda_bugetari,
		@ComAprov=contract,@Jurnal=jurnal, @DVI=DVI, @Stare=stare,@Barcod=barcod,
		@TipTVA=tipTVA,@DataExp=data_expirarii,@Utilizator=ISNULL(utilizator,''),@Serie=isnull(serie,0),@TotCant=isnull(accizecump,0),
		@NrPozitie=ISNULL(numar_pozitie,0),@Lot=lot,@CotaTVA=cota_TVA,@SumaTVA=suma_tva,		
		@update=isnull(ptupdate,0),@tip=tip,@subtip=subtip,@text_alfa2=text_alfa2,@detalii=detalii,
		@Explicatii=explicatii,@ContTvaPrimit=cont_venituri 
	
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		detalii xml 'detalii/row',
		tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip', 
		numar varchar(20) '@numar',
		data datetime '@data',
		tert varchar(13) '@tert',
		factura varchar(20) '@factura',
		data_facturii datetime '@data_facturii',
		data_scadentei datetime '@data_scadentei',
		cont_factura varchar(40) '@cont_factura',
		gestiune varchar(9) '@gestiune',
		cod varchar(20) '@cod',
		cod_intrare varchar(20) '@cod_intrare',
		cont_stoc varchar(40) '@cont_stoc', 	
		locatie varchar(30) '@locatie', 
		cantitate float '@cantitate',	
		valuta varchar(3) '@valuta' , 
		curs varchar(14) '@curs',
		pret_valuta float '@pret_valuta', 
		discount float '@discount', 
		pret_amanunt float '@pret_amanunt', 
		pret_stoc float '@pret_stoc',
		lm varchar(9) '@lm', 
		comanda_bugetari varchar(40) '@comanda_bugetari', 
		contract varchar(20) '@contract',
		jurnal varchar(3) '@jurnal', 
		DVI varchar(25) '@DVI',
		stare int '@stare',
		barcod varchar(30) '@barcod', 
		tipTVA int '@tipTVA',
		data_expirarii datetime '@data_expirarii',
		utilizator varchar(20) '@utilizator', 
		serie varchar(20) '@serie',
		suma_tva float '@suma_tva', 
		cota_TVA float '@cota_TVA',
		numar_pozitie int '@numar_pozitie',
		accizecump float '@accizecump', 
		lot varchar(13) '@lot',
		cont_corespondent varchar(40) '@cont_corespondent',
		cont_venituri varchar(40) '@cont_venituri', 
		suprataxe float '@suprataxe', 
		ptupdate int '@update',
		explicatii varchar(30) '@explicatii',
		text_alfa2 varchar(30) '@text_alfa2'-->campul alfa2 din textpozdoc
		
	)
	
	set @Comanda=@parXmlScriereIntrari.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end

	exec luare_date_par 'GE','SUBPRO',0,0,@Sb output
	exec luare_date_par 'GE','TIMBRULIT',@TLit output,0,''
	exec luare_date_par 'GE','TIMBRULT2',@TLitR output,0,''
	exec luare_date_par 'GE','ACCIZE',@Accize output,0,''
	exec luare_date_par 'GE','CACCIZE',0,0,@CtAccize output
	exec luare_date_par 'GE','CADAOS',@AnGest378 output,@AnGr378 output,@Ct378 output
	exec luare_date_par 'GE','CNTVA',@AnGest4428 output,0,@Ct4428 output
	exec luare_date_par 'GE','DVE',@DVE output,0,''
	exec luare_date_par 'GE','ACCIMP',@AccImpDVI output,0,''
	exec luare_date_par 'GE','CODVAM',@CodVam output,0,''
	exec luare_date_par 'GE','BUGETARI',@Bug output,0,''
	exec luare_date_par 'GE','ROTPRETV',@RotPretV output,@SumaRotP output,''
	exec luare_date_par 'GE','FARATVANE',@PAmFaraTVAnx output,0,''
	exec luare_date_par 'GE','STOCPECOM',@SCom output,0,''
	exec luare_date_par 'GE','STOCFURN',@SFurn output,0,''
	exec luare_date_par 'GE','COTATVA',0,@CotaTVAGen output,''
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

	if @Tip='RC'
		select @Tip='RM',@Discount=-convert(decimal(12,4),@CotaTVAGen*100/(@CotaTVAGen+100)),@Jurnal='RC'
	
	if isnull(@Tip,'')='' 
		set @Tip='RM'
	
	exec iauNrDataDoc @Tip,@Numar output,@Data output,0
	
	if isnull(@Stare,0)=0
		set @Stare=3

	select @TipN='',@CotaTVAN=0,@PAmN=0,@GrN='',@GreutN=0
	select @TipN=tip,@CotaTVAN=cota_TVA,
		--Nu mai lucram tu preturile din nomenclator 
		--@PAmN=pret_cu_amanuntul,
		@GrN=grupa,@GreutN=greutate_specifica,
		@Barcod=(case when @Tip<>'RS' and @CodVam=1 and isnull(@DVI,'')<>'' and tip<>'R' and tip<>'F' then substring(tip_echipament,2,20) else isnull(@Barcod,'') end)
	from nomencl
	where cod=isnull(@Cod,'')

	--Pretul cu amanuntul se ia din tabela de preturi aferent categoriei 1. Poate ca trebuie verificata categoria de pret pe gestiune(Andrey: se face in wiapreturi)
	if isnull(@PAmN,0)=0
	begin
		create table #preturi(cod varchar(20),nestlevel int)
		insert into #preturi
		select @Cod,@@NESTLEVEL

		exec CreazaDiezPreturi
		exec wIaPreturi @sesiune='',@parXML=null
		
		select @pamn=pret_amanunt from #preturi where cod=@cod
	end
	/* Tip tert reprezinta Tert Intern =0, Ue =1, Tert Extern=2*/
	set @TipTert=0
	select @TipTert=zile_inc
	from infotert
	where subunitate=@Sb and tert=@Tert and identificator=''

	if isnull(@TotCant,0)=0 
		set @TotCant=isnull(@Cantitate,0)
	set @AccCump=@TotCant

	/*	Pentru receptii cu DVI, cota TVA=0. */
	if left(@CtStoc,1)='8' or @Tip<>'RS' and @TipTert<>0 and isnull(@DVI,'')<>'' and isnull(@Valuta,'')<>''
		set @CotaTVA=0
	
	if @CotaTVA is null
		set @CotaTVA=(case when @DVE=1 and @Tip<>'RS' and isnull(@DVI,'')<>'' /*or not (left(@CtStoc,1)='8' or @Tip<>'RS' and @TipTert<>0 and isnull(@DVI,'')<>'' and isnull(@Valuta,'')<>'')*/ then @CotaTVAN else 0 end)

	if ISNULL(@SumaTVA,0)=0
		set @SumaTVA=(case when @DVE=1 and @Tip<>'RS' and isnull(@DVI,'')<>'' then 0 else round(convert(decimal(17,4),isnull(@PretFurn,0)*(1+isnull(@Discount,0)/100)*(case when isnull(@Valuta,'')<>'' then isnull(@Curs,0) else 1 end)*isnull(@Cantitate,0)*@CotaTVA/100),2) end)

	if @subtip<>'ST' --isnull(@PStoc,0)=0
	set @PStoc=convert(decimal(17,5),
		(isnull(@PretFurn,0)-(case when @TLit=1 or @TLitR=1 then @GreutN else 0 end))
		--*(case when @Discount<>0 or @Valuta<>'' then 1+(case when @Jurnal='RC' and @discount<>0 then -@CotaTVA/(100+@cotatva) else isnull(@Discount,0)/100 end) else 1 end)
		-- daca pretul de stoc va contine si TVA-ul nu mai aplic "discountul" de RC, deoarece nu voi aplica nici Cota de TVA:
		*(case when @Discount<>0 and @Valuta='' and @Jurnal='RC' then 1-@CotaTVA/(100+@cotatva) else 1 end)
		-- Lucian (mai sus): totusi la RC pt. pret de stoc trebuie scos TVA-ul din pretul introdus
		*(case when /*@TipTVA=3 and */(@Tip='RS' or isnull(@DVI,'')='') and @Jurnal<>'RC' then 1+isnull(@Discount,0)/100 else 1 end)
		*(case when isnull(@Valuta,'')<>'' then isnull(@Curs,0) else 1 end)
		*(case when @TipTVA=3 and (@Tip='RS' or isnull(@DVI,'')='') and @Jurnal<>'RC' and 1=0 then 1+@CotaTVA/100 else 1 end)
		+(case when @TipTVA=3 and (@Tip='RS' or isnull(@DVI,'')='') and @Jurnal<>'RC' then @SumaTVA/@cantitate else 0 end)
		)
	if (isnull(@Cantitate,0)<=-0.001) and isnull(@CodIntrare,'')=''
	begin
		declare @TipGest char(1)
		set @TipGest=isnull((select tip_gestiune from gestiuni where subunitate=@Sb and cod_gestiune=isnull(@Gest,'')),'')
		select top 1 @CodIntrare=cod_intrare,@CtStoc=(case when isnull(@CtStoc,'')='' then cont else @CtStoc end),
			@PretAmPrim=(case when isnull(@PretAmPrim,0)=0 then pret_cu_amanuntul else isnull(@PretAmPrim,0) end)
		from stocuri
		where subunitate=@Sb and tip_gestiune=@TipGest and cod_gestiune=isnull(@Gest ,'')and cod=isnull(@Cod,'')
		and (isnull(@CtStoc,'')='' or cont=@CtStoc) and abs(pret-@PStoc)<0.00001
		and (@TipGest<>'A' or isnull(@PretAmPrim,0)=0 or abs(pret_cu_amanuntul-isnull(@PretAmPrim,0))<0.00001)
		and stoc-abs(isnull(@Cantitate,0))>=0.001 and data<=@Data and (@SFurn=0 or furnizor='' or furnizor=@Tert)
		order by (case when @SFurn=1 and furnizor<>'' then 0 else 1 end),data
	end
	if isnull(@PretAmPrim,0)=0
		set @PretAmPrim=(case when @TipN='R' then 0 else @PAmN end)

	if isnull(@CtStoc,'')=''
		set @CtStoc=dbo.formezContStoc(isnull(@Gest,''),isnull(@Cod,''),isnull(@LM,''))

	/* La Stornare avans, daca s-a completat factura de avans, caut in tabela facturi contul facturii de avans. Daca este, contul facturii de avans devine cont de stoc. */
	if @update=0 and @TipN='R' and isnull(@CodIntrare, '') <> '' and isnull(@Cantitate,0)<=-0.001
			and exists (select 1 from conturi where subunitate = @Sb and cont = @CtStoc and sold_credit = 1)
		select @CtStoc = fa.Cont_de_tert from facturi fa where fa.Subunitate=@Sb and fa.tip=0x54 and fa.Tert=@tert and fa.Factura=@CodIntrare

	if isnull(@CtFact,'')='' or left(@CtStoc,1)='8'
		set @CtFact=(case when left(@CtStoc,1)='8' then '' else isnull((select max(cont_ca_furnizor) from terti where subunitate=@Sb and tert=@Tert),'') end)

	if isnull(@Valuta,'')<>'' and (@Tip='RS' or isnull(@DVI,'')='') and @RotPretV=1 and abs(@SumaRotP)>=0.00001 and exists (select 1 from sysobjects where type in ('FN','IF') and name='rot_pret')
		set @PStoc=dbo.rot_pret(@PStoc,@SumaRotP)

	select @Valoare=isnull(@Valoare,0)+round(convert(decimal(17,3),isnull(@Cantitate,0)*@PStoc),2),
		@ValTVA=isnull(@ValTVA,0)+@SumaTVA,
		@DiscSuma=isnull(@DiscSuma,0)+(case when left(@CtStoc,1)='8' then round(convert(decimal(17,3),isnull(@Cantitate,0)*@PStoc),2) else 0 end),
		@ValValuta=isnull(@ValValuta,0)+(case when isnull(@Valuta,'')<>'' then round(convert(decimal(17,3),isnull(@Cantitate,0)*isnull(@PretFurn,0)*(1+(case when @Tip='RS' or isnull(@DVI,'')='' then isnull(@Discount,0) else 0 end)/100)+(case when isnull(@Valuta,'')<>'' and isnull(@Curs,0)>0 then convert(decimal(14,2),@SumaTVA/isnull(@Curs,0)) else 0 end)),2) else 0 end)
		--@TotCant=isnull(@TotCant,0)+@Cantitate,
		
	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)	
		
	set @TVAnx=(case when @PAmFaraTVAnx=1 or @TipN='R' then 0 else @CotaTVAN end)
	set @CtTVAnxPrim=(case when @Bug=0 and @TipN='F' then '' when @Bug=0 then RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@Gest,'')) else '' end) when @TipN='O' then '311' when @TipN<>'F' then '' when left(@CtStoc,2)='02' then '312' else '309' end)
	set @CtAdPrim=(case when @TipN='F' then '' else RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@Gest,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrN) else '' end) end)

	declare @CtTVA varchar(40),@Ct4426 varchar(40)
	exec luare_date_par 'GE','CDTVA',0,0,@Ct4426 output
	set @CtTVA=@Ct4426
	/*Cont Tva*/
	if @SumaTVA<>0
	begin
		declare @Ct4428AV varchar(40),@Ct4428LaInc varchar(40)
		exec luare_date_par 'GE','CNEEXREC',0,0,@Ct4428AV output
		exec luare_date_par 'GE','CNTLIFURN',0,0,@Ct4428LaInc output

		set @CtTVA=(case when @ContTvaPrimit<>'' then @ContTvaPrimit 
			when left(@CtStoc,1)='8' then '' 
			when left(@CtFact,3)='408' then @Ct4428AV
			else @Ct4426 end)
	end
	else
		set @CtTVA = '' -- la un eventual update, se actualizeaza?


	set @Grupa=(case when @DVE=1 and @Tip<>'RS' and isnull(@DVI,'')<>'' then '' when @TLitR=1 then @CtAccize else '' end)
	set @Grupa=(case when @DVE=1 and @tip<>'RS' and isnull(@DVI,'')<>'' or @TLitR=1 or not (isnull(@valuta,'')<>'' and (@tip='RS' or isnull(@DVI,'')='') and isnull(@Curs,0)<>0) then @Grupa else convert(char(13),convert(decimal(14,2),(@SumaTVA)/isnull(@Curs,0))) end)
	set @AccCump=(case when @TipN<>'F' and (@TLit=1 or @TLitR=1) then @GreutN else @AccCump end)
	if isnull(@DataExp,'01/01/1901')<='01/01/1901'
		set @DataExp=@Data

	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
		set @areDetalii = 1

	select 			
		@dataOperarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104),
		@oraOperarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', ''))

	-----start adaugare pozitie noua in pozdoc-----
	if @update=0 and @subtip<>'SE'
	begin
		if isnull(@CodIntrare,'')=''--daca nu s-a introdus un cod de intrare, se genereaza din program 
			set @CodIntrare=dbo.formezCodIntrare(@Tip,@Numar,@Data,isnull(@Cod,''),isnull(@Gest,''),@CtStoc,@PStoc)
	
		exec luare_date_par 'DO','POZITIE',0,@NrPozitie output,''--alocare numar pozitie
		set @NrPozitie=@NrPozitie+1	
		
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
		begin --daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			select @cod = (case when @Cod is null then '' else @cod end ),
				@Gest = (case when @Gest is null then '' else @Gest end),
				@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end)
			exec wScriuPDserii @tip, @Numar, @Data, @Gest, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
			set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip=@Tip and Numar=@Numar and data=@Data and Gestiune=isnull(@gest,'') and cod=isnull(@Cod,'') 
														  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
		end
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------

		IF OBJECT_ID('tempdb..#RMInserat') IS NOT NULL
			DROP TABLE #RMInserat

		CREATE TABLE #RMInserat (idPozDoc INT)

		SET @comandaSql = N'
				INSERT pozdoc (
					Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
					Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
					Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
					Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
					Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
					Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+'
					)
				OUTPUT inserted.idPozDoc INTO #RMInserat(idPozDoc)
				VALUES (	
				@Sb,@Tip,@Numar,isnull(@Cod,''''),@Data,isnull(@Gest,''''),isnull(@Cantitate,0),isnull(@PretFurn,0),@PStoc,
				(case when @PStoc>0 then round(convert(decimal(10,3),(isnull(@PretAmPrim,0)/(1+@TVAnx/100)/@PStoc-1)*100),2) else 0 end),0,isnull(@PretAmPrim,0),
				@SumaTVA,isnull(@CotaTVA,0),isnull(@Utilizator,''''),@dataoperarii,@oraoperarii,@CodIntrare,isnull(@CtStoc,''''),ISNULL(@lot,''''),
				@TVAnx,0,(case when isnull(@TipN,'''') in (''F'',''R'') then ''V'' else ''I'' end),isnull(@Locatie,''''),@DataExp,@NrPozitie,
				isnull(@LM,''''),isnull(@Comanda,''''),isnull(@Barcod,''''),@CtTVAnxPrim,@CtTVA,isnull(@Discount,0),@Tert,isnull(@Fact,''''),
				@CtAdPrim,isnull((case when @tip=''RS'' then @Explicatii else @DVI end),''''),@Stare,@Grupa,isnull(@CtFact,''''),isnull(@Valuta,''''),
				isnull(@Curs,0),@DataFact,@DataScad,@TipTVA,0,@AccCump,0,isnull(@ComAprov,''''),isnull(@Jurnal,''''),
				(case when @subtip=@tip then null else @subtip end)'
			+(case when @areDetalii=1 then ', @detalii' else '' end)+')'

			exec sp_executesql @statement=@comandaSql, @params=N'
				@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20), 
				@Data DATETIME, @Gest CHAR(9), @Cantitate FLOAT,@PStoc FLOAT, @PretFurn float,
				@PretAmPrim FLOAT, @SumaTVA FLOAT, @CotaTVA FLOAT, @Utilizator CHAR(10),@lot varchar(13), @dataOperarii datetime, @oraOperarii varchar(50), 
				@CodIntrare CHAR(13), @CtStoc VARCHAR(40), @TVAnx FLOAT,@TipN varchar(1), @Locatie CHAR(30), 
				@DataExp DATETIME, @NrPozitie INT, @LM CHAR(9), @Comanda CHAR(40), @Barcod CHAR(30),@CtTVAnxPrim VARCHAR(40),@CtTVA VARCHAR(40),
				@Discount FLOAT, @Tert CHAR(13), @Fact CHAR(20), @CtAdPrim VARCHAR(40), @Explicatii varchar(30), @DVI varchar(30), @Stare INT, @grupa char(13),
				@Curs FLOAT, @DataFact DATETIME,  @DataScad DATETIME,@TipTVA int,@CtFact VARCHAR(40), @valuta char(3),				
				@AccCump FLOAT, @ComAprov CHAR(20),@Jurnal CHAR(3),@subtip varchar(2)',
				@detalii = @detalii, @Sb=@Sb, @Tip=@Tip, @Numar=@Numar, @cod=@cod, @Data=@Data, @gest=@gest, @Cantitate=@Cantitate, @PretFurn=@PretFurn,
				@PStoc=@PStoc, @PretAmPrim=@PretAmPrim, @SumaTVA=@SumaTVA, @CotaTVA=@CotaTVA, @Utilizator=@Utilizator, @lot=@lot,@dataOperarii=@dataOperarii,
				@oraOperarii=@oraOperarii, @CodIntrare=@CodIntrare, @CtStoc=@CtStoc, @TVAnx=@TVAnx, @TipN=@TipN,@Locatie=@Locatie, @DataExp=@DataExp, 
				@NrPozitie=@NrPozitie,@LM=@LM, @Comanda=@Comanda, @Barcod=@Barcod,@CtTVAnxPrim=@CtTVAnxPrim,@CtTVA=@CtTVA,@Discount=@Discount, @Tert=@Tert, 
				@Fact=@Fact, @CtAdPrim=@CtAdPrim,@Explicatii=@Explicatii,@DVI=@DVI,@Stare=@Stare,@grupa=@grupa,@valuta=@valuta,@CtFact=@CtFact,@Curs=@Curs,
				@DataFact=@DataFact,@DataScad=@DataScad,@TipTVA=@TipTVA,@AccCump=@AccCump,@ComAprov=@ComAprov,@Jurnal=@Jurnal,@subtip=@subtip	

		SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #RMInserat
				FOR XML raw, root('Inserate')
				)	
		
		if ISNULL(@text_alfa2,'')<>''
			insert into textpozdoc (Subunitate,Tip,Numar,Data,Numar_pozitie,Explicatii,Tara_de_origine,Alfa1,Alfa2,Alfa3,Val1,Val2,Val3,Data1,Data2,Data3,Logic)
			values (@Sb,@Tip,@Numar,@Data,@NrPozitie,'','','',@text_alfa2,'',0,0,0,'1901-01-01','1901-01-01','1901-01-01',0)
				
		exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
			
	end
	-----stop adaugare pozitie noua in pozdoc-----
	
	-----start modificare pozitie existenta in pozdoc----
	if @update=1 or @subtip='SE'--situatia in care se modifica o pozitie din pozdoc sau se adauga pozitie cu subtip SE->serie in cadrul pozitiei din pozdoc
	begin
		
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
		begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			select @cod = (case when @Cod is null then '' else @cod end ),
				@Gest = (case when @Gest is null then '' else @Gest end),
				@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end)
			exec  wScriuPDserii @Tip,@Numar,@Data,@Gest,@Cod,@CodIntrare,@NrPozitie,@Serie,@Cantitate,''
			set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip=@Tip and Numar=@Numar and data=@Data and Gestiune=isnull(@gest,'') and cod=isnull(@Cod,'') 
														  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
		end
		
		if @subtip='SE'
		begin --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
			update pozdoc set Cantitate=(case when isnull(@Cantitate,0)<>0 then @Cantitate else Cantitate end)
			where subunitate=@Sb and tip=@tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
		end				
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
		
		else	
			SET @comandaSql = N'
				UPDATE pozdoc
				SET '+	
					(case when @Cod is null then '' else 'Cod=@cod' end)+
					(case when @Gest is null then '' else ',Gestiune =@Gest' end)+
					(case when @Cantitate is null then ''  else ',Cantitate=convert(decimal(17,3),@Cantitate)' end)+
					(case when @PretFurn is null then '' else ',Pret_valuta=convert(decimal(17,5),@PretFurn)' end)+
					(case when @PStoc is null then '' else ',Pret_de_stoc=convert(decimal(17,5),@PStoc)' end)+
					(case when @PStoc>0 then ',adaos=round(convert(decimal(10,3),(isnull(@PretAmPrim,0)/(1+@TVAnx/100)/@PStoc-1)*100),2)' else ',adaos=0' end)+
					(case when @PretAmPrim is null then '' else  ',Pret_cu_amanuntul=convert(decimal(17,5),@PretAmPrim)' end)+
					(case when @SumaTVA is null then  '' else ',TVA_deductibil=convert(decimal(17,5),@SumaTVA)' end)+
					(case when @CotaTVA is null then '' else ',Cota_TVA=convert(decimal(17,5),@CotaTVA)' end)+
					',utilizator=@Utilizator'+
					',data_operarii=@dataoperarii'+
					',ora_operarii=@oraoperarii'+
					(case when @CodIntrare is null then '' else ',Cod_intrare=@CodIntrare' end)+
					(case when @CtStoc is null then '' else  ',Cont_de_stoc =@CtStoc' end)+
					(case when @Lot is null then '' else ',Cont_corespondent=@Lot' end)+--cont_corespondent -> Lot
					(case when @TVAnx is null then '' else ',TVA_neexigibil=convert(decimal(11,5),@TVAnx)' end)+
					(case when @Locatie is null then '' else ',Locatie=@Locatie' end)+
					(case when @DataExp is null then '' else ',Data_expirarii =@DataExp' end)+
					(case when @LM is null then '' else ',Loc_de_munca =@LM' end)+
					(case when @Comanda is null then ''  else ',Comanda=@Comanda' end)+
					(case when @Barcod is null then '' else ',Barcod=@Barcod' end)+				
					(case when @CtTVAnxPrim is null then '' else ',Cont_intermediar=@CtTVAnxPrim' end)+
					(case when @CtTVA is null then '' else ',Cont_venituri=@CtTVA' end)+
					(case when @Discount is null then '' else ',Discount=convert(decimal(11,5),@Discount)' end)+
					(case when @Fact is null then '' else ',Factura=@Fact' end)+
					(case when @CtAdPrim is null then '' else ',Gestiune_primitoare=@CtAdPrim' end)+
					(case when @tip='RS'  then (case when @Explicatii is null then '' else ',numar_dvi=@explicatii' END) 
						when @DVI is null then ''  else ',numar_dvi=@DVI' end)+				
					(case when @Stare is null then '' else ',Stare=@Stare' end)+
					(case when @DVE=1 and @tip<>'RS' and @dvi<>'' or @TLitR=1 or not 
					(@valuta<>'' and (@tip='RS' or @dvi='') and @curs<>0) then '' else 
						',grupa=convert(char(13),convert(decimal(14,2),(@SumaTVA)/isnull(@Curs,0)))' end)+	--TVA_deductibil Nu e cazul sa se adauge TVA_deductibil+@SumaTVA la scriere in pozdoc
					(case when @CtFact is null then ''  else ',Cont_factura=@CtFact' end)+
					(case when @Valuta is null then ''  else ',Valuta=@Valuta' end)+
					(case when @Curs is null then  '' else ',Curs =convert(decimal(11,4),@Curs)' end)+
					(case when @DataFact is null then ''  else ',Data_facturii=@DataFact' end)+
					(case when @DataScad is null then '' else ',Data_scadentei=@DataScad' end)+
					(case when @TipTVA is null then '' else ',Procent_vama =@TipTVA' end)+
					(case when @AccCump is null then ''  else ',Accize_cumparare=convert(decimal(11,3),@AccCump)' end)+
					(case when @ComAprov is null then '' else ',Contract=substring(@ComAprov, 9, 8)' end)+			
					(case when @Jurnal is null then '' else ',Jurnal =@Jurnal' end)	+
					(CASE WHEN @areDetalii=1 THEN ', detalii = @detalii' else '' end)+	
								
				' WHERE subunitate = @Sb
				AND tip = @tip
				AND numar = @Numar
				AND data = @Data
				AND numar_pozitie = @NrPozitie '	
		
			exec sp_executesql @statement=@comandaSql, @params=N'
				@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20), 
				@Data DATETIME, @Gest CHAR(9), @Cantitate FLOAT,@PStoc FLOAT, @PretFurn float,
				@PretAmPrim FLOAT, @SumaTVA FLOAT, @CotaTVA FLOAT, @Utilizator CHAR(10),@lot varchar(13), @dataOperarii datetime, @oraOperarii varchar(50), 
				@CodIntrare CHAR(13), @CtStoc VARCHAR(40), @TVAnx FLOAT,@TipN varchar(1), @Locatie CHAR(30), 
				@DataExp DATETIME, @NrPozitie INT, @LM CHAR(9), @Comanda CHAR(40), @Barcod CHAR(30), @CtTVAnxPrim VARCHAR(40), @CtTVA VARCHAR(40),
				@Discount FLOAT, @Tert CHAR(13), @Fact CHAR(20), @CtAdPrim VARCHAR(40), @Explicatii varchar(30), @DVI varchar(30), @Stare INT, @grupa char(13),
				@Curs FLOAT, @DataFact DATETIME,  @DataScad DATETIME, @TipTVA int, @CtFact VARCHAR(40), @valuta char(3),				
				@AccCump FLOAT, @ComAprov CHAR(20),@Jurnal CHAR(3),@subtip varchar(2)',
				@detalii = @detalii, @Sb=@Sb, @Tip=@Tip, @Numar=@Numar, @cod=@cod, @Data=@Data, @gest=@gest, @Cantitate=@Cantitate, @PretFurn=@PretFurn,
				@PStoc=@PStoc, @PretAmPrim=@PretAmPrim, @SumaTVA=@SumaTVA, @CotaTVA=@CotaTVA, @Utilizator=@Utilizator, @lot=@lot,@dataOperarii=@dataOperarii,
				@oraOperarii=@oraOperarii, @CodIntrare=@CodIntrare, @CtStoc=@CtStoc, @TVAnx=@TVAnx, @TipN=@TipN,@Locatie=@Locatie, @DataExp=@DataExp, 
				@NrPozitie=@NrPozitie,@LM=@LM, @Comanda=@Comanda, @Barcod=@Barcod,@CtTVAnxPrim=@CtTVAnxPrim,@CtTVA=@CtTVA,@Discount=@Discount, @Tert=@Tert, 
				@Fact=@Fact, @CtAdPrim=@CtAdPrim,@Explicatii=@Explicatii,@DVI=@DVI,@Stare=@Stare,@grupa=@grupa,@valuta=@valuta,@CtFact=@CtFact,@Curs=@Curs,
				@DataFact=@DataFact,@DataScad=@DataScad,@TipTVA=@TipTVA,@AccCump=@AccCump,@ComAprov=@ComAprov,@Jurnal=@Jurnal,@subtip=@subtip	
			
		if ISNULL(@text_alfa2,'')<>'' 			
		begin	
			if not exists(select 1 from textpozdoc where Subunitate=@sb and Numar=@Numar and tip=@Tip and data=@Data and Numar_pozitie=@NrPozitie)
				insert into textpozdoc (Subunitate,Tip,Numar,Data,Numar_pozitie,Explicatii,Tara_de_origine,Alfa1,Alfa2,Alfa3,Val1,Val2,Val3,Data1,Data2,Data3,Logic)
				values (@Sb,@Tip,@Numar,@Data,@NrPozitie,'','','',@text_alfa2,'',0,0,0,'1901-01-01','1901-01-01','1901-01-01',0)
			else	
				update textpozdoc set 
					Alfa2=(case when @text_alfa2 is null then Alfa2 else @text_alfa2 end)
				where subunitate=@Sb and tip=@tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie	
		end		
			
	end
		-----stop modificare pozitie existenta in pozdoc----
	
	---returnare parametri in @parXmlScriereIesiri ---
	-->numar_pozitie	
	if @parXmlScriereIntrari.value('(/row/@numar_pozitie)[1]','int') is null
		set @parXmlScriereIntrari.modify ('insert attribute numar_pozitie {sql:variable("@NrPozitie")} into (/row)[1]')
	else
		set @parXmlScriereIntrari.modify('replace value of (/row/@numar_pozitie)[1] with sql:variable("@NrPozitie")')
	-->cont_de stoc	
	if @parXmlScriereIntrari.value('(/row/@cont_stoc)[1]','varchar(40)') is null
		set @parXmlScriereIntrari.modify ('insert attribute cont_stoc {sql:variable("@CtStoc")} into (/row)[1]')
	else
		set @parXmlScriereIntrari.modify('replace value of (/row/@cont_stoc)[1] with sql:variable("@CtStoc")')			
	---stop returnare parametrii in @parXmlScriereIesiri---		
	
	--daca se adauga o pozitie pe un RM care are dvi, deschidem macheta pentru DVI pentru refacere repartizare taxe vamale
	--if @tip='RM' and exists(select 1 from pozdoc where Subunitate=@Sb and tip='RM' and Numar=@numar and data=@data and isnull(Numar_DVI,'')<>'')
	--begin
	--	DECLARE @dateInitializare XML	
	--	set @dateInitializare=
	--	(
	--		select convert(char(10), @data, 101) as data, @numar as numar, @tert as tert, @tip as tip
	--		for xml raw ,root('row')
	--	)
	--	SELECT 'Pe aceasta receptie au fost introduse taxe vamale, este necesara actualizarea lor la fiecare modificare a receptiei.'  nume, 'DO' codmeniu, 'D' tipmacheta,'RM' tip,'DV' subtip,'O' fel,convert(char(10), @data, 101) as data, @numar as numar, @tert as tert,
	-- (SELECT @dateInitializare ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	--end
	
	---->in cazul in care se exista pozitii de prestari pe receptie, se apeleaza procedura de repartizare prestari pe pozitiile receptiei
	--if exists (select 1 from pozdoc where tip ='RP' and Subunitate=@Sb and Numar=@numar and data=@data)
	--	exec repartizarePrestariReceptii 'RM', @numar, @data	
		
	-->returnare idPozDoc
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIntrari = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIntrari) + convert(VARCHAR(max), @docInserate))	
		
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
