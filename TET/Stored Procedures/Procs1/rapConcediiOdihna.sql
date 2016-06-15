--***
/**	procedura pentru returnare date concedii odihna	si stat de plata concedii de odihna*/
Create 
procedure rapConcediiOdihna
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @tipco char(1)=null, @sirtipco varchar(30)=null, @tipstat varchar(30)=null, 
	@ordonare char(1)='1', @alfabetic bit, @includePrimaVStatPL int=0, @calcCOnetFDP int=0, @ldataoperarii int=0, @dataoperariiJos datetime='', @dataoperariiSus datetime='',
	@listadreptcond char(1)='T')
as
begin try
	set transaction isolation level read uncommitted
	declare @eroare varchar(2000), @userASiS varchar(20), @SubtipCor int, @dreptConducere int, @areDreptCond int, @lista_drept char(1), 
	@pCASIndiv decimal(5,2), @pSomajIndiv decimal(5,2), @SalarMediu decimal(10), 
	@nDataOperariiJ float, @nDataOperariiS float, @gMarca varchar(6), @Data datetime, @vMarca varchar(6), @Nume varchar(50), @LM varchar(6), @DenLM varchar(30), 
	@VechimeTotala datetime, @SalarIncadrare float, @TipSalarizare char(1), @GrupaMunca char(1), @SomajPersonal int, @ProcCASS as decimal(5,2), @TipImpozitare char(1), 
	@Grad_invalid char(1), @Tip_colab char(3), @SumaCorectieO float, @ArePrimaCODataInceput int, @Tip_concediu char(1), @DenumireTipCO varchar(20), 
	@Data_inceput datetime, @Data_sfarsit datetime, @Zile_CO int, @Indemnizatie_CO float, @Zile_prima_vacanta int, @Prima_vacanta float, 
	@IndemnizatieNeta float, @Grupare char(10), @Ordonare1 char(30), @NrPersintr int, @Contor int, 
	@VenitCO float, @CASIndiv float, @CASSIndiv float, @SomajIndiv float, @VenitBaza float, @Impozit float, @DedBaza float, @Retinere float, @vVenitBaza float, @TipCorectiePrima char(2)
	
	SET @userASiS = dbo.fIaUtilizator('')
	Set @SubtipCor=dbo.iauParL('PS','SUBTIPCOR')
	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @pCASIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pSomajIndiv=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	Set @nDataOperariiJ=datediff(day,convert(datetime,'01/01/1901'),@dataoperariiJos)+693961
	Set @nDataOperariiS=datediff(day,convert(datetime,'01/01/1901'),@dataoperariiSus)+693961

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept=@listaDreptcond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@userASiS,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end 

	IF OBJECT_ID('tempdb..#corectiiO') IS NOT NULL drop table #corectiiO
	select @TipCorectiePrima='O-'
	select * into #corectiiO
	from corectii c
	where Data between @dataJos and @dataSus 
		and (@Subtipcor=0 and c.tip_corectie_venit=@TipCorectiePrima
		or @Subtipcor=1 and (c.Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit=@TipCorectiePrima) or c.Tip_corectie_venit=@TipCorectiePrima))

	IF OBJECT_ID('tempdb..#DateCO') IS NOT NULL drop table #DateCO
	Create table #DateCO
		(data datetime, marca char(6), nume char(50), lm char(9), den_lm char(30), 
		suma_corectie_O float, are_prima_CO_data_inceput int, tip_concediu char(1), den_tipco char(20), data_inceput datetime, data_sfarsit datetime, 
		zile_co int, venit_co float, indemnizatie_co float, zile_prima_vacanta int, prima_vacanta float, indemnizatie_co_net float, 
		grupare char(50), ordonare char(50), cas_indiv float, cass_indiv float, somaj_indiv float, venit_baza float, impozit float, retinere float)
	Create index indx on #DateCO (Data, Marca, Tip_concediu, Data_inceput)

	declare tmpdateCO cursor for
	select a.Data, a.Marca, isnull(i.Nume,p.Nume) as Nume, isnull(i.Loc_de_munca, p.Loc_de_munca) as LM, lm.denumire as DenLM, 
	p.Vechime_totala as VechimeTotala, isnull(i.Salar_de_incadrare, p.Salar_de_incadrare) as SalarIncadrare, 
	isnull(i.Tip_salarizare, p.Tip_salarizare) as TipSalarizare, 
	isnull(i.Grupa_de_munca, p.Grupa_de_munca) as GrupaMunca, p.Somaj_1 as SomajPersonal, p.As_sanatate as ProcCASS, 
	p.Tip_impozitare, p.Grad_Invalid, p.Tip_colab as Tip_colab, 
	(case when a.Tip_concediu in ('1','3','4','6','7') 
		then (case when isnull((select sum(c.suma_corectie) from #corectiiO c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca 
				and c.Data=h.Data_inceput),0)<>0 
			then isnull((select sum(c.suma_corectie) from #corectiiO c where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and c.Data=a.Data_inceput),0) 
			else isnull((select sum(c.suma_corectie) from #corectiiO c where dbo.eom(c.Data)=dbo.eom(a.Data) and c.Marca=a.Marca),0) end) 
		else 0 end) as SumaCorectieO, 
	(case when isnull((select sum(c.suma_corectie) from #corectiiO c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca and c.Data=h.Data_inceput),0)<>0 
		then 1 else 0 end) as ArePrimaCODataInceput,
	a.Tip_concediu as Tip_concediu, isnull(t.Denumire_scurta,''), a.Data_inceput as Data_inceput, a.Data_sfarsit as Data_sfarsit, 
	a.Zile_CO as Zile_CO, a.Indemnizatie_CO as Indemnizatie_CO, a.Zile_prima_vacanta as Zile_prima_vacanta, a.Prima_vacanta, 
	(case when a.Tip_concediu<>'5' then isnull(c.indemnizatie_CO,0) else 0 end) as IndemnizatieNeta, 
	isnull((select count(1) from persintr s where s.data=a.data and s.marca=a.marca and s.coef_ded<>0),0),
	(case when @Ordonare='1' then a.Marca else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Grupare, 
	(case when @Ordonare='1' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Ordonare1
	from concodih a
		left outer join personal p on p.marca = a.marca
		left outer join infopers ip on ip.marca = a.marca
		left outer join lm on p.Loc_de_munca=lm.cod 
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join concodih c on a.Data=c.Data and a.Marca=c.Marca and a.Data_inceput=c.Data_inceput and c.tip_concediu='9' 
		left outer join dbo.fTip_CO() t on a.Tip_concediu=t.Tip_concediu
	where a.Data between @dataJos and @dataSus and (@marca is null or a.Marca=@marca) 
		and (@locm is null or isnull(i.Loc_de_munca, p.Loc_de_munca) like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@functie is null or isnull(i.Cod_functie, p.Cod_functie)=@functie) 
		and a.Tip_concediu in ('1','2','3','4','5','6','7','8') and (@tipco is null or a.Tip_concediu=@tipco) 
		and (@sirtipco is null or charindex(','+rtrim(ltrim(a.Tip_concediu))+',',@sirtipco)>0) 
		and (@tipstat is null or ip.religia=@tipstat)
		and (@lDataOperarii=0 or a.Prima_vacanta between @nDataOperariiJ and @nDataOperariiS)
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 or @lista_drept='S' and p.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@userASiS)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=isnull(i.Loc_de_munca, p.Loc_de_munca)))
	order by Ordonare1 Asc, (case when @Alfabetic=1 then p.Nume+a.Marca else a.Marca end), a.Data, a.Data_inceput

	open tmpdateCO
	fetch next from tmpdateCO into @Data, @Marca, @Nume, @LM, @DenLM, @VechimeTotala, @SalarIncadrare, 
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
			fetch next from tmpdateCO into @Data, @Marca, @Nume, @LM, @DenLM, @VechimeTotala, @SalarIncadrare, 
				@TipSalarizare, @GrupaMunca, @SomajPersonal, @ProcCASS, @TipImpozitare, @Grad_invalid, @Tip_colab, 
				@SumaCorectieO, @ArePrimaCODataInceput, 
				@Tip_concediu, @DenumireTipCO, @Data_inceput, @Data_sfarsit, @Zile_CO, @Indemnizatie_CO, @Zile_prima_vacanta, 
				@Prima_vacanta, @IndemnizatieNeta, @NrPersintr, @Grupare, @Ordonare1
		End

		select data, marca, nume, lm, den_lm, suma_corectie_O, are_prima_CO_data_inceput, tip_concediu, den_tipco, data_inceput, data_sfarsit, zile_CO, indemnizatie_CO, 
			zile_prima_vacanta, prima_vacanta, indemnizatie_CO_net, grupare, ordonare, cas_indiv, cass_indiv, somaj_indiv, venit_baza, impozit, retinere
		from #DateCO
end try

begin catch
	set @eroare='Procedura rapConcediiOdihna (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='tmpdateCO' and session_id=@@SPID )
if @cursorStatus=1 
	close tmpdateCO 
if @cursorStatus is not null 
	deallocate tmpdateCO 

IF OBJECT_ID('tempdb..#DateCO') IS NOT NULL drop table #DateCO


/*
	exec rapConcediiOdihna '01/01/2012', '01/31/2012', null, null, 0, null,  null, null, null, '1', 0, 0, 0, 0, '', '', 'T'
*/
