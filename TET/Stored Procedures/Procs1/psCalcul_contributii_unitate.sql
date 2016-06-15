--***
/**	proceduta pentru calcul contributii unitate	*/
Create procedure psCalcul_contributii_unitate
	@dataJos datetime,@dataSus datetime,@Marca char(6),@Locm char(9),@Salmin float,@pCASgr1 decimal(7,3),@pCASgr2 decimal(7,3),@pCASgr3 decimal(7,3),@pCCI decimal(7,3),@CoefCCI float,
	@pCASSU decimal(7,3),@pSomajU decimal(7,3),@pFondGar decimal(7,3), @pFambp decimal(7,3),@CalculITM int,@pITM decimal(7,3),@InstPubl int,@CASScolab int,@NuITMcolab int,
	@NuITMpens int,@SomajColab int,@CCIcolabO int,@CCIcolabP int,@NuCAS_H int,@NuCASS_H float,@CASSimps_K int,@CCI_K int,@CorU_RP int,@CAS_U int,@Pasmatex int,@Plastidr int,
	@IndFAMBP float,@CMCAS float,@SumaImpoz float,@ConsAdmin float,@AjDeces float,@Venit_total float, @CorU float,@Somaj1P int,@AsSanP int,@GrpMP char(1),@TipcolabP char(3),
	@AlteSurseP char(1),@GradInvP char(1),@Tipded_somajP int,@OUG13 int, @OUG6 int, @ExpatriatCuA1 int, @Indcmcas19 float,@Coef_ded float,@SalComp float,@AlocHrana float,@SomajTehn float,
	@BazaCASCMCN float,@BazaCASCMCD float, @BazaCASCMCS float,@CASCM float,@CCIFambp float,@BazaSomajI float,@SomajI float,@BazaCASSI float,@CASSI float, 
	@CASSFambpsal float, @CASSFambpang float,@BazaCASInd float,@CASInd float,@DedBaza float,@Vennet_in_imp float,@DedPensie float,@VenitBaza float, @Impozit float,@ImpozSep float,
	@Venit_net float,@DedSomaj float,@Part_profit float,@BazaCASCN float,@BazaCASCD float,@BazaCASCS float,@vBazaFambp float,@vBazaFambpCM float,
	@TBCASCN float output,@TBCASCD float output,@TBCASCS float output,@TCAS decimal(12,2) output,@TBCASS float output,@TCASS decimal(12,2) output,
	@TBSomajPCON float output,@TBSomajPNECON float output,@TSomaj decimal(12,2) output,@TBCCI float output,@TCCI decimal(12,2) output,
	@TBFambp float output,@TFambp decimal(12,2) output,@TBFG float output,@TFG decimal(12,2) output,@TBITM float output,@TITM decimal(12,2) output
As
Begin try
	declare @CASunit float,@BazaCASSunit float,@CASSunit float,@BazaSomajU float,@Somajunit float,@BazaCCI float,@vBazaCCI float,@CCI float, @BazaFambp float,@Fambp float,
	@BazaFG float,@FondGar float,@BazaITM float,@ITM float,@SalMediuAnAnt float,@vBazaCASCN float,@vBazaCASCD float,@vBazaCASCS float
	set @SalMediuAnAnt=(case when 1=1 then dbo.iauParLN(@dataSus,'PS','SALMBRUT') else dbo.iauParLN(DateAdd(day,-1,dbo.boy(@dataSus)),'PS','SALMBRUT') end)
	select @CASunit=0,@BazaCASSunit=0,@CASSunit=0,@BazaSomajU=0,@Somajunit=0,@BazaFG=0,@FondGar=0, @BazaCCI=0,@vBazaCCI=0,@CCI=0,@BazaITM=0,@ITM=0,@BazaFambp=0,@Fambp=0,@Coef_ded=0
--	cazul SRLD-urilor - OUG6/2011
	select @vBazaCASCN=(case when @OUG13=1 then 0 when @OUG6=1 then (case when @BazaCASCN>@SalMediuAnAnt then @BazaCASCN-@SalMediuAnAnt else 0 end) else @BazaCASCN end)
	select @vBazaCASCD=(case when @OUG13=1 then 0 when @OUG6=1 then (case when @BazaCASCD>@SalMediuAnAnt then @BazaCASCD-@SalMediuAnAnt else 0 end) else @BazaCASCD end)
	select @vBazaCASCS=(case when @OUG13=1 then 0 when @OUG6=1 then (case when @BazaCASCS>@SalMediuAnAnt then @BazaCASCS-@SalMediuAnAnt else 0 end) else @BazaCASCS end)
	set @TBCASCN=@TBCASCN+@vBazaCASCN
	set @TBCASCD=@TBCASCD+@vBazaCASCD
	set @TBCASCS=@TBCASCS+@vBazaCASCS
	select @CASunit=round(@vBazaCASCS*@pCASgr1/100+@vBazaCASCD*@pCASgr2/100+@vBazaCASCN*@pCASgr3/100,2) -- where @OUG13=0
	set @TCAS=@TCAS+@CASunit
	set @BazaCASSunit=@Venit_total-(@Indcmcas19+@CMCAS)-(case when @Plastidr=1 and @CASSimps_K=1 then @ConsAdmin else 0 end)-(case when @NuCASS_H=1 then @SumaImpoz else 0 end)-@SomajTehn
	select @BazaCASSunit=0 where ((@CASScolab=0 or @AsSanP=0) and @GrpMP in ('O','P') or @GrpMP='O' and @TipColabP in ('DAC','CCC','ECT') or @OUG13=1)
--	cazul SRLD-urilor - OUG6/2011
--	select @BazaCASSunit=(case when @BazaCASSunit>@SalMediuAnAnt then @BazaCASSunit-@SalMediuAnAnt else 0 end) where @OUG6=1
	set @TBCASS=@TBCASS+@BazaCASSunit
	set @CASSunit=round(convert(decimal(12,3),@BazaCASSunit*@pCASSU/100),2)
	set @TCASS=@TCASS+@CASSunit
	set @BazaSomajU=@BazaSomajI
	select @BazaSomajU=0 where ((@GrpMP in ('O','P') or @Pasmatex=1 or @Tipded_somajP=5) and @Somaj1P=0 or @GrpMP='O' and @TipColabP in ('DAC','CCC','ECT') or @OUG13=1)
--	cazul SRLD-urilor - OUG6/2011
--	select @BazaSomajU=(case when @BazaSomajU>@SalMediuAnAnt then @BazaSomajU-@SalMediuAnAnt else 0 end) where @OUG6=1
	select @TBSomajPCON=@TBSomajPCON+@BazaSomajU where @InstPubl=0
	select @TBSomajPNECON=@TBSomajPNECON+@BazaSomajU where @InstPubl=1
	set @Somajunit=round(convert(decimal(12,3),@BazaSomajU*@pSomajU/100),2) 
	set @TSomaj=@TSomaj+@Somajunit
	if year(@dataSus)<2012
		set @BazaFG=@BazaSomajI
	else 
		set @BazaFG=@Venit_total-(@Indcmcas19+@CMCAS)-@SalComp-@AlocHrana-@SomajTehn-(case when @NuCAS_H=1 then @SumaImpoz else 0 end)-@Part_profit

	select @BazaFG=0 where @GrpMP in ('O','P') and (@dataSus>='06/30/2009' or @SomajColab=0 and @Somaj1P<>1) or @InstPubl=1 or @OUG13=1
--	cazul SRLD-urilor - OUG6/2011
--	select @BazaFG=(case when @BazaFG>@SalMediuAnAnt then @BazaFG-@SalMediuAnAnt else 0 end) where @OUG6=1
	set @TBFG=@TBFG+@BazaFG
	set @FondGar=round(convert(decimal(12,3),@BazaFG*@pFondGar/100),2)
	set @TFG=@TFG+@FondGar
	set @vBazaCCI=@Venit_total-(@Indcmcas19+@CMCAS)+(case when year(@dataSus)<2011 then @IndFAMBP else 0 end)
		-(case when @NuCAS_H=1 and (year(@dataSus)<=2010 or @NuCASS_H=1) then @SumaImpoz else 0 end)
		-(case when @CASSimps_K=1 and not(year(@dataSus)>=2011 and @GrpMP in ('O','P') and @TipcolabP='AS2') and @CCI_K=0 then @ConsAdmin else 0 end)-@SalComp-@AlocHrana-@SomajTehn
	select @vBazaCCI=(case when @vBazaCCI>12*@Salmin then 12*@Salmin else @vBazaCCI end) where (@GrpMP='O' and @CCIcolabO=1 or @GrpMP='P' and @CCIcolabP=1) and year(@dataSus)<2011
	select @vBazaCCI=0 where (@GrpMP='O' and @CCIcolabO=0 or @GrpMP='P' and @CCIcolabP=0) and year(@dataSus)<2011 
	or year(@dataSus)>=2011 and (@GrpMP in ('O','P') and (@TipcolabP in ('AS4','AS5','AS6') or @TipcolabP in ('AS2') and @ExpatriatCuA1=1) 
		or @GrpMP in ('O') and @TipcolabP in ('DAC','CCC','ECT')) or @OUG13=1
--	cazul SRLD-urilor - OUG6/2011
--	select @vBazaCCI=(case when @vBazaCCI>@SalMediuAnAnt then @vBazaCCI-@SalMediuAnAnt else 0 end) where @OUG6=1
	select @BazaCCI=@vBazaCCI
	select @vBazaCCI=@vBazaCCI*@CoefCCI-(case when year(@dataSus)<2011 then @IndFAMBP else 0 end) 
	set @CCI=round(convert(decimal(12,3),@vBazaCCI*@pCCI/100),2)
--	select @vBazaCCI=@vBazaCCI*@CoefCCI-(case when year(@dataSus)<2011 then @IndFAMBP else 0 end)
	set @TBCCI=@TBCCI+@vBazaCCI
	select @BazaCCI=@SalMin where @OUG13=1
	set @TCCI=@TCCI+@CCI
--	cazul SRLD-urilor - OUG6/2011
	select @vBazaFambp=(case when @vBazaFambp>@SalMediuAnAnt then @vBazaFambp-@SalMediuAnAnt else 0 end) where @OUG6=1
	set @BazaFambp=(case when year(@dataSus)>=2011 then @vBazaFambp+@vBazaFambpCM else @BazaCASInd end)
	select @BazaFambp=0 where (year(@dataSus)<2011 and @GrpMP='O' or year(@dataSus)=2011 and @GrpMP='O' and @TipcolabP='AS2' 
		or @OUG13=1 or year(@dataSus)>=2012 and @TipcolabP in ('AS2','AS4','AS5','AS6'))
	set @TBFambp=@TBFambp+@BazaFambp
	set @Fambp=round(convert(decimal(12,3),@BazaFambp*@pFambp/100),2)
	set @TFambp=@TFambp+@Fambp
	if @CalculITM=1
	Begin
		set @BazaITM=@Venit_total-(@Indcmcas19+@CMCAS)-(case when @NuCAS_H=1 then @SumaImpoz else 0 end)- (case when @CASSimps_K=1 then @ConsAdmin else 0 end)
		select @BazaITM=0 where @NuITMcolab=1 and @GrpMP in ('O','P') or @NuITMpens=1 and @Tipded_somajP=5
		set @TBITM=@TBITM+@BazaITM
		set @ITM=round(convert(decimal(12,3),@BazaITM*@pITM/100),2)
		set @TITM=@TITM+@ITM
	End
--	scriu pozitia cu ultima zi din luna
	exec scriuNet_salarii @dataSus,@dataSus,@Marca,@Locm,@VENIT_TOTAL,0,0,0,0,0,@Impozit,@CASInd,@SomajI,@CASSFambpsal,@CASSI, @BazaSomajI, @VENIT_NET,0,0,0,0,0,0,0,
	@CASunit,@Somajunit,@Fambp,@ITM,@CASSunit,@Coef_ded,@GradInvP,@Tipded_somajP,@AlteSurseP,@Vennet_in_imp,@DedBaza,@CCI,@VenitBaza,@DedSomaj,
	@BazaCASInd,@BazaCASCN,@BazaCASCD,@BazaCASCS,1
--	scriu pozitia cu prima zi din luna
	update net set Rest_de_plata=Venit_net-Diferenta_impozit-Avans-Premiu_la_avans-Rate-Debite_interne-Debite_externe-Cont_curent-Suma_incasata-CM_incasat-CO_incasat+@AjDeces+
		(case when @CorU_RP=1 and @CAS_U=0 then @CorU else 0 end)
	where data=@dataSus and Marca=@Marca
	exec scriuNet_salarii @dataJos,@dataJos,@Marca,@Locm,0,@BazaFG,0,0,0,0,@ImpozSep,0,0,@CASSFambpang,@BazaCASSI,@vBazaFambpCM,0,0,0,0,0,0,0,0, 
	@CASCM,@FondGar,0,0,0,0,'',0,0,0,@DedPensie,@CCIFambp,0,0,@BazaCCI,@BazaCASCMCN,@BazaCASCMCD,@BazaCASCMCS,1
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_contributii_unitate (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
