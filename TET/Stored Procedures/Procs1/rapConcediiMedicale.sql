/**	procedura pentru raportul de concedii medicale */
Create procedure rapConcediiMedicale
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @tipdiagnostic char(2)=null, @tipdiagnosticExceptat char(2)=null,
	@locm char(9)=null, @strict int=0, @activitate varchar(20)=null, @ordonare char(1), @alfabetic int, @CMmm30Zile int, @Luni_istoric int=6, @listadreptcond char(1)='T') 
as
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#concedii_medicale') is not null drop table #concedii_medicale

	declare @Data datetime, @dataJosPoz datetime, @vmarca char(6), @Nume char(50), @cnp varchar(13), @lm char(9), @denlm char(50), 
	@ore_luna float, @salar_mediu float, @salar_minim float, @pr_somaj float, @proc_somaj float, @proc_cas float, 
	@Medie_zilnica float, @Cod_diagnostic char(2), @Denumire_diagnostic char(30), @Data_inceput datetime, @Data_sfarsit datetime, @Procent float, @Zile_calendaristice int, 
	@Zile_unitate int, @Zile_buget int, @Indemnizatie_unitate float, @Indemnizatie_FNUASS float, @Indemnizatie_FAAMBP float, @Indemnizatie_neta float, @Indemnizatie_bruta float, 
	@Data_inceput_cm_initial datetime, @baza_calcul float, @Tip_concediu char(10), @datacmi datetime, @Zile_anterioare int, @Zile_lucratoare int, @zile_platite_FNUASS int, 
	@zile_platite_FAMBP int, @vechime datetime, @spor10 float, @data_risc int, @serie_cmini char(10), @nrpersintr int, @deducere float, @baza_impozit float, @impozit float, 
	@ord char(30), @ord1 char(30), @Continuare int, @ZileCMsusp int, @total_indemniz_marca decimal(10), @total_deducere decimal(10)

	declare @dreptConducere int, @areDreptCond int, @lista_drept char(1), @utilizator varchar(20)	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	SET @utilizator = dbo.fIaUtilizator('')
	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @salar_mediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @salar_minim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @pr_somaj=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @proc_cas=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept=@listaDreptcond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end

	Create table #concedii_medicale
		(data datetime, marca char(6), nume char(50), cnp varchar(13), loc_de_munca char(9), denumire_lm char(30), vechime datetime, spor10 float, 
		tip_diagnostic varchar(2), denumire_diagnostic char(30), Data_inceput datetime, Data_sfarsit datetime, 
		zile_calendaristice int, zile_lucratoare int, zile_unitate int, zile_buget int, zile_anterioare int, medie_zilnica float, procent float, 
		indemnizatie_unitate float, indemnizatie_fnuass float, indemnizatie_fambp float, indemnizatie_neta float, 
		zile_platite_fnuass int, zile_platite_fambp int, Data_inceput_cm_initial datetime, baza_calcul float,
		Baza1 float, Baza2 float, Baza3 float, Baza4 float, Baza5 float, Baza6 float, 
		Baza7 float, Baza8 float, Baza9 float, Baza10 float, Baza11 float, Baza12 float, Baza_Stagiu float, 
		Z_st1 int, Z_st2 int, Z_st3 int, Z_st4 int, Z_st5 int, Z_st6 int, Z_st7 int, Z_st8 int, Z_st9 int, Z_st10 int, Z_st11 int, Z_st12 int, Zile_Stagiu int, 
		Z_luc1 int, Z_luc2 int, Z_luc3 int, Z_luc4 int, Z_luc5 int, Z_luc6 int, Z_luc7 int, Z_luc8 int, Z_luc9 int, Z_luc10 int, Z_luc11 int, Z_luc12 int, 
		Tip_concediu char(10), data_risc int, serie_cmini char(10), ordonare char(30), ordonare1 char(30),
		Luna1 char(7), Luna2 char(7), Luna3 char(7), Luna4 char(7), Luna5 char(7), Luna6 char(7), 
		Luna7 char(7), Luna8 char(7), Luna9 char(7), Luna10 char(7), Luna11 char(7), Luna12 char(7))

	declare concedii_medicale cursor for 
	select a.data, a.marca, isnull(i.Nume,p.Nume), p.Cod_numeric_personal, isnull(i.Loc_de_munca,p.Loc_de_munca), lm.denumire, 
		(case when p.Somaj_1=1 then @pr_somaj else 0 end) as proc_somaj, 
		a.Indemnizatia_zi, a.Tip_diagnostic, d.Denumire, a.Data_inceput, a.Data_sfarsit, a.Procent_aplicat, day(a.data_sfarsit-a.data_inceput), 
		a.Zile_lucratoare, a.Zile_cu_reducere, a.Zile_lucratoare-a.Zile_cu_reducere, a.zile_luna_anterioara, a.Indemnizatie_unitate,
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then 0 else indemnizatie_CAS end), 
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then indemnizatie_CAS else 0 end), 
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then 0 else a.zile_lucratoare-a.zile_cu_reducere end),
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then a.zile_lucratoare-a.zile_cu_reducere else 0 end),
		(case when a.Zile_luna_anterioara=0 and isnull(e.Serie_certificat_CM_initial,'')='' or a.Tip_diagnostic='0-' then a.Data_inceput else 
		(select dbo.data_inceput_cm(@dataSus, a.marca, a.Data_inceput, 1)) end), 
		(case when a.Zile_luna_anterioara=0 and isnull(e.Serie_certificat_CM_initial,'')='' then 'Initial' else 'Continuare' end),
		a.baza_calcul, p.vechime_totala, ip.spor_cond_10, a.suma as data_risc, isnull(e.serie_certificat_cm_initial,'') as serie_certificat_cm_initial, 
		isnull((select count(1) from persintr s where s.data=a.data and s.marca=a.marca and s.coef_ded<>0),0),
		isnull((select sum(cm.Indemnizatie_unitate+cm.Indemnizatie_CAS) from conmed cm where cm.data=a.data and cm.marca=a.marca),0),
		(case when @ordonare='1' then '' when @ordonare='2' then a.tip_diagnostic else isnull(i.loc_de_munca,p.loc_de_munca) end) as ordonare,
		(case when @alfabetic=1 then p.nume else a.marca end) as ordonare1
	from conmed a
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join personal p on a.Marca=p.Marca
		left outer join infopers ip on a.Marca=ip.Marca
		left outer join lm on isnull(i.Loc_de_munca,p.Loc_de_munca)=lm.Cod
		left outer join infoconmed e on a.Data=e.Data and a.Marca=e.Marca and a.Data_inceput=e.Data_inceput
		left outer join dbo.fDiagnostic_CM() d on a.Tip_diagnostic=d.Tip_diagnostic
	where a.data between @dataJos and @dataSus and (@marca is null or a.marca=@marca)
		and (@locm is null or isnull(i.Loc_de_munca,p.Loc_de_munca) like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@tipdiagnostic is null or a.tip_diagnostic=@tipdiagnostic)
		and (@tipdiagnosticExceptat is null or a.tip_diagnostic<>@tipdiagnosticExceptat) 
		and (@activitate is null or p.Activitate=@activitate) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 
				or @lista_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)))
	order by ordonare, ordonare1, a.data

	open concedii_medicale
	fetch next from concedii_medicale into @Data, @Marca, @Nume, @cnp, @lm, @denlm, @proc_somaj, 
		@Medie_zilnica, @Cod_diagnostic, @Denumire_diagnostic, @Data_inceput, @Data_sfarsit, @Procent, 
		@Zile_calendaristice, @Zile_lucratoare, @Zile_unitate, @Zile_buget, @Zile_anterioare, @Indemnizatie_unitate, @Indemnizatie_FNUASS, @Indemnizatie_FAAMBP, @zile_platite_FNUASS, 
		@zile_platite_FAMBP, @Data_inceput_cm_initial, @Tip_concediu, @baza_calcul, @vechime, @spor10, @data_risc, @serie_cmini, @nrpersintr, @total_indemniz_marca, @ord, @ord1
	While @@fetch_status = 0 
	Begin
		if dbo.EOM(@dataJos)<>dbo.EOM(@dataSus)
		Begin
			set @ore_luna=dbo.iauParLN(dbo.eom(@Data_inceput),'PS','ORE_LUNA')
			if @ore_luna=0
				set @ore_luna=dbo.zile_lucratoare(dbo.bom(@Data_inceput),dbo.eom(@Data_inceput))*8
			set @salar_mediu=dbo.iauParLN(dbo.eom(@Data_inceput),'PS','SALMBRUT')
			set @salar_minim=dbo.iauParLN(dbo.eom(@Data_inceput),'PS','S-MIN-BR')
		End

		set @dataJosPoz=dbo.bom(@Data)
		set @datacmi=dbo.eom(@Data_inceput_cm_initial)	
		set @Continuare=(case when @Zile_anterioare>0 or @serie_cmini<>'' then 1 else 0 end)
		select @ZileCMsusp=Zile_CM_suspendare from dbo.fPSCalculZileCMSuspendare(@Marca,@dataJosPoz,@Data)
--	calcul indemnizatie neta functie de contributiile sociale retinute pt. CM si impozit
		select @Indemnizatie_neta=0, @deducere=0, @baza_impozit=0, @impozit=0, @total_deducere=0
		set @Indemnizatie_bruta=@Indemnizatie_unitate+@Indemnizatie_FNUASS+@Indemnizatie_FAAMBP
		if @total_indemniz_marca<>0
		Begin
			exec calcul_deducere @total_indemniz_marca, @nrpersintr, @total_deducere output
			set @deducere=round(@total_deducere*@Indemnizatie_bruta/@total_indemniz_marca,0)
		End	
		
		set @Indemnizatie_neta=@indemnizatie_bruta-round(@Indemnizatie_unitate*@proc_somaj/100,0)
			-(case when @Cod_diagnostic<>'0-' and not(@Cod_diagnostic='2-' or @Cod_diagnostic='3-' or @Cod_diagnostic='4-' or (@Cod_diagnostic='10' or @Cod_diagnostic='11') and @data_risc=1) 
				then round((case when year(@Data_inceput)>=2011 then 0.35*@salar_mediu else @salar_minim end)*@Zile_lucratoare/(@ore_luna/8)*@proc_cas/100,0) else 0 end)
		if @Cod_diagnostic not in ('8-','9-','15')
		Begin
			set @baza_impozit=@Indemnizatie_neta-@deducere
			exec calcul_impozit_salarii @baza_impozit, @impozit output, 0
		End	
		set @Indemnizatie_neta=@Indemnizatie_neta-@impozit
--	sfarsit calcul indemnizatie neta

		if @CMmm30Zile=0 or @ZileCMsusp>0
			insert #concedii_medicale
			select @Data, @Marca, @Nume, @cnp, @lm, @denlm, @vechime, @spor10, 
				(case when left(@Cod_diagnostic,1)='0' then left(@Cod_diagnostic,1) when RIGHT(@Cod_diagnostic,1)='-' then '0'+LEFT(@Cod_diagnostic,1) else @Cod_diagnostic end), 
				@Denumire_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_calendaristice, @Zile_lucratoare, @Zile_unitate, @Zile_buget, @Zile_lucratoare, @Medie_zilnica, @Procent, 
				@Indemnizatie_unitate, @Indemnizatie_FNUASS, @Indemnizatie_FAAMBP, @Indemnizatie_neta, 
				@zile_platite_FNUASS, @zile_platite_FAMBP, @Data_inceput_cm_initial, @baza_calcul,
				Baza_stagiu1, Baza_stagiu2, Baza_stagiu3, Baza_stagiu4, Baza_stagiu5, Baza_stagiu6, Baza_stagiu7, Baza_stagiu8, Baza_stagiu9, Baza_stagiu10, Baza_stagiu11, Baza_stagiu12, 0,
				Zile_stagiu1, Zile_stagiu2, Zile_stagiu3, Zile_stagiu4, Zile_stagiu5, Zile_stagiu6, Zile_stagiu7, Zile_stagiu8, Zile_stagiu9, Zile_stagiu10, Zile_stagiu11, Zile_stagiu12, 0,
				Zile_lucr1, Zile_lucr2, Zile_lucr3, Zile_lucr4, Zile_lucr5, Zile_lucr6, Zile_lucr7, Zile_lucr8, Zile_lucr9, Zile_lucr10, Zile_lucr11, Zile_lucr12, 
				@Tip_concediu, @data_risc, @serie_cmini, @ord, @ord1,
				right(convert(char(10),Luna1,104),7), right(convert(char(10),Luna2,104),7), right(convert(char(10),Luna3,104),7), 
				right(convert(char(10),Luna4,104),7), right(convert(char(10),luna5,104),7), right(convert(char(10),Luna6,104),7), 
				right(convert(char(10),Luna7,104),7), right(convert(char(10),Luna8,104),7), right(convert(char(10),Luna9,104),7), 
				right(convert(char(10),Luna10,104),7), right(convert(char(10),Luna11,104),7), right(convert(char(10),Luna12,104),7)
				
			from dbo.stagiu_cm (@Data, @Marca, @Data_inceput, @Datacmi, @Continuare, @Luni_istoric) 

		fetch next from concedii_medicale into @Data, @Marca, @Nume, @cnp, @lm, @denlm, @proc_somaj, @Medie_zilnica, @Cod_diagnostic, @Denumire_diagnostic, 
			@Data_inceput, @Data_sfarsit, @Procent, @Zile_calendaristice, @Zile_lucratoare, @Zile_unitate, @Zile_buget, @Zile_anterioare, 
			@Indemnizatie_unitate, @Indemnizatie_FNUASS, @Indemnizatie_FAAMBP, @zile_platite_FNUASS, @zile_platite_FAMBP, 
			@Data_inceput_cm_initial, @Tip_concediu, @baza_calcul, @vechime, @spor10, @data_risc, @serie_cmini, @nrpersintr, @total_indemniz_marca, @ord, @ord1
	End
	update #concedii_medicale Set Baza_Stagiu=Baza1+Baza2+Baza3+Baza4+Baza5+Baza6, Zile_Stagiu=Z_st1+Z_st2+Z_st3+Z_st4+Z_st5+Z_st6

	select Data, Marca, Nume, Loc_de_munca, Denumire_lm, vechime, spor10, 
		Tip_diagnostic, Denumire_diagnostic, Data_inceput as Data_inceput, Data_sfarsit as Data_sfarsit, 
		Zile_lucratoare, Zile_calendaristice, Zile_unitate, Zile_buget, Zile_anterioare, Medie_zilnica, Procent, 
		Indemnizatie_unitate, Indemnizatie_FNUASS, Indemnizatie_FAMBP, indemnizatie_neta, 
		zile_platite_FNUASS, zile_platite_FAMBP, baza_calcul, data_risc, serie_cmini, data_inceput_cm_initial, Tip_concediu, 
		Luna12, Baza12, Z_luc12, Z_st12, Luna11, Baza11, Z_luc11, Z_st11, Luna10, Baza10, Z_luc10, Z_st10, Luna9, Baza9, Z_luc9, Z_st9, 
		Luna8, Baza8, Z_luc8, Z_st8, Luna7, Baza7, Z_luc7, Z_st7, Luna6, Baza6, Z_luc6, Z_st6, Luna5, Baza5, Z_luc5, Z_st5, 
		Luna4, Baza4, Z_luc4, Z_st4, Luna3, Baza3, Z_luc3, Z_st3, Luna2, Baza2, Z_luc2, Z_st2, Luna1, Baza1, Z_luc1, Z_st1, 
		Baza_Stagiu, Zile_Stagiu, cnp, ordonare
	from #concedii_medicale
	order by ordonare, ordonare1, data
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapConcediiMedicale (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='concedii_medicale' and session_id=@@SPID )
if @cursorStatus=1 
	close concedii_medicale 
if @cursorStatus is not null 
	deallocate concedii_medicale 

if object_id('tempdb..#concedii_medicale') is not null drop table #concedii_medicale

/*
	exec rapConcediiMedicale '05/01/2012', '05/31/2012', '123', null, null, null, 0, null, '1', 0, 0, 6, 'C'
*/
