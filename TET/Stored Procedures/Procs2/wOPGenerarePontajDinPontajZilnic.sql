--***
Create procedure wOPGenerarePontajDinPontajZilnic @sesiune varchar(50), @parXML xml
as
begin try
	declare @userASiS varchar(20), @datalunii datetime, @luna int, @an int, @datajos datetime, @datasus datetime, @mesaj varchar(1000), 
			@marca varchar(6), @marcaJos varchar(6), @marcaSus varchar(6), @lm varchar(9), @lmJos varchar(9), @lmSus varchar(9), @nrLMFiltru int, @LMFiltru varchar(9),
			@lGestionareTichete int

	set @lGestionareTichete=dbo.iauParL('PS','TICHETE')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerarePontajDinPontajZilnic' 
	select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)

	set @datajos = @parXML.value('(/parametri/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/parametri/@datasus)[1]', 'datetime')
	set @marca = isnull(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'),'')

	set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else '' end)
	
	select	@marcaJos=(case when @marca<>'' then @marca else '' end), 
			@marcaSus=(case when @marca<>'' then rtrim(@marca)+'Z' else 'ZZZ' end),
			@lmJos=(case when @lm<>'' then @lm else '' end), 
			@lmSus=(case when @lm<>'' then rtrim(@lm)+'Z' else 'ZZZ' end)

	if @datajos is null
	begin
		set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
		set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
		set @datajos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
		set @datasus=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	end
	set @datalunii=@datasus

	if object_id('tempdb..#ppontaj') is not null
		drop table #ppontaj

	create table #ppontaj
		(datalunii datetime, marca varchar(50), lm varchar(50), 
		ore_regie int, ore_acord int, ore_supl1 int, ore_supl2 int, ore_supl3 int, ore_supl4 int, ore_noapte int, ore_diurna int,
		ore_cm int, ore_co int, ore_intr1 int, ore_cfs int, ore_invoiri int, ore_nemotivate int, ore_obligatii int)

	exec pPontajDinPontajZilnic @datajos=@datajos, @datasus=@datasus, @lm=@lm, @marca=@marca, @sesiune=@sesiune, @parXML=@parXML 

	if object_id('tempdb..#salor') is not null drop table #salor
	Create table #salor 
		(Data datetime, Marca char(6), Salar_orar decimal(12,4), Loc_de_munca char(9), Ore_lucrate int, Regim_de_lucru decimal(5,2), Numar_curent int)
	Create Unique Clustered Index Marca_lm_nrc on #salor (Data, Marca, Loc_de_munca, Numar_curent)
	exec pCalcul_salor @dataJos=@dataJos, @dataSus=@dataSus, @marcaJos=@marcaJos, @marcaSus=@marcaSus, @locmJos=@lmJos, @locmSus=@lmSus

	delete p 
	from pontaj p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.loc_de_munca
	where data=@datalunii
		and (nullif(@marca,'') is null or p.marca=@marca)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

	insert into pontaj(Data, Marca, Loc_de_munca, Numar_curent, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, 
		Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical, 
		Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, 
		Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, 
		Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)

	select @datalunii, po.marca, po.lm, row_number() over (partition by po.marca order by po.lm), 1, p.tip_salarizare, isnull(nullif(p.salar_lunar_de_baza,0),8), isnull(so.salar_orar,0), 
		ore_regie+ore_acord as ore_lucrate, ore_regie, ore_acord, 
		ore_supl1, ore_supl2, ore_supl3, ore_supl4, 0 as ore_spor_100, ore_noapte, ore_intr1, ore_co, ore_cm, ore_invoiri, ore_nemotivate, ore_obligatii, ore_cfs, 
		0 as ore_donare_sange, 0 as salar_categoria_lucrarii, 0 as Coeficient_acord, 0 as realizat, 0 as Coeficient_de_timp, 0 as Ore_realizate_acord, 
		p.Spor_sistematic_peste_program, 0 as Ore_sistematic_peste_program, p.Spor_specific, p.Spor_conditii_1 as spor_conditii_1, p.Spor_conditii_2, p.Spor_conditii_3, p.Spor_conditii_4, 
		p.Spor_conditii_5, p.Spor_conditii_6, 0 as ore_cond_1, 0 as ore_cond_2, 0 as ore_cond_3, 0 as ore_cond_4, 0 as ore_cond_5, 0, 
		(case when p.grupa_de_munca in ('C','P') then 'N' else p.grupa_de_munca end), 0, 0, 0, 0, ore_diurna
	from #ppontaj po
		join personal p on p.marca=po.marca
		left join #salor so on so.marca=po.marca
	where po.datalunii between @datajos and @datasus and (p.Loc_ramas_vacant=0 or p.Data_plec>=@datajos) and ISNULL(p.fictiv,0)<>1
	order by po.marca

	/*	Apelare calcul tichete de masa. */
	if @lGestionareTichete=1 
		exec psCalculTichete @dataJos, @dataSus, @marca, @lm, 1, 1

end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
/*
	wOPGenerarePontajDinPontajZilnic @sesiune='EF0B1993710A6', @parXML='<parametri luna="8" an="2015" />'
*/
