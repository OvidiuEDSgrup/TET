--***
/**	proc. calcul impozit,venit net */
Create procedure psCalcul_impozit_vennet 
	@dataJos datetime,@dataSus datetime,@Marca char(6),@SalarDeBaza float,@Salmin float,@Salar_mediu float,@RefSomaj float,@OreLuna int,@SindProc int,@ProcSind float, @pCASind float,@Buget int,
	@NuRotBI int,@ChindPont int,@Chindlcrt int,@Chindvnet int,@NuCASS_H int,@Imps_H int,@NuASS_N int, @CorU_RP int,@CAS_U int,@ImpozitNegativ int, @Tichete int, @NuDPSH int, @AdVenNet_Q int,
	@venitBrutCuDed float,@venitBrutFaraDed float,@Dafora int,@Drumor int,@OreCFS int,@OreCMSubvSomaj int,@OreCO int,@Invoiri int,@Nemotivate int,@OreJust int,@SumaImpoz float,@SumaImpsep float,@ConsAdmin float,
	@Venit_total float,@RL float,@CorU float,@RetSindicat float,@RLPontaj float,@AsSanP float,@TipImpozP char(1),@ProcImpoz int,@GrpMP char(1),
	@TipColabP char(3),@GradInvP char(1),@Tipded_somajP float,@Orelunacm int,@SomajTehn float,@OreST int,@SumaNeimp float,@ValTichete float,
	@SomajI float output, @CASSI float output,@CASInd float output,@Vennet_in_imp float output,@DedBaza float output,@DedPensie float output,
	@VenitBaza float output,@Impozit float output,@ImpozSep float output,@Venit_net float output,@DedSomaj float output,
	@DataAng datetime,@Plecat char(1), @ModAngP char(1),@DataPlecP datetime,@DataEcvsom datetime,@DataIcvsom datetime, 
	@NrPersintr int,@Zcm8915 int,@Indcm8915 float,@PersNecontractual char(1),@Pensmax_ded float,@Pensded_lun float,
	@Pensded_ant float,@Pensluna float,@AvantajeMat float,@AvantajeMatImpozabile float,@DiurneNeimpoz float
As
Begin try
	declare @VenitDed float,@OreDedSomaj int, @OreSCdedSomaj int, @BazaImpO float, @BazaImpH float, @BazaN float, @ImpozH float, @DedSindicat float, @ValTicheteUtilizata float, 
			@SalarLunaAngaj float, @RefSomajLunaAng float

	select	@Vennet_in_imp=0, @DedBaza=0, @VenitDed=0, @DedPensie=0, @VenitBaza=0, @Impozit=0, @ImpozSep=0, @Venit_net=0, 
			@DedSomaj=0, @OreDedSomaj=0, @OreSCdedSomaj=0, @ValTicheteUtilizata=0, @SalarLunaAngaj=0, @RefSomajLunaAng=0
	set @ValTicheteUtilizata=(case when @Tichete=1 and @ValTichete>0 and @dataJos>='07/01/2010' then round(@ValTichete,0) else 0 end)

--	calcul deducere personala de baza
	if @GrpMP not in ('O','P') and @TipColabP<>'FDP'
	Begin
		set @VenitDed=@Venit_total-(case when @Imps_H=1 or @NuDPSH=1 then @SumaImpoz else 0 end)
			-(case when @NuDPSH=1 then @ConsAdmin else 0 end)
			-(case when @Buget=1 and @PersNecontractual='1' or @NuDPSH=1 then @SumaImpsep else 0 end)
			-(case when @NuASS_N=1 then 0 else @SumaNeimp end)-@SomajTehn
			+@ValTicheteUtilizata+@AvantajeMat--+@AvantajeMatImpozabile
		exec calcul_deducere @VenitDed, @NrPersintr, @DedBaza output, @OreJust, @OreLuna, @GrpMP, @RLPontaj, @venitBrutCuDed, @venitBrutFaraDed, @ChindPont
--	mutat partea de calcul functie de orele lucrate in procedura de calcul_deducere (Lucian 14.11.2012)
/*
		If @OreJust<@Oreluna and @ChindPont=1
		Begin
			set @DedBaza=@DedBaza*@OreJust/(@Oreluna*(case when @GrpMP='C' then @RLPontaj/8 else 1 end))
			select @DedBaza=(round(@DedBaza/10,0,1)+1)*10 where @VenitDed>@venitBrutCuDed and @VenitDed<@venitBrutFaraDed
				and @DedBaza>0 and cast(ceiling(@DedBaza) as int) % 10<>0
		End
		set @DedBaza=ceiling(@DedBaza)
*/
		select @DedBaza=0 where day(@DataAng)<>1 and month(@DataAng)=month(@dataSus) and year(@DataAng)=year(@dataSus) and @Drumor=0 and @Chindlcrt=0 and (@Dafora=0 or @Tipded_somajP=6)
	End
	if exists(select * from sysobjects where name='DedBazaSP' and type='FN') 
		set @DedBaza=dbo.DedBazaSP (@dataJos, @dataSus, @Marca, @DedBaza)
	if exists(select * from sysobjects where name='DedBazaSP' and type='P') 
		exec DedBazaSP @dataJos, @dataSus, @Marca, @DedBaza output

	set @BazaImpO=(case when @Buget=1 and @PersNecontractual='1' then round(@SumaImpsep*(1-@AsSanP/10/100-@pCASInd/100),0) else 0 end)
	set @BazaImpH=(case when @Imps_H=1 then round(@SumaImpoz*(case when @NuCASS_H=1 then 1 else 1-@AsSanP/10/100 end),0) else 0 end)
	set @BazaN=round(@SumaNeimp*(1-(case when @NuASS_N=1 then 1 else @AsSanP/10/100+@pCASInd/100 end)),0)
	select @Vennet_in_imp=@Venit_total-@SomajI-@CASSI-@CASInd-@BazaN-@BazaImpH-@BazaImpO+(case when @AdVenNet_Q=1 then @AvantajeMat else 0 end)
	where (@Venit_total>0 or @ImpozitNegativ=1 and @Venit_total<0 or @AdVenNet_Q=1 and @AvantajeMat>0)
	select @DedBaza=@Vennet_in_imp+@ValTicheteUtilizata where @Chindvnet=1 and @DedBaza>@Vennet_in_imp+@ValTicheteUtilizata and @DedBaza<>0 and @Vennet_in_imp+@ValTicheteUtilizata>=0
	set @DedSindicat=@RetSindicat*(case when @SindProc=1 and @ProcSind>1 then 1/@ProcSind else 1 end)
	if @SindProc=0 and @ProcSind>1 and @DedSindicat>round(@Venit_total*1/100,0)
		set @DedSindicat=round(@Venit_total*1/100,0)

	if @Pensmax_ded-@Pensded_ant>0 and not(@DedBaza>@Vennet_in_imp)
	Begin
		set @DedPensie=dbo.valoare_minima((case when @Pensded_lun=0 then @Pensluna else @Pensded_lun end), @Pensmax_ded-@Pensded_ant,@DedPensie)
		set @DedPensie=(case when @Vennet_in_imp-@DedBaza-@DedSindicat<@DedPensie then @Vennet_in_imp-@DedBaza-@DedSindicat else @DedPensie end)
		select @DedPensie=0 where @DedPensie<0
	End
--	calcul venit baza de calcul impozit
	set @VenitBaza=@Vennet_in_imp-(case when @GrpMP in ('C','N') and @TipColabP='FDP' then 0 else @DedSindicat end)-@DedBaza-@DedPensie-@SomajTehn+
		(case when @AdVenNet_Q=0 then @AvantajeMat else 0 end)+@ValTicheteUtilizata
	select @VenitBaza=@VenitBaza-(@Indcm8915-@Zcm8915*(case when year(@dataSus)>=2011 then round(0.35*@Salar_mediu,2) else @Salmin end)/
	((case when @Dafora=1 then @Orelunacm else @Oreluna end)/8)*@pCASInd/100) where @Indcm8915<>0
	select @VenitBaza=0 where @VenitBaza<0 and (@ImpozitNegativ=0 or @Venit_total>=0)
	select @VenitBaza=round(@VenitBaza,0)
	select @VenitBaza=(case when @NuRotBI=1 then round(@VenitBaza,0) else round(@VenitBaza,0,1) end)
	select @VenitBaza=@Venit_total where @GrpMP in ('O','P') and @TipColabP in ('DAC','CCC','ECT') 
		and (@TipImpozP='8' and year(@dataSus)<2012 or @TipImpozP='9')
--	calcul impozit 
	select @Impozit=dbo.fCalcul_impozit_salarii(@VenitBaza,0,@Impozit) where (@VenitBaza>0 or @ImpozitNegativ=1 and @Venit_total<0) and @TipImpozP<>'3' and @GradInvP not in ('1','2')
	if @GrpMP in ('O','P') and @TipColabP in ('DAC','CCC','ECT')
	Begin
--		daca @ProcImpoz<>0 se aplica procentul la Venitul total (pana la anul 2011)
		select @Impozit=round(@Venit_total*@ProcImpoz/100,0) where @ProcImpoz<>0 and year(@dataSus)<2012
--		conform OG 30/2011 (incepand cu 2012), cota de impozitare anticipata (10%) se aplica asupra
--		venitului brut din care se deduc contributiile sociale (->venit baza de calcul)
		select @Impozit=round(@VenitBaza*@ProcImpoz/100,0) where @TipImpozP='8' and year(@dataSus)>=2012 and @ProcImpoz=10
	End	
--	calcul impozit separat pt. corectia O
	If @SumaImpsep>0 and @Buget=1 and @PersNecontractual='1' and @TipImpozP<>'3' and @GradInvP not in ('1','2')
	Begin
		select @ImpozSep=dbo.fCalcul_impozit_salarii(@BazaImpO,0,@ImpozSep)
		set @Impozit=@Impozit+@ImpozSep
		set @VenitBaza=@VenitBaza+@BazaImpO 
	End
	If @SumaImpoz>0 and @Imps_H=1 and @TipImpozP<>'3' and @GradInvP not in ('1','2')
	Begin
		select @ImpozH=dbo.fCalcul_impozit_salarii(@BazaImpH,0,@ImpozH)
		set @Impozit=@Impozit+@ImpozH
		set @VenitBaza=@VenitBaza+@BazaImpH
	End
	select @Impozit=0 where @TipImpozP='3' or (@GradInvP in ('1','2'))
	set @BazaN=round(@SumaNeimp*(1-(case when @NuASS_N=1 then 0 else @AsSanP/10/100+@pCASInd/100 end)),0)
--	calcul venit net
	select @VENIT_NET=@Vennet_in_imp-@Impozit+@BazaN+@BazaImpH+@BazaImpO+@DiurneNeimpoz where (@Venit_total>0 or @ImpozitNegativ=1 and @Venit_total<0)
	select @VENIT_NET=@SumaNeimp where @Venit_total=0 and @NuASS_N=1
	select @VENIT_NET=@VENIT_NET+round(@CorU*(1-(case when @VENIT_NET=0 then @pCASInd/100 else 0 end)),0) where @CorU_RP=1 and @CAS_U=1 and @CorU<>0
	select @Vennet_in_imp=@Vennet_in_imp+round(@SumaImpsep*(1-@AsSanP/10/100-@pCASInd/100),0) where @SumaImpsep>0 and @Buget=1 and @PersNecontractual='1'
	select @Vennet_in_imp=0 where @Dafora=1 and @Vennet_in_imp<0

--	calcul subventie somaj
	if (@ModAngP='N' and @Tipded_somajP in (1,2,3,4,9) or @ModAngP='D' and @Tipded_somajP=7 or @Tipded_somajP=8) and dbo.eom(@DataEcvsom)>=@dataSus and dbo.eom(@DataIcvsom)<=@dataSus
	Begin
		select @OreDedSomaj=dbo.Zile_lucratoare((case when day(@DataIcvsom)<>1 and month(@DataIcvsom)=month(@dataSus) and year(@DataIcvsom)=year(@dataSus) then @DataIcvsom else @dataJos end),
		(case when day(@DataEcvsom)<>1 and month(@DataEcvsom)=month(@dataSus) and year(@DataEcvsom)=year(@dataSus) then @DataEcvsom 
			else (case when @Plecat=1 and month(@DataPlecP)=month(@dataSus) and year(@DataPlecP)=year(@dataSus) then DateADD(day,-1,@DataPlecP) else @dataSus end) end))*(case when @RL=0 then 8 else @RL end) 
		where (day(@DataIcvsom)<>1 and month(@DataIcvsom)=month(@dataSus) and year(@DataIcvsom)=year(@dataSus) 
			or day(@DataEcvsom)<>1 and month(@DataEcvsom)=month(@dataSus) and year(@DataEcvsom)=year(@dataSus)  
			or @Plecat=1 and month(@DataPlecP)=month(@dataSus) and year(@DataPlecP)=year(@dataSus))

		if @Tipded_somajP=8
		begin
			set @RefSomajLunaAng=dbo.iauParLN(dbo.eom(@DataAng),'PS','SOMAJ-ISR')
			set @SalarLunaAngaj=isnull((select (case when @Buget=1 then salar_de_baza else Salar_de_incadrare end) from istpers where Marca=@Marca and Data=dbo.EOM(@DataAng)),@SalarDeBaza)
		end

		select @OreSCdedSomaj=(@OreCMSubvSomaj+@OreCFS+@Invoiri+@Nemotivate+@OreST+(case when @Tipded_somajP=7 then @OreCO else 0 end))
		select @DedSomaj=round((case when @Tipded_somajP in (1,2,8,9) then 1 when @Tipded_somajP=3 then 1.2 when @Tipded_somajP=4 then 1.5 when @Tipded_somajP=7 then 0.5 else 0 end)*
			(case when @Tipded_somajP=8 then (case when @SalarLunaAngaj>2*@RefSomajLunaAng then 2*@RefSomajLunaAng else @SalarLunaAngaj end)
			when dbo.eom(@DataIcvsom)=@dataSus or @Tipded_somajP in (1,7,9) then 
				(case when @DataIcvsom>='10/14/2008' and not(@Tipded_somajP in (2,3,4) and @DataAng<'10/14/2008') then @RefSomaj else @Salmin end) 
			else dbo.iauParLN(dbo.eom(@DataAng),'PS',(case when @DataIcvsom>='10/14/2008' and not(@Tipded_somajP in (2,3,4) and @DataAng<'10/14/2008') then 'SOMAJ-ISR' else 'S-MIN-BR' end)) end)
				*(case when @GrpMP='C' then @RLPontaj/8.00 else 1 end)
			*(case when @OreDedSomaj<>0 or @OreSCdedSomaj<>0 then (case when @OreDedSomaj<>0 then (case when @OreDedSomaj-@OreSCdedSomaj>0 then @OreDedSomaj-@OreSCdedSomaj else 0 end) 
				else @Oreluna-@OreSCdedSomaj end)/convert(float,@Oreluna) else 1 end),0)
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_impozit_vennet (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

