--***
/**	procedura pentru calcul zile CO cuvenite pentru toti salariatii.	*/
Create procedure pZileCOcuvenite 
	(@marca varchar(6)=null, @data datetime, @Calcul_pana_la_luna_curenta int=0)
As
Begin try
	declare @Drumor bit, @Stoehr bit, @Colas bit, @cCodCompanieCoda varchar(15), @ProbaZile bit, @DiminZileCOcuZileCM int, @DiminZileCOPeLM varchar(9), @CodDiagnDiminZileCO varchar(50),
	@ZileLucratoareAn float, @ZileLucratoarePanaLaLunaCrt float, @DataJos datetime, @DataSus datetime, @DataPlus1Zi datetime, @DataPrimaziAnNext datetime, 
	@populare int, @tabela_marci int

	set @Drumor = dbo.iauParL('SP','DRUMOR')
	set @Stoehr = dbo.iauParL('SP','STOEHR')
	set @Colas = dbo.iauParL('SP','COLAS')
--	@cCodCompanieCoda='K2730' -> specific Colas; o anumita companie din grup.
	set @cCodCompanieCoda = dbo.iauParA('SY','CMPCODE')
	set @ProbaZile = dbo.iauParL('PS','PPROBA_ZI')
	set @DiminZileCOcuZileCM = dbo.iauParL('PS','DIMZCOZCM')
	set @DiminZileCOPeLM = dbo.iauParA('PS','DIMZCOZCM')
	set @CodDiagnDiminZileCO = dbo.iauParA('PS','DIMZCOCD')

	set @DataJos = dbo.boy(@data)
	set @DataSus = dbo.eoy(@data)
	set @DataPrimaziAnNext = dbo.bom(dateadd(month,12-MONTH(@data)+1,@data))
	set @DataPlus1Zi = dateadd(day,1,@data)
	set @ZileLucratoareAn = dbo.zile_lucratoare(@DataJos, @DataSus)
	set @ZileLucratoarePanaLaLunaCrt = dbo.zile_lucratoare(@DataJos, @Data)
	set @populare=1

	if object_id('tempdb..#fltPers') is not null 
		drop table #fltPers
	if object_id('tempdb..#brutMarca') is not null 
		drop table #brutMarca
	if object_id('tempdb..#conmedExcep') is not null 
		drop table #conmedExcep

	/*	Creez tabela #marci daca nu s-a creat dinspre procedura ce apeleaza pZileCOcuvenite. Se poate apela pZileCOcuvenite dinspre wIaSalariati pentru primele 100 de marci. */
	if object_id('tempdb..#marci') IS NULL
	begin
		CREATE TABLE #marci (marca varchar(6))
		set @tabela_marci=0
	end
	else
		set @tabela_marci=1

	if object_id('tempdb..#zileCOcuv') is null 
	begin
		create table #zileCOcuv (marca char(6), zile int)
		set @populare=0
	end

	select p.marca, 
		(case when mod_angajare='D' and Data_plec<>'01/01/1901' then Data_plec 
			else (case when @ProbaZile=1 then dateadd(day, zile_absente_an,data_angajarii_in_unitate) else dateadd(month, zile_absente_an,data_angajarii_in_unitate) end) end) as dataSfDet,
		(case when p.Data_angajarii_in_unitate between @DataJos and @dataSus then p.Data_angajarii_in_unitate else @DataJos end) as DataAngPtCalc,
		(case when p.Loc_ramas_vacant=1 and p.data_plec between @DataJos and @DataPlus1Zi then p.Data_plec else @DataSus end) as dataSusNedet,
		(case when p.Data_angajarii_in_unitate between @DataJos and @dataSus or p.Loc_ramas_vacant=1 and p.data_plec between @DataJos and @DataPlus1Zi then 1 else 0 end) as AngajatPlecat,
		null as zile, 0 as zileLucrAngPl, convert(datetime,null) as DataSfDetCalc
	into #fltPers
	from personal p
		left join #marci m on m.marca=p.marca
	where (isnull(@marca,'')='' or p.marca=@marca) and p.grupa_de_munca not in ('O')
		and (convert(int,p.loc_ramas_vacant)=0 or p.Data_plec>=dbo.bom(@data))
		and p.data_angajarii_in_unitate<=@data
		and (@tabela_marci=0 or m.marca is not null)
	create index marca on #fltPers (marca)

	select b.Marca, sum(b.ore_invoiri) as ore_invoiri, sum(b.ore_concediu_fara_salar) as ore_concediu_fara_salar, sum(b.ore_nemotivate) as ore_nemotivate, 
		sum(b.ore_concediu_medical) as ore_concediu_medical, max(b.spor_cond_10) as regim_lucru 
	into #brutMarca
	from brut b 
		inner join istpers i on i.Data=b.Data and i.Marca=b.Marca
		inner join #fltPers fp on fp.marca=b.marca
	where b.data between @DataJos and (case when @Calcul_pana_la_luna_curenta=1 then @Data else @DataSus end) 
	group by b.marca

	select c.marca, sum(c.zile_lucratoare) as zile_cm_exceptie
	into #conmedExcep
	from conmed c 
		inner join #fltPers fp on fp.marca=c.marca
	where c.data between @DataJos and (case when @Calcul_pana_la_luna_curenta=1 then @Data else @DataSus end)
		and (c.tip_diagnostic='0-' or @DiminZileCOcuZileCM=0 and charindex(c.tip_diagnostic,@CodDiagnDiminZileCO)<>0) 
	group by c.marca

	update #fltPers set DataSfDetCalc=(case when dataSfDet>@DataSus then @DataSus else dataSfDet end)

	update fp set 
		zile=(case 
			when p.Mod_angajare='D' and (DataSfDetCalc<=@DataJos 
				or dbo.Zile_lucratoare(DataAngPtCalc,DataSfDetCalc)=0)
				or @Calcul_pana_la_luna_curenta=1 and p.Data_angajarii_in_unitate>@data then 0 
			when p.Mod_angajare='N' and DateDiff(day,DataAngPtCalc,dataSusNedet)<10	-- Am pus aceasta conditie pentru a nu se apela dbo.zile_lucratoare, decat pentru acele persoane care pot avea zile_lucratoare=0.
				and dbo.Zile_lucratoare(DataAngPtCalc,dataSusNedet)=0 then 0 
			end),
		zileLucrAngPl=(case when AngajatPlecat=1 then dbo.zile_lucratoare(fp.DataAngPtCalc,fp.DataSusNedet) else 0 end)
	from #fltPers fp
		inner join personal p on p.marca=fp.marca

	insert into #zileCOcuv (marca, zile)
	select p.marca, 
	(case when fp.zile=0 
		then 0 
		else isnull(e.Procent,0)+(p.Zile_concediu_de_odihna_an+p.Zile_concediu_efectuat_an)*
	--perioada determinata
		(case when p.mod_angajare='D' and p.zile_absente_an<>0 
			then (case when @ProbaZile=1 
						then (case when p.data_angajarii_in_unitate<@DataJos and fp.dataSfDet>@DataSus then 1 
								else (dbo.Zile_lucratoare(fp.DataAngPtCalc,fp.DataSfDetCalc)/@ZileLucratoareAn) end) 
						else (case when p.data_angajarii_in_unitate<@DataJos and fp.dataSfDet>@DataSus then 1 
								else (dbo.Zile_lucratoare(DataAngPtCalc,fp.DataSfDetCalc)/@ZileLucratoareAn) end) end) 
	--perioada nedeterminata
			when fp.AngajatPlecat=0 then 1 else fp.zileLucrAngPl/@ZileLucratoareAn end)*
				((case when @Calcul_pana_la_luna_curenta=1 
					then dbo.zile_lucratoare((case when p.data_angajarii_in_unitate>@DataJos then p.data_angajarii_in_unitate else @DataJos end), 
						(case when convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec<>'01/01/1901' and p.Data_plec<dbo.EOY(@data) then p.Data_plec else @Data end)) 
					else @ZileLucratoareAn end)
					-(case when @cCodCompanieCoda='K2730' then round(p.Zile_concediu_de_odihna_an*(case when @Calcul_pana_la_luna_curenta=1 then month(@data)/convert(float,12) else 1 end),2) else 0 end)
					-(isnull((b.ore_invoiri+b.ore_concediu_fara_salar+b.ore_nemotivate
					+(case when @Colas=1 and 1=0 or @DiminZileCOcuZileCM=1 and (@DiminZileCOPeLM='' or p.Loc_de_munca like RTRIM(@DiminZileCOPeLM)+'%') then 1 else 0 end)*b.ore_concediu_medical)
				/(case when b.regim_lucru=0 then 8 else b.regim_lucru end),0)+isnull(cm.zile_cm_exceptie,0)))/
				((case 
					when @Calcul_pana_la_luna_curenta=1 and p.Mod_angajare='D' and (@ProbaZile=1 or 1=1) and p.zile_absente_an<>0 
						then dbo.Zile_lucratoare(DataAngPtCalc,fp.DataSfDetCalc)
					when @Calcul_pana_la_luna_curenta=1 and fp.AngajatPlecat=1 then zileLucrAngPl else @ZileLucratoareAn end)
					-(case when @cCodCompanieCoda='K2730' then p.Zile_concediu_de_odihna_an else 0 end)) 
	end)
	from personal p 
		inner join #fltPers fp on fp.marca=p.marca
		left outer join #brutMarca b on b.marca=p.marca  
		left outer join #conmedExcep cm on cm.marca=p.marca
		left outer join extinfop e on p.marca=e.marca and e.cod_inf='SOLDZILECO' and e.data_inf between @DataJos and @DataSus
	where (p.Loc_ramas_vacant=0 or p.Data_plec>=@DataJos)

	if @populare=0
		select marca, zile from #zileCOcuv

End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pZileCOcuvenite (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
