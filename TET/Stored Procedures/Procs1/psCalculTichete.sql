--***
/**	procedura calcul tichete de masa */
Create procedure psCalculTichete
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLm char(9), @Stergere int, @Generare int, @GenerareTichSoc int=0, @parXML xml=null
As
Begin
	set transaction isolation level read uncommitted
	declare @utilizator varchar(10), @OreLuna float, @OreLunaAnt float, @NrTichLuna int, @NrTichLunaMarca int, @ValTichet decimal(10,3), @ValTichetSocial decimal(10,3), 
	@ValImprimat decimal(10,3), @TVAImprimat decimal(10,3), @LmStatPLSal int, @SCONDORN int, @OSNRN int, @O100NRN int, @ORegieFaraOS2 int, @TichZileLucr int, @TichZileLucrPond int, @NuTichXZileAng int, 
	@XZileFaraTich int, @AnulTichXNem int, @TichMacheta int, @NrFixTichete int, @TichPontajLunaAnt int, @TicheteMarca int, @TicheteRegimL int, @TichetePers int, @TotalTichete decimal(10,2),
	@dataJosCalc datetime, @dataSusCalc datetime, @Dafora int, @Somesana int, @Prodpan int, @Colas int, @Imcop int, @LibrNOI int, @Grup7 int, 
	@Data datetime, @Marca char(6), @gMarca char(6), @Nr_tichete decimal(5,2), @Lm char(9), @LmStatPL int, @LmPers char(9), @AreTichete int, @DataAngajarii datetime, @Plecat int, 
	@GrupaMuncaP char(1), @DataPlecarii datetime, @Tip_colab char(3), @RegimL decimal(5,2), @ZileLucrate int, @OreRN int, @OreNelucrate int, @NrTicheteDafora int, @OreDelegatie int, 
	@OreIT int, @OreIntemp int, @OreNemotivate int, @NrCrt int, @OreLucrFTich int, @ZileLucrFTich int, @ZileIngCopil int, @TicheteZileLucr decimal(6,3), @NrTichete decimal(6,3), 
	@NrTicheteCuvMarca decimal(6,3), @AngajatOrPlecat int, @CondAnulare int, @Rotunjire int, @CoefImcop decimal(5,2), @CoefPonderat decimal(6,3), @NrTichAnt int, @SerieInceputAnt char(13), 
	@OreProba int, @OrePreaviz int, @NrTichDePus int, @SerieInceputDePus int, @gfetch int, 
	@repartizarePeSerii int, @serieInceput int, @serieSfarsit int, @ordineRepartizare int
	/*
		@ordineRepartizare=1	-> Loc de munca, Marca
		@ordineRepartizare=2	-> Loc de munca, Nume
		@ordineRepartizare=3	-> Marca
	*/

	set @repartizarePeSerii=ISNULL(@parXML.value('(/row/@repserii)[1]', 'int'), 0)
	set @serieInceput=ISNULL(@parXML.value('(/row/@serieinc)[1]', 'int'), 0)
	set @serieSfarsit=ISNULL(@parXML.value('(/row/@seriesf)[1]', 'int'), 0)
	set @ordineRepartizare=ISNULL(@parXML.value('(/row/@ordinerep)[1]', 'int'), 0)

	set @utilizator = dbo.fIaUtilizator(null)
--	preluare parametrii lunarii
	exec psInitParLunari @dataJos, @dataSus, 0

	set @NrTichLuna = dbo.iauParLN(@dataSus,'PS','NRTICHETE')
	set @ValTichet = dbo.iauParLN(@dataSus,'PS','VALTICHET')
	set @ValTichetSocial = dbo.iauParN('PS','VALTICSOC')
	set @ValImprimat = dbo.iauParN('PS','VALIMPR')
	set @TVAImprimat = dbo.iauParN('PS','TVAIMPR')
	set @LmStatPLSal = dbo.iauParL('PS','LOCMSALAR')
	set @SCONDORN = dbo.iauParL('PS','SP-C-ORN')
	set @OSNRN = dbo.iauParL('PS','OSNRN')
	set @O100NRN = dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2 = dbo.iauParL('PS','OREG-FOS2')
	set @TichMacheta = dbo.iauParL('PS','OPTICHINM')
	set @TichZileLucr = dbo.iauParL('PS','TICHZLUC')
	set @TichZileLucrPond = dbo.iauParL('PS','TICHZLDIM')
	set @NuTichXZileAng = dbo.iauParL('PS','TICNUZANG')
	set @XZileFaraTich = dbo.iauParN('PS','TICNUZANG')
	set @AnulTichXNem = dbo.iauParL('PS','TICH-ANUL')
	set @NrFixTichete = dbo.iauParL('PS','TICVALFIX')
	set @TichPontajLunaAnt = dbo.iauParL('PS','TICHLANT')
	set @TicheteMarca = dbo.iauParL('PS','TICHMARCA')
	set @TicheteRegimL = dbo.iauParL('PS','TICH-RLTP')
	set @TichetePers = dbo.iauParL('PS','TICHPERS')
	set @Rotunjire = dbo.iauParN('PS','ROTTICH')
	set @Rotunjire=(case when @TichetePers=1 then 2 else @Rotunjire end)
	set @Dafora = dbo.iauParL('SP','DAFORA')
	set @Somesana = dbo.iauParL('SP','SOMESANA')
	set @Prodpan = dbo.iauParL('SP','PRODPAN')
	set @Colas = dbo.iauParL('SP','COLAS')
	set @Imcop = dbo.iauParL('SP','IMCOP')
	set @LibrNOI = dbo.iauParL('SP','NOI')
	set @Grup7 = dbo.iauParL('SP','GRUP7')
	set @TotalTichete=0
	set @dataJosCalc=dbo.bom(DateAdd(day,(case when @TichPontajLunaAnt=1 then -1 else 0 end),@dataJos))
	set @dataSusCalc=dbo.eom(DateAdd(day,(case when @TichPontajLunaAnt=1 then -1 else 0 end),@dataJos))
	set @OreLuna = dbo.iauParLN(@dataSusCalc,'PS','ORE_LUNA')

	if exists (select * from sysobjects where name='psCalculTicheteSP1' and type='P') 
		exec psCalculTicheteSP1 @dataJos, @dataSus, @pMarca, @pLm

	/* pun datele din tabela personal in tabela temporara si le filtram aici. Ulterior facem doar inner join pe #personal */
	if OBJECT_ID('tempdb..#personal') is not null drop table #personal
	select p.* into #personal 
	from personal p
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where (@pMarca='' or p.Marca=@pMarca) and (@pLm='' or p.loc_de_munca like rtrim(@pLm)+'%') 
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	If @Stergere=1 
		delete tichete from tichete t
			inner join #personal p on t.marca=p.marca
		where t.Data_lunii between @dataJos and @dataSus and t.tip_operatie between 'C' and (case when @TichetePers=1 then 'C' else 'P' end) 
			

	If @Generare=1 and @TichMacheta=1 and @NrFixTichete=1
--	inserare in tichete pt. cazul setarii [X]Numar fix de tichete cuvenite
		Insert into tichete 
			(Marca, Data_lunii, Tip_operatie, Serie_inceput, Serie_sfarsit, Nr_tichete, Valoare_tichet, Valoare_imprimat, TVA_imprimat)
		Select p.marca, @dataSus, 'C', '', '', (case when dbo.iauExtinfopProc(Marca,'NRTICHETE')=0 then @NrTichLuna else dbo.iauExtinfopProc(Marca,'NRTICHETE') end), 
			@ValTichet, @ValImprimat, @TVAImprimat
		from #personal p 
		where p.Data_angajarii_in_unitate<=@dataSusCalc and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataSusCalc) and (@TicheteMarca=0 or convert(int,p.Loc_de_munca_din_pontaj)=1)
			and p.Grupa_de_munca not in ('P','O')

--	calcul tichete pt. celelalte cazuri: parcurgere cursor din pontaj cu calcul functie de setari
	If @Generare=1 and (@NrFixTichete=0 or @TichetePers=1)
	Begin
		Declare TichetePontaj Cursor For
		select a.Data, a.Marca, a.Ore__cond_6, a.Loc_de_munca, a.Loc_munca_pentru_stat_de_plata,
		p.Loc_de_munca, p.Grupa_de_munca, p.Loc_de_munca_din_pontaj, p.Data_angajarii_in_unitate, convert(int,p.Loc_ramas_vacant), p.Data_plec, p.Tip_colab,
		a.Regim_de_lucru, (a.Ore_regie+(case when @Somesana=1 then 0 else a.Ore_acord end)
		-(case when @OSNRN=1 and @Prodpan=0 then a.Ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.Ore_suplimentare_2 end)+a.Ore_suplimentare_3+a.Ore_suplimentare_4 else 0 end)
		-(case when @O100NRN=1 and @Prodpan=0 then a.Ore_spor_100 else 0 end)) as OreRN,
		(a.ore_concediu_de_odihna+a.Ore_concediu_medical+a.ore_nemotivate+a.Ore_invoiri+a.Ore_intrerupere_tehnologica+a.Ore_concediu_fara_salar
		+a.ore_obligatii_cetatenesti+(case when @SCONDORN=1 and a.Spor_conditii_6<>0 then 0 else a.Ore_donare_sange end)+a.Spor_cond_10) as OreNelucrate,
		(a.Ore_regie+a.Ore_acord-(a.Ore_suplimentare_1+a.Ore_suplimentare_2+a.Ore_suplimentare_3+a.Ore_suplimentare_4+a.Spor_cond_10))/Regim_de_lucru as NrTicheteDafora,
		a.Spor_cond_10, a.Ore_intrerupere_tehnologica, a.Spor_cond_8, a.Ore_nemotivate, isnull(c.Zile_lucratoare,0),
		a.Numar_curent
		from pontaj a
			inner join #personal p on p.Marca=a.Marca
			left outer join conmed c on c.Marca=a.Marca and c.Data=@dataSus and c.Tip_diagnostic='0-'
		where a.data between @dataJosCalc and @dataSusCalc
			and (@TichPontajLunaAnt=0 or (a.Ore_lucrate>0 and a.Marca not in (select marca from #personal where loc_ramas_vacant=1 and Data_plec between @dataJosCalc and @dataSusCalc)))
		order by a.Marca, a.Data
	
		open TichetePontaj
		fetch next from TichetePontaj into
		@Data, @Marca, @Nr_tichete, @Lm, @LmStatPL, @LmPers, @GrupaMuncaP, @AreTichete, @DataAngajarii, @Plecat, @DataPlecarii, @Tip_colab, @RegimL, @OreRN, @OreNelucrate, @NrTicheteDafora, 
		@OreDelegatie, @OreIT, @OreIntemp, @OreNemotivate, @ZileIngCopil, @NrCrt
		set @gfetch=@@fetch_status
		set @gmarca = @marca
		While @@fetch_status=0 
		Begin
			Select @NrTicheteCuvMarca=0, @ZileLucrFTich=0
			while @marca = @gMarca and @gfetch = 0
			Begin
				set @NrTichLunaMarca=(case when dbo.iauExtinfopProc(@Marca,'NRTICHETE')=0 then @NrTichLuna else dbo.iauExtinfopProc(@Marca,'NRTICHETE') end)
				select @ZileLucrate=0, @OreProba=0, @OrePreaviz=0
				set @AngajatOrPlecat=(case when @DataAngajarii between @dataJosCalc and @dataSusCalc or @Plecat=1 and @DataPlecarii between @dataJosCalc and @dataSusCalc then 1 else 0 end)
				set @CoefImcop=(case when @Imcop=1 and @NrTichLuna<@OreLuna/8.00 then @NrTichLuna/(@OreLuna/8.00) else 1 end) 
				set @CoefPonderat=(case when @TichZileLucrPond=1 and @NrTichLunaMarca<@OreLuna/8.00 then @NrTichLunaMarca/(@OreLuna/8.00) else 1 end) 
--	calcul nr. zile lucratoare fara tichete (daca setare [X]Nu se acorda tichete pt. primele X zile calendaristice)
				set @ZileLucrFTich=isnull((select dbo.psZileFaraTichete(@dataJos, @dataSus, @Marca) where @NuTichXZileAng=1 and DateAdd(day,@XZileFaraTich,@DataAngajarii)>=@dataJos),0)
				if @AngajatOrPlecat=1 and @TichZileLucr=0
				set @ZileLucrate=dbo.Zile_lucratoare((case when @DataAngajarii between @dataJosCalc and @dataSusCalc then @DataAngajarii else @dataJosCalc end),
					(case when @Plecat=1 and @DataPlecarii between @dataJosCalc and @dataSusCalc then DateAdd(day,-1,@DataPlecarii) else @dataSusCalc/*+1*/ end))-@ZileLucrFTich-@ZileIngCopil
				select @OreProba=Zile*@RegimL+Ore from dbo.fDate_pontaj_automat(@dataJos, @dataSus, @Data, 'PB', @Marca, 0, 0)
				select @OrePreaviz=Zile*@RegimL+Ore from dbo.fDate_pontaj_automat(@dataJos, @dataSus, @Data, 'PZ', @Marca, 0, 0)
				select @OreProba=isnull(@OreProba,0), @OrePreaviz=isnull(@OrePreaviz,0)
				Select @OreLucrFTich=@OreProba+@OrePreaviz+@ZileLucrFTich*@RegimL

				Select @TicheteZileLucr=(case when @TicheteMarca=1 and @AreTichete=0 or @GrupaMuncaP in ('O','P') and @TicheteMarca=0 then 0 
--	Lucian: pus rotunjire intermediara la 3 zecimale, si se face la final rotunjirea functie de parametru (@rotunjire) - sesizarea PC052916
				when @TicheteRegimL=1 and @GrupaMuncaP='C' then round((@OreRN-@OreLucrFTich+(case when @Colas=1 then @OreIT+@OreIntemp else 0 end)-@OreDelegatie)/8.00,3/*@Rotunjire,1*/)
				else round((@OreRN-@OreLucrFTich+(case when @Colas=1 then @OreIT+@OreIntemp else 0 end)-@OreDelegatie)/@RegimL,3) end) where @TichZileLucr=1

				Select @TicheteZileLucr=@TicheteZileLucr*@CoefPonderat where @TichZileLucrPond=1
				set @NrTichete=round((case when @AngajatOrPlecat=1 and @TichZileLucr=0 
					then (case when @ZileLucrate-(@OreNelucrate+(case when @Grup7=1 then @OrePreaviz else 0 end))/@RegimL-(case when @Imcop=1 then 0 else @OreLuna/8.00-@NrTichLunaMarca end)<0 or @OreRN=0 
						then 0 else (@ZileLucrate-(@OreNelucrate+(case when @Grup7=1 then @OrePreaviz else 0 end))/@RegimL)*@CoefImcop-(case when @Imcop=1 then 0 else @OreLuna/8.00-@NrTichLunaMarca end) end)
					when @TichPontajLunaAnt=1 and @Prodpan=0 and @TichZileLucr=0 then @OreLuna/8.00
					when @TichZileLucr=1 then @TicheteZileLucr else @NrTichLunaMarca end),6,3/*@Rotunjire*/)

				set @CondAnulare=(case when @GrupaMuncaP in ('O','P') and @TicheteMarca=0 or @GrupaMuncaP='C' and @Tip_colab='FDP' or @AnulTichXNem=1 and @OreNemotivate>7 then 1 else 0 end)

				Select @NrTichete=(case when (@Dafora=1 or @TicheteMarca=1) and @AreTichete=0 then 0 
					when (@LmStatPLSal=1 and @Lm<>@LmPers and @LmStatPL=0 or @LmStatPLSal=0 and @LmStatPL=0) and @Dafora=0 or @CondAnulare=1 then 0 
					else round((case when @Dafora=1 then @NrTicheteDafora 
						else @NrTichete-@ZileIngCopil-@ZileLucrFTich
							-(case when @TichPontajLunaAnt=0 and @LibrNOI=1 then @OreLuna/8.00-@OreRN 
								else (@OreNelucrate+(case when @Grup7=1 then @OrePreaviz else 0 end))*@CoefPonderat end)/@RegimL*@CoefImcop end),3/*@Rotunjire*/) end)
				where @AngajatOrPlecat=0 and @TichZileLucr=0

				select @NrTichete=round(@NrTichete,@Rotunjire)
				Select @NrTichete=(case when @NrTichete<0  or @TicheteMarca=1 and @AreTichete=0 then 0 when @NrTichete>@NrTichLunaMarca then @NrTichLunaMarca else @NrTichete end)
--	calcul tichete in pontaj
				update pontaj set Ore__cond_6=@NrTichete where @TichPontajLunaAnt=0 and @NrTichete>=0 and Data=@Data and Marca=@Marca and Loc_de_munca=@Lm and Numar_curent=@NrCrt
--	scriu tichete pontaj din luna anterioara
				update pontaj set Ore__cond_6=@NrTichete where @TichPontajLunaAnt=1 and @NrTichete>=0 and Data between @dataJos and @dataSus and Marca=@Marca and Loc_munca_pentru_stat_de_plata=1

				set @NrTicheteCuvMarca=@NrTicheteCuvMarca+@NrTichete
				fetch next from TichetePontaj into
					@Data, @Marca, @Nr_tichete, @Lm, @LmStatPL, @LmPers, @GrupaMuncaP, @AreTichete, @DataAngajarii, @Plecat, @DataPlecarii, @Tip_colab, @RegimL, @OreRN, @OreNelucrate, 
					@NrTicheteDafora, @OreDelegatie, @OreIT, @OreIntemp, @OreNemotivate, @ZileIngCopil, @NrCrt
				set @gfetch=@@fetch_status
			End
			set @NrTichLunaMarca=(case when dbo.iauExtinfopProc(@gMarca,'NRTICHETE')=0 then @NrTichLuna else dbo.iauExtinfopProc(@gMarca,'NRTICHETE') end)
--	scriere numar tichete in tabela tichete (daca se lucreaza cu macheta de tichete)
			if @TichMacheta=1 and @NrTicheteCuvMarca>0
			Begin
				select @NrTicheteCuvMarca=(case when @NrTicheteCuvMarca<0 then 0 when @NrTicheteCuvMarca>@NrTichLunaMarca then @NrTichLunaMarca else @NrTicheteCuvMarca end)
				select @NrTichAnt=Nr_Tichete, @SerieInceputAnt=Serie_inceput from tichete where Data_lunii=@dataSus and Marca=@gMarca and Tip_operatie='C'
				select @NrTichDePus=round(@NrTicheteCuvMarca,0)-isnull(@NrTichAnt,0), @SerieInceputDePus=convert(char(13),convert(int,isnull(@SerieInceputAnt,''))+1)
				exec scriuTichete @gMarca, @dataSus, 'C', @SerieInceputDePus, '', @NrTichDePus, @ValTichet, @ValImprimat, @TVAImprimat
			End			
			set @gMarca=@Marca
		end
		close TichetePontaj
		Deallocate TichetePontaj
	End

	if exists (select * from sysobjects where name='psCalculTicheteSP3' and type='P') 
		exec psCalculTicheteSP3 @dataJos, @dataSus, @pMarca, @pLm

	if @TichMacheta=1 and @TotalTichete>0
		delete tichete 
		from tichete t
			inner join #personal p on t.marca=p.marca
		where Data_lunii=@dataSus and tip_operatie='C' and Nr_tichete=0

--	sterg tichetele sociale generate anterior	
	if @GenerareTichSoc=1 
		delete tichete from tichete t
			inner join #personal p on t.marca=p.marca
		where Data_lunii between @dataJos and @dataSus and tip_operatie='X' 

--	inserare in tichete nr. tichete sociale=nr. tichete de masa acordate
	if @GenerareTichSoc=1 
		Insert into tichete
			(Marca, Data_lunii, Tip_operatie, Serie_inceput, Serie_sfarsit, Nr_tichete, Valoare_tichet, Valoare_imprimat, TVA_imprimat)
		Select t.marca, @dataSus, 'X', '', '', sum(Nr_tichete*(case when t.Tip_operatie='R' then -1 else 1 end)), @ValTichetSocial, 0, 0
		from tichete t
			inner join #personal p on p.Marca=t.Marca
			outer apply (select top 1 val_inf from extinfop e where e.Marca=t.marca and e.cod_inf='TICHSOCIALE' and e.Data_inf<=t.Data_lunii order by e.data_inf desc) ts 
		where t.Data_lunii=@dataSus and t.Tip_operatie in ('C','P','R') and (@TicheteMarca=0 or convert(int,p.Loc_de_munca_din_pontaj)=1)
			and isnull(ts.val_inf,'')='DA' -- and exists (Select Marca from extinfop e where e.Marca=t.Marca and e.Cod_inf='TICHSOCIALE' and upper(val_inf)='DA')
		Group by t.Marca	

	/*	repartizare tichete de masa pe serii (de la seria ... la seria ...) */
	if @repartizarePeSerii=1
	begin
		if OBJECT_ID('tempdb..#TicheteAcordate') is not null drop table #TicheteAcordate
		if OBJECT_ID('tempdb..#pontajTichete') is not null drop table #pontajTichete
		if OBJECT_ID('tempdb..#TicheteRep') is not null drop table #TicheteRep

		Create table #pontajTichete (marca varchar(6), NrTichete int)

		if @TichMacheta=0
			insert into #pontajTichete
			select a.marca, sum(a.Ore__cond_6) as NrTichete
			from pontaj a
				inner join #personal p on p.Marca=a.Marca
			where a.data between @dataJosCalc and @dataSusCalc and (@pMarca='' or a.Marca=@pMarca)
			group by a.marca

		select t.marca, sum((case when t.Tip_operatie='P' then Nr_tichete else 0 end)) as TicheteRepartizate, 
			sum((case when t.Tip_operatie='C' and @TichMacheta=1 then Nr_tichete else 0 end)) as TicheteCuvenite
		into #TicheteAcordate
		from tichete t
			inner join #personal p on p.Marca=t.Marca
		where t.Data_lunii between @DataJosCalc and @dataSusCalc and (@pMarca='' or t.Marca=@pMarca)
		group by t.marca

		select p.marca, (case when @TichMacheta=1 then isnull(ta.TicheteCuvenite,0) else isnull(pt.NrTichete,0) end) as TicheteCuvenite,
			isnull(ta.TicheteRepartizate,0) as TicheteRepartizate, 0 as TicheteDeRepart,
			convert(varchar(13),'') as SerieInceput, convert(varchar(13),'') as SerieSfarsit,
			row_number() over (order by (case when @ordineRepartizare=1 then p.Loc_de_munca+p.Marca when @ordineRepartizare=2 then p.Loc_de_munca+p.Nume else p.Nume end)) ordine
		into #TicheteRep
		from #personal p
			left outer join #pontajTichete pt on pt.Marca=p.marca
			left outer join #TicheteAcordate ta on ta.Marca=p.marca
		where (@Dafora=0 or p.Loc_ramas_vacant=0 or p.Loc_ramas_vacant=1 and p.Data_plec>=@dataJos) 
		order by ordine
		update #TicheteRep set TicheteDeRepart=(case when TicheteCuvenite-TicheteRepartizate<0 then 0 else TicheteCuvenite-TicheteRepartizate end)
		delete from #TicheteRep where TicheteDeRepart<=0

		declare @SerieIncCalcul int, @SerieSfCalcul int, @TicheteDeRepart int, 
			@SerieInceputTampon int	-- variabila tampon pentru serie inceput. Daca s-ar folosi mai jos SerieInceput=@SerieIncCalcul la prima pozitie ar completa gresit seria de inceput.
		select @SerieIncCalcul=@serieInceput

		update tr 
			set 
				@TicheteDeRepart=(case when @SerieIncCalcul+TicheteDeRepart-1>@serieSfarsit then @serieSfarsit-convert(int,@SerieIncCalcul)+1 else TicheteDeRepart end)
				,TicheteDeRepart=@TicheteDeRepart
				,@SerieSfCalcul=@SerieIncCalcul+@TicheteDeRepart-1
				,@SerieInceputTampon=@SerieIncCalcul
				,SerieInceput=@SerieInceputTampon, SerieSfarsit=@SerieSfCalcul
				,@SerieIncCalcul=@SerieIncCalcul+@TicheteDeRepart	--	serie inceput pentru urmatoare pozitie
		from #TicheteRep tr

		insert into tichete 
			(Marca, Data_lunii, Tip_operatie, Serie_inceput, Serie_sfarsit, Nr_tichete, Valoare_tichet, Valoare_imprimat, TVA_imprimat)
		select marca, @dataSusCalc, 'P', convert(varchar(13),SerieInceput), convert(varchar(13),SerieSfarsit), TicheteDeRepart, @ValTichet, @ValImprimat, @TVAImprimat
		from #TicheteRep
	end
	
	if exists (select * from sysobjects where name='psCalculTicheteSP2' and type='P') 
		exec psCalculTicheteSP2 @dataJos, @dataSus, @pMarca, @pLm
End

/*
	exec psCalculTichete '08/01/2014', '08/31/2014', '', '', 1, 1, 0, '<row repserii="1" serieinc="1" seriesf="100000" optiunirep="1" />'
*/
