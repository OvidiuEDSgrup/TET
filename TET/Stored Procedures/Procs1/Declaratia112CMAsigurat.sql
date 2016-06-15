--***
Create procedure Declaratia112CMAsigurat
	(@dataJos datetime, @dataSus datetime, @lm char(9))
As
Begin
	declare @OreLuna int, @pCASIndiv decimal(4,2), @SalMin decimal(7), @SalMediu decimal(7)

	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @pCASIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @SalMin=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @SalMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')

	if object_id('tempdb..#CMAsigurat') is not null drop table #CMAsigurat
	if object_id('tempdb..#DateCM') is not null drop table #DateCM
	if object_id('tempdb..#cmcnp') is not null drop table #cmcnp

	create table #CMAsigurat
	(Data datetime, TagAsigurat char(20), Marca char(6), CNP char(13), Zile_prestatii_CN int, Zile_prestatii_CD int, Zile_prestatii_CS int, 
		Zile_CM_fnuass int, Zile_CM_faambp int, Zile_faambp int, NRZ_CFP int, Baza_CASCM decimal (10), 
		Indemniz_angajator_faambp decimal(10), Indemniz_Faambp decimal(10), Total_indemniz decimal(10),
		Indemniz_angajator_fnuass decimal(10), Indemniz_fnuass decimal(10))

	create table #DateCM 
		(Data datetime, TagAsigurat char(20), Marca char(6), CNP char(13), Zile_prestatii int, Zile_prestatii_CN int, Zile_prestatii_CD int, Zile_prestatii_CS int, 
		Zile_CM_fnuass int, Zile_CM_faambp int, Zile_faambp int, Baza_CASCM decimal (10), 
		Indemniz_angajator_faambp decimal(10), Indemniz_Faambp decimal(10), Total_indemniz decimal(10),
		Indemniz_angajator_fnuass decimal(10), Indemniz_fnuass decimal(10), ExistaCMCNP int)

--	creare cursor pt. verificare existenta CM pe acelasi CNP, alta marca si aceeasi perioada
	select a.Data, a.Marca, a.Data_inceput, 
		(case when exists (select 1 from #conmed cm left outer join personal p1 on cm.Marca=p1.Marca 
		where cm.Marca<>a.Marca and cm.Data_inceput=a.Data_inceput and p1.Cod_numeric_personal=p.Cod_numeric_personal) then 1 else 0 end) as NrCMCNP
	into #cmcnp
	from #conmed a 
		left outer join personal p on a.marca = p.marca 
	where a.data_inceput between @dataJos and @dataSus 
		and not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1)
		and a.tip_diagnostic<>'0-' 

	insert into #DateCM
	select a.Data, max(ta.TagAsigurat), a.Marca as Marca, max(p.cod_numeric_personal) as CNP, 
		isnull((select round(sum(b.ore_concediu_medical/b.regim_de_lucru),0) from pontaj b where b.data between @dataJos and @dataSus and b.marca=a.marca),0) as Zile_prestatii, 
		isnull((select round(sum(round(m.zile_lucratoare*(case when m.Tip_diagnostic='10' then 0.25 else 1 end),0)),0) 
			from #conmed m where m.data_inceput between @dataJos and @dataSus and m.marca=a.marca and m.tip_diagnostic not in ('2-','3-','4-','0-')
			and m.marca in (select t.marca from pontaj t where t.marca=m.marca and year(t.data)=year(m.data) and month(t.data)=month(m.data) and t.grupa_de_munca='N' 
				and t.ore_concediu_medical<>0)),0) as Zile_prestatii_CN, 
		isnull((select round(sum(round(m.zile_lucratoare*(case when m.Tip_diagnostic='10' then 0.25 else 1 end),0)),0) 
			from #conmed m where m.data_inceput between @dataJos and @dataSus and m.marca=a.marca and m.tip_diagnostic in ('1-','2-','3-','4-','5-','6-','12','13','14') 
			and m.marca in (select t.marca from pontaj t where t.marca=m.marca and year(t.data)=year(m.data) and month(t.data)=month(m.data) and t.grupa_de_munca='D' 
				and t.ore_concediu_medical<>0)),0) as Zile_prestatii_CD, 
		isnull((select round(sum(round(m.zile_lucratoare*(case when m.Tip_diagnostic='10' then 0.25 else 1 end),0)),0) 
			from #conmed m where m.data_inceput between @dataJos and @dataSus and m.marca=a.marca and m.tip_diagnostic in ('1-','2-','3-','4-','5-','6-','12','13','14') 
			and m.marca in (select t.marca from pontaj t where t.marca=m.marca and year(t.data)=year(m.data) and month(t.data)=month(m.data) and t.grupa_de_munca='S' 
				and t.ore_concediu_medical<>0)),0) as Zile_prestatii_CS, 
		sum((case when not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1) 
			then round(a.Zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end),0) else 0 end)) as Zile_CM_fnuass, 
		sum((case when a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1 then a.Zile_lucratoare else 0 end)) as Zile_CM_faambp, 
		sum((case when a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1 
			then a.Zile_lucratoare-a.Zile_cu_reducere else 0 end)) as Zile_faambp, 
		round(convert(float,0.35*@SalMediu)*sum((case when not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1) 
			then round(a.Zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end),0) else 0 end))/max(a.zile_lucratoare_in_luna),0) as Baza_CASCM, 
		sum((case when a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1 
			then a.Indemnizatie_unitate else 0 end)) as Indemniz_angajator_faambp, 
		sum((case when a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1 then a.Indemnizatie_CAS else 0 end)) as Indemniz_faambp, 
		sum(a.Indemnizatie_unitate+a.Indemnizatie_CAS) as Total_indemniz, 
		sum((case when not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1) 
			then a.Indemnizatie_unitate else 0 end)) as Indemniz_angajator_fnuass, 
		sum((case when not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1) 
			then a.Indemnizatie_CAS else 0 end)) as Indemniz_fnuass,
		max(isnull(c.NrCMCNP,0))
	from #conmed a 
		left outer join personal p on a.marca=p.marca 
		left outer join #net n1 on n1.data=dbo.bom(a.data) and n1.marca=a.marca
		left outer join #TagAsigurat ta on a.data=ta.data and a.marca=ta.marca
		left outer join #cmcnp c on a.Data=c.Data and a.Marca=c.Marca and a.Data_inceput=c.Data_inceput
	where a.data_inceput between @dataJos and @dataSus and tip_diagnostic<>'0-'
	group by a.Data, a.Marca

	update #DateCM set Zile_prestatii=Zile_prestatii_CN+Zile_prestatii_CD+Zile_prestatii_CS
	where exists (select 1 from #conmed cm where cm.Marca=#DateCM.Marca and cm.Tip_diagnostic='10') 

	select Data, max(TagAsigurat) as TagAsigurat, max(Marca) as marca, CNP, 
		max((case when Zile_prestatii-Zile_prestatii_CD-Zile_prestatii_CS<0 then 0 else Zile_prestatii-Zile_prestatii_CD-Zile_prestatii_CS end)) as Zile_prestatii_CN, 
		max(Zile_prestatii_CD) as Zile_prestatii_CD, max(Zile_prestatii_CS) as Zile_prestatii_CS, max(Zile_CM_fnuass) as Zile_CM_fnuass, max(Zile_CM_faambp) as Zile_CM_faambp, 
		max(Zile_faambp) as Zile_faambp, 0 as NRZ_CFP, 
		(case when max(ExistaCMCNP)=1 then max(Baza_CASCM) else sum(Baza_CASCM) end) as Baza_CASCM, sum(Indemniz_angajator_faambp) as Indemniz_angajator_faambp, 
		sum(Indemniz_faambp) as Indemniz_faambp, 
		sum(Total_indemniz) as Total_indemniz, sum(Indemniz_angajator_fnuass) as Indemniz_angajator_fnuass, sum(Indemniz_fnuass) as Indemniz_fnuass
	from #DateCM
	group by Data, CNP
	order by CNP

	return
end

/*
	exec Declaratia112CMAsigurat '11/01/2012', '11/30/2012', ''
	select * from dbo.fDeclaratia112DateBass ('08/01/2010', '08/31/2010', 0, '', '', 0, 0, '', 'asiguratB3')
*/
