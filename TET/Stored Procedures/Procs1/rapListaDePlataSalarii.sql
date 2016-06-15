--***
/**	procedura pentru raportul Lista de plata salarii.RDL */
Create procedure rapListaDePlataSalarii
	(@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9)=null, @strict int=0, @locmExcep char(9)=null, @strictLocmExcep int=0, 
	@codfunctie varchar(6)=null, @mandatar char(6)=null, @grupaMunca char(1)=null, @card char(30)=null, @tipSalarizare char(1)=null, 
	@tipstat char(30)=null, @restplpozitiv int=0,  @ordonare char(1), @listaDreptCond char(1)='T', @alfabetic int=0, @afisarecnp int=0)
as
/*
	Ordonare=1 -> Locuri de munca, salariati
	Ordonare=2 -> Locuri de munca, functii, salariati
	Ordonare=3 -> Salariati
*/
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#listaplata') is not null drop table #listaplata
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
	
	declare @eroare varchar(2000), @utilizator char(10), @dreptConducere int, @areDreptCond int, @mandatari int, @ListaContineSume int, @i int, @niv int
	set @niv=1
--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @mandatari=dbo.iauParL('PS','MANDATARI')
	set @ListaContineSume=dbo.iauParL('PS','LISTCSUME')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end

	select n.data, n.marca, rtrim(isnull(i.nume,p.nume))+(case when @afisarecnp=1 then ' - '+rtrim(p.Cod_numeric_personal) else '' end) as nume, 
		n.loc_de_munca, lm.Denumire as denumire_lm, 
		isnull(i.cod_functie,p.cod_functie) as cod_functie, f.denumire as den_functie, p.banca, 1 as nivel, lm.Nivel+1 as niv, isnull(lm.cod,'') as parinte,
		rtrim(n.Loc_de_munca)+i.Cod_functie+' '+n.Marca as cod,
		(case when @ListaContineSume=1 then n.rest_de_plata else 0 end) as rest_de_plata, 0 as numar_curent, 
		(case when @ordonare=3 then '' else n.loc_de_munca end)+(case when @ordonare=2 then p.Cod_functie else '' end)
			+(case when @alfabetic=1 then p.Nume else n.marca end) as ordonare
	into #listaplata
	from net n
		left outer join personal p on n.Marca=p.Marca
		left outer join istpers i on n.Data=i.Data and n.Marca=i.Marca
		left outer join lm on isnull(i.Loc_de_munca,p.Loc_de_munca)=lm.Cod
		left outer join functii f on isnull(i.Cod_functie,p.cod_functie)=f.cod_functie
		left outer join fMod_plata_la_data (@dataSus,'') c on n.marca=c.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.Loc_de_munca
	where n.data = @dataSus and (@marca is null or n.marca=@marca) 
		and (@locm is null or n.loc_de_munca like RTRIM(@locm)+(case when @strict=1 then '' else '%' end))
		and (@restplpozitiv=0 or n.rest_de_plata>0) 
		and (@codfunctie is null or isnull(i.cod_functie,p.cod_functie)=@codfunctie) 
		and (@grupaMunca is null or isnull(i.grupa_de_munca,p.grupa_de_munca)=@grupaMunca) 
		and (@mandatar is null or n.loc_de_munca in (select loc_munca from mandatar where mandatar=@mandatar)) 
		and (@card is null or c.banca=@card) 
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@ListaDreptCond='T' or @ListaDreptCond='C' and p.pensie_suplimentara=1 or @ListaDreptCond='S' and p.pensie_suplimentara<>1)) 
		or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@locmExcep is null or n.loc_de_munca not like rtrim(@locmExcep)+(case when @strictLocmExcep=1 then '' else '%' end)) 
		and (@tipSalarizare is null or @tipSalarizare='T' and i.Tip_salarizare in ('1','2') or @tipSalarizare='M' and i.Tip_salarizare in ('3','4','5','6','7'))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	order by ordonare

	update #listaplata set Numar_curent=n.Numar_curent
		from #listaplata a
			inner join (select Marca, Loc_de_munca, Cod_functie, ROW_NUMBER() over (order by ordonare) 
				as Numar_curent from #listaplata a) n on a.marca=n.marca and a.Loc_de_munca=n.Loc_de_munca and a.Cod_functie=n.Cod_functie

	if @ordonare=3 
		update #listaplata set parinte='<T>'+space(6), niv=1	-- daca nu se doresc locuri de munca in stat ramane totalul ca loc de munca

	if @ordonare<>3 
		update #listaplata set parinte=(case when exists (select 1 from #listaplata s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#listaplata.loc_de_munca) 
			then rtrim(parinte)+'_' else parinte end),
		loc_de_munca=(case when exists (select 1 from #listaplata s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#listaplata.loc_de_munca) 
			then rtrim(loc_de_munca)+'_' else loc_de_munca end),
		niv=(case when exists (select 1 from #listaplata s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#listaplata.loc_de_munca) then niv+1 else niv end)

	create table #lm (Nivel int, Cod char(10), Cod_parinte char(10), Denumire char(30))
	insert into #lm
	select (select min(nivel) from lm)-1 as nivel, convert(char(10),'<T>') as cod, '' as cod_parinte, 'Total' as denumire
	union all	-->> total general
	select 
	Nivel, Cod, (case when isnull(rtrim(Cod_parinte),'')='' then '<T>' else cod_parinte end), Denumire
	from lm
	union all	-->> linii pt. locurile de munca de nivel superior care au copii - le mut le nivel inferior
	select 
	Nivel+1, rtrim(Cod)+'_', Cod, Denumire
	from lm
	where exists (select 1 from lm lm1 where lm1.Cod_parinte=lm.cod)

	set @i=(select max(nivel) from #lm)

	while @i>-1 and exists (select 1 from #listaplata)
	begin
		insert into #listaplata (data, marca, nume, loc_de_munca, denumire_lm, cod_functie, den_functie, banca, nivel, niv, cod, parinte, rest_de_plata, numar_curent, ordonare)
		select '' as data, '' as marca, '' as nume, max(s.loc_de_munca) as loc_de_munca, max(rtrim(lm.denumire)) as denumire_lm, 
		'' as cod_functie, '' as den_functie, '' as banca, 2 as nivel, max(lm.nivel) as niv, max(isnull(lm.cod,'')) as cod, max(isnull(lm.cod_parinte,'')) as parinte, 
		SUM(rest_de_plata) as rest_de_plata, max(numar_curent) as numar_curent, MAX(s.ordonare) as ordonare
		from #listaplata s
			left join #lm lm on lm.cod=s.parinte 
		where @i=lm.nivel and lm.cod is not null and s.nivel>0
		group by Data, isnull(lm.cod_parinte,''), s.parinte
		set @i=@i-1
	end

--	selectez din functii_lm pozitiile valabile la data generarii raportului
	select * into #functii_lm from 
	(select Data, Loc_de_munca, Cod_functie, Pozitie_stat, RANK() 
		over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm where (@locm is null or Loc_de_munca like rtrim(@locm)+'%')
		and (@codfunctie is null or Cod_functie=@codfunctie) and (@tipSalarizare is null or Tip_personal=@tipSalarizare) and Data<=@datasus) a
	where Ordine=1

	select s.data, s.marca, s.nume, s.loc_de_munca, s.denumire_lm, s.cod_functie, s.den_functie, s.banca, 
		s.nivel, s.niv, rtrim(s.cod) as cod, rtrim(s.parinte) as parinte, s.rest_de_plata, s.numar_curent, s.ordonare 
	from #listaplata s
		left outer join #functii_lm f on f.Loc_de_munca=s.loc_de_munca and f.Cod_functie=s.cod_functie
	where (@ordonare=1 or @ordonare=2 or @ordonare=3 and (s.nivel=2 and s.cod='<T>' or s.nivel=1))
		--and niv<2
	order by (case when @ordonare=3 then '' else nivel end)
		,(case when @ordonare=3 then '' else s.loc_de_munca end)
		,(case when @ordonare=2 then isnull(f.Pozitie_stat,s.cod_functie) else '' end)
		,(case when @alfabetic=0 then marca else nume end), data

end try

begin catch
	set @eroare='Procedura rapListaDePlataSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#listaplata') is not null drop table #listaplata
if object_id('tempdb..#functii_lm') is not null drop table #functii_lm

/*
	exec rapListaDePlataSalarii '09/01/2012', '09/30/2012', null, null, 0, null, 0, null, null, null, null, null, null, 0, '1', 'T', 0
*/
