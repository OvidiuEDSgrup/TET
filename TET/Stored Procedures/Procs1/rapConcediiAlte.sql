/**	procedura pentru raportul de date concedii\alte	*/
Create procedure rapConcediiAlte
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @tipco char(1)=null, @tipstat varchar(30)=null, 
	@ordonare char(1), @alfabetic bit, @tip_raport char (1), @ziledepasire int=null)
as
begin try
	set transaction isolation level read uncommitted
	declare @userASiS char(10) -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)

	select max(a.Data) as data, a.marca, max(isnull(i.Nume,p.Nume)) as nume, max(isnull(i.Loc_de_munca, p.Loc_de_munca)) as lm, max(lm.denumire) as denumire_lm, 
	max(a.Tip_concediu) as tip_concediu, (case when @Tip_Raport='2' then '' when max(a.Tip_concediu)='1' then 'Concediu fara salar' when max(a.Tip_concediu)='2' then 'Nemotivate' 
	when max(a.Tip_concediu)='4' then 'Delegatie' when max(a.Tip_concediu)='5' then 'Perioada de proba' 
	when max(a.Tip_concediu)='6' then 'Preaviz' when max(a.Tip_concediu)='9' then 'Cercetare disciplinara'
	when max(a.Tip_concediu)='R' then 'Recuperare' when max(a.Tip_concediu)='F' then 'Formare profesionala' else '' end) as denumire_tipco, 
	max(a.Data_inceput) as data_inceput, max(a.Data_sfarsit) as data_sfarsit, 
	sum((case when a.tip_concediu='2' and a.Indemnizatie<>0 then 0 else a.Zile end)) as zile, 
	(case when max(a.Tip_concediu)='4' then sum(isnull(a.zile,0)) else 0 end) as zile_delegatie,
	(case when max(a.Tip_concediu)='5' then sum(isnull(a.zile,0)) else 0 end) as zile_proba,
	(case when max(a.Tip_concediu)='6' then sum(isnull(a.zile,0)) else 0 end) as zile_preaviz,
	(case when max(a.Tip_concediu)='1' then sum(isnull(a.zile,0)) else 0 end) as zile_CFS,
	(case when max(a.Tip_concediu)='2' then sum(isnull((case when a.Indemnizatie=0 then a.zile else 0 end),0)) else 0 end) as zile_nemotivate, 
	(case when max(a.Tip_concediu)='2' then sum(isnull((case when a.Indemnizatie<>0 then a.Indemnizatie else 0 end),0)) else 0 end) as ore_nemotivate, 
	(case when max(a.Tip_concediu)='9' then sum(isnull(a.zile,0)) else 0 end) as zile_CD,
	(case when max(a.Tip_concediu)='R' then sum(isnull(a.zile,0)) else 0 end) as zile_recuperare,
	(case when max(a.Tip_concediu)='F' then sum(isnull(a.zile,0)) else 0 end) as zile_formare_prof,
	(case when @Ordonare='1' then '' else max(isnull(i.Loc_de_munca,p.Loc_de_munca)) end) as Ordonare
	from conalte a
		left outer join personal p on p.marca = a.marca
		left outer join infopers ip on ip.marca = a.marca
		left outer join lm on p.Loc_de_munca=lm.cod 
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where a.Data between @dataJos and @dataSus and (@marca is null or a.Marca=@marca) 
		and (@locm is null or isnull(i.Loc_de_munca,p.Loc_de_munca) like RTRIM(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@functie is null or isnull(i.Cod_functie,p.Cod_functie)=@functie) 
		and a.Tip_concediu in ('1','2','4','5','6','9','R','F') and (@tipco is null or a.Tip_concediu=@tipco) 
		and (@tipstat is null or ip.religia=@tipstat)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and (@ziledepasire is null 
			or exists (select ca.marca from conalte ca where year(ca.Data)=year(@dataSus) and ca.Marca=a.Marca
			and (@tipco is null or ca.Tip_concediu=@tipco) group by ca.Marca having SUM(DateDiff(day,ca.Data_inceput,ca.Data_sfarsit)+1)>@ziledepasire))
	group by a.marca, (case when @Tip_Raport='1' then a.Data_inceput else '01/01/1901' end)
	order by Ordonare Asc, (case when @Alfabetic=1 then max(p.Nume)+a.Marca else a.Marca end), max(a.Data)
	return
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapConcediiAlte (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapConcediiAlte '10/01/2011', '10/31/2011', null, null, 0, null, null, null, '1', 0, '1', null
*/
