--***
Create procedure [dbo].[rapPersIntr]
	@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @codfunctie varchar(6)=null, 
	@datacopil18 datetime=null, @dataexpdedJos datetime=null, @dataexpdedSus datetime=null, @ordonarelm int=1, @nivel int=0, @tipraport char(1)='N'
as
/*
	tipraport = N ->	Lista nominala
	tipraport = P ->	Lista premii - pentru PSplus
*/
begin
	set transaction isolation level read uncommitted
	declare @utilizator varchar(20), @lista_lm int 

	set @utilizator = dbo.fIaUtilizator(null)	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select b.data, b.marca as marca, max(p.nume) as nume, max(b.tip_intretinut)as tip_intretinut, max(ti.denumire) as den_intretinut, 
		max(b.nume_pren) as nume_pren, b.cod_personal, 
		(case max(b.coef_ded) when 0 then 'fara deducere' else 'cu deducere' end) as deducere, case max(b.coef_ded) when 0 then 0 else 1 end as nrdeducere,
		max(b.Grad_invalid) as grad_invalid, 
		max((case when b.Grad_invalid=1 then 'Handicap grav' when b.Grad_invalid=2 then 'Handicap accentuat' else 'Fara handicap' end)) as tip_handicap, 
		datediff(year,max(b.data_nasterii),(case when @datacopil18 is null then convert(datetime,getdate(),103) else @datacopil18 end)) as varsta, 
		max(b.Data_nasterii) as data_nasterii, 
		max(p.Loc_de_munca) as lm, max(lm.Denumire) as den_lm,
		(case when @ordonarelm=1 and isnull(@nivel,0)=0 then  max(p.Loc_de_munca) else '' end) as ordonare_lm, 
		(case when @ordonarelm=1 and isnull(@nivel,0)<>0 then substring(max(p.Loc_de_munca),1,@nivel) else '' end) as ordonare_lm1
	from persintr b
		left outer join personal p on p.Marca=b.Marca
		left outer join istPers i on i.Data=b.Data and i.Marca=b.Marca
		left outer join extpersintr c on b.marca=c.marca and b.data=c.data and b.cod_personal=c.cod_personal
		left outer join dbo.fTip_intretinut() ti on b.Tip_intretinut=ti.Tip_intretinut
		left outer join lm on lm.Cod=(case when isnull(@nivel,0)<>0 then substring(p.Loc_de_munca,1,@nivel) else p.Loc_de_munca end)
	where b.data between @dataJos and @dataSus 
--	am inlocuit conditia de filtrare stricta pe marca, cu cea de filtrare pe CNP-ul acelei marci (sa aduca si persoanele in intretinere de pe alte contracte anterioare).
--		and (@marca is null or b.marca=@marca) 
		and (@marca is null or exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca))
		and (@locm is null  or p.loc_de_munca like rtrim (@locm)+(case when @strict=0 then '%'else '' end)) 
		and (@lista_lm=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)))
		and (@datacopil18 is null or datediff(day,b.data_nasterii,@datacopil18)<=6574) 
		and (convert(char(1),loc_ramas_vacant)='0' or convert(char(1),loc_ramas_vacant)='1' and p.data_plec between @datajos and @dataSus) 
		and (@dataexpdedJos is null or c.data_exp_ded between @dataexpdedJos and @dataexpdedSus or DateAdd(day,6574,b.data_nasterii) between @dataexpdedJos and @dataexpdedSus) 
		and (@codfunctie is null or p.cod_functie=@codfunctie)
		and (@tipraport='N' or b.Tip_intretinut in ('C','U'))
	group by b.Data, b.marca, b.cod_personal
	order by Ordonare_lm, Ordonare_lm1, max(p.nume)
	return
End	

/*
	exec rapPersIntr '04/01/2012', '04/30/2012', null, null, 0, null, null, null, null, '1'
*/
