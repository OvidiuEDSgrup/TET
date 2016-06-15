--***
/**	proc. calcul asig. angajat	*/
Create procedure psCalcul_asigurari_angajat
	@dataJos datetime, @dataSus datetime, @Marca char(6), @Inversare int, @Salmin float, @Salmed float, @OreLuna int, 
	@pCASind float, @pCASSind float, @pSomajind float, @pSomajI float, @pCASgr3 float, @pCASgr2 float, @pCASgr1 float, @pCCI float, @CoefCAS float, 
	@CompSalnet int, @SalNetValuta int,@SalNetFCM int,@NuCAS_H int,@NuCASS_H int,@CASSimps_K int,@Somaj_K int,@NuASS_J int,@CAS_J int, @NuASSA_N int, @CAS_U int,@Dafora int,@Pasmatex int,
	@OreCFS int,@Invoiri int,@Nemotivate int,@OreJust int,@IndFAMBP float, @CMUnitate float, @CMcas float,@Diurna float,@SumaImpoz float,@ConsAdmin float,@Venit_total float,@RL float,@CorT float, 
	@CorU float, @GrpMpont char(1), @Somaj1P int,@AsSanP float,@GrpMP char(1),@TipColabP char(3),@TipdedSomajP float, @CheltDed decimal(10),
	@BazaCN float,@BazaCD float, @BazaCS float,@Indcmunit19 float, @Indcmcas19 float,@Orelunacm int,@Indcm float,
	@Zcm18 int, @Zcm18ant int,@BazaCASIant float, @BazaCASCMant float, @Zcm2341011 int,@Indcmunit234 float,@Zcm15 int,
	@Zcm78 int, @Indcm78 float,@Indcmsomaj float,@Zcm_unitate int,@Zcm_fonduri int,
	@uMarca2CNP int, @uMarca2CNPCM int, @uMarca2CNPSomaj int, @tipAsigurat int, @CNP char(13),@SalComp float, 
	@SomajTehn float, @OreST int,@SumaNeimp float,@PensieFUnitate float, @SomajTehnicSusp float, 
	@vBazaFambp float output,@vBazaFambpCM float output,@TBCASCMCN decimal(12,2) output,@TBCASCMCD decimal(12,2) output,
	@TBCASCMCS decimal(12,2) output, @TCASCM decimal(12,2) output,@TBCASSFambpS decimal(12,2) output,
	@TCASSFambpS decimal(12,2) output,@TBCASSFambpA decimal(12,2) output,@TCASSFambpA decimal(12,2) output,
	@TBsomajPCON decimal(12,2) output, @TBsomajPNECON decimal(12,2) output,@TSomaj decimal(12,2) output,
	@TBCCIFambp decimal(12,2) output,@TCCIFambp decimal(12,2) output,@SomajI float output,@BazaSomajI float output,
	@BazaCASCM float output,@CASCM float output,@CCIFambp float output,@BazaCASSI float output,@CASSI float output,
	@BazaCASInd float output,@CASInd float output,@BazaCASCMCN float output,@BazaCASCMCD float output,
	@BazaCASCMCS float output,@BazaCASCN float output, @BazaCASCD float output,@BazaCASCS float output,
	@CASSFambpsal float output,@CASSFambpang float output, @OUG13 int, @AlteSurseP int, -- (pt. cei cu tip colaborator=CCC, DAC si ECT? inseamna ca persoana este asigurata in sistemul de pensii)
	@OrdinePlafonareCAS int=0, --	ordinea marcilor in care sa se faca plafonarea CAS pentru acelasi CNP
	@lmCorectie varchar(9)='', @FaraAltVenitPtCASS int
As
Begin try
	declare @OreSomaj int, @ZileCMsusp int,@IndCMsusp float,@DifBazaCAS_2CNP float,@DifCAS_2CNP float, @DifSomaj_2CNP float,@DifCASS_2CNP float, @vBazaCASCM decimal(7,3), @vBazaCASInd decimal(7)

	select @OreSomaj=0,@ZileCMsusp=0,@IndCMsusp=0,@DifBazaCAS_2CNP=0,@DifCAS_2CNP=0, @DifSomaj_2CNP=0, @DifCASS_2CNP=0, @vBazaCASInd=0,
		@vBazaCASCM=(case when year(@dataSus)>=2011 then 0.35*@Salmed else @Salmin end)
	set @BazaCASCM=(case when (@uMarca2CNPCM>0 or @CMUnitate+@CMcas+@Indcmunit19+@Indcmcas19=0) and charindex(@GrpMP,'NDSC')=0 then 0 
		else round(convert(decimal(10,2),(@Zcm18+@Zcm15-@Zcm18ant)*@vBazaCASCM/((case when @Dafora=1 then @Orelunacm else @Oreluna end)/8)+@BazaCASCMant),0) end)
	set @vBazaFambpCM=round((@Zcm18+@Zcm15-@Zcm18ant)*@Salmin/((case when @Dafora=1 then @Orelunacm else @Oreluna end)/8),0)
	set @BazaCASCMCN=(case when @GrpMpont='N' or @GrpMP in ('N','P') then @BazaCASCM else 0 end)
	set @BazaCASCMCD=(case when @GrpMpont='D' or @GrpMP='D' then @BazaCASCM else 0 end)
	set @BazaCASCMCS=(case when @GrpMpont='S' or @GrpMP='S' then @BazaCASCM else 0 end)
	if @OUG13=0
	Begin
		select @TBCASCMCN=@TBCASCMCN+@BazaCASCMCN*@CoefCAS,@TBCASCMCD=@TBCASCMCD+@BazaCASCMCD*@CoefCAS, @TBCASCMCS=@TBCASCMCS+@BazaCASCMCS*@CoefCAS
		set @CASCM=round(@BazaCASCMCS*@CoefCAS*@pCASgr1/100+@BazaCASCMCD*@CoefCAS*@pCASgr2/100+@BazaCASCMCN*@CoefCAS*@pCASgr3/100,0)
	End	
	set @TCASCM=@TCASCM+@CASCM
	set @TBCCIFambp=@TBCCIFambp+@IndFAMBP
	set @CCIFambp=round(@IndFAMBP*@pCCI/100,2)
	set @TCCIFambp=@TCCIFambp+@CCIFambp
	select @BazaCASCN=round(@BazaCN*@CoefCAS,0),@BazaCASCD=round(@BazaCD*@CoefCAS,0), @BazaCASCS=round(@BazaCS*@CoefCAS,0)

	if @Indcm<>0 or @Zcm18+@Zcm2341011+@Zcm15<>0
	Begin
		if year(@dataSus)<=2010
			select @ZileCMsusp=Zile_CM_suspendare, @IndCMsusp=Indemniz_CM_suspendare 
			from dbo.fPSCalculZileCMSuspendare (@Marca,@dataJos,@dataSus)
		else
			select @ZileCMsusp=@Zcm_fonduri, @IndCMsusp=@Indcmcas19
	--exec psCalcul_zileCM_suspendare @Marca,@dataJos,@dataSus,@ZileCMsusp output,@IndCMsusp output
	End
	if @Venit_total>0
	Begin
		set @OreSomaj=@OreJust-(case when year(@dataSus)<=2010 then @Zcm78*@RL else 0 end)
			-(case when @ZileCMsusp>0 then @ZileCMsusp*@RL else 0 end)-@OreCFS-@Invoiri-@Nemotivate-@OreST
		set @pSomajI=(case when @Somaj1P=1 then @pSomajInd/100 else 0 end)
		set @BazaSomajI=@Venit_total-(case when year(@dataSus)<=2010 then @Indcm78 else 0 end)-(case when @IndCMsusp=0 then @IndcmSomaj else @IndCMsusp end)
			-@SalComp-(case when @NuCAS_H=1 then @SumaImpoz else 0 end)
			-(case when @CASSimps_K=1 and @Somaj_K=0 then @ConsAdmin else 0 end)-@SomajTehn-@CheltDed-@SomajTehnicSusp
		select @BazaSomajI=(case when @BazaSomajI>5*@Salmed then 5*@Salmed else @BazaSomajI end) where @GrpMP='O' and @TipColabP in ('DAC','CCC','ECT')
		select @BazaSomajI=0 where @OreSomaj=0
		set @SomajI=(case when @BazaSomajI*@pSomajI>0 and @BazaSomajI*@pSomajI<1 then 1 else round(@BazaSomajI*@pSomajI,0) end)
--	Corectez pe ultima marca de pe CNP contributia la somaj la nivel de CNP si tip contract
		if @uMarca2CNPSomaj>0
		Begin
			select @DifSomaj_2CNP=round((case when (isnull(sum(Asig_sanatate_din_CAS),0)+@BazaSomajI)*@pSomajI>0 AND (isnull(sum(Asig_sanatate_din_CAS),0)+@BazaSomajI)*@pSomajI<1 then 1 
				else (isnull(sum(Asig_sanatate_din_CAS),0)+@BazaSomajI)*@pSomajI end),0)-(isnull(sum(Somaj_1),0)+@SomajI)
			from net n 
				left outer join #tipasigurat ta on ta.data=n.Data and ta.marca=n.marca
			where n.data=@dataSus /*and n.marca<@marca*/ and ta.tip_asigurat=@tipAsigurat 
				and n.marca in (select p.marca from personal p where p.cod_numeric_personal=@CNP and (@lmCorectie='' or p.Loc_de_munca like rtrim(@lmCorectie)+'%') 
					and (p.Grupa_de_munca<>'C' or year(@dataSus)>=2011) and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos))
			having abs((isnull(sum(Asig_sanatate_din_CAS),0)+@BazaSomajI)*@pSomajI-(isnull(sum(Somaj_1),0)+@SomajI))>=0.5
--	modificarea (p.Grupa_de_munca<>'C' or year(@dataSus)>=2011) din conditia de where de mai sus a fost facuta abia la 21/06/2011.
			select @SomajI=@SomajI+@DifSomaj_2CNP where @DifSomaj_2CNP<>0
		End
	End
	set @BazaCASSI=round(@Venit_total-(case when not((@CompSalnet=1 or @SalNetValuta=1 or @SalNetFCM=1) and @Inversare=1) then @Indcmunit19+@CMUnitate+@Indcmcas19+@CMCAS else 0 end)
		-(case when @NuASS_J=1 then @Diurna else 0 end)
		-(case when @NuCASS_H=1 then @SumaImpoz else 0 end)-(case when @NuASSA_N=1 then @SumaNeimp else 0 end)-@SomajTehn,0)-@CheltDed
	select @BazaCASSI=@Salmin where @FaraAltVenitPtCASS=1 and @BazaCASSI>0 and @BazaCASSI<@Salmin
	select @BazaCASSI=0 where (@TipColabP in ('DAC','CCC','ECT') or @GrpMP='O') and @AsSanP=0
--	S-a tranformat corectia T (de mai jos) din Diferenta CASS in Pensie facultativa suportata de angajator
	set @CASSI=(case when @AsSanP<>0 then (case when @BazaCASSI*@AsSanP/10/100>0 and @BazaCASSI*@AsSanP/10/100<1 then 1 else round(@BazaCASSI*@AsSanP/10/100,0) end)/*+@CorT*/ else 0 end)
--	Corectez contributia la sanatate la nivel de CNP pe ultima marca de pe CNP 
--	Lucian 07/12/2012: ultima marca in ordinea in care se face plafonarea CAS-ului
	if @uMarca2CNP>0 and 1=1
	Begin
		select @DifCASS_2CNP=round((isnull(sum(n1.Asig_sanatate_din_net),0)+@BazaCASSI)*@pCASSInd/100,0)-(isnull(sum(n.Asig_sanatate_din_net),0)+@CASSI)
		from net n 
			left outer join net n1 on n1.Data=dbo.bom(n.Data) and n1.Marca=n.Marca
			left outer join extinfop e on e.Marca=n.Marca and e.Cod_inf='ORDINECAS' and Val_inf<>''			
		where n.data=@dataSus 
			and (isnull(convert(int,e.Val_inf),0)<@OrdinePlafonareCAS or isnull(convert(int,e.Val_inf),0)=@OrdinePlafonareCAS and n.marca<@marca) 
			--and n.marca<@marca 
			and n.marca in (select p.marca from personal p where p.cod_numeric_personal=@CNP and (@lmCorectie='' or p.Loc_de_munca like rtrim(@lmCorectie)+'%') 
				and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos))
		having abs((isnull(sum(n1.Asig_sanatate_din_net),0)+@BazaCASSI)*@pCASSInd/100-(isnull(sum(n.Asig_sanatate_din_net),0)+@CASSI))>=0.5
		select @CASSI=@CASSI+@DifCASS_2CNP where @DifCASS_2CNP<>0
	End
	set @TBCASSFambpS=@TBCASSFambpS+@IndFAMBP
	set @CASSFambpsal=round(@IndFAMBP*@pCASSInd/100,0)
	set @TCASSFambpS=@TCASSFambpS+@CASSFambpsal
	set @TBCASSFambpA=@TBCASSFambpA+@Indcmunit234
	set @CASSFambpang=round(@Indcmunit234*@pCASSInd/100,0)
	set @TCASSFambpA=@TCASSFambpA+@CASSFambpang
	select @vBazaCASInd=@Venit_total-(case when not((@CompSalnet=1 or @SalNetValuta=1 or @SalNetFCM=1) and @Inversare=1) then @Indcmunit19+@CMUnitate+@Indcmcas19+@CMCAS else 0 end)
		-(case when @CAS_J=1 or @Pasmatex=1 then 0 else (case when @Dafora=1 then -1 else 1 end)*@Diurna end)
		-(case when @CASSimps_K=1 and @GrpMP<>'P' then @ConsAdmin else 0 end)-
		(case when @NuCAS_H=1 then @SumaImpoz else 0 end)+(case when @CAS_U=1 then @CorU else 0 end)-@SomajTehn-@CheltDed
	set @vBazaCASInd=dbo.valoare_maxima(@vBazaCASInd-@PensieFUnitate,0,@vBazaCASInd)
	select @BazaCASInd=@vBazaCASInd	where (@BazaCASCN+@BazaCASCD+@BazaCASCS<>0 or @TipColabP in ('DAC','CCC','ECT') and @TipdedSomajP<>5 and (@dataSus<'07/01/2012' or @AlteSurseP<>1))
	select @vBazaFambp=@vBazaCASInd	where @BazaCASCN+@BazaCASCD+@BazaCASCS<>0
	set @BazaCASInd=round(@BazaCASInd+@BazaCASCM,0)
	select @BazaCASInd=(case when @BazaCASInd>5*@Salmed then 5*@Salmed else @BazaCASInd end) where (@GrpMP='O' and @TipColabP in ('DAC','CCC','ECT') or @dataSus>='01/01/2011')
	select @CASInd=(case when (@BazaCASInd-@BazaCASIant)*@pCASInd/100+@BazaCASIant*@pCASInd/100>0 and (@BazaCASInd-@BazaCASIant)*@pCASInd/100+@BazaCASIant*@pCASInd/100<1 then 1 
		else round((@BazaCASInd-@BazaCASIant)*@pCASInd/100,0)+round(@BazaCASIant*@pCASInd/100,0) end)
	where (@BazaCASCN+@BazaCASCD+@BazaCASCS+round((@Zcm18+@Zcm15)*@vBazaCASCM/((case when @Dafora=1 then @Orelunacm else @Oreluna end)/8),0)<>0 or @TipColabP in ('DAC','CCC','ECT'))
--	Corectez pe ultima marca de pe CNP contributia la CAS la nivel de CNP
	if @uMarca2CNP>0 
	Begin
		select @DifBazaCAS_2CNP=round(((case when isnull(sum(baza_cas),0)+@BazaCASInd>5*@Salmed then 5*@Salmed-(isnull(sum(Baza_CAS),0)+@BazaCASInd) else 0 end)),0),
			@DifCAS_2CNP=round(((case when isnull(sum(baza_cas),0)+@BazaCASInd>5*@Salmed then 5*@Salmed else isnull(sum(baza_cas),0)+@BazaCASInd end))*@pCASInd/100,0)
				-(isnull(sum(pensie_suplimentara_3),0)+@CASInd)
		from net n 
			left outer join extinfop e on e.Marca=n.Marca and e.Cod_inf='ORDINECAS' and Val_inf<>''
		where n.data=@dataSus 
			and (isnull(convert(int,e.Val_inf),0)<@OrdinePlafonareCAS or isnull(convert(int,e.Val_inf),0)=@OrdinePlafonareCAS and n.marca<@marca) 
			--and n.marca<@marca 
			and n.marca in (select p.marca from personal p where p.cod_numeric_personal=@CNP and (@lmCorectie='' or p.Loc_de_munca like rtrim(@lmCorectie)+'%') 
				and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos))
		having abs(((case when isnull(sum(baza_cas),0)+@BazaCASInd>5*@Salmed then 5*@Salmed else isnull(sum(baza_cas),0)+@BazaCASInd end))*@pCASInd/100
			-(isnull(sum(pensie_suplimentara_3),0)+@CASInd))>=0.5

		select @BazaCASInd=@BazaCASInd+@DifBazaCAS_2CNP, @CASInd=@CASInd+@DifCAS_2CNP where @DifBazaCAS_2CNP<>0 or @DifCAS_2CNP<>0
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_asigurari_angajat (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
