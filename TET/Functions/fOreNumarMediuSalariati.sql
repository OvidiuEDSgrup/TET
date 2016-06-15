--***
/*	functie pentru calcul ore (la nivel de marca) ce intra in determinarea numarului mediu de salariati 
	Aceasta functie va fi apelata astfel atat din functia de calcul contributie neangajare cu handicap cat si din procedura pt. raportul statistic S3 */
Create function fOreNumarMediuSalariati
	(@dataJos datetime, @dataSus datetime, @functie char(6), @lmJos char(9), @lmSus char(9), @tipstat varchar(30), @judet varchar(30), @activitate varchar(20))
returns @ore_nrmedsal table 
	(data datetime, marca char(6), ore float)
As
Begin
	Declare @utilizator varchar(20), @lista_lm int, @multiFirma int, @DataIncr datetime, @DataFiltru datetime, @Numar_mediu float, 
		@OreS_RN bit, @Ore100_RN bit, @ORegieFaraOS2 int, @ore_int_rn bit, @Pontaj_zilnic bit, @STOUG28 int, @ExcepGrpMP int, 
		@IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int
	
	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @OreS_RN=dbo.iauParL('PS','OSNRN')
	set @Ore100_RN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	set @ore_int_rn=dbo.iauParL('PS','OINTNRN')
	set @pontaj_zilnic=dbo.iauParL('PS','PONTZILN')
	set @ExcepGrpMP=dbo.iauParL('PS','CPH-EGMP')
	set @IT1SuspContr=dbo.iauParL('PS','IT1-SUSPC')
	set @IT2SuspContr=dbo.iauParL('PS','PROC2INT')
	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')	
	set @numar_mediu=0
	set @DataIncr = @dataJos

	declare @tmpore table (data datetime, marca char(6), nr_ore float)

--	calcul pentru cazul in care se lucreaza cu pontaj zilnic
	if @pontaj_zilnic=1
	Begin
		while @DataIncr <= @dataSus
		Begin
--	daca zi	lucratoare
			if not(datename(WeekDay, @DataIncr) in ('Sunday','Saturday') or @DataIncr in (select data from calendar))
			Begin
				insert into @tmpore (data, marca, nr_ore)
				select dbo.eom(a.Data), a.Marca, sum(a.ore_regie+a.ore_acord
					-(case when @OreS_RN=1 then a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4 else 0 end)
					-(case when @Ore100_RN=1 then a.ore_spor_100 else 0 end)
					+(case when @ore_int_rn=1 or @IT1SuspContr=1 then 0 else a.ore_intrerupere_tehnologica end)
					+a.ore_concediu_de_odihna +a.ore_obligatii_cetatenesti+(case when @STOUG28=1 or @IT2SuspContr=1 then 0 else ore end))/8.0
				from pontaj a
					left outer join personal p on p.Marca=a.Marca
					left outer join istpers i on i.data=dbo.EOM(a.data) and i.Marca=a.Marca
					left outer join infopers ip on ip.Marca=a.Marca
					left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
				where a.data=@DataIncr and (@functie='' or i.Cod_functie=@functie) 
					and (@lmJos='' or i.Loc_de_munca between @lmJos and @lmSus) 
					and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
					and i.Grupa_de_munca<>'O' and (@ExcepGrpMP=0 or i.Grupa_de_munca<>'P') and (@tipstat='' or ip.Religia=@tipstat)
					and not exists (select cod from proprietati where tip='LM' and valoare='DA' and cod_proprietate='FARANCHAND' and proprietati.cod=a.Loc_de_munca) 
					and (@judet is null or i.Judet=@judet or exists (select 1 from judete j where j.denumire=i.judet and j.cod_judet=@judet))
					and (@activitate is null or p.Activitate=@activitate)
					and i.Tip_colab not in ('DAC','CCC','ECT')
				Group by dbo.eom(a.Data), a.Marca	
			End
			else
--	daca zi	nelucratoare
			Begin
				Set @DataFiltru=@DataIncr
				while datename(WeekDay, @DataFiltru) in ('Sunday','Saturday') or @DataFiltru in (select data from calendar)
				Begin
					Set @DataFiltru=@DataFiltru-1
				End
				insert into @tmpore (data, marca, nr_ore)
				select @DataFiltru, a.Marca, sum((case when p.loc_ramas_vacant=0 or p.data_plec>@DataFiltru 
					then a.ore_regie+a.ore_acord
					-(case when @OreS_RN=1 then a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4 else 0 end)
					-(case when @Ore100_RN=1 then a.ore_spor_100 else 0 end)
					+(case when @ore_int_rn=1 or @IT1SuspContr=1 then 0 else a.ore_intrerupere_tehnologica end)
					+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+(case when @STOUG28=1 or @IT2SuspContr=1 then 0 else ore end) else 0 end))/8.0
				from pontaj a
					left outer join istpers i on i.data=dbo.EOM(a.data) and i.Marca=a.Marca
					left outer join personal p on p.Marca=a.Marca
					left outer join infopers ip on ip.Marca=a.Marca
					left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
				where a.data=@DataFiltru and (@functie='' or i.Cod_functie=@functie) 
					and (@lmJos='' or i.Loc_de_munca between @lmJos and @lmSus) 
					and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
					and i.Grupa_de_munca<>'O' and (@ExcepGrpMP=0 or i.Grupa_de_munca<>'P') and (@tipstat='' or ip.Religia=@tipstat) 
					and not exists (select cod from proprietati where tip='LM' and valoare='DA' and cod_proprietate='FARANCHAND' and proprietati.cod=a.Loc_de_munca) 
					and (@judet is null or i.Judet=@judet or exists (select 1 from judete j where j.denumire=i.judet and j.cod_judet=@judet))
					and (@activitate is null or p.Activitate=@activitate)
					and i.Tip_colab not in ('DAC','CCC','ECT')
				Group by a.Marca
			End
			Set @DataIncr = dateadd(day, 1, @DataIncr)
		End
	End
--	calcul pentru cazul in care NU se lucreaza cu pontaj zilnic
	If @pontaj_zilnic=0
	Begin 
		insert into @tmpore (data, marca, nr_ore)
		select dbo.eom(a.Data), a.Marca, sum(a.ore_regie+a.ore_acord
			-(case when @OreS_RN=1 then a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4 else 0 end)
			-(case when @Ore100_RN=1 then a.ore_spor_100 else 0 end)
			+(case when @ore_int_rn=1 or @IT1SuspContr=1 then 0 else a.ore_intrerupere_tehnologica end)
			+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+(case when @STOUG28=1 or @IT2SuspContr=1 then 0 else ore end))/8.0
		from pontaj a 
			left outer join istpers i on i.data=dbo.EOM(a.data) and i.Marca=a.Marca
			left outer join personal p on p.Marca=a.Marca
			left outer join infopers ip on ip.Marca=a.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		where a.data between @dataJos and @dataSus and (@functie='' or i.Cod_functie=@functie) 
			and (@lmJos='' or i.Loc_de_munca between @lmJos and @lmSus) 
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
			and i.Grupa_de_munca<>'O' and (@ExcepGrpMP=0 or i.Grupa_de_munca<>'P') and (@tipstat='' or ip.Religia=@tipstat) 
			and not exists (select cod from proprietati where tip='LM' and valoare='DA' and cod_proprietate='FARANCHAND' and proprietati.cod=a.Loc_de_munca) 
			and (@judet is null or i.Judet=@judet or exists (select 1 from judete j where j.denumire=i.judet and j.cod_judet=@judet))
			and (@activitate is null or p.Activitate=@activitate)
			and i.Tip_colab not in ('DAC','CCC','ECT')
		Group by dbo.eom(a.Data), a.Marca

		while @DataIncr <= @dataSus
		Begin
			if datename(WeekDay, @DataIncr) in ('Sunday','Saturday') or @DataIncr in (select data from calendar)
			Begin
				Set @DataFiltru=@DataIncr
			while datename(WeekDay, @DataFiltru) in ('Sunday','Saturday') or @DataFiltru in (select data from calendar)
				Begin
					Set @DataFiltru=@DataFiltru-1
				End

				insert into @tmpore (data, marca, nr_ore)
				select a.Data, a.Marca, sum(a.regim_de_lucru/8) 
					from (select distinct dbo.eom(data) as Data, marca, max(Loc_de_munca) as Loc_de_munca, max(regim_de_lucru) as regim_de_lucru 
						from pontaj where data between @dataJos and @dataSus group by dbo.eom(data), marca) a 
							left outer join istpers i on i.data=dbo.EOM(a.data) and i.Marca=a.Marca
							left outer join personal p on p.Marca=a.Marca
							left outer join infopers ip on ip.Marca=a.Marca
							left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
					where a.data between /*@dataJos and @dataSus*/ dbo.BOM(@DataIncr) and dbo.EOM(@DataIncr) and (@functie='' or i.Cod_functie=@functie) 
						and (@lmJos='' or i.Loc_de_munca between @lmJos and @lmSus) 
						and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
						and (@tipstat='' or ip.Religia=@tipstat) and i.Tip_colab not in ('DAC','CCC','ECT') 
						and p.Data_angajarii_in_unitate<=@DataFiltru and i.Grupa_de_munca<>'O' 
						and (@ExcepGrpMP=0 or i.Grupa_de_munca<>'P') 
						and not exists (select cod from proprietati where tip='LM' and valoare='DA' and cod_proprietate='FARANCHAND' and proprietati.cod=a.Loc_de_munca) 
						and (@judet is null or i.Judet=@judet or exists (select 1 from judete j where j.denumire=i.judet and j.cod_judet=@judet))
						and (@activitate is null or p.Activitate=@activitate)
						and	(p.loc_ramas_vacant=0 or p.data_plec>=@DataFiltru) 
						and	(not exists (select marca from conmed where data between @dataJos-1 and @dataSus
						and Marca=a.marca and @DataFiltru>=Data_inceput and @DataFiltru<=Data_sfarsit)) 
						and	(not exists (select marca from conalte where data between @dataJos-1 and @dataSus
						and Marca=a.marca and @DataFiltru>=Data_inceput and @DataFiltru<=Data_sfarsit and Indemnizatie=0))
				group by a.Data, a.marca

				insert into @tmpore (data, marca, nr_ore)
				select dbo.eom(a.Data), a.Marca, -sum(a.Indemnizatie)/8 
					from conalte a 
						left outer join istpers i on i.data=dbo.EOM(a.data) and i.Marca=a.Marca
						left outer join personal p on p.Marca=a.Marca
						left outer join infopers ip on ip.Marca=a.Marca
						left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
					where a.data between @dataJos-1 and @dataSus and (@functie='' or i.Cod_functie=@functie) 
						and (@lmJos='' or i.Loc_de_munca between @lmJos and @lmSus) 
						and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
						and (@tipstat='' or ip.Religia=@tipstat) and p.Data_angajarii_in_unitate<=@DataFiltru 
						and	(p.loc_ramas_vacant=0 or p.data_plec>=@DataFiltru)
						and not exists (select cod from proprietati where tip='LM' and valoare='DA' and cod_proprietate='FARANCHAND' and proprietati.cod=isnull(i.Loc_de_munca,p.Loc_de_munca))
						and (@judet is null or i.Judet=@judet or exists (select 1 from judete j where j.denumire=i.judet and j.cod_judet=@judet))
						and (@activitate is null or p.Activitate=@activitate)
						and Data_inceput=Data_sfarsit and Data_inceput=@DataFiltru and Indemnizatie<>0
				group by dbo.eom(a.Data), a.marca
							
			End
			Set @DataIncr = dateadd(day, 1, @DataIncr)
		End
	End

	insert into @ore_nrmedsal (data, marca, ore)
	select dbo.eom(Data), Marca, SUM(nr_ore) 
	from @tmpore 
	group by dbo.eom(Data), marca
	
	return
End
