--***
Create procedure Declaratia112TagAsigurat 
	(@dataJos datetime, @dataSus datetime, @lm char(9)='')
as
begin
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

--	daca tabela #istpers nu a fost creata dintr-o procedura anterioara (Declaratia112) se creeaza aici
	if object_id('tempdb..#istpers') is null 
	begin
		Select i.* into #istpers 
		from istPers i
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		where i.Data=@dataSus 
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 
		create unique index [Data_Marca] ON #istpers (Data, Marca)		
	end

	select i.Data, i.Marca, (case when i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT') then 'asiguratC' else 'asiguratB' end) as TagAsigurat, 
		(case when i.Grupa_de_munca in ('N','D','S','C') then 1 
			when i.Grupa_de_munca in ('P','O') and (i.Tip_colab in ('AS5') or i.Tip_colab in ('AS2') and year(@dataSus)>=2012 and year(@dataSus)<=2013) then 4 
			when i.Grupa_de_munca in ('P','O') and i.Tip_colab in ('AS2') and year(@dataSus)>=2014 then 6 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('DAC') then 17 when i.Grupa_de_munca in ('O') and i.Tip_colab in ('CCC') then 18 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('ECT') then 20 
			else 3 end) as Tip_asigurat, 
		(case when p.coef_invalid=5 then 1 else 0 end) as Pensionar,
		(case when i.Grupa_de_munca in ('N','D','S') then 'N' when i.Grupa_de_munca in ('C') 
			then 'P'+rtrim(convert(char(10),isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
				(case when i.Salar_lunar_de_baza=0 then 8 else round(i.Salar_lunar_de_baza,0) end)))) 
			else 'N' end) as Tip_contract,
		(case when charindex(i.grupa_de_munca,'O')<>0 and i.Tip_colab in ('DAC','CCC','ECT') then '3' 
			when i.grupa_de_munca in ('N','D','S','C') and i.tip_colab='FDP' or charindex(i.grupa_de_munca,'OP')<>0 then '2' else '1' end) as Tip_functie,
		isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)) as Regim_de_lucru
	into #TagAsigurat
	from #istpers i 
		left outer join personal p on p.marca=i.marca
--	studiez daca este colaborator sau are alte contracte de munca.	
	where (i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT')
			or exists (select 1 from #istpers i1 
				left outer join personal p1 on i1.Marca=p1.Marca 
				left outer join LMFiltrare lu1 on lu1.utilizator=@utilizator and lu1.cod=i1.Loc_de_munca
				where i1.Data=i.Data and i1.Marca<>i.Marca and i1.Grupa_de_munca in ('N','D','S','C','P','O') and p1.Cod_numeric_personal=p.Cod_numeric_personal
					and (@lista_lm=0 or lu1.cod is not null))
			or i.grupa_de_munca in ('D','S') 
			or i.marca in (select marca from conmed where data_inceput between @dataJos and @dataSus) 
			or i.Marca in (select marca from fBass_somaj_tehnic (@dataJos, @dataSus, 0, '', 0, '', '', 0, '', 0, '', 0, 0, 0)) 
			or i.Marca in (select marca from fPSScutiriOUG13 (@dataJos, @dataSus, 0, '', '', 0))
			or i.Marca in (select marca from fDeclaratia112Scutiri (@dataJos, @dataSus, 1, @lm)))
--	inserez prin diferenta salariatii care au un singur contract si nu au cazuri specifice (CM, etc)
	insert into #TagAsigurat
	select i.Data, i.Marca, 'asiguratA' as TagAsigurat, 
		(case when i.Grupa_de_munca in ('N','D','S','C') then 1 
			when i.Grupa_de_munca in ('P','O') and (i.Tip_colab in ('AS5') or i.Tip_colab in ('AS2') and year(@dataSus)>=2012 and year(@dataSus)<=2013) then 4 
			when i.Grupa_de_munca in ('P','O') and i.Tip_colab in ('AS2') and year(@dataSus)>=2014 then 6 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('DAC') then 17 when i.Grupa_de_munca in ('O') and i.Tip_colab in ('CCC') then 18 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('ECT') then 20 
			else 3 end) as Tip_asigurat, 
		(case when p.coef_invalid=5 then 1 else 0 end) as Pensionar,
		(case when i.Grupa_de_munca in ('N','D','S') then 'N' when i.Grupa_de_munca in ('C') 
			then 'P'+rtrim(convert(char(10),isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else round(i.Salar_lunar_de_baza,0) end)))) 
			else 'N' end) as Tip_contract,
		(case when charindex(i.grupa_de_munca,'O')<>0 and i.Tip_colab in ('DAC','CCC','ECT') then '3' 
			when i.grupa_de_munca in ('N','D','S','C') and i.tip_colab='FDP' or charindex(i.grupa_de_munca,'OP')<>0 then '2' else '1' end) as Tip_functie,
		isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)) as Regim_de_lucru
	from #istpers i
		left outer join personal p on p.marca=i.marca
	where i.Marca not in (select marca from #TagAsigurat)
	order by i.Marca
	
	select Data, Marca, TagAsigurat, Tip_asigurat, Pensionar, Tip_contract, Tip_functie, Regim_de_lucru from #TagAsigurat
end

/*
	exec Declaratia112TagAsigurat '03/01/2013', '03/31/2013', ''
*/
