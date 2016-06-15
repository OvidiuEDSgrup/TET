--***
Create procedure  wScriuPontaj @sesiune varchar(50), @parXML xml 
as
declare @PontajZilnic int, @RegimLVariabil int, @OreLunaTura int, @OreLuna int, @OreMedLuna int, @ScadOSRegN int, @ScadO100RegN int, @GestTichete int, 
@ptupdate int, @tip varchar(2),@subtip varchar(2),@lmantet varchar(20),@denlmantet varchar(30),@datad datetime,@data datetime, 
@datalunii1 datetime, @datalunii datetime, @datasus datetime, @marca varchar(6),@loc_de_munca varchar(9),@tlocm varchar(9),@i int,@in int,
@data_pontaj datetime,@ore_regie float,@densalariat varchar(50),@denlm varchar(30),@denfunctie varchar(30),@im int, 
@salarincadrare float,@userASiS varchar(20),@docXML xml,@docXMLIaDLSalarii xml,@eroare xml,@eroare_atentie xml,@mesaj varchar(254),
@tipop int,@loc_de_munca_ptr_stat int,@tip_salarizare char(1), @regim_de_lucru float,@salar_orar float,@k int,@grupa_de_munca char(1),@ore_acord float,
@oresupl1 float, @oresupl2 float,@oresupl3 float, @oresupl4 float,@orespor100 float,@orenoapte float,@oreco float,@orecm float,
@oreintr1 float,@oreintr2 float,@obligcet float,@Bugetari int,@oreinvoiri float,@orenem float,@orecfs float,@oredetasare float,
@oredelegatii float,@sporspecific float,@orepesteprogr float,@sppesteprogr float,@ore1 float,@ore2 float,@ore3 float,
@ore4 float,@ore5 float,@ore6 float,@sp1 float,@sp2 float,@sp3 float,@sp4 float,@sp5 float,@sp6 float,@sp7 float,@sp8 float,
@comanda varchar(20)

declare @o_regie int,@o_acord int,@o_supl_1 int,@o_supl_2 int,@o_supl_3 int,@o_supl_4 int,@o_spor_100 int, @o_de_noapte int, @o_intr_tehn int, @o_CO int, @o_CM int, @o_invoiri int, 
@o_nemotivate int,@o_obl_cet int,@o_cfs int,@o_donare_sange int, @s_cat_lucr float,@coef_acord float,@realiz float,@coef_de_timp float, @o_real_acord float, @sist_peste_program float, 
@o_sist_peste_program int,@sp_specific float,@sp_conditii_1 float, @sp_conditii_2 float,@sp_conditii_3 float, @sp_conditii_4 float, @sp_conditii_5 float, @sp_conditii_6 float, 
@o_cond_1 int,@o_cond_2 int,@o_cond_3 int, @o_cond_4 int,@o_cond_5 int,@o_cond_6 int,@tore int,@sp_cond_7 float,@sp_cond_8 float,@sp_cond_9 float,@sp_cond_10 float,
@nrcrt int,@stergXML xml,@nrpozitie int,@tcomanda varchar(20),@salcatl float,@coefacord float,@realizat float,@orerealizate float,@tnrdoc varchar(20), 
@SalariatiPeComenzi int, @orejustificate int, @regimsal decimal(10), @DataAngajarii datetime, @Plecat int, @DataPlec datetime, @OreLunaMarca int, @validcomstrictGE int, 
@SugerezSalCatLucr int, @ExistaModifSalarLuna int

begin try
	--BEGIN TRAN
	select @Bugetari = (case when Tip_parametru='PS' and parametru='UNITBUGET' then Val_logica else @Bugetari end),
		@GestTichete = (case when Tip_parametru='PS' and parametru='TICHETE' then Val_logica else @GestTichete end),
		@SalariatiPeComenzi = (case when Tip_parametru='PS' and parametru='SALCOM' then Val_logica else @SalariatiPeComenzi end),
		@PontajZilnic = (case when Tip_parametru='PS' and parametru='PONTZILN' then Val_logica else @PontajZilnic end),
		@RegimLVariabil = (case when Tip_parametru='PS' and parametru='REGIMLV' then Val_logica else @RegimLVariabil end),
		@ScadOSRegN = (case when Tip_parametru='PS' and parametru='OSNRN' then Val_logica else @ScadOSRegN end),
		@ScadO100RegN = (case when Tip_parametru='PS' and parametru='O100NRN' then Val_logica else @ScadO100RegN end),
		@validcomstrictGE = (case when Tip_parametru='GE' and parametru='COMANDA' then Val_logica else @ScadO100RegN end),
		@SugerezSalCatLucr = (case when Tip_parametru='PS' and parametru='CSALCATL' then Val_logica else @SugerezSalCatLucr end)
	from par
	where Tip_parametru='PS' and (Parametru='TICHETE' or Parametru='SALCOM' or Parametru='PONTZILN' or Parametru='REGIMLV' or Parametru='OSNRN' or Parametru='O100NRN' or Parametru='CSALCATL')
		or Tip_parametru='GE' and Parametru='COMANDA'
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPontajSP')
		exec wScriuPontajSP @sesiune, @parXML OUTPUT
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec wValidarePontaj @sesiune, @parXML
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	select @ptupdate=isnull(ptupdate,0),@tip=isnull(tip,''),@subtip=isnull(subtip,''),@marca=isnull(marca,isnull(marca_poz,'')),@lmantet=isnull(lmantet,''),
	@denlmantet=isnull(denlmantet,''),@datalunii=isnull(datalunii,'01/01/1901'), @densalariat=isnull(densalariat,''),@denlm=isnull(denlm,''),@denfunctie=isnull(denfunctie,''),
	@salarincadrare=isnull(salarincadrare,0),
	@loc_de_munca=(case when isnull(loc_de_munca,'')='' then (case when isnull(marca,'')='' then (select p.loc_de_munca from personal p where p.marca=isnull(a.marca_poz,'')) 
	else (select p.loc_de_munca from personal p where p.marca=isnull(a.marca,'')) end) else isnull(loc_de_munca,'') end),
	@data_pontaj=isnull(data_pontaj,datalunii),@regim_de_lucru=isnull(regim_de_lucru,0),@tip_salarizare=tip_salarizare,
	@ore_regie=ore_regie,@ore_acord=ore_acord,@oresupl1=oresupl1,@oresupl2=oresupl2,@oresupl3=oresupl3,
	@oresupl4=oresupl4,@orespor100=orespor100,@orenoapte=orenoapte,
	@oreco=oreco,@orecm=orecm,@oreintr1=oreintr1,@oreintr2=oreintr2,
	@obligcet=obligcet,@oreinvoiri=oreinvoiri,@orenem=orenem,@orecfs=orecfs,
	@oredetasare=oredetasare,@oredelegatii=oredelegatii,
	@sporspecific=sporspecific,@orepesteprogr=orepesteprogr,@sppesteprogr=sppesteprogr,
	@ore1=ore1,@sp1=sp1,@ore2=ore2,@sp2=sp2,@ore3=ore3,@sp3=sp3,@ore4=ore4,@sp4=sp4,@ore5=ore5,@sp5=sp5,@ore6=ore6,@sp6=sp6,
	@sp7=sp7,@sp8=sp8,@nrcrt=isnull(nrcrt,0),@nrpozitie=isnull(nrpozitie,0),
	@comanda=isnull(comanda,''), 
	@salcatl=isnull(salcatlucr,0),@coefacord=isnull(coefacord,0),@realizat=isnull(realizat,0),@orerealizate=isnull(orerealizate,0)
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update', 
		tip varchar(2) '../@tip', 
		subtip varchar(2) '@subtip',
		marca varchar(6) '../@marca', 
		marca_poz varchar(6) '@marca', 
		lmantet varchar(6) '../@lmantet', 
		denlmantet varchar(30) '../@denlmantet', 
		datalunii datetime '../@data',
		densalariat varchar(50) '../@densalariat', 
		denlm varchar(30) '../@denlm', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare', 
		loc_de_munca varchar(9) '@lm', 
		data_pontaj datetime '@data', 
		regim_de_lucru float '@regimlucru',
		tip_salarizare char(1) '@tipsal',
		ore_regie float '@oreregie',
		ore_acord float '@oreacord',
		oresupl1 float '@oresupl1',
		oresupl2 float '@oresupl2',
		oresupl3 float '@oresupl3',
		oresupl4 float '@oresupl4',
		orespor100 float '@orespor100',
		orenoapte float '@orenoapte',
		oreco float '@oreco',
		orecm float '@orecm',
		oreintr1 float '@oreintr1',
		oreintr2 float '@oreintr2',
		obligcet float '@oreobligatii',
		oreinvoiri float '@oreinvoiri',
		orenem float '@orenemotivate',
		orecfs float '@orecfs',
		oredetasare float '@oredetasare',
		oredelegatii float '@oredelegatii',
		sporspecific float '@sporspecific',
		orepesteprogr float '@orepesteprogr',
		sppesteprogr float '@sppesteprogr',
		ore1 float '@ore1',
		sp1 float '@sp1',
		ore2 float '@ore2',
		sp2 float '@sp2',
		ore3 float '@ore3',
		sp3 float '@sp3',
		ore4 float '@ore4',
		sp4 float '@sp4',
		ore5 float '@ore5',
		sp5 float '@sp5',
		ore6 float '@ore6',
		sp6 float '@sp6',
		sp7 float '@sp7',
		sp8 float '@sp8',
		nrcrt int '@nrcrt',
		nrpozitie int '@numarpozitie',
		comanda varchar(20) '@comanda',
		salcatlucr float '@salcatl',
		coefacord float '@coefacord',
		realizat float '@realizat',
		orerealizate float '@orerealizate'
	) a

	set @datalunii1=dbo.bom(@datalunii)
	set @data=(case when isnull((select Vizibil from webConfigForm where Meniu='SL' and tip=@tip and subtip=@subtip and Nume='Data'),0)<>0 then @data_pontaj else @datalunii end)	
	set @datasus=dbo.eom(@data)
	set @OreLuna=isnull(dbo.iauParLN(@datasus,'PS','ORE_LUNA'),1)
	set @OreMedLuna=isnull(dbo.iauParLN(@datasus,'PS','NRMEDOL'),1)
	set @OreLunaTura=dbo.iauParLN(@datasus,'PS','ORET_LUNA')
	if @SugerezSalCatLucr=1 and @tip_salarizare in ('6','7')
		set @ExistaModifSalarLuna=(case when exists (select Procent from extinfop 
			where Marca=@marca and Cod_inf='SALAR' and Data_inf between @datalunii1 and @datasus and Procent>1) then 1 else 0 end)

	select @loc_de_munca=isnull(@loc_de_munca,p.loc_de_munca), @loc_de_munca_ptr_stat=(case when p.loc_de_munca<>isnull(@loc_de_munca,p.loc_de_munca) then 0 else 1 end),
		@tip_salarizare=isnull(@tip_salarizare,p.tip_salarizare),
		@regim_de_lucru=(case when @regim_de_lucru<>0 then @regim_de_lucru 
			when @RegimLVariabil=1 and p.Salar_lunar_de_baza<>0 then round(p.salar_lunar_de_baza/(case when p.Tip_salarizare in ('1','2') then @OreLuna else @OreMedLuna end)*8,0) 
			when p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end),
		@salar_orar=round((case when @Bugetari=1 then p.salar_de_baza else p.salar_de_incadrare end)/(case when convert(int,p.tip_salarizare)>2 then @OreMedLuna else @OreLuna end),3),
		@grupa_de_munca=(case p.grupa_de_munca when 'P' then 'N' when 'C' then 'N' else p.grupa_de_munca end),
		@regimsal=p.Salar_lunar_de_baza, @DataAngajarii=p.Data_angajarii_in_unitate, @Plecat=CONVERT(int,p.Loc_ramas_vacant),
		@DataPlec=p.Data_plec, @salcatl=(case when @SugerezSalCatLucr=1 and @tip_salarizare in ('6','7') and @salcatl=0
		then round((case when @ExistaModifSalarLuna=1 then i.Salar_de_incadrare else p.Salar_de_incadrare end)/(case when convert(int,p.tip_salarizare)>2 then @OreMedLuna else @OreLuna end),3) else @salcatl end)
	from personal p 
		left outer join istPers i on i.Marca=p.Marca and i.Data=DateAdd(day,-1,@datalunii1)
	where p.marca=@marca

	if @salcatl=0 and @tip_salarizare in ('6','7')
	begin
		raiserror('Eroare operare (wScriuPontaj): Salar categoria lucrarii necompletat pentru tip salarizare 6/7!',11,1)
		return -1
	end
	if @datalunii<>dbo.eom(@data_pontaj)
	begin
		raiserror('Eroare operare (wScriuPontaj): Data pontajului trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
		
--	completez comanda cu comanda din salariati daca Nu s-a completat in macheta si [X]Incadrare salariati pe comenzi
	if isnull(@comanda,'')='' and @SalariatiPeComenzi=1 and (@ptupdate=0 or @validcomstrictGE=1)
		select @comanda=centru_de_cost_exceptie from infopers where marca=@marca

	select @sporspecific=isnull(@sporspecific,p.Spor_specific),@sppesteprogr=isnull(@sppesteprogr,p.Spor_sistematic_peste_program),
	@sp1=isnull(@sp1,p.Spor_conditii_1),@sp2=isnull(@sp2,p.Spor_conditii_2),@sp3=isnull(@sp3,p.Spor_conditii_3),
	@sp4=isnull(@sp4,p.Spor_conditii_4),@sp5=isnull(@sp5,p.Spor_conditii_5),@sp6=isnull(@sp6,p.Spor_conditii_6),
	@sp7=isnull(@sp7,i.Spor_cond_7),@sp8=isnull(@sp8,i.Spor_cond_8)
	from personal p 
		left outer join infopers i on i.Marca=p.Marca
	where @ptupdate=0 and p.marca=@marca
	
	if @nrcrt>0
	begin
		set @tlocm=(select loc_de_munca from pontaj where data=@data and marca=@marca and numar_curent=@nrcrt)
		set @tcomanda=(select comanda from realcom where data=@data and marca=@marca and Loc_de_munca=@tlocm and numar_document='PS'+rtrim(convert(char(10),@nrcrt)))
		set @tlocm=isnull(@tlocm,'')
		set @tcomanda=isnull(@tcomanda,'')
		if @tlocm<>@loc_de_munca or @tcomanda<>@comanda
		begin
			Set @stergXML='<row data="'+convert(char(10),@data,101)+'" marca="'+rtrim(@marca)+'" numarpozitie="'+rtrim(convert(char(10),@nrpozitie))+
			'" subtip="'+@subtip+'" tip="'+@tip+'" nrdoc="" codac="" explicatii="" cantitate="1" valoare="0.00" lm="'+rtrim(@tlocm)+
			'" denlm="'+rtrim(@denlm)+'" datasfarsit="'+convert(char(10),@data,101)+'" nrcrt="'+rtrim(convert(char(10),@nrcrt))+'"/>'
			--exec wStergPozitieDocument  @sesiune='',@tipmacheta='SL',@docXML=@stergXML
			exec wStergPontajEfectiv @sesiune=@sesiune, @parXML=@stergXML, @stergere=''
			set @nrcrt=0
		end
	end
--	@tipop = 0 -> adaugare pozitie, 1 -> modificare pozitie
	if @nrcrt>0
	begin
		set @in=@nrcrt
		set @k=-1
		set @tipop=1		
	end
	else 
	begin
		set @i=isnull((select max(numar_curent) from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca),0)

		set @im=isnull((select max(numar_curent) from pontaj where year(data)=year(@data) and month(data)=month(@data) and marca=@marca),0)			
		set @tipop=(case when @i>0 then 1 else 0 end)
		if @tipop=1 and @comanda<>''
		begin
			set @tnrdoc=(select substring(numar_document,3,10) 
				from realcom where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and comanda=@comanda and left(numar_document,2)='PS')
			set @tnrdoc=isnull(@tnrdoc,'0')
			if convert(int,@tnrdoc)>0
				set @i=convert(int,@tnrdoc)
			else
				set @tipop=0
		end
		if @tipop=1
		begin
			set @in=@i
			set @k=-1
		end
		else
		begin
			set @in=@im+1
			set @k=0
		end
	end

-->	daca adaugare atunci sa faca isnull pe variabile. Altfel sa ramina null si daca null sa ramina ce este in tabela	
	if @tipop=0
		select @ore_regie=isnull(@ore_regie,0),@ore_acord=isnull(@ore_acord,0),@oresupl1=isnull(@oresupl1,0),@oresupl2=isnull(@oresupl2,0),@oresupl3=isnull(@oresupl3,0),
			@oresupl4=isnull(@oresupl4,0),@orespor100=isnull(@orespor100,0),@orenoapte=isnull(@orenoapte,0),
			@oreco=isnull(@oreco,0),@orecm=isnull(@orecm,0),@oreintr1=isnull(@oreintr1,0),@oreintr2=isnull(@oreintr2,0),
			@obligcet=isnull(@obligcet,0),@oreinvoiri=isnull(@oreinvoiri,0),@orenem=isnull(@orenem,0),@orecfs=isnull(@orecfs,0),
			@oredetasare=isnull(@oredetasare,0),@oredelegatii=isnull(@oredelegatii,0)

	select @o_regie=(case when @subtip in ('P1','P2') then @ore_regie else @k end),
	@o_acord=(case when @subtip in ('P1','P2') then @ore_acord else @k end),
	@o_supl_1=(case when @subtip in ('P1','P2') then @oresupl1 else @k end),
	@o_supl_2=(case when @subtip in ('P1','P2') then @oresupl2 else @k end),
	@o_supl_3=(case when @subtip in ('P1','P2') then @oresupl3 else @k end),
	@o_supl_4=(case when @subtip in ('P1','P2') then @oresupl4 else @k end),
	@o_spor_100=(case when @subtip in ('P1','P2') then @orespor100 else @k end),
	@o_de_noapte=(case when @subtip in ('P1','P2') then @orenoapte else @k end),
	@o_intr_tehn=(case when @subtip in ('P1','P2') then @oreintr1 else @k end),
	@o_CO=(case when @subtip in ('O1','O2','P1','P2') then @oreco else @k end),
	@o_CM=(case when @subtip in ('M1','M2','P1','P2') then @orecm else @k end),
	@o_invoiri=(case when @subtip in ('E1','E2','P1','P2') then @oreinvoiri else @k end),
	@o_nemotivate=(case when @subtip in ('E1','E2','P1','P2') then @orenem else @k end),
	@o_obl_cet=(case when @subtip in ('O1','O2','P1','P2') then @obligcet else @k end),
	@o_cfs=(case when @subtip in ('E1','E2','P1','P2') then @orecfs else @k end),
	@o_donare_sange=(case when @subtip in ('P1','P2','S1','S2') and @ore6 is not null then @ore6 else @k end),
	@s_cat_lucr=(case when @subtip in ('P1','P2') then @salcatl else @k end),
	@coef_acord=(case when @subtip in ('P1','P2') then @coefacord else @k end),
	@realiz=(case when @subtip in ('P1','P2') then @realizat else @k end),
	@coef_de_timp=(case when @subtip='XX' then @ore_acord else @k end),
	@o_real_acord=(case when @subtip in ('P1','P2') then @orerealizate else @k end),
	@sist_peste_program=(case when @subtip in ('P1','P2','S1','S2') and @sppesteprogr is not null then @sppesteprogr else @k end),
	@o_sist_peste_program=(case when @subtip in ('P1','P2','S1','S2') and @orepesteprogr is not null then @orepesteprogr else @k end),
	@sp_specific=(case when @subtip in ('P1','P2','S1','S2') and @sporspecific is not null then @sporspecific else @k end),
	@sp_conditii_1=(case when @subtip in ('P1','P2','S1','S2') and @sp1 is not null then @sp1 else @k end),
	@sp_conditii_2=(case when @subtip in ('P1','P2','S1','S2') and @sp2 is not null then @sp2 else @k end),
	@sp_conditii_3=(case when @subtip in ('P1','P2','S1','S2') and @sp3 is not null then @sp3 else @k end),
	@sp_conditii_4=(case when @subtip in ('P1','P2','S1','S2') and @sp4 is not null then @sp4 else @k end),
	@sp_conditii_5=(case when @subtip in ('P1','P2','S1','S2') and @sp5 is not null then @sp5 else @k end),
	@sp_conditii_6=(case when @subtip in ('P1','P2','S1','S2') and @sp6 is not null then @sp6 else @k end),
	@o_cond_1=(case when @subtip in ('P1','P2','S1','S2') and @ore1 is not null then @ore1 else @k end),
	@o_cond_2=(case when @subtip in ('P1','P2','S1','S2') and @ore2 is not null then @ore2 else @k end),
	@o_cond_3=(case when @subtip in ('P1','P2','S1','S2') and @ore3 is not null then @ore3 else @k end),
	@o_cond_4=(case when @subtip in ('P1','P2','S1','S2') and @ore4 is not null then @ore4 else @k end),
	@o_cond_5=(case when @subtip in ('P1','P2','S1','S2') and @ore5 is not null then @ore5 else @k end),
	@o_cond_6=(case when @subtip='XX' then @ore_acord else @k end),--tichet de masa
	@sp_cond_7=(case when @subtip in ('P1','P2','S1','S2') and @sp7 is not null then @sp7 else @k end),		
	@tore=(case when @subtip in ('P1','P2') then @oreintr2 else @k end),
	@sp_cond_8=(case when @subtip in ('P1','P2','S1','S2') and @sp8 is not null then @sp8 else @k end),
	@sp_cond_9=(case when @subtip in ('P1','P2') then @oredetasare else @k end),
	@sp_cond_10=(case when @subtip in ('P1','P2') then @oredelegatii else @k end)

	exec scriuPontaj @data, @marca, @in, @loc_de_munca, @loc_de_munca_ptr_stat, @tip_salarizare, @regim_de_lucru,@salar_orar, 
	@o_regie, @o_acord, @o_supl_1, @o_supl_2, @o_supl_3, @o_supl_4, @o_spor_100, @o_de_noapte, @o_intr_tehn, @o_CO, @o_CM, @o_invoiri, 
	@o_nemotivate, @o_obl_cet, @o_cfs, @o_donare_sange, @s_cat_lucr, @coef_acord, @realiz, @coef_de_timp, @o_real_acord, @sist_peste_program,
	@o_sist_peste_program,@sp_specific,@sp_conditii_1, @sp_conditii_2, @sp_conditii_3, @sp_conditii_4, @sp_conditii_5, @sp_conditii_6, 
	@o_cond_1, @o_cond_2, @o_cond_3, @o_cond_4, @o_cond_5, @o_cond_6, @grupa_de_munca, @tore, @sp_cond_7, @sp_cond_8, @sp_cond_9, @sp_cond_10, @comanda, @tipop, 0

	exec pCalcul_salarii_realizate @datalunii1, @datalunii, @marca, @marca, '', 'ZZZZZZ'

--	nu am apelat pt. moment procedura de calcul tichete: sa vedem daca facem calcul doar pe pozitia curenta sau pe toate pozitiile unui salariat.
	if @GestTichete=1 and 1=0
		exec psCalculTichete @datalunii1, @datalunii, @Marca, @loc_de_munca, 1, 1

	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" subtip="'+rtrim(@subtip)+'" marca="'+rtrim(@marca)+'" lmantet="'+rtrim(@lmantet)+'" data="'+convert(char(10),dbo.eom(@data),101)+ '" densalariat="'+rtrim(@densalariat)+'" denlmantet="'+rtrim(@denlmantet)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	if @tip not in ('ME','OD')
		exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 

--	fac validare daca orele justificate difera de orele lucratoare/regimul salariatului (daca se lucreaza cu ture)
	select @orejustificate=sum(Ore_regie+Ore_acord
		-(case when @ScadOSRegN=1 then Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4 else 0 end)
		-(case when @ScadO100RegN=1 then Ore_spor_100 else 0 end)
		+Ore_concediu_de_odihna+Ore_concediu_medical+Ore_nemotivate+Ore_concediu_fara_salar+Ore_invoiri+Ore_obligatii_cetatenesti+Ore_intrerupere_tehnologica+Ore) 
	from pontaj 
	where Data between @datalunii1 and @datalunii and Marca=@marca

	set @OreLunaMarca=@OreLuna*@regim_de_lucru/8
	if @DataAngajarii between @datalunii1 and @datalunii or @Plecat=1 and @DataPlec between @datalunii1 and @datalunii
		set @OreLunaMarca=dbo.zile_lucratoare((case when @DataAngajarii between @datalunii1 and @datalunii then @DataAngajarii else @datalunii1 end),
			(case when @Plecat=1 and @DataPlec between @datalunii1 and @datalunii then DateAdd(day,-1,@DataPlec) else @datalunii end))*@regim_de_lucru
	set @OreLunaMarca=(case when @RegimLVariabil=1 and @OreLunaTura<>0 and @regimsal<>0 then @regimsal else @OreLunaMarca end)

	if @orejustificate<>@OreLunaMarca and @PontajZilnic=0 and not(@tip in ('ME','OD','CA') or @tip='SL' and @subtip in ('M1','O1','E1'))
		select 'Atentie! Numarul de ore justificate in pontaj: '+convert(char(3),@orejustificate)+' este DIFERIT de '+
		(case when @RegimLVariabil=1 and @OreLunaTura<>0 and @regimsal<>0 then 'regimul de lucru de ' else 'numarul de ore lucratoare in luna: ' end)
		+convert(char(3),@OreLunaMarca)+'!' as textMesaj for xml raw, root('Mesaje')

	exec scriuistPers @DataJos=@datalunii1, @DataSus=@DataSus, @pMarca=@marca, @pLocm='', @Stergere=0, @Scriere=1

	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPontajSP2')
		exec wScriuPontajSP2 @sesiune, @parXML OUTPUT
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()+'(wScriuPontaj - linia '+convert(varchar(20),ERROR_LINE())+')'
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
