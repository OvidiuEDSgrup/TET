--***
/**	functie pentru raportul Situatii\Pontaj,Pontati eronat;apelat si din operatia Validari date salarii in RIA */
Create function frapSalariatiPontatiEronat
	(@datajos datetime, @datasus datetime, @lm varchar(9), @strict int, @marca varchar(6), @sirmarci varchar(200), @functie varchar(6), 
		@tipstat varchar(30), @listaDrept char(1), @ordonare int)
returns @PontatiEronat table
	(data datetime, marca varchar(6), nume varchar(50), lm varchar(9), ore_justificate int, ore_lucratoare int)
as
begin 
	declare @utilizator varchar(20),  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
		@RegimVariabil int, @dreptConducere int, @vListaDrept char(1), @areDreptCond int, @ScadOS_RN int, @ScadO100_RN int, @ORegieFaraOS2 int, 
		@Colas int, @Vestiro int
	
	SET @utilizator = dbo.fIaUtilizator(null)
	SET @RegimVariabil=dbo.iauParL('PS','REGIMLV')
	SET @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	SET @ScadOS_RN=dbo.iauParL('PS','OSNRN')
	SET @ScadO100_RN=dbo.iauParL('PS','O100NRN')
	SET @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	SET @Colas=dbo.iauParL('SP','COLAS')
	SET @Vestiro=dbo.iauParL('SP','VESTIRO')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @vListaDrept=@listaDrept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @vListaDrept='S'
	end

	declare @Pontati table (data datetime, marca varchar(6), nume varchar(50), lm varchar(9), regim_de_lucru float, regim_de_lucru_pers float, 
		data_angajarii datetime, data_plecarii datetime, plecat int, ore_justificate int, ore_lucratoare int)
	
	insert into @Pontati
	select dbo.EOM(a.Data) as data, a.marca, max(p.nume) as nume, max(a.loc_de_munca) as lm, 
	max(a.regim_de_lucru), max(isnull(i.salar_lunar_de_baza,p.salar_lunar_de_baza)) as regim_de_lucru_pers, 
	max(p.data_angajarii_in_unitate) as data_angajarii, max(p.data_plec) as data_plecarii, p.loc_ramas_vacant as plecat, 
	sum(a.ore_regie+a.ore_acord-@ScadOS_RN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)-@ScadO100_RN*(a.Ore_spor_100)
		+a.ore_intrerupere_tehnologica+a.ore+a.Ore_concediu_de_odihna+a.ore_concediu_medical+a.ore_invoiri+a.ore_nemotivate+a.ore_obligatii_cetatenesti
		+a.ore_concediu_fara_salar+(case when 1=1 then 0 else a.ore_donare_sange end)+(case when @Colas=1 then a.Spor_cond_8 else 0 end)+a.Spor_cond_9)
		+max(isnull(cm.zile_lucratoare*(case when p.salar_lunar_de_baza=0 or @RegimVariabil=1 then 8 else p.salar_lunar_de_baza end),0)) as ore_justificate,
		max(isnull(e.Procent,0)) as ore_lucratoare
	from pontaj a 
		left outer join personal p on a.marca=p.marca 
		left outer join istpers i on i.data=dbo.EOM(a.Data) and a.marca=i.marca
		left outer join infopers ip on a.marca=ip.marca 
		left outer join extinfop e on a.Marca=e.Marca and e.Cod_inf='TIPINTREPTM' and e.Val_inf='OrePeLuna' and e.Procent<>0
		left outer join (select Data, Marca, sum(Zile_lucratoare) as Zile_lucratoare 
			from conmed where Data=@datasus and Tip_diagnostic='0-' group by Data, Marca) cm on cm.Data=dbo.eom(a.Data) and cm.Marca=a.Marca
	where a.data between @datajos and @datasus 
		and (@lm is null or (a.loc_de_munca like rtrim(@lm) +(case when @strict=0 then '' else '%' end)))
		and (@marca is null or a.marca like rtrim(@marca)) 
		and (@functie is null or isnull(i.Cod_functie,p.cod_functie)=@functie) 
		and (@tipstat is null or ip.religia=@tipstat) 
		and (@sirmarci is null or charindex(','+rtrim(ltrim(a.marca))+',',rtrim(@sirmarci))>0)
		and (@dreptconducere=0 or (@areDreptCond=1 and (@vListaDrept='T' or @vListaDrept='C' and p.pensie_suplimentara=1 or @vListaDrept='S' and p.pensie_suplimentara<>1))
			or (@areDreptCond=0 and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.loc_de_munca,p.loc_de_munca)))			
	group by dbo.EOM(a.Data), a.marca, p.nume, p.loc_ramas_vacant 
	order by (case when @ordonare=2 then p.nume else a.marca end)

	update @Pontati set ore_lucratoare=
		(case when @RegimVariabil=1 and dbo.iauParLN(data,'PS','ORET_LUNA')<>0 and regim_de_lucru_pers<>0 and regim_de_lucru_pers=dbo.iauParLN(data,'PS','ORET_LUNA') 
			then regim_de_lucru_pers
		when @datajos<>dbo.BOM(@datajos) or @datasus<>dbo.EOM(@datasus) then dbo.zile_lucratoare(@datajos,@datasus)*regim_de_lucru
		when data_angajarii between @datajos and @datasus or plecat=1 and data_plecarii between @datajos and @datasus
			then dbo.zile_lucratoare((case when data_angajarii between @datajos and @datasus then data_angajarii else @datajos end),
				(case when plecat=1 and data_plecarii between @datajos and @datasus then DateAdd(day,-1,data_plecarii) else @datasus end))*regim_de_lucru
		else dbo.iauParLN(data,'PS','ORE_LUNA')/8*regim_de_lucru end)
	where ore_lucratoare=0

	insert into @PontatiEronat
	select data, marca, nume, lm, Ore_justificate, ore_lucratoare
	from @Pontati
	where ore_justificate<>ore_lucratoare and not(@Vestiro=1 and ore_justificate=0)

	return
end

