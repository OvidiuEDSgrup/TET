--***
Create 
procedure rapAbsenteAngajati (@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null)
as
begin try
	set transaction isolation level read uncommitted

	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	SET @utilizator = dbo.fIaUtilizator(null) 

	select row_number() over (order by i.loc_de_munca,p.nume) as id, 
	i.data, i.marca as marca, rtrim(max(i.nume)) as nume,
	max(i.loc_de_munca) as lm, max(rtrim(lm.denumire)) as den_lm, 
	max(i.Cod_functie) as cod_functie, max(rtrim(isnull(f.denumire,''))) as den_functie,
	sum(isnull(b.ore_concediu_fara_salar,0)) as ore_cfs, sum(isnull(b.ore_nemotivate,0)) as ore_nemotivate, sum(isnull(b.ore_invoiri,0)) as ore_invoiri,
	sum(isnull(c.zile_co,0)) as zile_co, sum(isnull(m.zile_cm,0)) as zile_cm
	from istpers i
		inner join personal p on i.marca = p.marca 
		inner join lm on i.loc_de_munca = lm.cod 
		left join functii f on p.cod_functie = f.cod_functie
		left join (select data, marca, sum(Ore_concediu_fara_salar) as Ore_concediu_fara_salar, sum(Ore_nemotivate) as Ore_nemotivate, sum(Ore_invoiri) as Ore_invoiri
			from brut where Data between @dataJos and @dataSus group by Data, Marca) b on b.marca = i.marca and b.data=i.data
		left join (select data, marca, sum(isnull(zile_co,0)) as zile_co from concodih where Data between @dataJos and @dataSus group by data,marca) c on i.marca= c.marca and i.data=c.data
		left join (select data, marca, sum(isnull(zile_lucratoare,0)) as zile_cm from conmed where Data between @dataJos and @dataSus group by data,marca) m 
			on i.marca= m.marca and i.data=m.data
	where i.data between @dataJos and @dataSus 
		and (isnull(b.ore_concediu_fara_salar,0)<>0 or isnull(b.ore_nemotivate,0)<>0 or isnull(c.zile_co,0)<>0 or isnull(m.zile_cm,0)<>0)
		and (@marca is null or i.Marca=@marca) 
		and (@locm is null or i.Loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@functie is null or i.Cod_functie=@functie)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.Loc_de_munca))
	group by i.data, i.marca, i.loc_de_munca, p.nume
	order by lm
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapAbsenteAngajati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
