/****** Object:  StoredProcedure [dbo].[wScriuPozCon]    Script Date: 03/21/2012 11:58:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--***
ALTER procedure [dbo].[wScriuPozCon] @sesiune varchar(50), @parXML xml 
as 
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @termen datetime, @termene datetime, @data1 datetime, @lm char(9), @modplata char(8), @o_modplata char(8),
	@info1_antet char(13), @info2_antet float, @info3_antet float, @info4_antet float, @info5_antet float, @info6_antet char(20), 
	@numar_pozitie int, @cod char(20), @o_cod char(20), @cantitate float, @Tcantitate float, @cantitate_UM1 float, @cantitate_UM2 float, @cantitate_UM3 float, 
	@cod_intrare char(13), @cota_TVA float, @pret float, @Tpret float, @valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5), 
	@categ_pret int, @lot char(200), @data_expirarii datetime, @obiect varchar(20), 
	@info1_pozitii float, @info2_pozitii char(13), @info3_pozitii float, @info4_pozitii char(200), @info5_pozitii char(13), 
	@info6_pozitii datetime, @info7_pozitii datetime, @info8_pozitii float, @info9_pozitii float, @info10_pozitii float, @info11_pozitii float, 
	@info12_pozitii varchar(200), @info13_pozitii varchar(200), @info14_pozitii varchar(200), @info15_pozitii varchar(200), @info16_pozitii varchar(200), @info17_pozitii varchar(200), 
	@tipGrp char(2), @numarGrp char(20), @tertGrp char(20), @dataGrp datetime, @sir_numere_pozitii varchar(max), 
	@sub char(9), @CantAprob0BKBP int, @TermPeSurse int, @docXMLIaPozContract xml, @userASiS varchar(20), 
	@gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),
	@categPretProprietate varchar(20), @stare char(1), @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @subtip char(2), 
	@eroare xml,@mesajj varchar(20),@contclient varchar(20),@procpen float,@update int,@Ttermen datetime,
	@Gluni int, @nr int, @scadenta int , @periodicitate int,@explicatii_pozitii varchar(50),@mesaj varchar(200),
	@contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),@gestdepozitBK varchar(20),
	@T1 float,@T2 float,@T3 float,@T4 float,@T5 float,@T6 float,@T7 float,@T8 float,
	@T9 float,@T10 float,@T11 float,@T12 float

begin try
	--BEGIN TRAN
	 
		set @eroare = dbo.wfValidareContract(@parXML)
		begin
			set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
			if @mesaj<>''
			raiserror(@mesaj, 11, 1)
		end	
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConSP')
	begin
		exec wScriuConSP @sesiune=@sesiune, @parXML=@parXML output
		select 'Atentie: se apeleaza procedura wScriuConSP din procedura wScriuPozCon. Contactati distribuitorul aplicatiei pt. a '+
			'corecta functionarea aplicatiei(apelare wScriuPozConSP).' as textMesaj, 'Functionare nerecomandata' as titluMesaj
		for xml raw,root('Mesaje')
	end
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozConSP')
		exec wScriuPozConSP @sesiune=@sesiune, @parXML=@parXML output
	
	select	@update = isnull(@parXML.value('(/row/row/@update)[1]','int'),''),
			@Ttermen = isnull(@parXML.value('(/row/row/@Ttermen)[1]','datetime'),''),
			@gestProprietate='', @clientProprietate='', @lmProprietate='',@gestdepozitBK=''
	
	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),
			@CantAprob0BKBP=isnull((case when Parametru='CNAZBKBP' then Val_logica else @CantAprob0BKBP end),0),
			@TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('CNAZBKBP','POZSURSE'))

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	
	select @gestProprietate=(case when cod_proprietate='GESTBK' then valoare else isnull(@gestProprietate,'') end), 
		@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else isnull(@clientProprietate,'') end), 
		@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else isnull(@lmProprietate,'') end),
		@gestdepozitBK=(case when cod_proprietate='GESTDEPBK' then valoare else isnull(@gestdepozitBK,'') end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTBK', 'CLIENT', 'LOCMUNCA','GESTDEPBK') and valoare<>''
	
	set @stare=0
	set @categPretProprietate=isnull((select max(sold_ca_beneficiar) from terti where tert=@clientProprietate), 0)
	if @categPretProprietate=0
		set @categPretProprietate=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestProprietate), 1)
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozcon cursor for
	select tip, upper([contract]), data, 
	upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else ''/*@gestProprietate*/ end)) as gestiune, 
	upper(isnull(gestiune_primitoare, '')) as gestiune_primitoare, 
	upper((case when isnull(tert, '')<>'' then tert when tip in ('BF', 'BK', 'BP') then ''/*@clientProprietate*/ else '' end)) as tert, 
	upper(isnull(factura, '')) as factura, 
	--extcon
	isnull(contclient,'') as contclient,
	isnull(procpen,'') as procpen,
	isnull(contr_cadru,'') as contr_cadru,
	isnull(ext_camp4,'') as ext_camp4,
	isnull(ext_camp5,'1901-01-01') as ext_camp5,
	isnull(ext_modificari,'') as ext_modificari,
	isnull(ext_clauze,'') as ext_clauze,
	
	isnull(termen_pozitii, isnull(termen_antet, data)) as termen, 
	isnull(subtip, tip) as subtip, 
	isnull(scadenta,0) as scadenta,
	--termene
	isnull(termene, data) as termene,
	isnull(data1,data) as data1,
	
	upper(case when isnull(lm,'')<>'' then lm else @lmProprietate end) as lm, 
	isnull(info1_antet, '') as info1_antet, isnull(info2_antet, 0) as info2_antet, isnull(info3_antet, 0) as info3_antet, 
	isnull(info4_antet, 0) as info4_antet, isnull(info5_antet, 0) as info5_antet, isnull(info6_antet, '') as info6_antet, 
	isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod, isnull(o_cod,'') as o_cod, 
	isnull(cantitate, 0) as cantitate, 
	--termene
	isnull(Tcantitate, 0) as Tcantitate,
	isnull(cantitate_UM1, 0) as cantitate_UM1, isnull(cantitate_UM2, 0) as cantitate_UM2, isnull(cantitate_UM3, 0) as cantitate_UM3, 
	pret, 
	
	--termene
	Tpret,
	
	cota_TVA, 
	upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(explicatii_pozitii,'')as explicatii_pozitii, upper(isnull(explicatii,'')) as explicatii, 
	discount, isnull(punct_livrare, '') as punct_livrare, upper(isnull(modplata, '')) as modplata, isnull(o_modplata,'') as o_modplata, 
	(case when isnull(categ_pret,0)=0 then @categPretProprietate else isnull(categ_pret,0) end) as categ_pret, 
	upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901') as data_expirarii, isnull(obiect, '') as obiect, 
	isnull(info1_pozitii, 0) as info1_pozitii, isnull(info2_pozitii, '') as info2_pozitii, 
	isnull(info3_pozitii, 0) as info3_pozitii, isnull(info4_pozitii, '') as info4_pozitii, isnull(info5_pozitii, '') as info5_pozitii, 
	--isnull(info6_pozitii, '01/01/1901') as info6_pozitii, 
	--isnull(info7_pozitii, '01/01/1901') as info7_pozitii, 
	isnull(info8_pozitii, 0) as info8_pozitii, isnull(info9_pozitii, 0) as info9_pozitii, isnull(info10_pozitii, 0) as info10_pozitii, isnull(info11_pozitii, 0) as info11_pozitii, isnull(info12_pozitii, '') as info12_pozitii, isnull(info13_pozitii, '') as info13_pozitii, isnull(info14_pozitii, '') as info14_pozitii, isnull(info15_pozitii, '') as info15_pozitii, isnull(info16_pozitii, '') as info16_pozitii, isnull(info17_pozitii, '') as info17_pozitii, 
	isnull(Gluni,0) as Gluni,	isnull(periodicitate,0) as periodicitate
		
	from OPENXML(@iDoc, '/row/row') 
	WITH 
	(
		tip char(2) '../@tip', 
		[contract] char(20) '../@numar',
		data datetime '../@data',
		gestiune_antet char(9) '../@gestiune',
		gestiune_primitoare char(13) '../@gestprim', 
		tert char(13) '../@tert',
		punct_livrare char(5) '../@punctlivrare', 
		modplata char(8) '@modplata', 
		o_modplata char(8) '@o_modplata', 
		factura char(20) '../@factura',
		--extcon
		contclient varchar(10) '../@contclient',
		procpen varchar(10) '../@procpen',
		contr_cadru varchar(50) '../@contr_cadru',
		ext_camp4 varchar(50) '../@ext_camp4',
		ext_camp5 datetime '../@ext_camp5',
		ext_modificari varchar(50) '../@ext_modificari',
		ext_clauze varchar(500)'../@ext_clauze',
		
		
		termen_antet datetime '../@termen',
		termen_pozitii datetime '@termen',
		subtip char(2) '@subtip',
		scadenta int '../@scadenta', 
		
		--termene
		termene datetime '@termene',
		data1 datetime '@data1',
		
		lm char(9) '../@lm',
		explicatii char(50) '../@explicatii', 
		info1_antet char(13) '../@info1', 
		info2_antet float '../@info2', 
		info3_antet float '../@info3', 
		info4_antet float '../@info4', 
		info5_antet float '../@info5', 
		info6_antet char(20) '../@info6', 
		numar_pozitie int '@numarpozitie',
		cod char(20) '@cod',
		o_cod char(20) '@o_cod',
		cantitate decimal(17, 5) '@cantitate',
		--termene
		Tcantitate decimal(17, 5) '@Tcantitate',
		cantitate_UM1 decimal(17, 5) '@cantitateum1',
		cantitate_UM2 decimal(17, 5) '@cantitateum2',
		cantitate_UM3 decimal(17, 5) '@cantitateum3',
		cota_TVA decimal(5, 2) '@cotatva', 
		gestiune_pozitii char(9) '@gestiune', 
		pret float '@pret', 
		
		--termene
		Tpret float '@Tpret',
		
		valuta char(3) '../@valuta', 
		curs float '@curs', 
		discount float '@discount', 
		categ_pret int '@categpret', 
		lot char(200) '@lot', 
		data_expirarii datetime '@dataexpirarii', 
		obiect varchar(20) '@obiect', 
		explicatii_pozitii char(200) '@explicatii', 
		info1_pozitii float '@info1', 
		info2_pozitii char(13) '@info2', 
		info3_pozitii float '@info3', 
		info4_pozitii char(200) '@info4', 
		info5_pozitii char(13) '@info5', 
		--info6_pozitii datetime '@info6', 
		--info7_pozitii datetime '@info7', 
		info8_pozitii float '@info8', 
		info9_pozitii float '@info9', 
		info10_pozitii float '@info10', 
		info11_pozitii float '@info11', 
		info12_pozitii varchar(200) '@info12', 
		info13_pozitii varchar(200) '@info13', 
		info14_pozitii varchar(200) '@info14', 
		info15_pozitii varchar(200) '@info15', 
		info16_pozitii varchar(200) '@info16', 
		info17_pozitii varchar(200) '@info17',
		Gluni int '@Gluni',
		periodicitate int '@periodicitate'
	) 

	open crspozcon
	fetch next from crspozcon into @tip, @contract, @data, @gestiune, @gestiune_primitoare, 
		@tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze, @termen, @subtip, 
		@scadenta,
		--termene
		@termene, @data1, 
		
		@lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet, 
		@numar_pozitie, @cod, @o_cod, @cantitate, 
		
		--termene
		@Tcantitate, 
		
		@cantitate_UM1, @cantitate_UM2, @cantitate_UM3, 
		@pret, 
		
		--termene
		@Tpret,
		
		@cota_tva, @valuta, @curs,@explicatii_pozitii, @explicatii, @discount, @punct_livrare, @modplata,@o_modplata, @categ_pret, 
		@lot, @data_expirarii, @obiect, @info1_pozitii, @info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii, 
		--@info6_pozitii, @info7_pozitii, 
		@info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii, 
		@info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, @info17_pozitii, 
		@Gluni, @periodicitate
	while @@fetch_status = 0
	begin 
		if @tip in ('BF', 'BK', 'BP') and @tert='' set @tert=@clientProprietate
		if @tip in ('BF', 'BK', 'BP') 
		begin
			if @gestiune='' and (@gestdepozitBK<>'') 
				set @gestiune=@gestdepozitBK
			if @gestiune_primitoare='' and (@gestiune='' or @gestiune<>@gestProprietate) 
				set @gestiune_primitoare=@gestProprietate
		end
		if @gestiune='' and (@tip not in ('BF', 'BK', 'BP') or @gestiune_primitoare='' or @gestiune_primitoare<>@gestProprietate) 
			set @gestiune=@gestProprietate
		if @cantitate=0
			select @cantitate=@cantitate_UM1+@cantitate_UM2*(case when UM_1<>'' then Coeficient_conversie_1 else 0 end)+@cantitate_UM3*(case when UM_2<>'' then Coeficient_conversie_2 else 0 end) from nomencl where cod=@cod
		if @lm='' or @lm is null
			set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')
		if @cota_tva is null 
			set @cota_TVA=ISNULL((select max(cota_tva) from nomencl where cod=@cod),24) 
		if isnull(@contract, '')=''
		begin
			declare @fXML xml, @NrDocPrimit varchar(20)
			
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			
			exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output
			
			if ISNULL(@NrDocPrimit, '')<>''
				set @contract=LTrim(RTrim(CONVERT(char(8), @NrDocPrimit)))
			if isnull(@contract, '')=''
			begin
				declare @ParUltNr char(9), @UltNr int
				set @ParUltNr='NRCNT' + @tip
				exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0
				while @UltNr=0 or exists (select 1 from con where subunitate=@Sub and tip=@tip and contract=rtrim(ltrim(convert(char(9), @UltNr))))
					set @UltNr=@UltNr+1
				set @contract=rtrim(ltrim(convert(char(9), @UltNr)))
				exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null
			end
		end
		
		if @tip in ('BK', 'BP') and (isnull(@pret,0)=0 or isnull(@discount,0)=0)
		begin
			declare @dXML xml, @doc_in_valuta int, @iaupretamanunt int
			set @dXML = '<row/>'
			set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
			declare @dstr char(10)
			set @dstr=convert(char(10),@data,101)			
			set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')
			set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
			set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')
			set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)
			set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')
			set @iaupretamanunt=(case when exists (select 1 from gestiuni where Subunitate=@sub and Cod_gestiune=@gestiune_primitoare and Tip_gestiune in ('A','V')) then 1 else 0 end)
			set @dXML.modify ('insert attribute iaupretamanunt {sql:variable("@iaupretamanunt")} into (/row)[1]')
			if @pret=0 set @pret=null
			exec wIaPretDiscount @dXML, @pret output, @discount output
		end
		select @pret=isnull(@pret, 0), @discount=isnull(@discount, 0)
		if not exists (select 1 from con where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub )and @update='0'
		begin
			if @tip in ('BF','FA') 
				if (@tert='' or @tert is null) 
					raiserror('wScriuPozCon:Nu se poate adauga contract fara completare tert!', 11, 1)
			if exists(select 1 from con where Contract=@contract and tip=@tip and (YEAR(data)=YEAR(@data) or @tip='BF')) 
				raiserror('wScriuPozCon:Numarul acesta de contract a fost deja introdus!', 11, 1)
			insert con 
			(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Stare, Loc_de_munca, Gestiune, Termen, Scadenta, 
			Discount, Valuta, Curs, Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA, 
			Contract_coresp, Mod_penalizare, Procent_penalizare, Procent_avans, Avans, 
			Nr_rate, Val_reziduala, Sold_initial, Cod_dobanda, Dobanda, 
			Incasat, Responsabil, Responsabil_tert, Explicatii, Data_rezilierii)
			select @Sub, @tip, @contract, @tert, @punct_livrare, @data, '0', @lm, @gestiune, @termen, @scadenta, 
			(case when @tip in ('BF', 'FA') then @Discount else @info5_antet end), @Valuta, @Curs, '', '', @Factura, 0, 0, 
			'', @info1_antet, @info4_antet, 0, 0, 
			0, @info2_antet, @info3_antet, @gestiune_primitoare, @categ_pret as dobanda, 
			0, @info6_antet, (case when @tip in ('BF', 'FA') then '' else @info6_antet end), @explicatii, '1/1/1901'
		end
		if not exists (select 1 from extcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub and Numar_pozitie=1)
			insert extcon 
		     (Subunitate,Tip,Contract,Tert,Data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,
		     Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,Utilizator,Data_operarii,Ora_operarii)
		     
		     select @Sub,@tip, @contract , @tert, @data,1,'','','',@ext_clauze,@ext_modificari,'',@contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@userASiS,
		     convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		if ISNULL((select max(stare) from con where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub), '0')<>'0'
				raiserror('wScriuPozCon:Contractul/comanda nu e in starea 0-Operat', 11, 1)

		if @tip in ('BF','FA') -- se presupune lucrul pe termene, altfel se va merge pe "else"
		begin
		if (@tert='' or @tert is null) 
			raiserror('wScriuPozCon:Nu se poate adauga contract fara completare tert!', 11, 1)
		if @subtip='BA'	
			return 
		--if @TermPeSurse=1 
		--	set @numar_pozitie=isnull((select max(numar_pozitie) from pozcon 
		--			where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub and cod=@cod and mod_de_plata=@modplata and /*modificat sa ia pozitie noua dc are explicatii diferite pt APE-Andrey*/ Explicatii=@explicatii_pozitii ),0)		   
		if isnull(@numar_pozitie,0)=0 
			set @numar_pozitie=isnull((select max(numar_pozitie) from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub),0)+1
	    if isnull(@Tpret,0)=0
			set @Tpret=(select max(Pret_vanzare) from nomencl where Cod=@cod)
        if not exists (select 1 from pozcon where subunitate=@sub and tip=@tip and contract=@contract and
			tert=@tert and data=@data and cod=@cod and (@TermPeSurse=0 or mod_de_plata=@modplata) 
			and /*modificat sa adauge pozitie noua dc are explicatii diferite pt APE-Andrey*/ Explicatii=@explicatii_pozitii)  and @update='0'/*in cazul in care nu se face update */
			insert pozcon 
					(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, 
					Discount, Termen, Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, 
					Suma_TVA, Mod_de_plata, UM, Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, 
					Data_operarii, Ora_operarii)
				values (@Sub, @tip, @contract, @tert, @gestiune_primitoare, @data, @cod, @Tcantitate, @Tpret, 0, 
					@Discount, @termen, @gestiune, 0, @cantitate, 0, @valuta, @cota_TVA, 
					0, @modplata, '', 0, @explicatii_pozitii, @numar_pozitie, @userASiS, 
					convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', '')))		
		else /*Silviu:modificare antet termene :sursa, pret pe cod daca cant realizata=0(adica daca nu a fost facturat)*/
		if @update='1' and @subtip='BF'
		    if exists(select 1 from pozcon where subunitate=@sub and contract=@contract and tert=@tert 
																	and data=@data and (cod=@cod or cod=@o_cod)and Cant_realizata=0)
			begin
			 /*Silviu:formez numar pozitie atunci cand vreau sa modific sursa altfel primesc un numar de pozitie nou dupa noua sursa
			 si nu  poate sa faca update la cantitate*/
			update pozcon set pret=@Tpret, Mod_de_plata=@modplata, cod=@cod
				where subunitate=@sub and tip=@tip and contract=@contract and
					  tert=@tert and data=@data and numar_pozitie=@numar_pozitie--and cod=@o_cod
					  
			if @TermPeSurse=0
			     begin
			      update termene set cod=@cod where subunitate=@Sub and tip=@tip and contract=@contract and
													tert=@tert and data=@data and 
													cod=@o_cod
			     end  
			update termene set Pret=@Tpret where subunitate=@Sub and tip=@tip and contract=@contract and
													tert=@tert and data=@data and 
													cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and pret=0 
			if @TermPeSurse='1'
			begin
			set @T1=isnull(@parXML.value('(/row/row/@Tianuarie)[1]','float'),'')
			set @T2=isnull(@parXML.value('(/row/row/@Tfebruarie)[1]','float'),'')
			set @T3=isnull(@parXML.value('(/row/row/@Tmartie)[1]','float'),'')
			set @T4=isnull(@parXML.value('(/row/row/@Taprilie)[1]','float'),'')
			set @T5=isnull(@parXML.value('(/row/row/@Tmai)[1]','float'),'')
			set @T6=isnull(@parXML.value('(/row/row/@Tiunie)[1]','float'),'')
			set @T7=isnull(@parXML.value('(/row/row/@Tiulie)[1]','float'),'')
			set @T8=isnull(@parXML.value('(/row/row/@Taugust)[1]','float'),'')
			set @T9=isnull(@parXML.value('(/row/row/@Tseptembrie)[1]','float'),'')
			set @T10=isnull(@parXML.value('(/row/row/@Toctombrie)[1]','float'),'')
			set @T11=isnull(@parXML.value('(/row/row/@Tnoiembrie)[1]','float'),'')
			set @T12=isnull(@parXML.value('(/row/row/@Tdecembrie)[1]','float'),'')
			
				
			declare @termenelocal datetime, @cantitatelocal float
			declare crstermene cursor for 
		    select termen, cantitate from termene where subunitate=@Sub and tip=@tip and contract=@contract and 
											tert=@tert and data=@data and 
											cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)
			open crstermene	
			fetch next from crstermene into @termenelocal, @cantitatelocal
			while @@FETCH_STATUS=0
			begin
			update termene set Cantitate=(case when month(@termenelocal)='1'  then @T1
												when month(@termenelocal)='2'  then @T2 
												when month(@termenelocal)='3'  then @T3
												when month(@termenelocal)='4'  then @T4
												when month(@termenelocal)='5'  then @T5
												when month(@termenelocal)='6'  then @T6
												when month(@termenelocal)='7'  then @T7
												when month(@termenelocal)='8'  then @T8
												when month(@termenelocal)='9'  then @T9
												when month(@termenelocal)='10' then @T10
												when month(@termenelocal)='11' then @T11
												when month(@termenelocal)='12' then @T12
												else @cantitatelocal
												end)
			where subunitate=@Sub and tip=@tip and contract=@contract and
					tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and 
					Termen=@termenelocal
			delete from termene where subunitate=@Sub and tip=@tip and contract=@contract and
					tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and 
					Termen=@termenelocal and abs(cantitate)<'0.01'
		    fetch next from crstermene into @termenelocal, @cantitatelocal
			end
			close crstermene
			deallocate crstermene	
			end
			end				
			 else 
			   raiserror('wScriuPozCon:De pe acest cod s-a facturat, operatie de modificare pret/sursa/cod nepermisa!',16,1)
		if @update='1' and @subtip='BF' and @TermPeSurse=1
		--pentru Ape: ia valorile introduse in subformul antetelor de termene le sterge in cazul in care un termen este 0 si il insereaza in cazul in care cant pe termen>0
		     if exists(select 1 from pozcon where subunitate=@sub and contract=@contract and tert=@tert 
																	and data=@data and (cod=@cod or cod=@o_cod)and Cant_realizata=0)
			begin
				declare @count int, @termenVerificare datetime
				set @count=0
				IF OBJECT_ID('tempdb..#termeneLunaOrizontal') IS NOT NULL
					drop table #termeneLunaOrizontal
				select	convert(float,@T1) as T1, @T2 as T2, @T3 as T3,@T4 as T4,@T5 as T5 ,
						@T6 as T6,@T7 as T7,@T8 as T8,@T9 as T9 ,@T10 as T10,
						@T11 as T11,@T12 as T12
						into #termeneLunaOrizontal
				declare @termeneLunaVertical table (valoare varchar(20))
				insert into @termeneLunaVertical
				SELECT Orders
				FROM 
					(SELECT T1, T2, T3, T4, T5, T6, T7, T8, T9,T10,T11,T12
						FROM #termeneLunaOrizontal) AS p
					UNPIVOT
					(Orders FOR Employee IN 
						(T1, T2, T3, T4, T5, T6, T7, T8, T9,T10,T11,T12)
				)AS unpvt
				declare @valoare float
				declare verificareTermene cursor for 
				select valoare from @termeneLunaVertical 
				open verificareTermene
				fetch next from verificareTermene into @valoare
				while @@FETCH_STATUS=0
				begin
					
					set @termenVerificare=(select dateadd(month,@count,dbo.EOM(dbo.BOY(getdate()))))
					set @count=@count+1
					if @valoare>0 and not exists (select 1 from termene where subunitate=@Sub and tip=@tip and contract=@contract
														and tert=@tert and data=@data 
														and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) 
														and month(termen)=@count)
							begin
								insert termene (Subunitate, Tip, Contract, Tert, Cod, 
											Data, Termen, Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)
								values (@sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end), 
											@data, @termenVerificare,@valoare, 0 , @Tpret, '', 0,0,'','01/01/1901')
							end
				fetch next from verificareTermene into @valoare
				end
				close verificareTermene
				deallocate verificareTermene	
			end
		if @subtip='GT'
		begin
			set @nr=0 
			select @Tcantitate = (case when @periodicitate<3 then @Tcantitate/convert(float,@periodicitate) else @Tcantitate*convert(float,@periodicitate) end)
			while @nr<@Gluni*(case when isnull(@periodicitate,1)<3 then isnull(@periodicitate,1) else 1 end)
			begin
				if isnull(@periodicitate,1) in ('1','2')
					set @nr=@nr+1
				else if isnull(@periodicitate,1) in ('3','6','12')
					set @nr=@nr+@periodicitate
				if @periodicitate=2 and convert(float,@nr)/2=convert(int,convert(float,@nr)/2) -- numar par
					set @termene=DATEADD(day,14,dbo.BOM(@termene))
				else if @periodicitate in ('3','6','12')
				begin				
					if not exists(select 1 from termene where  subunitate=@sub and tip=@tip and contract=@contract 
								and tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) 
								and data=@data)
						set @termene=@termene
					else --if @nr>@Gluni and (@nr-@Gluni)<@periodicitate
						set @termene=dateadd(month,@periodicitate,dbo.BOM(convert(varchar(20),@termene,101)))	
					/*else 
						set @termene=dateadd(month,abs(@nr-@periodicitate),dbo.BOM(@termene))*/
				end
				else
					set @termene=dbo.EOM(@termene)
				
				if not exists (select 1 from termene where subunitate=@sub and tip=@tip and contract=@contract 
								and tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) 
								and Termen=@termene and data=@data)
					insert termene 
					(Subunitate, Tip, Contract, Tert, Cod, 
					Data, Termen, 
					Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)
					values (@sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end), 
					@data, @termene, 
					@Tcantitate, 0 , @Tpret, '', 0,0,'','01/01/1901')
				if isnull(@periodicitate,1)=1 or convert(float,@nr)/2=convert(int,convert(float,@nr)/2) and @periodicitate not in ('3','6','12') -- numar par
					set @termene=DATEADD(MONTH,1,dbo.BOM(@termene))
			end		
			  
			--update Termene set Cantitate=@Tcantitate, Pret=@Tpret
			--				where subunitate=@sub and tip=@tip and contract=@contract and 
			--				tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and Termen=@termene and data=@data 
				
		end
		else -- subtip BF si FA
		begin
		if @update<>'1' -- update=0, adica adaugare pozitie noua 	
		 begin
		   if not exists (select 1 from termene where subunitate=@Sub and tip=@tip and contract=@contract 
			and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and Termen=@termene) --and pret=@pret)
	 			insert termene 
				(Subunitate, Tip, Contract, Tert, Cod, Data, Termen, 
				Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)
				values (@Sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end), @data, @termene, 
				@Tcantitate, 0 , @Tpret, '', 0,0,@data1,'01/01/1901')
            
            update Termene set Cantitate=@Tcantitate, Pret=@Tpret, Data1=@data1
			where subunitate=@Sub and tip=@tip and contract=@contract and 
			tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and Termen=@termene 
			
			--update pozcon set 
			--cantitate=(select SUM(round(cantitate,3)) from Termene where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)  group by Subunitate,tip,Contract,tert,data,cod), 
			--termen=@termene, Pret=ISNULL(@pret,@Tpret), 
			--utilizator=@utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
			--ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,
			--mod_de_plata=@modplata
			--where subunitate=@sub and tip=@tip and contract=@contract and
			--tert=@tert and data=@data and cod=@cod and (@TermPeSurse=0 or mod_de_plata=@modplata)
			
			--update con set Total_contractat=(select SUM(round(cantitate*pret,2)) from Termene where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data  group by Subunitate,tip,Contract,tert,data)
			--where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub
			
			--update extcon set Camp_1=@contclient, Camp_2=@procpen
			--where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub and Numar_pozitie=1
		 end
		 else -- update='1', adica modificare pozitie 
		  if @update='1' and @subtip='TE'
		  begin
		    if exists (select 1 from termene where Subunitate=@sub and tip=@tip and contract=@contract 
							and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) 
							and Termen=@termene and cant_realizata=0)
				
			  update Termene set Cantitate=@Tcantitate, Pret=@Tpret , Termen=@termene
			  where Subunitate=@sub and tip=@tip and contract=@contract and 
			  tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and  Termen=@termene
			  
			else 
			  raiserror('wScriuPozCon:De pe acest termen s-a facturat, operatie de modificare cantitate/pret nepermisa!',16,1)
		  --begin
		  --   update Termene set Cantitate=@Tcantitate, Pret=@Tpret , Termen=@termene
			 -- where Subunitate=@sub and tip=@tip and contract=@contract and 
			 -- tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and  Termen=@Ttermen
		  end
		end
		 update pozcon set 
		 cantitate=isnull((select SUM(round(cantitate,5)) 
			from Termene where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data 
			and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)),0), 
		  termen=@termene,-- Pret=ISNULL(@pret,@Tpret), 
		  utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
		  ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,
		  --mod_de_plata=@modplata,
		  Explicatii=@explicatii_pozitii
		  where subunitate=@sub and tip=@tip and contract=@contract and
		  tert=@tert and data=@data and Numar_pozitie=@numar_pozitie
		  --and cod=@cod /*and (@TermPeSurse=0 or mod_de_plata=@modplata)*//*modificat sa nu faca update dc are explicatii diferite pt APE-Andrey*/and Explicatii=@explicatii_pozitii
		  
		 update con set Total_contractat=isnull((select SUM(round(cantitate*pret,2)) from Termene where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data),0),
						Total_TVA=isnull((select SUM(round(round(pret*Cota_TVA/100,2)*cantitate,2)) from pozcon 
					where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data),0)
		  where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub
		  
		 update extcon set Camp_1=@contclient, Camp_2=@procpen, Clauze_speciale=@ext_clauze,Modificari=@ext_modificari,Camp_3=@contr_cadru,Camp_4=@ext_camp4,Camp_5=@ext_camp5
		  where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub and Numar_pozitie=1
		 ----------------------------------------------     
		--update pozcon set 
		--		cantitate=(select SUM(round(cantitate,3)) from Termene where subunitate=@sub and tip=@tip and contract=@contract 
		--		and tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and data=@data), --group by Subunitate,tip,Contract,tert,cod),  
		--		--termen=@termene,
		--		utilizator=@utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
		--		ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) --,
		--		--mod_de_plata=@modplata
		--		where subunitate=@sub and tip=@tip and contract=@contract and
		--		tert=@tert and cod=@cod and (@TermPeSurse=0 or mod_de_plata=@modplata) and data=@data
						

		--update con set Total_contractat=(select SUM(round(cantitate*pret,2)) from Termene where subunitate=@sub 
		--				 and tip=@tip and contract=@contract and tert=@tert and data=@data ) --group by Subunitate,tip,Contract,tert)
		--				 where tip=@tip and contract=@contract and tert=@tert and subunitate=@sub and data=@data 
		-----------------
		end
		else -- @tip not in ('BF','FA') 
		begin 
			if (@tert='' or @tert is null) and (@gestiune_primitoare='' or @gestiune_primitoare is null) 
				raiserror('wScriuPozCon:Nu se poate adauga comanda fara completare tert sau gest. primitoare', 11, 1) 
			
			if isnull(@numar_pozitie,0)=0 
				set @numar_pozitie=isnull((select max(numar_pozitie) from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub),0)+1
			else begin
				delete from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate in (@Sub, 'EXPAND', 'EXPAND2') and numar_pozitie=@numar_pozitie
				delete detpozcon where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and numar_pozitie=@numar_pozitie and numar_ordine in (0, 1)
			end
			
			if @cantitate<>0
				insert pozcon 
				(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, 
					Termen, Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, 
					Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)
				select @Sub, @tip, @contract, @tert, @gestiune_primitoare, @data, 
					@cod, @cantitate, @pret, 0, @Discount, @termen, @gestiune, 0, 
					(case when @CantAprob0BKBP=1 and @tip in ('BK', 'BP') then 0 else @cantitate end), 0, @valuta, @cota_TVA, round(round(@pret*@Cota_TVA/100,2)*@cantitate,2), @modplata, '', 
					0, @explicatii_pozitii, @numar_pozitie, @userASiS, 
					convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		end

		if @tip not in ('BF', 'FA') and @cantitate<>0 and (@lot<>'' or @data_expirarii>'01/01/1901') or @info1_pozitii<>0 or @info2_pozitii<>'' or @info3_pozitii<>0
			insert pozcon 
			(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, 
				Pret_promotional, Discount, Termen, 
				Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, 
				Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)
			select 'EXPAND', @tip, @contract, @tert, @info2_pozitii, @data, @cod, @info3_pozitii, @info1_pozitii, 
				0, 0, (case when @tip not in ('BF', 'FA') then @data_expirarii else '01/01/1901' end), 
				'', 0, 0, 0, '', 0, 0, '', '', 
				0, (case when @tip not in ('BF', 'FA') then @lot else '' end), @numar_pozitie, '', '01/01/1901', '000000'
		if @info4_pozitii<>'' or @info5_pozitii<>''
			insert pozcon 
			(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, Termen, 
				Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, 
				Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)
			select 'EXPAND2', @tip, @contract, @tert, @info5_pozitii, @data, @cod, 0, 0, 0, 0, '01/01/1901', 
				'', 0, 0, 0, '', 0, 0, '', '', 
				0, @info4_pozitii, @numar_pozitie, '', '01/01/1901', '000000'
		if @tip not in ('BF', 'FA') and (@obiect<>'' or @info6_pozitii>'01/01/1901' or @info7_pozitii>'01/01/1901' or @info8_pozitii<>0 or @info9_pozitii<>0 or @info12_pozitii<>'' or @info13_pozitii<>'' or @info14_pozitii<>'')
			insert detpozcon
			(Subunitate, Tip, Contract, Tert, Data, Numar_pozitie, Numar_ordine, 
				Obiect, Punct_livrare, Comanda, Versiune, Stare, Termen, Data_inceput, Data_sfarsit, Garantie, 
				Observatii, Val1, Val2, Data1, Data2, Info1, Info2)
			select @Sub, @tip, @contract, @tert, @data, @numar_pozitie, 0, 
				@obiect, '', '', 0, '', '01/01/1901', '01/01/1901', '01/01/1901', '',
				@info12_pozitii, @info8_pozitii, @info9_pozitii, @info6_pozitii, @info7_pozitii, @info13_pozitii, @info14_pozitii
		if @tip not in ('BF', 'FA') and (@info10_pozitii<>0 or @info11_pozitii<>0 or @info15_pozitii<>'' or @info16_pozitii<>'' or @info17_pozitii<>'')
			insert detpozcon
			(Subunitate, Tip, Contract, Tert, Data, Numar_pozitie, Numar_ordine, 
				Obiect, Punct_livrare, Comanda, Versiune, Stare, Termen, Data_inceput, Data_sfarsit, Garantie, 
				Observatii, Val1, Val2, Data1, Data2, Info1, Info2)
			select @Sub, @tip, @contract, @tert, @data, @numar_pozitie, 1, 
				'', '', '', 0, '', '01/01/1901', '01/01/1901', '01/01/1901', '',
				@info15_pozitii, @info10_pozitii, @info11_pozitii, '01/01/1901', '01/01/1901', @info16_pozitii, @info17_pozitii
		
		if @numarGrp is null
			select @tipGrp=@tip, @numarGrp=@contract, @tertGrp=@tert, @dataGrp=@data, @sir_numere_pozitii=''
		
		if @tip in ('FA') and @tip=@tipGrp and @contract=@numarGrp and @tert=@tertGrp and @data=@dataGrp
			set @sir_numere_pozitii = @sir_numere_pozitii + (case when @sir_numere_pozitii<>'' then ';' else '' end) + ltrim(str(@numar_pozitie))
		
			update con set Total_contractat=p.total_contractat,Total_TVA=p.total_tva
			from 
				(select isnull(SUM(round(cantitate*pret,2)),0) as total_contractat,
						isnull(SUM(round(round(pret*Cota_TVA/100,2)*cantitate,2)),0) as total_tva
						from pozcon
						where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data) p
			where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data
		


	fetch next from crspozcon into @tip, @contract, @data, @gestiune, @gestiune_primitoare, 
		@tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze,@termen, @subtip, 
		@scadenta,
		--termene
		@termene, @data1,  
		
		@lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet, 
		@numar_pozitie, @cod, @o_cod, @cantitate, 
		
		--termene
		@Tcantitate, 
		
		@cantitate_UM1, @cantitate_UM2, @cantitate_UM3, 
		@pret, 
		
		--termene
		@Tpret,
		
		@cota_tva, @valuta, @curs, @explicatii_pozitii,@explicatii, @discount, @punct_livrare, @modplata, @o_modplata, @categ_pret, 
		@lot, @data_expirarii, @obiect, @info1_pozitii, @info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii, 
		--@info6_pozitii, @info7_pozitii, 
		@info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii, 
		@info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, @info17_pozitii, 
		@Gluni, @periodicitate
	end
		
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozConSP2')
		exec wScriuPozConSP2 @sesiune=@sesiune, @parXML=@parXML

	set @docXMLIaPozContract = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tipGrp) 
		+ '" numar="' + rtrim(@numarGrp) + '" tert="' + rtrim(@tertGrp) + '" data="' + convert(char(10), @dataGrp, 101)+'"/>'
	exec wIaPozCon @sesiune=@sesiune, @parXML=@docXMLIaPozContract 
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	set @mesaj = '(wScriuPozCon)'+ERROR_MESSAGE() 
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspozcon' and session_id=@@SPID )
if @cursorStatus=1 
	close crspozcon 
if @cursorStatus is not null 
	deallocate crspozcon 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

if ISNULL(@mesaj,'')!=''
	raiserror(@mesaj, 11, 1)

GO

/****** Object:  StoredProcedure [dbo].[wIaPozCon]    Script Date: 03/21/2012 12:27:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--***  
ALTER procedure [dbo].[wIaPozCon] @sesiune varchar(50), @parXML xml      
as      
      
declare @iDoc int, @lCuTermene int, @TermPeSurse int,@doc xml,@tip varchar(2), @sub char(9),@numar char(20),@tert char(20),@numere_pozitii varchar(max),      
  @data datetime, @cautare varchar(100), @Periodicitate int  
   
select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'      
set @TermPeSurse=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)  
set @Periodicitate=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='PERIODCON'),0)  
  
select  @sub=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),        
  @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),        
  @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),        
  @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),    
  @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),    
  @numere_pozitii=ISNULL(@parXML.value('(/row/@numerepozitii)[1]', 'varchar(20)'), ''),  
  @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(100)'), '')  
     
set @cautare='%'+replace(@cautare,' ','%')+'%'    
IF OBJECT_ID('tempdb..#termene') IS NOT NULL  
  drop table #termene  
select max(te.subunitate) as subunitate, max(te.tert) as tert, max(te.data) as data, max(te.explicatii) as explicatii, max(te.data2) as data2, max(te.termen) as termen,  
      max(te.cod) as cod, max(te.contract) as contract,  
      max(case when month(te.termen)=1 then te.cantitate else 0 end) as Tianuarie,  
      max(case when month(te.termen)=2 then te.cantitate else 0 end) as Tfebruarie,  
      max(case when month(te.termen)=3 then te.cantitate else 0 end) as Tmartie,  
      max(case when month(te.termen)=4 then te.cantitate else 0 end) as Taprilie,  
      max(case when month(te.termen)=5 then te.cantitate else 0 end) as Tmai,  
      max(case when month(te.termen)=6 then te.cantitate else 0 end) as Tiunie,  
      max(case when month(te.termen)=7 then te.cantitate else 0 end) as Tiulie,  
      max(case when month(te.termen)=8 then te.cantitate else 0 end)as Taugust,  
      max(case when month(te.termen)=9 then te.cantitate  else 0 end) as Tseptembrie,  
      max(case when month(te.termen)=10 then te.cantitate else 0 end) as Toctombrie,  
      max(case when month(te.termen)=11 then te.cantitate else 0 end) as Tnoiembrie,  
      max(case when month(te.termen)=12 then te.cantitate else 0 end) as Tdecembrie  
     into #termene from termene te   
     where  te.Subunitate=@sub and te.tip=@tip and   
       te.Contract=@numar and te.Data=@data and te.tert=@tert  
       group by te.cod  
       order by te.cod  
         
  
--set @doc=(      
select rtrim(te.subunitate) as subunitate, convert(varchar(10),te.termen,103) as codsisursa, te.cantitate as Taugust,  
		rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,30), '')) as dencod, rtrim(p.cod) as cod,  
		convert(decimal(17, 5), te.cantitate) as Tcantitate, convert(varchar(10),te.data,101) as Tdata,  
		convert(varchar(10),te.termen,101) as Ttermen,  
		isnull((select convert(decimal(15,2),convert(decimal(15,2),achitat)/(select count (*) from termene where subunitate=@sub and explicatii=f.factura and data2=f.data))   
		from facturi f where f.subunitate=@sub and f.tip='F' and f.tert=@tert and f.Factura=te.Explicatii and data=te.Data2),0) as Tachitat,  
		convert(decimal(15,2),(te.cant_realizata*te.pret))as Tfacturat,  
		convert(varchar(10),te.Data1,101) as termen, convert(varchar(10),te.termen,101) as termene,    
		convert(varchar(10),te.data1,101) as Tdata1,  convert(decimal(14, 4), te.pret) as Tpret,  
		rtrim(p.Explicatii) as explicatii, convert(int,p.numar_pozitie) as numarpozitie,     
		(convert(decimal(17, 5), te.cant_realizata)) as Tcant_realizata,rtrim(isnull(n.um, '')) as um1,  
		(case when te.cant_realizata>0 then '#808080' else '#08088A' end )as culoare,  
		convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else  
		0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,  RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret,   
		convert(decimal(17, 5), p.pret_promotional) as cant_transferata,     
		convert(decimal(10, 5), p.discount) as discount,  
		convert(decimal(5, 2), p.cota_tva) as cotatva,    
		rtrim(p.punct_livrare) as punctlivrare,   
		rtrim(te.tert) as Ttert, rtrim(te.Contract) as Tcontract,     
		rtrim(p.Mod_de_plata) as modplata,'('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,'TE' as subtip   
 into #tmptermen  
 from TERMENE te   
 inner join  pozcon p on te.subunitate=p.subunitate and te.contract=p.contract and te.tert=p.tert and te.data=p.data   
 left outer join nomencl n on n.cod = p.Cod    
 left outer join surse s on s.Cod=p.Mod_de_plata         
 where	p.Subunitate=@sub and p.Tip=@tip and p.Contract=@numar and p.Data=@data  
		and (te.Cod=(case when @TermPeSurse=0  then p.cod else ltrim(str(p.numar_pozitie)) end) or  
		te.Cod=(case when @TermPeSurse=1  then ltrim(str(p.numar_pozitie))else  p.cod end) )  
 order by(case when te.Cantitate is null then p.numar_pozitie else '' end),       
		(case when te.Cantitate is null then null else       
		(case when @TermPeSurse=0 then '' else isnull(rtrim(p.Mod_de_plata),'')+' '+isnull(rtrim(left(s.Denumire,50)),'') end)      
		+' - '+rtrim(isnull(p.cod,'')) +' - '+rtrim(isnull(left(n.denumire,30), ''))       
		+' ('+convert(varchar(17),convert(decimal(17, 5), isnull(p.cantitate,'')))+' '+rtrim(isnull(n.um, ''))+')'  end),       
		te.Termen  
              
select	rtrim(p.subunitate) as subunitate, rtrim(p.tip) as tip, rtrim(p.tip) as subtip, rtrim(p.contract) as numar,       
		p.data as data, rtrim(p.cod ) as cod, rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,30), '')) as dencod,      
		rtrim(p.factura) as gestiune,  convert(decimal(17, 5), p.cantitate) as cantitate,  rtrim(isnull(p.valuta, '')) as valuta,  
		convert(varchar(10),p.termen,101) as termene, convert(decimal(14, 4), p.pret) as Tpret,  rtrim(p.tert) as tert,
		convert(decimal(17, 5), p.cantitate) as Tcantitate, convert(decimal(17, 5), p.cant_realizata) as Tcant_realizata,  
		rtrim(isnull(n.um, '')) as um1, convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,    
		RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret, convert(decimal(10, 4), p.pret_promotional) as cant_transferata,     
		convert(decimal(10, 5), p.discount) as discount, convert(decimal(5, 2), p.cota_tva) as cotatva,     
		rtrim(p.punct_livrare) as punctlivrare,  rtrim(p.Mod_de_plata) as modplata,  '('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,  
		rtrim(isnull(n.denumire, ''))+' - ('+isnull(rtrim(p.Mod_de_plata),'')+')'+isnull(RTRIM(s.Denumire),'') as denumire,       
		isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune,  isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,       
		isnull(rtrim(t.denumire), '') as dentert,  convert(decimal(17, 5),p.cant_realizata) as cant_realizata,       
		convert(decimal(17, 5),p.cant_aprobata) as cant_aprobata, convert(varchar(10),p.termen,101) as termen_poz,       
		rtrim(p.Explicatii) as explicatii, p.numar_pozitie as numarpozitie, RTrim(ISNULL(pe.Explicatii, '')) as lot,    
		convert(char(10), isnull(pe.termen, '01/01/1901'), 101) as dataexpirarii,       
		rtrim(isnull(dp.Obiect, '')) as obiect, rtrim(isnull(obiecteds.denumire, '')) as denobiect,      
		isnull(pe.pret, 0) as info1, rtrim(isnull(pe.punct_livrare, '')) as info2, isnull(pe.cantitate, 0) as info3,       
		rtrim(isnull(pe2.explicatii, '')) as info4,    rtrim(isnull(pe2.punct_livrare, '')) as info5,      
		convert(char(10), isnull(dp.data1, '01/01/1901')) as info6, convert(char(10), isnull(dp.data2, '01/01/1901')) as info7,       
		convert(decimal(17, 5), isnull(dp.val1, 0)) as info8,  convert(decimal(17, 5), isnull(dp.val2, 0)) as info9,       
		convert(decimal(17, 5), isnull(dp1.val1, 0)) as info10,   convert(decimal(17, 5), isnull(dp1.val2, 0)) as info11,       
		rtrim(isnull(dp.observatii, '')) as info12,  rtrim(isnull(dp.info1, '')) as info13, rtrim(isnull(dp.info2, '')) as info14,       
		rtrim(isnull(dp1.observatii, '')) as info15,  rtrim(isnull(dp1.info1, '')) as info16,    
		rtrim(isnull(dp1.info2, '')) as info17,  convert(decimal(17, 5),tr.Tianuarie) as Tianuarie,  
		convert(decimal(17, 5),tr.Tfebruarie) as Tfebruarie,  convert(decimal(17, 5),tr.Tmartie) as Tmartie,  
		convert(decimal(17, 5),tr.Taprilie) as Taprilie,  convert(decimal(17, 5),tr.Tmai) as Tmai,  
		convert(decimal(17, 5),tr.Tiunie) as Tiunie,  convert(decimal(17, 5),tr.Tiulie) as Tiulie,  convert(decimal(17, 5),tr.Taugust) as Taugust,  
		convert(decimal(17, 5),tr.Tseptembrie) as Tseptembrie,  convert(decimal(17, 5),tr.Toctombrie) as Toctombrie,  
		convert(decimal(17, 5),tr.Tnoiembrie) as Tnoiembrie,  convert(decimal(17, 5),tr.Tdecembrie) as Tdecembrie,  
		isnull((select convert(decimal(15,2),achitat) from facturi f where f.subunitate=@sub and f.tip='F' and f.tert=tr.tert and  f.tert=@tert and f.Factura=tr.Explicatii and data=tr.Data2),0)   
						as Tachitat,  
		convert(decimal(15,2),(p.cant_realizata)*p.pret) as Tfacturat,  
		rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,100), ''))+char(10)+(case when @TermPeSurse=1 then ' - ('+isnull(rtrim(p.Mod_de_plata),'')+')'+isnull(RTRIM(s.Denumire),'') else '' end) as codsisursa  
into #tmppozcon  
from pozcon p      
left outer join nomencl n on n.cod = p.Cod       
left outer join surse s on s.Cod=p.Mod_de_plata      
left outer join terti t on t.subunitate = p.subunitate and t.tert = p.Tert      
left outer join gestiuni gest on gest.cod_gestiune = p.factura      
left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
left outer join pozcon pe2 on pe2.Subunitate='EXPAND2' and pe2.Tip=p.Tip and pe2.Contract=p.Contract and pe2.Tert=p.Tert and pe2.Data=p.Data and pe2.Cod=p.Cod      
left outer join detpozcon dp on dp.subunitate=p.subunitate and dp.tip=p.tip and dp.contract=p.contract and dp.tert=p.tert and dp.data=p.data and dp.numar_pozitie=p.numar_pozitie and dp.numar_ordine=0      
left outer join obiecteds on obiecteds.cod_obiect=dp.obiect      
left outer join detpozcon dp1 on dp1.subunitate=p.subunitate and dp1.tip=p.tip and dp1.contract=p.contract and dp1.tert=p.tert and dp1.data=p.data and dp1.numar_pozitie=p.numar_pozitie and dp1.numar_ordine=1      
left outer join #termene tr  
on tr.subunitate=p.subunitate and tr.contract=p.contract and tr.Data=p.data and tr.tert=p.tert and  
  tr.Subunitate=@sub and tr.Contract=@numar and tr.Data=@data and   
  tr.Cod=(case when @TermPeSurse=0  then p.cod else ltrim(str(p.numar_pozitie)) end)   
where p.subunitate=@sub and p.tip=@tip and p.contract=@numar and ltrim(p.tert)=@tert and p.data=@data   
 and (p.cod like @cautare or @cautare='')  
 and (isnull(@numere_pozitii, '')='' or charindex(';' + ltrim(str(p.numar_pozitie)) + ';', ';' + @numere_pozitii + ';')>0)      
order by p.Numar_pozitie desc   
  
declare @areDetalii int  
if exists(select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='pozcon' and sc.name='detalii')  
begin  
 set @areDetalii=1  
 alter table #tmppozcon add detalii xml  
 update #tmppozcon set #tmppozcon.detalii=pozcon.detalii  
 from pozcon where #tmppozcon.subunitate=pozcon.subunitate and #tmppozcon.tip=pozcon.tip and   
     #tmppozcon.data=pozcon.data and #tmppozcon.numar=pozcon.contract  
end  
else  
 set @areDetalii=0  

set @doc=(select *,(select * from #tmptermen ter where ter.subunitate=pz.subunitate and ter.Tcontract=pz.numar and   
            ter.Tdata=pz.data and ter.cod=pz.cod for xml raw, type) from #tmppozcon pz  
for xml raw
, root('Ierarhie')
)  
select @areDetalii as areDetaliiXml for xml raw, root ('Mesaje')      
select @doc for xml path('Date')      
  
GO

