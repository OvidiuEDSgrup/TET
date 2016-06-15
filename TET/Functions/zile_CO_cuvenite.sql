--***
/**	functie calc. zile CO cuvenite	*/
Create function zile_CO_cuvenite 
	(@Marca char(6), @Data datetime, @Calcul_pana_la_luna_curenta int)
Returns int
As
Begin
	Declare @ZileCOCuvenite float, @Drumor bit, @Stoehr bit, @Colas bit, @cCodCompanieCoda varchar(15), @ProbaZile bit, @DiminZileCOcuZileCM int, @DiminZileCOPeLM varchar(9), 
		@ZileLucratoareAn float, @ZileLucratoarePanaLaLunaCrt float, @DataJos datetime, @DataSus datetime, @DataJosNedet datetime, @DataSusNedet datetime, 
		@DataPlus1Zi datetime, @DataPrimaziAnNext datetime, @DataFinal datetime, @ModAngajare char(1), @CodDiagnDiminZileCO varchar(50), @DataAngajarii datetime, @AngajatPlecat int

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

	Select @DataFinal=(case when mod_angajare='D' and Data_plec<>'01/01/1901' then Data_plec 
		else (case when @ProbaZile=1 then dateadd(day, zile_absente_an,data_angajarii_in_unitate) 
			else dateadd(month, zile_absente_an,data_angajarii_in_unitate) end) end),
		@DataAngajarii=Data_angajarii_in_unitate, @ModAngajare=Mod_angajare, 
		@DataJosNedet=(case when Data_angajarii_in_unitate between @DataJos and @dataSus then Data_angajarii_in_unitate else @DataJos end),
		@DataSusNedet=(case when Loc_ramas_vacant=1 and data_plec between @DataJos and @DataPlus1Zi then Data_plec else @DataSus end),
		@AngajatPlecat=(case when Data_angajarii_in_unitate between @DataJos and @dataSus or Loc_ramas_vacant=1 and data_plec between @DataJos and @DataPlus1Zi then 1 else 0 end)
	from personal where marca=@Marca

	set @ZileCOCuvenite = 0
--	am pus conditia de mai jos intrucat in caz contrar numarul de zile calculat prin functia zile_lucratoare() => 0 si da eroare
	if @ModAngajare='D' and ((case when @DataFinal>@DataSus then @DataSus else @DataFinal end)<=@DataJos 
			or dbo.Zile_lucratoare((case when max(@DataAngajarii)<@DataJos then @DataJos else @DataAngajarii end),(case when @DataFinal>@DataSus then @DataSus else @DataFinal end))=0)
			or @Calcul_pana_la_luna_curenta=1 and @DataAngajarii>@data
		Return round(@ZileCOCuvenite,0)

--	daca numarul de zile lucratoare pentru perioada lucrata in an este 0, nu este cazul sa se calculeze numarul de zile de CO cuvenite.
	if @ModAngajare='N' and dbo.Zile_lucratoare((case when @DataAngajarii<@DataJos then @DataJos else @DataAngajarii end), (case when @DataSusNedet>@DataSus then @DataSus else @DataSusNedet end))=0
		Return round(@ZileCOCuvenite,0)

	set @ZileCOCuvenite=(select isnull(max(e.Procent),0)+(max(b.Zile_concediu_de_odihna_an)+max(b.Zile_concediu_efectuat_an))*
	(case when max(b.mod_angajare)='D' and @ProbaZile=0 and max(b.zile_absente_an)<>0 and not(max(b.data_angajarii_in_unitate)<@DataJos and @DataFinal>@DataSus) and 1=0 then 
	max(convert(float,b.zile_absente_an))/12 else 1 end)*
	(case when 
	--perioada determinata
	max(b.mod_angajare)='D' and max(b.zile_absente_an)<>0 
		then (case when @ProbaZile=1 then (case when max(b.data_angajarii_in_unitate)<@DataJos and @DataFinal>@DataSus then 1 
			else (dbo.Zile_lucratoare((case when max(b.data_angajarii_in_unitate)<@DataJos then @DataJos else max(b.data_angajarii_in_unitate) end),
				(case when @DataFinal>@DataSus then @DataSus else @DataFinal end))/@ZileLucratoareAn) end) 
		else (case when max(b.data_angajarii_in_unitate)<@DataJos and @DataFinal>@DataSus then 1 
		else (dbo.Zile_lucratoare((case when max(b.data_angajarii_in_unitate)<@DataJos then @DataJos else max(b.data_angajarii_in_unitate) end), 
			(case when @DataFinal>@DataSus then @DataSus else @DataFinal end))/@ZileLucratoareAn) end) end) 
	--perioada nedeterminata
	when @AngajatPlecat=0 then 1 else dbo.zile_lucratoare(@DataJosNedet,@DataSusNedet)/@ZileLucratoareAn end)*
			((case when @Calcul_pana_la_luna_curenta=1 
			then dbo.zile_lucratoare((case when max(b.data_angajarii_in_unitate)>@DataJos then max(b.data_angajarii_in_unitate) else @DataJos end), 
				(case when max(convert(int,b.Loc_ramas_vacant))=1 and max(b.Data_plec)<>'01/01/1901' and max(b.Data_plec)<dbo.EOY(@data) then max(b.Data_plec) else @Data end)) 
			else @ZileLucratoareAn end)
			-(case when @cCodCompanieCoda='K2730' then round(max(b.Zile_concediu_de_odihna_an)*
			(case when @Calcul_pana_la_luna_curenta=1 then month(@data)/convert(float,12) else 1 end),2) else 0 end)- 
	(isnull(sum((a.ore_invoiri+a.ore_concediu_fara_salar+a.ore_nemotivate+a.ore_ST
	+(case when @Colas=1 and 1=0 or @DiminZileCOcuZileCM=1 and (@DiminZileCOPeLM='' or b.Loc_de_munca like RTRIM(@DiminZileCOPeLM)+'%') then 1 else 0 end)*a.ore_concediu_medical)
	/(case when a.spor_cond_10=0 then 8 else a.spor_cond_10 end)),0)+ 
	isnull((select sum(c.zile_lucratoare) from conmed c where c.marca=b.marca and (c.tip_diagnostic='0-' or @DiminZileCOcuZileCM=0 and charindex(c.tip_diagnostic,@CodDiagnDiminZileCO)<>0) 
		and c.data between @DataJos and (case when @Calcul_pana_la_luna_curenta=1 then @Data else @DataSus end)),0)))/
	((case 
		when @Calcul_pana_la_luna_curenta=1 and max(b.Mod_angajare)='D' and (@ProbaZile=1 or 1=1) and max(b.zile_absente_an)<>0 
			then dbo.Zile_lucratoare((case when max(b.data_angajarii_in_unitate)<@DataJos then @DataJos else max(b.data_angajarii_in_unitate) end),
				(case when @DataFinal>@DataSus then @DataSus else @DataFinal end))
		when @Calcul_pana_la_luna_curenta=1 and @AngajatPlecat=1 then dbo.zile_lucratoare(@DataJosNedet,@DataSusNedet) else @ZileLucratoareAn end)-
	(case when @cCodCompanieCoda='K2730' then max(b.Zile_concediu_de_odihna_an) else 0 end)) 
	from personal b  
		left outer join (select b.Marca, sum(b.ore_invoiri) as ore_invoiri, sum(b.ore_concediu_fara_salar) as ore_concediu_fara_salar, sum(b.ore_nemotivate) as ore_nemotivate, 
			sum(b.ore_concediu_medical) as ore_concediu_medical, sum(isnull(p.Ore_ST,0)) as Ore_ST, max(spor_cond_10) as spor_cond_10 
		from brut b 
			inner join istpers i on i.Data=b.Data and i.Marca=b.Marca
			left outer join (select dbo.eom(Data) as Data, Marca, Loc_de_munca, sum(ore) as Ore_ST from pontaj p 
				where p.Data between @DataJos and (case when @Calcul_pana_la_luna_curenta=1 then @Data else @DataSus end) group by dbo.eom(Data), Marca, Loc_de_munca) p on 1=0 
					and isnull((select convert(int,val_logica) from par_lunari where data=b.data and tip='PS' and parametru='STOUG28'),0)=1 
						and b.Ore_intrerupere_tehnologica<>0 and b.Data=p.Data and b.Marca=p.Marca and b.Loc_de_munca=p.Loc_de_munca 
		where b.data between @DataJos and (case when @Calcul_pana_la_luna_curenta=1 then @Data else @DataSus end) group by b.marca) a on a.marca=b.marca  
		left outer join extinfop e on b.marca=e.marca and e.cod_inf='SOLDZILECO' and e.data_inf between @DataJos and @DataSus
	where b.marca=@Marca and (b.Loc_ramas_vacant=0 or b.Data_plec>=@DataJos)
	group by b.marca)

	Return round(@ZileCOCuvenite,0)
End
