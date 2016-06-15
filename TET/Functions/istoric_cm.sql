--***
/**	functie istoric CM ce returneaza stagiul de cotizare pentru un concediu medical (zile si baza stagiu)*/
Create function istoric_cm 
	(@pData datetime, @Marca char(6), @Tip_diagnostic char(2), @Data_inceput datetime, @Continuare int, @Suma int, @Luni_istoric int)
returns @istoric_cm table
	(Data datetime, Marca char(6), Total_Ore_lucrate int, ore_suplimentare_1 int, ore_suplimentare_2 int, 
	ore_suplimentare_3 int, ore_suplimentare_4 int, ore_spor_100 int, ore_lucrate_regim_normal int, 
	ore_concediu_de_odihna int, ore_concediu_medical int, ore_nemotivate int, ore_invoiri int, ore_obligatii_cetatenesti int, 
	ore_intrerupere_tehnologica int, ore_concediu_fara_salar int,cm_unitate float, cm_cas float, 
	regim_lucru float, baza_cci float, baza_cci_plaf float, baza_casi float, zile_asig float, 
	Ore_somaj_tehnic float, Baza_somaj_tehnic float)
as
Begin
	declare @utilizator varchar(20), @lista_lm int, @multifirma int, 
	@Data datetime, @vMarca char(6), @Ore_lucrate int, @ore_s1 int, @ore_s2 int, @ore_s3 int, @ore_s4 int, @ore_spor100 int, 
	@ore_rn int, @ore_co int, @ore_cm int, @ore_nemotivate int, @ore_invoiri int, @ore_obligatii int, @ore_intr int, @ore_cfs int, 
	@cm_unitate float, @cm_cas float, @regim_lucru float, @baza_cci float, @baza_cci_plaf float, @baza_casi float, @zile_asig float, @Salar_minim float, 
	@Ore_somaj_tehnic float, @Baza_somaj_tehnic float, @OreS_RN int, @Ore100_RN int, @ORegieFaraOS2 int, @ore_int_rn int, @Zile_nelucr_cm int, @CM_luniant int, 
	@ProcIT1 float, @IT1SuspContr int, @ProcIT2 float, @IT2SuspContr int, @ProcIT3 float, @IT3SuspContr int, @denIntrTehn3 varchar(50), 
	@NuCAS_H int, @CASSimps_K int, @Dafora int, @Somesana int, @Salubris int, @Elite int, @Colas int, @Remarul int, 
	@Data_inceput_CM datetime, @Datajos datetime, @Datasus datetime, @Ore_luna float, @Din_FNUASS int, 
	@cZileAsig int, @TipDiagnosticCMInitial char(2), @DataSCMinitial datetime

	set @utilizator=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	select @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V') set @multiFirma=1

	select @Din_FNUASS=(case when isnull(tip_diagnostic,@Tip_diagnostic) in ('2-','3-','4-') or isnull(tip_diagnostic,@Tip_diagnostic) in ('10','11') and isnull(suma,@Suma)=1 
		then 0 else 1 end) 
	from conmed where data=@pData and marca=@Marca and data_inceput=@Data_inceput
	select @Din_FNUASS=(case when @Tip_diagnostic in ('2-','3-','4-') or @Tip_diagnostic in ('10','11') and @Suma=1 then 0 else 1 end) where @Din_FNUASS is Null
	set @Luni_istoric=(case when @Luni_istoric=0 then 6 else @Luni_istoric end)
	set @Data_inceput_CM=dbo.data_inceput_cm(@pData, @Marca, @Data_inceput, @Continuare)
	select @TipDiagnosticCMInitial=Tip_diagnostic from conmed where Marca=@Marca and Data_inceput=@Data_inceput_CM
	set @Datajos=dbo.eom(dateadd(month,-@Luni_istoric,@Data_inceput_CM))
	set @Datasus=dbo.eom(dateadd(month,-1,@Data_inceput_CM))
	set @DataSCMinitial=dbo.eom(@Data_inceput_CM)

	select 
		@OreS_RN=max(case when Parametru='OSNRN' then Val_logica else 0 end),
		@Ore100_RN=max(case when Parametru='O100NRN' then Val_logica else 0 end),
		@ORegieFaraOS2=max(case when parametru='OREG-FOS2' then Val_logica else 0 end),
		@ore_int_rn=max(case when Parametru='OINTNRN' then Val_logica else 0 end),
		@Zile_nelucr_CM=max(case when Parametru='ZNLCALCCM' then Val_logica else 0 end),
		@CM_luniant=max(case when Parametru='OPCMLANT' then Val_logica else 0 end),
		@ProcIT1=max(case when Parametru='PROCINT' then Val_numerica else 0 end),
		@IT1SuspContr=max(case when Parametru='IT1-SUSPC' then Val_logica else 0 end),
		@ProcIT2=max(case when Parametru='PROC2INT' then Val_numerica else 0 end),
		@IT2SuspContr=max(case when Parametru='PROC2INT' then Val_logica else 0 end),
		@ProcIT3=max(case when Parametru='PROC3INT' then Val_numerica else 0 end),
		@IT3SuspContr=max(case when Parametru='PROC3INT' then Val_logica else 0 end),
		@denIntrTehn3=max(case when Parametru='PROC3INT' then Val_alfanumerica else '' end),
		@NuCAS_H=max(case when Parametru='NUCAS-H' then Val_logica else 0 end),
		@CASSimps_K=max(case when Parametru='ASSIMPS-K' then Val_logica else 0 end),
		@Dafora = max(case when Parametru='DAFORA' then Val_logica else 0 end),
		@Somesana = max(case when Parametru='SOMESANA' then Val_logica else 0 end),
		@Salubris = max(case when Parametru='SALUBRIS' then Val_logica else 0 end),
		@Elite = max(case when Parametru='ELITE' then Val_logica else 0 end),
		@Colas = max(case when Parametru='COLAS' then Val_logica else 0 end),
		@Remarul = max(case when Parametru='REMARUL' then Val_logica else 0 end)
	from par 
	where Tip_parametru='PS' and Parametru in ('OSNRN','O100NRN','OREG-FOS2','OINTNRN','ZNLCALCCM','OPCMLANT','PROCINT','IT1-SUSPC','PROC2INT','PROC3INT','NUCAS-H','ASSIMPS-K')
			or Tip_parametru='SP' and Parametru in ('DAFORA','SOMESANA','SALUBRIS','ELITE','COLAS','REMARUL')

--	creez tabela temporara in care pun datele si fac ordonarea dupa sa nu dea eroare pe SQL2000
	declare @tmp table (data datetime, marca varchar(6), cnp varchar(13), ore_lucrate int, ore_s1 int, ore_s2 int, ore_s3 int, ore_s4 int, 
		ore_100 int, ore_rn int, ore_co int, ore_cm int, ore_nemotivate int, ore_invoiri int, ore_obligatii int, 
		ore_intr int, ore_cfs int, cm_unitate float, cm_cas float, regim_lucru float, baza_cci float, baza_casi float, ore_somaj_tehnic int, zileAsig int)
	
	declare @personal table (marca varchar(6), cnp varchar(13))
	insert into @personal
	select p.marca, p.Cod_numeric_personal
	from personal p
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where (@marca is null or exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca))
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)

--	creez tabela temporara in care pune orele de intrerupere tehnologica din pontaj grupate pe marca, loc de munca
	declare @pontaj table (data datetime, marca varchar(6), loc_de_munca varchar(9), Ore_intr_tehn_1 int, Ore_intr_tehn_2 int, Ore_somaj_tehnic int, Ore_intemperii_Colas int, Ore_intr_tehn_3 float)
	insert into @pontaj
	select dbo.EOM(data) as data, po.Marca, po.Loc_de_munca, 
		sum((case when @IT1SuspContr=1 and @ProcIT1=0 and not (@Remarul=1 and po.data<='04/30/2013') then 0 else Ore_intrerupere_tehnologica end)) as Ore_intr_tehn_1, 
		sum((case when @IT2SuspContr=1 and @ProcIT2=0 then 0 else ore end)) as Ore_intr_tehn_2, 
		sum((case when dbo.iauParLL(dbo.EOM(data),'PS','STOUG28')=1 then ore else 0 end)) as Ore_somaj_tehnic, 
		sum((case when @Colas=1 then spor_cond_8 else 0 end)) as Ore_intemperii, 
		sum((case when @denIntrTehn3<>'' and @IT3SuspContr=1 and @ProcIT3=0 or @Colas=1 then 0 else Spor_cond_8 end)) as Ore_intr_tehn_3
	from pontaj po
		inner join @personal p on p.marca=po.marca
	where data between dbo.BOM(@dataJos) and @dataSus --and (@Marca='' or po.marca=@Marca) inlocuit cu inner join @personal
	group by dbo.EOM(data), po.marca, po.loc_de_munca

	insert into @tmp
	select a.data, a.marca, max(s.cnp) as cnp, sum(a.total_ore_lucrate) as Ore_lucrate, sum(a.ore_suplimentare_1) as Ore_s1, 
		sum(a.ore_suplimentare_2) as Ore_s2, sum(a.ore_suplimentare_3) as Ore_s3, sum(a.ore_suplimentare_4) as Ore_s4, 
		sum(a.Ore_spor_100) as Ore_100, sum(a.ore_lucrate_regim_normal) as Ore_rn, sum(a.ore_concediu_de_odihna) as Ore_co, 
		sum(a.ore_concediu_medical) as Ore_cm, sum(a.ore_nemotivate) as Ore_nemotivate, sum(a.ore_invoiri) as Ore_invoiri, 
		sum(a.ore_obligatii_cetatenesti) as ore_obligatii, 
		sum((case when @Elite=1 then 0 else 1 end)*(isnull(p.Ore_intr_tehn_1,0)+isnull(p.Ore_intr_tehn_2,0)+isnull(Ore_intr_tehn_3,0))+isnull(p.Ore_intemperii_Colas,0)) as Ore_intr, 
		sum(a.ore_concediu_fara_salar) as Ore_cfs, sum(a.ind_c_medical_unitate+a.cmunitate) 
			-isnull((select sum(indemnizatie_unitate) from conmed m where @cm_luniant=1 and m.data=a.data and m.marca=a.marca and month(m.data_inceput)<>month(a.data)),0)
			+isnull((select sum(indemnizatie_unitate) from conmed m where @cm_luniant=1 and m.data<>a.data and m.marca=a.marca 
				and year(m.data_inceput)=year(a.data) and month(m.data_inceput)=month(a.data)),0) as cm_unitate,
		sum(a.ind_c_medical_CAS+a.spor_cond_9+a.cmcas)
			-isnull((select sum(indemnizatie_cas) from conmed m where @cm_luniant=1 and m.data=a.data and m.marca=a.marca and month(m.data_inceput)<>month(a.data)),0) 
			+isnull((select sum(indemnizatie_cas) from conmed m where @cm_luniant=1 and m.data<>a.data and m.marca=a.marca 
				and year(m.data_inceput)=year(a.data) and month(m.data_inceput)=month(a.data)),0) as CM_cas,
		max((case when a.spor_cond_10=0 then 8 else a.spor_cond_10 end)) as Regim_lucru, 
		(case when year(a.data)>=2006 
			then (case when isnull(max(n1.Baza_CAS),0)<>0 
				then isnull(max(n1.Baza_CAS),0)-sum((case when year(a.data)<2011 then a.spor_cond_9 else 0 end)) 
				else sum(a.venit_total-(a.ind_c_medical_CAS+a.cmcas+a.spor_cond_9)-(case when dbo.iauParLL(a.data,'PS','STOUG28')=1 then a.Ind_invoiri else 0 end)
					-(case when @NuCAS_H=1 then a.suma_impozabila else 0 end)
					-(case when @CASSimps_K=1 then a.cons_admin else 0 end)) end) 
			else 0 end) as Baza_cci, 
		isnull(max(n.Baza_CAS),0) as Baza_CASI, 
		sum(isnull(p.Ore_somaj_tehnic,0)) as Ore_somaj_tehnic, 
		0 as ZileAsig
	from brut a
		left outer join net n on n.data=a.data and n.marca=a.marca
		left outer join net n1 on n1.data=dbo.bom(a.data) and n1.marca=a.marca
		left outer join @pontaj p on p.data=a.data and p.marca=a.marca and p.loc_de_munca=a.Loc_de_munca
		inner join @personal s on s.marca=a.marca
	where a.data between @datajos and @datasus -- and a.marca = @marca inlocuit cu inner join @personal
	group by a.marca, a.data
--	selectez si pozitiile care sunt introduse ca implementare pe salariat (pozitiile din net cu data de 15)
	union all
	select dbo.eom(a.data) as Data, a.marca, max(p.Cod_numeric_personal) as cnp, 0 as Ore_lucrate, 0 as Ore_s1, 0 as Ore_s2, 0 as Ore_s3, 0 as Ore_s4, 
	0 as Ore_100, 0 as Ore_rn, 0 as Ore_co, 0 as Ore_cm, 0 as Ore_nemotivate, 0 as Ore_invoiri, 
	0 as ore_obligatii, 0 as Ore_intr, 0 as Ore_cfs, 0 as cm_unitate, 0 as CM_cas,
	max((case when isnull(b.Spor_cond_10,0)<>0 then b.Spor_cond_10 when p.Salar_lunar_de_baza=0 then 8 else p.Salar_lunar_de_baza end)) as Regim_lucru, 
	sum(a.Baza_CAS) as Baza_CCI, 0 as Baza_CASI, 0 as Ore_somaj_tehnic, sum(a.Ded_suplim) as ZileAsig
	from net a
		left outer join personal p on p.Marca=a.Marca
		left outer join brut b on b.Marca=a.Marca and b.data=dbo.EOM(a.Data)
	where a.marca = @marca and a.data between dbo.bom(@datajos) and @datasus and day(a.Data)=15
	group by a.marca, dbo.eom(a.data)

	declare baza_cm cursor for 
--	selectare date salarii rezultate in urma calculului de lichidare pe luni anterioare
	select data, max(marca) as marca, sum(ore_lucrate) as ore_lucrate, sum(ore_s1) as ore_s1, sum(ore_s2) as ore_s2, sum(ore_s3) as ore_s3, sum(ore_s4) as ore_s4, 
		sum(ore_100) as ore_100, sum(ore_rn) as ore_rn, sum(ore_co) as ore_co, sum(ore_cm) as ore_cm, sum(ore_nemotivate) as ore_nemotivate, sum(ore_invoiri) as ore_invoiri, 
		sum(ore_obligatii) as ore_obligatii, sum(ore_intr) as ore_intr, sum(ore_cfs) as ore_cfs, sum(cm_unitate) as cm_unitate, sum(cm_cas) as cm_cas, 
		max(regim_lucru) as regim_lucru, sum(baza_cci) as baza_cci, sum(baza_casi) as baza_casi, sum(ore_somaj_tehnic) as ore_somaj_tehnic, sum(zileAsig) as zileAsig
	from @tmp	
	group by cnp, data
	order by data

	open baza_cm
	fetch next from baza_cm into @Data, @vMarca, @Ore_lucrate, @ore_s1, @ore_s2, @ore_s3, @ore_s4, @ore_spor100, 
		@ore_rn, @ore_co, @ore_cm, @ore_nemotivate, @ore_invoiri, @ore_obligatii, @ore_intr, @ore_cfs, 
		@cm_unitate, @cm_cas, @regim_lucru, @baza_cci, @Baza_casi, @Ore_somaj_tehnic, @cZileAsig
	While @@fetch_status = 0 
	Begin
		set @Salar_minim = dbo.iauParLN(@data,'PS','S-MIN-BR')
		set @Ore_luna = dbo.iauParLN(@data,'PS','ORE_LUNA')
		set @Zile_asig = 0
		set @Baza_somaj_tehnic=(case when @Data>='02/01/2010' and @Din_FNUASS=1 then round(@Ore_somaj_tehnic/@Ore_luna*@Salar_minim,0) else 0 end)
--		determin baza CCI
		set @Baza_cci_plaf = round((case when (case when year(@data)>=2006 then @Baza_cci+@Baza_somaj_tehnic else @Baza_casi+@Cm_unitate end)+@cm_cas>12*@Salar_minim and @data>='11/01/2006' then 12*@Salar_minim 
				else (case when year(@data)>=2006 then @Baza_cci+@Baza_somaj_tehnic else @Baza_casi+@Cm_unitate end)+@cm_cas end),0)
--		determin zile asigurate
		set @Zile_asig = round(((case when @ore_rn = 0 then @ore_lucrate
			-(case when @Somesana=1 and 1=0 then 0 else (case when @OreS_RN=1 then @ore_s1+(case when @ORegieFaraOS2=1 then 0 else @ore_s2 end)+@ore_s3+@ore_s4 else 0 end) end)
			-(case when @ore100_RN=1 then @ore_spor100 else 0 end)
			+(case when @Salubris=1 then @ore_s1+@ore_s2-@ore_s3 else 0 end) else @ore_rn end)+@ore_co+@ore_cm+@ore_obligatii
			+(case when @Elite=1 or @ore_int_rn=1 then 0 else @ore_intr-@Ore_somaj_tehnic end)
			+(case when @Data>='02/01/2010' and @Din_FNUASS=1 then @Ore_somaj_tehnic else 0 end)
			+(case when @Zile_nelucr_cm=1 then @ore_nemotivate+@ore_invoiri+@ore_cfs else 0 end))/@regim_lucru,0)
		set @Zile_asig = @Zile_asig+@cZileAsig
--		daca zile asigurate > zile lucratoare luna, se vor luna in calcul zilele lucratoare din luna
		set @Zile_asig = (case when @Zile_asig > @Ore_luna/8 and @Ore_luna<>0 then @Ore_luna/8 else @Zile_asig end)
					
		insert @istoric_cm
		select @Data, @vMarca, @Ore_lucrate, @ore_s1, @ore_s2, @ore_s3, @ore_s4, @ore_spor100, 
			@ore_rn, @ore_co, @ore_cm, @ore_nemotivate, @ore_invoiri, @ore_obligatii, @ore_intr-@Ore_somaj_tehnic, @ore_cfs, 
			@cm_unitate, @cm_cas, @regim_lucru, @baza_cci, @baza_cci_plaf, @Baza_casi, @Zile_asig, @Ore_somaj_tehnic, 
			@Baza_somaj_tehnic

		fetch next from baza_cm into @Data, @vMarca, @Ore_lucrate, @ore_s1, @ore_s2, @ore_s3, @ore_s4, @ore_spor100, 
		@ore_rn, @ore_co, @ore_cm, @ore_nemotivate, @ore_invoiri, @ore_obligatii, @ore_intr, @ore_cfs, 
		@cm_unitate, @cm_cas, @regim_lucru, @baza_cci, @Baza_casi, @Ore_somaj_tehnic, @cZileAsig
	End
--	inserez stagiu: baza=salar de incadrare, zile=zile lucratoare in luna 
--	pt. tip diagnostic=Urgenta si daca nu exista stagiu pe ultimele 6 luni
if isnull((select sum(baza_cci_plaf) from @istoric_cm),0)=0 and @Luni_istoric=6	and @TipDiagnosticCMInitial='6-' 
	if (@Tip_diagnostic<>'1-' or isnull((select sum(Zile_asig) from istoric_cm (@pData, @Marca, @Tip_diagnostic, @Data_inceput, @Continuare, @Suma, 12)),0)>=21)
/*	Am pus ca conditia de mai sus (tip diagnostic) intrucat Aurel Bican zice ca, daca exista un concediu medical (boala obisnuita) 
	in continuare la un concediu medical tip urgenta (care se plateste si fara stagiu), CM-ul (boala obisnuita) nu ar trebui platit
	Totusi se plateste daca salariatul are 1 luna stagiu de cotizare in ultimele 12 luni.
*/
	Begin
		if not exists (select Marca from @istoric_cm where Data=dbo.eom(DateAdd(month,-1,@DataSCMinitial)) and Marca=@Marca)
			insert into @istoric_cm
			select dbo.eom(DateAdd(month,-1,@DataSCMinitial)), @Marca, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			(case when isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)=0 then 8 else isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza) end) as regim_lucru, 
			isnull(i.Salar_de_baza,p.Salar_de_baza), (case when isnull(i.Salar_de_baza,p.Salar_de_baza)>12*dbo.iauParLN(@pData,'PS','S-MIN-BR') then 12*dbo.iauParLN(@pData,'PS','S-MIN-BR') else isnull(i.Salar_de_baza,p.Salar_de_baza) end) as Baza_CCI_plaf, 
			0, dbo.iauParLN(@DataSCMinitial,'PS','ORE_LUNA')/8 as zile_asig, 0, 0
			from personal p
				left outer join istPers i on p.Marca=i.Marca and i.Data=@DataSCMinitial
			where p.Marca=@Marca
		else		
			update @istoric_cm set Baza_CCI=isnull(i.Salar_de_baza,p.Salar_de_baza),
			Baza_CCI_plaf=(case when isnull(i.Salar_de_baza,p.Salar_de_baza)>12*dbo.iauParLN(@pData,'PS','S-MIN-BR') then 12*dbo.iauParLN(@pData,'PS','S-MIN-BR') else isnull(i.Salar_de_baza,p.Salar_de_baza) end),
			Zile_asig=dbo.iauParLN(@DataSCMinitial,'PS','ORE_LUNA')/8
			from @istoric_cm cm
				left outer join personal p on p.Marca=cm.Marca
				left outer join istPers i on i.Marca=cm.Marca and i.Data=@DataSCMinitial
			where cm.Marca=@Marca and cm.Data=dbo.eom(DateAdd(month,-1,@DataSCMinitial))
	End
	close baza_cm
	Deallocate baza_cm

	return
End
