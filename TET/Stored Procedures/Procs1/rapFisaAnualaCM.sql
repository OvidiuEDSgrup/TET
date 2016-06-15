/**	procedura pentru raportul web FisaAnualaCM.RDL */
Create procedure rapFisaAnualaCM
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, 
	@grupa_munca char(1)=null, @grupa_exceptata int=0, @tippersonal char(1)=null, @alfabetic int, @grupare char(1))
as
begin try
	set transaction isolation level read uncommitted
	IF OBJECT_ID('tempdb..#tmpfisacm') IS NOT NULL drop table #tmpfisacm
	IF OBJECT_ID('tempdb..#fisacm') IS NOT NULL drop table #fisacm
	
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
		, @culm int
	set @utilizator = dbo.fIaUtilizator(null)
	select @culm=(case when @grupare='2' then 1 else 0 end)

--	selectez datele grupate pe marca, diagnostic, data
	select cm.data, cm.marca, max(p.nume) as nume, max(p.cod_functie) as cod_functie, max(f.denumire) as den_functie, 
		max(p.Loc_de_munca) as lm, max(lm.denumire) as den_lm, 
		cm.Tip_diagnostic, max(d.Denumire) as den_diagnostic, 
		SUM(DateDiff(day,cm.Data_inceput,cm.Data_sfarsit)+1) as zile_cm, 
		(case when @grupare='2' then max(p.loc_de_munca) else '' end) as Ordonare, 
		(case when @alfabetic=1 then max(p.nume) else cm.marca end) as Ordonare1 
	into #tmpfisacm
	from conmed cm 
		left outer join personal p on cm.marca=p.marca 
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join istpers i on i.marca=cm.marca and i.data=cm.data
		left outer join dbo.fDiagnostic_CM() d on cm.Tip_diagnostic=d.Tip_diagnostic
	where cm.data between @dataJos and @dataSus and (@marca is null or cm.marca=@marca) 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@grupa_munca is null or (@grupa_exceptata=0 and p.Grupa_de_munca=@grupa_munca or @grupa_exceptata=1 and p.Grupa_de_munca<>@grupa_munca)) 
		and (@functie is null or p.Cod_functie=@functie)
		and (@tippersonal is null or (@tippersonal='T' and i.tip_salarizare in ('1','2')) or (@tipPersonal='M' and i.tip_salarizare in ('3','4','5','6','7')))		
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)))
	group by cm.marca, cm.Tip_diagnostic, cm.data
	order by Ordonare, Ordonare1
	
	create table #fisacm (ordonare varchar(200), parinte varchar(200), grupare varchar(200), data datetime, zile_cm int, nivel int)

/**	in tabela #fisacm se introduc datele organizate astfel incat sa se poata afisa conform cu gruparile dorite*/
--	pun data=3000-12-31 si pe aceasta data voi face totalurile pentru fiecare nivel de grupare
	insert into #fisacm (ordonare, parinte, grupare, data, zile_cm, nivel)
--	pozitie pentru loc de munca
	select ' | 11' ordonare, 
		'' parinte, (case when @grupare='2' then 'Loc de munca | Denumire loc de munca' 
					else 'Marca | Nume' end), '3000-12-31', '',1
	where @culm=1
--	pozitie pentru marca
	union all
	select ' | 12' ordonare, 
		'' parinte, 'Marca | Nume','3000-12-31','',2-(1-@culm)
	union all
--	pozitie pentru diagnostic	
	select ' | 13' ordonare, 
		'' parinte, 'Tip diagnostic','3000-12-31','',3-(1-@culm)
/*	union all
	select ' |A0' ordonare, '' parinte, '', '3000-12-31', 0, 0
*/	union all
	select ' |A01' ordonare, ' |A0' parinte, 'Total', '3000-12-31', sum(zile_cm),0
	from #tmpfisacm 

--	inserez totalurile pe criteriile de grupare
	insert into #fisacm (ordonare, parinte, grupare, data, zile_cm, nivel)
	select ' |A01' ordonare, ' |A0' parinte, 'Total', data, sum(zile_cm), 0
	from #tmpfisacm 
	group by data
--	locuri de munca
	insert into #fisacm (ordonare, parinte, grupare, data, zile_cm, nivel)
	select ' |A01 |'+lm ordonare, ' |A01' parinte, rtrim(lm)+' - '+max(den_lm), data, sum(zile_cm), 1
	from #tmpfisacm where @culm=1
	group by lm, data
	union all 
	select ' |A01 |'+lm ordonare, ' |A01' parinte, rtrim(lm)+' - '+max(den_lm), '3000-12-31', sum(zile_cm), 1
	from #tmpfisacm where @culm=1
	group by lm
--	marca
	insert into #fisacm (ordonare, parinte, grupare, data, zile_cm, nivel)
	select ' |A01 |'+lm+marca+max(nume) ordonare, ' |A01'+(case when @culm=1 then ' |'+lm else '' end) parinte, rtrim(marca)+' - '+max(nume), data, sum(zile_cm), 2-(1-@culm)
	from #tmpfisacm
	group by lm, marca, data
	union all
	select ' |A01 |'+lm+marca+max(nume) ordonare, ' |A01'+(case when @culm=1 then ' |'+lm else '' end) parinte, rtrim(marca)+' - '+max(nume), '3000-12-31', sum(zile_cm), 2-(1-@culm)
	from #tmpfisacm
	group by lm, marca
--	diagnostic
	insert into #fisacm (ordonare, parinte, grupare, data, zile_cm, nivel)
	select ' |A01 |'+lm+marca+max(nume)+Tip_diagnostic ordonare, ' |A01 |'+lm+marca+max(nume) parinte, Tip_diagnostic+max(den_diagnostic), data, sum(zile_cm), 3-(1-@culm)
	from #tmpfisacm
	group by lm, marca, tip_diagnostic, data
	union all 
	select ' |A01 |'+lm+marca+max(nume)+Tip_diagnostic ordonare, ' |A01 |'+lm+marca+max(nume) parinte, Tip_diagnostic+max(den_diagnostic), '3000-12-31', sum(zile_cm), 3-(1-@culm)
	from #tmpfisacm
	group by lm, marca, Tip_diagnostic

	select ordonare, parinte, grupare, data, zile_cm, nivel from #fisacm
	order by ordonare, nivel
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapFisaAnualaCM (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
IF OBJECT_ID('tempdb..#tmpfisacm') IS NOT NULL drop table #tmpfisacm
IF OBJECT_ID('tempdb..#fisacm') IS NOT NULL drop table #fisacm

/*
	exec rapFisaAnualaCM '01/01/2012', '08/31/2012', '1372', null, 0, null, null, 0, null, 0, '1'
*/
