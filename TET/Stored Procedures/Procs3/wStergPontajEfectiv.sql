--***
Create procedure wStergPontajEfectiv @sesiune varchar(50), @parXML xml, @stergere int=0
as
declare @lmantet char(9), @tip varchar(2), @subtip varchar(2), @data datetime, @marca varchar(6), @loc_de_munca varchar(9), @grupdoc varchar(20),   @i int, @in int, @data_pontaj datetime, @ore_regie float, @densalariat varchar(50), @denlm varchar(30), @denfunctie varchar(30),@im int, 
@salarincadrare float, @tipop int,
@loc_de_munca_ptr_stat int,@tip_salarizare varchar(1),@regim_de_lucru float,@salar_orar float,@ore_luna int,
@ore_med int,@k int,@grupa_de_munca varchar(1),@ore_acord float,@oresupl1 float,@oresupl2 float,@oresupl3 float,
@oresupl4 float,@orespor100 float,@orenoapte float,@oreco float,@orecm float,@oreintr1 float,@oreintr2 float,
@obligcet float,@bug int,@oreinvoiri float,@orenem float,@orecfs float,@oredetasare float,@oredelegatii float,
@sporspecific float,@orepesteprogr float,@sppesteprogr float,@ore1 float,@ore2 float,@ore3 float,@ore4 float,@ore5 float,
@ore6 float,@sp1 float,@sp2 float,@sp3 float,@sp4 float,@sp5 float,@sp6 float,@sp7 float,@sp8 float,@numarcurent float, 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254)

declare @o_regie int,@o_acord int,@o_supl_1 int,@o_supl_2 int,@o_supl_3 int,@o_supl_4 int,@o_spor_100 int, @o_de_noapte int, @o_intr_tehn int,@o_CO int,@o_CM int,@o_invoiri int, @o_nemotivate int,@o_obl_cet int,@o_cfs int, @o_donare_sange int,
@s_cat_lucr float,@coef_acord float,@realizat float,@coef_de_timp float,@o_real_acord float,
@sist_peste_program float,@o_sist_peste_program int,@sp_specific float,@sp_conditii_1 float, @sp_conditii_2 float, @sp_conditii_3 float, @sp_conditii_4 float,@sp_conditii_5 float,@sp_conditii_6 float, @o_cond_1 int,@o_cond_2 int,@o_cond_3 int,@o_cond_4 int, @o_cond_5 int,@o_cond_6 int, @tore int,@sp_cond_7 float,@sp_cond_8 float,@sp_cond_9 float,@sp_cond_10 float,@nrcom int

begin try
	--BEGIN TRAN
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select @lmantet=lmantet, @tip=isnull(tip,''),@subtip=isnull(subtip,''),@marca=isnull(marca,''),@data=isnull(data,getdate()),
	@densalariat=isnull(densalariat,''),@denlm=isnull(denlm,''),@denfunctie=isnull(denfunctie,''),
	@salarincadrare=isnull(salarincadrare,0),@loc_de_munca=isnull(loc_de_munca,null),@data_pontaj=isnull(data_pontaj,getdate()),
	@ore_regie=isnull(ore_regie,0),@ore_acord=isnull(ore_acord,0),@oresupl1=isnull(oresupl1,0),@oresupl2=isnull(oresupl2,0),
	@oresupl3=isnull(oresupl3,0),@oresupl4=isnull(oresupl4,0),@orespor100=isnull(orespor100,0),@orenoapte=isnull(orenoapte,0),
	@oreco=isnull(oreco,0),@orecm=isnull(orecm,0),@oreintr1=isnull(oreintr1,0),@oreintr2=isnull(oreintr2,0),@obligcet=isnull(obligcet,0),
	@oreinvoiri=isnull(oreinvoiri,0),@orenem=isnull(orenem,0),@orecfs=isnull(orecfs,0),@oredetasare=isnull(oredetasare,0),@oredelegatii=isnull(oredelegatii,0),
	@sporspecific=sporspecific,@sppesteprogr=sppesteprogr,@orepesteprogr=orepesteprogr,
	@sp1=sp1,@ore1=ore1,@sp2=sp2,@ore2=ore2,@sp3=sp3,@ore3=ore3,@sp4=sp4,@ore4=ore4,@sp5=sp5,@ore5=ore5,
	@sp6=sp6,@ore6=ore6,@sp7=sp7,@sp8=sp8,@numarcurent=isnull(numarcurent,0), @grupdoc=isnull(loc_de_munca,'') 
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		lmantet varchar(9) '@lmantet', 
		tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip',
		marca varchar(6) '@marca', 
		data datetime '@data',
		densalariat varchar(50) '@densalariat', 
		denlm varchar(30) '@denlm', 
		denfunctie varchar(30) '@denfunctie', 
		salarincadrare float '@salarincadrare', 
		loc_de_munca varchar(9) '@lm', 
		data_pontaj datetime '@data', 
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
		sppesteprogr float '@sppesteprogr',
		orepesteprogr float '@orepesteprogr',
		sp1 float '@sp1',
		ore1 float '@ore1',
		sp2 float '@sp2',
		ore2 float '@ore2',
		sp3 float '@sp3',
		ore3 float '@ore3',
		sp4 float '@sp4',
		ore4 float '@ore4',
		sp5 float '@sp5',
		ore5 float '@ore5',
		sp6 float '@sp6',
		ore6 float '@ore6',
		sp7 float '@sp7',
		sp8 float '@sp8',
		numarcurent float '@nrcrt'
	)
	select @loc_de_munca=isnull(@loc_de_munca,a.loc_de_munca),
	@loc_de_munca_ptr_stat=a.loc_munca_pentru_stat_de_plata,
	@tip_salarizare=a.tip_salarizare,@regim_de_lucru=a.regim_de_lucru,
	@salar_orar=a.salar_orar,
	@grupa_de_munca=a.grupa_de_munca
	from pontaj a where a.marca=@marca and numar_curent=@numarcurent and data=@data_pontaj and loc_de_munca=@loc_de_munca
	set @i=isnull((select max(numar_curent) from pontaj where data=@data_pontaj and marca=@marca and loc_de_munca=@loc_de_munca),0)
	set @im=isnull((select max(numar_curent) from pontaj where year(data)=year(@data_pontaj) and month(data)=month(@data_pontaj) and marca=@marca),0)			
	set @tipop=1
	set @k=-1
		
	select @o_regie=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_acord=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_supl_1=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_supl_2=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_supl_3=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_supl_4=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_spor_100=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_de_noapte=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_intr_tehn=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_CO=(case when @subtip in ('O1','O2') then 0 else @k end),
	@o_CM=(case when @subtip in ('M1','M2') then 0 else @k end),
	@o_invoiri=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_nemotivate=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_obl_cet=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_cfs=(case when @subtip in ('P1','P2') then 0 else @k end),
	@o_donare_sange=(case when @subtip in ('P1','P2','S1','S2') and @ore6 is not null then 0 else @k end),
	@s_cat_lucr=(case when @subtip in ('P1','P2') then 0 else @k end),
	@coef_acord=(case when @subtip in ('P1','P2') then 0 else @k end),
	@realizat=(case when @subtip in ('P1','P2') then 0 else @k end),
	@coef_de_timp=(case when @subtip='XX' then 0 else @k end),
	@o_real_acord=(case when @subtip in ('P1','P2') then 0 else @k end),
	@sist_peste_program=(case when @subtip in ('P1','P2','S1','S2') and @sppesteprogr is not null then 0 else @k end),
	@o_sist_peste_program=(case when @subtip in ('P1','P2','S1','S2') and @orepesteprogr is not null then 0 else @k end),
	@sp_specific=(case when @subtip in ('P1','P2','S1','S2') and @sporspecific is not null then 0 else @k end),
	@sp_conditii_1=(case when @subtip in ('P1','P2','S1','S2') and @sp1 is not null then 0 else @k end),
	@sp_conditii_2=(case when @subtip in ('P1','P2','S1','S2') and @sp2 is not null then 0 else @k end),
	@sp_conditii_3=(case when @subtip in ('P1','P2','S1','S2') and @sp3 is not null then 0 else @k end),
	@sp_conditii_4=(case when @subtip in ('P1','P2','S1','S2') and @sp4 is not null then 0 else @k end),
	@sp_conditii_5=(case when @subtip in ('P1','P2','S1','S2') and @sp5 is not null then 0 else @k end),
	@sp_conditii_6=(case when @subtip in ('P1','P2','S1','S2') and @sp6 is not null then 0 else @k end),
	@o_cond_1=(case when @subtip in ('P1','P2','S1','S2') and @ore1 is not null then 0 else @k end),
	@o_cond_2=(case when @subtip in ('P1','P2','S1','S2') and @ore2 is not null then 0 else @k end),
	@o_cond_3=(case when @subtip in ('P1','P2','S1','S2') and @ore3 is not null then 0 else @k end),
	@o_cond_4=(case when @subtip in ('P1','P2','S1','S2') and @ore4 is not null then 0 else @k end),
	@o_cond_5=(case when @subtip in ('P1','P2','S1','S2') and @ore5 is not null then 0 else @k end),
	@o_cond_6=(case when @subtip='XX' then 0 else @k end),--tichet de masa
	@sp_cond_7=(case when @subtip in ('P1','P2','S1','S2') and @sp7 is not null then 0 else @k end),		
	@tore=(case when @subtip in ('P1','P2') then 0 else @k end),--ore intrerupere 2
	@sp_cond_8=(case when @subtip in ('P1','P2','S1','S2') and @sp8 is not null then 0 else @k end),
	@sp_cond_9=(case when @subtip in ('P1','P2') then 0 else @k end),--ore detasare
	@sp_cond_10=(case when @subtip in ('P1','P2') then 0 else @k end)--ore detasare

	exec scriuPontaj @data_pontaj,@marca,@numarcurent,@loc_de_munca,@loc_de_munca_ptr_stat,@tip_salarizare,@regim_de_lucru,@salar_orar,
	@o_regie,@o_acord,@o_supl_1,@o_supl_2,@o_supl_3,@o_supl_4,@o_spor_100,@o_de_noapte,@o_intr_tehn,@o_CO,@o_CM, @o_invoiri, @o_nemotivate,@o_obl_cet,@o_cfs,@o_donare_sange,@s_cat_lucr,@coef_acord,
	@realizat,@coef_de_timp,@o_real_acord,@sist_peste_program,@o_sist_peste_program,@sp_specific,@sp_conditii_1,
	@sp_conditii_2,@sp_conditii_3,@sp_conditii_4,@sp_conditii_5,@sp_conditii_6,@o_cond_1,@o_cond_2,@o_cond_3,
	@o_cond_4,@o_cond_5,@o_cond_6,@grupa_de_munca,@tore,@sp_cond_7,@sp_cond_8,@sp_cond_9,@sp_cond_10,
	'',@tipop,@stergere
	
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" subtip="'+rtrim(@subtip)+'" marca="'+rtrim(@marca)+'" grupdoc="' +rtrim(@grupdoc)+'" lmantet="'+rtrim(@lmantet)
	+'" data="'+rtrim(convert(char(10),dbo.eom(@data),101))+ '" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" 	denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
