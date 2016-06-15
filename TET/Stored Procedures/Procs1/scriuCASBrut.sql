/* procedura pt. completare date in tabela CASBrut - spargere contributii pe locuri de munca de cheltuiala */
Create procedure scriuCASBrut
	@Data datetime, @Marca char(6), @Loc_de_munca char(9), @LmStatPl int, @VenitTotalBrut decimal(10),  
	@IndCMUnitPoz decimal(10), @CorCMUnitPoz decimal(10), @IndCMCasPoz decimal(10), @CorCMCasPoz decimal(10), 
	@IndCMFaambpPoz decimal(10), @VenitTotalNet decimal(10), @CasUnitate decimal(10,2), @SomajUnitate decimal(10,2), 
	@Faambp decimal(10,2), @ComisionITM decimal(10,2), @CassUnitate decimal(10,2), @CCI decimal(10,2), @CASCM decimal(10,2), @FondGarantare decimal(10,2), 
	@IndCMUnitM decimal(10), @CorCMunitM decimal(10), @IndCMCasM decimal(10), @CorCMCasM decimal(10), 
	@IndCMFaambpM decimal(10), @SomajTehnicPoz decimal(10), @SomajTehnicM decimal(10), @DedPers decimal(10),
	@ProcCASIndiv decimal(5,2), @ProcSomajIndiv decimal(5,2), @ProcCASSIndiv decimal(5,2), @BazaCASCM decimal(10),
	@SomajIndiv decimal(10), @SubvSomaj decimal(10), @ScutireSomaj decimal(10), @NCTaxePLMCh int=null, @NCSubvSomaj int=null
As
Begin try
	declare 
		@CMMarca decimal(10), @CMCasMarca decimal(10), @CMPoz decimal(10), @CMCasPoz decimal(10), 
		@Venit_locm decimal(10), @BazaIndiv decimal(10), @BazaSomajIndiv decimal(10), @BazaImpozit decimal(10),
		@CAS_individual decimal(10), @Somaj_1 decimal(10), @Asig_sanatate_din_net decimal(10), @Impozit decimal(10), 
		@Utilizator char(10)

	if @NCTaxePLMCh is null
		select 
			@NCTaxePLMCh=max(case when Parametru='N-C-TXLMC' then Val_logica else 0 end),
			@NCSubvSomaj=max(case when Parametru='N-SUBVSJD' then Val_logica else 0 end)
		from par where parametru in ('SUBPRO','N-C-TXLMC','N-SUBVSJD')
	set @Utilizator=dbo.fIaUtilizator(null)

	set @CMPoz=@IndCMUnitPoz+@CorCMunitPoz+@IndCMCasPoz+@CorCMCasPoz+@IndCMFaambpPoz
	set @CMCasPoz=@IndCMCasPoz+@CorCMCasPoz+@IndCMFaambpPoz
	set @CMMarca=@IndCMUnitM+@CorCMUnitM+@IndCMCasM+@CorCMCasM+@IndCMFaambpM
	set @CMCasMarca=@IndCMCasM+@CorCMCasM+@IndCMFaambpM
	select @CAS_individual=0, @Somaj_1=0, @Asig_sanatate_din_net=0, @BazaImpozit=0, @Impozit=0

	if not exists (select 1 from CASBrut where Loc_de_munca=@Loc_de_munca and Marca=@Marca)
		insert into CASBrut 
			(Loc_de_munca, Marca, Venit_locm, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, 
			Asig_sanatate_pl_unitate, CCI, Fond_de_garantare, CAS_individual, Somaj_1, Asig_sanatate_din_net,  
			Impozit, Subventie_somaj, Scutire_somaj)
		select @Loc_de_munca, @Marca, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

	set @Venit_locm=(case when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @VenitTotalNet else @VenitTotalBrut end)

	update CASBrut set Venit_locm=@Venit_locm, 
		CAS=(case when @VenitTotalNet-(@CMMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @CasUnitate+@CASCM 
			else round(round((@VenitTotalBrut-(@CMPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMMarca+@SomajTehnicM)),6)*(@CasUnitate+@CASCM),2) end), 
		Somaj_5=(case when @VenitTotalNet-(@CMCasMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @SomajUnitate 
			else round((@VenitTotalBrut-(@CMCasPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMCasMarca+@SomajTehnicM))*@SomajUnitate,2) end), 
		Fond_de_risc_1=(case when @VenitTotalNet-(@CMMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @Faambp 
			else round(round((@VenitTotalBrut-(@CMPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMMarca+@SomajTehnicM)),6)*@Faambp,2) end), 
		Camera_de_Munca_1=(case when @VenitTotalNet-@CMCasMarca=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @ComisionITM 
			else round((@VenitTotalBrut-(@CMCasPoz))/(@VenitTotalNet-(@CMCasMarca))*@ComisionITM,2) end), 
		Asig_sanatate_pl_unitate=(case when @VenitTotalNet-(@CMCasMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @CassUnitate 
			else round((@VenitTotalBrut-(@CMCasPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMCasMarca+@SomajTehnicM))*@CassUnitate,2) end), 
		CCI=(case when @VenitTotalNet-(@CMCasMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @CCI 
			else round((@VenitTotalBrut-(@CMCasPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMCasMarca+@SomajTehnicM))*@CCI,2) end), 
		Fond_de_garantare=(case when @VenitTotalNet-(@CMCasMarca+@SomajTehnicM)=0 then 0 when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @FondGarantare 
			else round((@VenitTotalBrut-(@CMCasPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMCasMarca+@SomajTehnicM))*@FondGarantare,2) end), 
		Subventie_somaj=(case when @NCSubvSomaj=1 and @SubvSomaj<>0 and @VenitTotalNet-(@CMMarca+@SomajTehnicM)<>0 
			then (case when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @SubvSomaj 
				else round(round((@VenitTotalBrut-(@CMPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMMarca+@SomajTehnicM)),6)*@SubvSomaj,2) end) 
			else 0 end), 
		Scutire_somaj=(case when @NCSubvSomaj=1 and @ScutireSomaj<>0 and @VenitTotalNet-(@CMCasMarca+@SomajTehnicM)<>0 
			then (case when abs(@VenitTotalNet-@VenitTotalBrut)<2 then @ScutireSomaj 
				else round((@VenitTotalBrut-(@CMCasPoz+@SomajTehnicPoz))/(@VenitTotalNet-(@CMCasMarca+@SomajTehnicM))*@ScutireSomaj,2) end) 
			else 0 end)
	where Loc_de_munca=@Loc_de_munca and Marca=@Marca

	if @NCTaxePLMCh=1
	Begin
		set @CAS_individual=((@Venit_locm-@CMMarca)+(case when @LmStatPl=1 then @BazaCASCM else 0 end))*@ProcCASIndiv/100
		if @SomajIndiv<>0
			set @Somaj_1=(@Venit_locm-@CMCasMarca)*@ProcSomajIndiv/100 

		set @Asig_sanatate_din_net=(@Venit_locm-@CMMarca)*@ProcCassIndiv/10/100
		set @BazaImpozit=@Venit_locm-(@CAS_individual+@Somaj_1+@Asig_sanatate_din_net)-(case when @LmStatPl=1 then @DedPers else 0 end)
		exec calcul_impozit_salarii @BazaImpozit, @Impozit output, 0

		update CASBrut set CAS_individual=@CAS_individual, Somaj_1=@Somaj_1, 
			Asig_sanatate_din_net=@Asig_sanatate_din_net, Impozit=@Impozit
		where Loc_de_munca=@Loc_de_munca and Marca=@Marca
	end
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura scriuCASBrut (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

