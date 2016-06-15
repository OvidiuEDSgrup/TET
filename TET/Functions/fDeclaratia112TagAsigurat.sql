--***
Create function fDeclaratia112TagAsigurat 
	(@dataJos datetime, @dataSus datetime, @lm char(9)='')
returns @TagAsigurat table 
	(Data datetime, Marca char(6), TagAsigurat char(20), Tip_asigurat int, Pensionar int, Tip_contract char(2), Regim_de_lucru float)
as
begin
	insert @TagAsigurat
	select i.Data, i.Marca, (case when i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC') then 'asiguratC' else 'asiguratB' end), 
		(case when i.Grupa_de_munca in ('N','D','S','C') then 1 
			when i.Grupa_de_munca in ('P','O') and i.Tip_colab in ('AS5') or year(@dataSus)>=2012 and i.Tip_colab in ('AS2') then 4 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('DAC') then 17 when i.Grupa_de_munca in ('O') and i.Tip_colab in ('CCC') then 18 
			else 3 end) as Tip_asigurat, 
		(case when p.coef_invalid=5 then 1 else 0 end) as Pensionar,
		(case when i.Grupa_de_munca in ('N','D','S') then 'N' when i.Grupa_de_munca in ('C') 
			then 'P'+rtrim(convert(char(10),isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
				(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)))) 
			else 'N' end) as Tip_contract,
		isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end))
	from istpers i 
		left outer join personal p on p.marca=i.marca
	where i.data=@dataSus 
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		and (i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC')
		or exists (select 1 from istpers i1 left outer join personal p1 on i1.Marca=p1.Marca 
		where i1.Data=@dataSus and i1.Grupa_de_munca in ('N','D','S','C','P','O') and p1.Cod_numeric_personal=p.Cod_numeric_personal and i1.Marca<>i.Marca)
		or i.grupa_de_munca in ('D','S') 
		or i.marca in (select marca from conmed where data_inceput between @dataJos and @dataSus) 
		or i.Marca in (select marca from fBass_somaj_tehnic (@dataJos, @dataSus, 0, '', 0, '', '', 0, '', 0, '', 0, 0, 0)) 
		or i.Marca in (select marca from fPSScutiriOUG13 (@dataJos, @dataSus, 0, '', '', 0))
		or i.Marca in (select marca from fDeclaratia112Scutiri (@dataJos, @dataSus, 1, @lm)))
--	inserez prin diferenta salariatii care au un singur contract si nu au cazuri specifice (CM, etc)
	insert @TagAsigurat
	select i.Data, i.Marca, 'asiguratA', 
		(case when i.Grupa_de_munca in ('N','D','S','C') then 1 
			when i.Grupa_de_munca in ('P','O') and i.Tip_colab in ('AS5') or year(@dataSus)>=2012 and i.Tip_colab in ('AS2') then 4 
			when i.Grupa_de_munca in ('O') and i.Tip_colab in ('DAC') then 17 when i.Grupa_de_munca in ('O') and i.Tip_colab in ('CCC') then 18 
			else 3 end) as Tip_asigurat, 
		(case when p.coef_invalid=5 then 1 else 0 end) as Pensionar,
		(case when i.Grupa_de_munca in ('N','D','S') then 'N' when i.Grupa_de_munca in ('C') 
			then 'P'+rtrim(convert(char(10),isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end)))) 
			else 'N' end) as Tip_contract,
		isnull((select (case when max(d.spor_cond_10)<1 then 1 else max(round(d.spor_cond_10,0)) end) from brut d where d.data=@dataSus and d.marca=i.marca),
			(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end))
	from istpers i
		left outer join personal p on p.marca=i.marca
	where i.data=@dataSus and i.Marca not in (select marca from @TagAsigurat)
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
	order by i.Marca
	return
end

/*
	select * from fDeclaratia112TagAsigurat ('05/01/2011', '05/31/2011')
*/