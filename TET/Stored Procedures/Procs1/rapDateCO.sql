--***
/**	procedura pentru returnare date concedii odihna	si stat de plata concedii de odihna*/
Create 
procedure [dbo].[rapDateCO]
	(@DataJ datetime, @DataS datetime, @pMarcaJ char(6), @pMarcaS char(6), @pLocmJ char(9), @pLocmS char(9), 
	@lCodFunctie int, @pCodFunctie char(6), @lTipCO int, @pTipCO char(1), @lLocmStatie int, @pLocmStatie char(9), 
	@lSirTipCO int, @pSirTipCO char(20), @lTipstat int, @pTipstat char(10),
	@Ordonare char(1), @Alfabetic bit, @IncludePrimaVStatPL int, @CalcCONetFDP int=0, 
	@lDataOperarii int=0, @dDataOperariiJ datetime='', @dDataOperariiS datetime='')
as
begin try
	declare @eroare varchar(2000), @userASiS varchar(20), @pCASIndiv decimal(5,2), @pSomajIndiv decimal(5,2), @SalarMediu decimal(10), 
	@nDataOperariiJ float, @nDataOperariiS float, @gMarca varchar(6), @Data datetime, @Marca varchar(6), @Nume varchar(50), @LM varchar(6), @DenLM varchar(30), 
	@VechimeTotala datetime, @SalarIncadrare float, @TipSalarizare char(1), 
	@GrupaMunca char(1), @SomajPersonal int, @ProcCASS as decimal(5,2), @TipImpozitare char(1), @Grad_invalid char(1), @Tip_colab char(3), 
	@SumaCorectieO float, @ArePrimaCODataInceput int, @Tip_concediu char(1), @DenumireTipCO varchar(20), 
	@Data_inceput datetime, @Data_sfarsit datetime, 
	@Zile_CO int, @Indemnizatie_CO float, @Zile_prima_vacanta int, @Prima_vacanta float, 
	@IndemnizatieNeta float, @Grupare char(10), @Ordonare1 char(30), @NrPersintr int, @Contor int, 
	@VenitCO float, @CASIndiv float, @CASSIndiv float, @SomajIndiv float, 
	@VenitBaza float, @Impozit float, @DedBaza float, @Retinere float, @vVenitBaza float
	SET @userASiS = dbo.fIaUtilizator('')
	set @pCASIndiv=dbo.iauParLN(@DataS,'PS','CASINDIV')
	set @pSomajIndiv=dbo.iauParLN(@DataS,'PS','SOMAJIND')
	set @SalarMediu=dbo.iauParLN(@DataS,'PS','SALMBRUT')
	Set @nDataOperariiJ=datediff(day,convert(datetime,'01/01/1901'),@dDataOperariiJ)+693961
	Set @nDataOperariiS=datediff(day,convert(datetime,'01/01/1901'),@dDataOperariiS)+693961
	
	IF OBJECT_ID('tempdb..#DateCO') IS NOT NULL drop table #DateCO
	Create table #DateCO
		(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_lm char(30), 
		Suma_corectie_O float, Are_prima_CO_data_inceput int, Tip_concediu char(1), Denumire_TipCO char(20), Data_inceput datetime, Data_sfarsit datetime, 
		Zile_CO int, Venit_CO float, Indemnizatie_CO float, Zile_prima_vacanta int, Prima_vacanta float, Indemnizatie_CO_net float, 
		Grupare char(50), Ordonare char(50), CASIndiv float, CASSIndiv float, SomajIndiv float, VenitBaza float, Impozit float, Retinere float)
	Create index indx on #DateCO (Data, Marca, Tip_concediu, Data_inceput)

	declare tmpDateCO cursor for
	select a.Data as Data, a.Marca as Marca, isnull(i.Nume,p.Nume) as Nume, isnull(i.Loc_de_munca, p.Loc_de_munca) as LM, l.denumire as DenLM, 
	p.Vechime_totala as VechimeTotala, isnull(i.Salar_de_incadrare, p.Salar_de_incadrare) as SalarIncadrare, 
	isnull(i.Tip_salarizare, p.Tip_salarizare) as TipSalarizare, 
	isnull(i.Grupa_de_munca, p.Grupa_de_munca) as GrupaMunca, p.Somaj_1 as SomajPersonal, p.As_sanatate as ProcCASS, 
	p.Tip_impozitare, p.Grad_Invalid, p.Tip_colab as Tip_colab, 
	(case when a.Tip_concediu in ('1','3','4','6','7') then (case when isnull((select sum(c.suma_corectie) from corectii c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca and c.Data=h.Data_inceput and c.Tip_corectie_venit='O-'),0)<>0 then 
	isnull((select sum(c.suma_corectie) from corectii c where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and c.Data=a.Data_inceput and c.Tip_corectie_venit='O-'),0) else 
	isnull((select sum(c.suma_corectie) from corectii c where dbo.eom(c.Data)=dbo.eom(a.Data) and c.Marca=a.Marca and c.Tip_corectie_venit='O-'),0) end) else 0 end) as SumaCorectieO, 
	(case when isnull((select sum(c.suma_corectie) from corectii c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca and c.Data=h.Data_inceput and c.Tip_corectie_venit='O-'),0)<>0 then 1 else 0 end) as ArePrimaCODataInceput,
	a.Tip_concediu as Tip_concediu, isnull(t.Denumire_scurta,''), a.Data_inceput as Data_inceput, a.Data_sfarsit as Data_sfarsit, 
	a.Zile_CO as Zile_CO, a.Indemnizatie_CO as Indemnizatie_CO, a.Zile_prima_vacanta as Zile_prima_vacanta, a.Prima_vacanta, 
	(case when a.Tip_concediu<>'5' then isnull(d.indemnizatie_CO,0) else 0 end) as IndemnizatieNeta, 
	isnull((select count(1) from persintr s where s.data=a.data and s.marca=a.marca and s.coef_ded<>0),0),
	(case when @Ordonare='1' then a.Marca else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Grupare, 
	(case when @Ordonare='1' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Ordonare1
	from concodih a
		left outer join personal p on p.marca = a.marca
		left outer join infopers b on b.marca = a.marca
		left outer join lm l on p.Loc_de_munca=l.cod 
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join concodih d on a.Data=d.Data and a.Marca=d.Marca and a.Data_inceput=d.Data_inceput and d.tip_concediu='9' 
		left outer join dbo.fTip_CO() t on a.Tip_concediu=t.Tip_concediu
	where a.Data between @DataJ and @DataS and (@pMarcaJ='' or a.Marca between @pMarcaJ and @pMarcaS) 
		and (@pLocmJ='' or isnull(i.Loc_de_munca, p.Loc_de_munca) between @pLocmJ and @pLocmS) 
		and (@lLocmStatie=0 or isnull(i.Loc_de_munca, p.Loc_de_munca) like rtrim(@pLocmStatie)+'%') 
		and (@lCodFunctie=0 or isnull(i.Cod_functie, p.Cod_functie)=@pCodFunctie) 
		and a.Tip_concediu in ('1','2','3','4','5','6','7','8') and (@lTipCO=0 or a.Tip_concediu=@pTipCO) 
		and (@lSirTipCO=0 or charindex(','+rtrim(ltrim(a.Tip_concediu))+',',@pSirTipCO)>0) 
		and (@lTipstat=0 or b.religia=@pTipstat)
		and (@lDataOperarii=0 or a.Prima_vacanta between @nDataOperariiJ and @nDataOperariiS)
		and (dbo.f_areLMFiltru(@userASiS)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=isnull(i.Loc_de_munca, p.Loc_de_munca)))
	order by Ordonare1 Asc, (case when @Alfabetic=1 then p.Nume+a.Marca else a.Marca end), a.Data, a.Data_inceput

	open tmpDateCO
	fetch next from tmpDateCO into @Data, @Marca, @Nume, @LM, @DenLM, @VechimeTotala, @SalarIncadrare, 
		@TipSalarizare, @GrupaMunca, @SomajPersonal, @ProcCASS, @TipImpozitare, @Grad_invalid, 
		@Tip_colab, @SumaCorectieO, @ArePrimaCODataInceput, @Tip_concediu, @DenumireTipCO, @Data_inceput, @Data_sfarsit, 
		@Zile_CO, @Indemnizatie_CO, @Zile_prima_vacanta, @Prima_vacanta, @IndemnizatieNeta, 
		@NrPersintr, @Grupare, @Ordonare1
	set @gMarca=@Marca
	While @@fetch_status = 0 
		Begin
			select @CASIndiv=0, @CASSIndiv=0, @SomajIndiv=0, @DedBaza=0, @VenitBaza=0, @Impozit=0, @Retinere=0
			if @Marca<>@gMarca
				set @Contor=0
			if CHARINDEX(@Tip_concediu,'13467')<>0
				set @Contor=@Contor+1
			set @VenitCO=(case when @Tip_concediu='5' then -1 else 1 end)*@Indemnizatie_CO+
				(case when @IncludePrimaVStatPL=1 and (@Contor=1 or @ArePrimaCODataInceput=1) then @SumaCorectieO else 0 end)
				
			if CHARINDEX(@Tip_concediu,'1234678')<>0
			Begin
				select @CASIndiv=ROUND((case when year(@Data)>=2011 and @VenitCO>5*@SalarMediu 
					then 5*@SalarMediu else @VenitCO end)*@pCASIndiv/100,0)
				select @CASSIndiv=ROUND(@VenitCO*@ProcCass/10/100,0)
				select @SomajIndiv=ROUND((case when @SomajPersonal<>0 then @VenitCO*@pSomajIndiv/100 else 0 end),0)
				set @VenitBaza=@VenitCO-(@CASIndiv+@CASSIndiv+@SomajIndiv)
				if @GrupaMunca not in ('O','P') and @Tip_colab<>'FDP' and @CalcCONetFDP=0
					exec calcul_deducere @VenitCO, @NrPersintr, @DedBaza output
				Set @vVenitBaza=(case when @VenitBaza-@DedBaza<0 then 0 else @VenitBaza-@DedBaza end)
				if @vVenitBaza>0 and @TipImpozitare<>'3' and @Grad_invalid not in ('1','2')
					exec calcul_impozit_salarii @vVenitBaza, @Impozit output, 0
				set @Retinere=@VenitCO-(@CASIndiv+@CASSIndiv+@SomajIndiv)-@Impozit-@IndemnizatieNeta
			End			
			insert into #DateCO
			values (@Data, @Marca, @Nume, @LM, @DenLM, @SumaCorectieO, @ArePrimaCODataInceput, 
			@Tip_concediu, @DenumireTipCO, @Data_inceput, @Data_sfarsit, @Zile_CO, @VenitCO, @Indemnizatie_CO, @Zile_prima_vacanta, 
			@Prima_vacanta, @IndemnizatieNeta, @Grupare, @Ordonare1, @CASIndiv, @CASSIndiv, @SomajIndiv, @VenitBaza, @Impozit, @Retinere)

			set @gMarca=@Marca
			fetch next from tmpDateCO into @Data, @Marca, @Nume, @LM, @DenLM, @VechimeTotala, @SalarIncadrare, 
				@TipSalarizare, @GrupaMunca, @SomajPersonal, @ProcCASS, @TipImpozitare, @Grad_invalid, @Tip_colab, 
				@SumaCorectieO, @ArePrimaCODataInceput, 
				@Tip_concediu, @DenumireTipCO, @Data_inceput, @Data_sfarsit, @Zile_CO, @Indemnizatie_CO, @Zile_prima_vacanta, 
				@Prima_vacanta, @IndemnizatieNeta, @NrPersintr, @Grupare, @Ordonare1
		End
		Close tmpDateCO
		Deallocate tmpDateCO
		select Data, Marca, Nume, Loc_de_munca, Denumire_lm, Suma_corectie_O, 
			Are_prima_CO_data_inceput, Tip_concediu, Denumire_TipCO, Data_inceput, Data_sfarsit, Zile_CO, Indemnizatie_CO, 
			Zile_prima_vacanta, Prima_vacanta, Indemnizatie_CO_net, Grupare, Ordonare, 
			CASIndiv, CASSIndiv, SomajIndiv, VenitBaza, Impozit, Retinere
		from #DateCO
	IF OBJECT_ID('tempdb..#DateCO') IS NOT NULL drop table #DateCO
end try
begin catch
	set @eroare='Procedura rapDateCO (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec rapDateCO '08/01/2011', '08/31/2011', '', 'ZZZ', '', 'ZZZ', 0, '', 0, '', 0, '', 0, '', 0, '', '1', 0, 0, 0
*/
