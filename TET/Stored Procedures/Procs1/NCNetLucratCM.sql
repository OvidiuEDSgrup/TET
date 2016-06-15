/* operatie pt. calcul net din timp lucrat si CM  */
Create procedure NCNetLucratCM
	@DataJ datetime, @DataS datetime, @Marca char(6), @NetLucrat_marca decimal(10,2) output, 
	@NetCMUnitate_marca decimal(10,2) output, @NetCMCas_marca decimal(10,2) output
As
Begin
	declare @Sub char(9), @Somaj_1 decimal(10), @Cas_individual decimal(10), @Cass_individual decimal(10), @Impozit decimal(10),
	@Venit_total decimal(10), @Salar_net decimal(10), @Venit_net_in_imp decimal(10), 
	@OreCM int, @CMUnitate decimal(10), @CMCas decimal(10), 
	@SomajLucrat decimal(10,2), @SomajCMUnitate decimal(10,2), @SomajCMCas decimal(10,2), 
	@ImpozitLucrat decimal(10,2), @ImpozitCMUnitate decimal(10,2), @ImpozitCMCas decimal(10,2), @CMNeimpozabil decimal(10,2),
	@DebitSomajActivi char(13), @DebitSomajBolnavi char(13), @CreditCMUnitate1 char(13), @CreditCMCas1 char(13),
	@DebitImpozitActivi char(13), @DebitImpozitBolnavi char(13), @CreditChelt char(13)

	Set @CreditChelt=dbo.iauParA('PS','N-C-SAL1C')
	Set @CreditCMUnitate1=dbo.iauParA('PS','N-C-CMU1C')
	Set @CreditCMCas1=dbo.iauParA('PS','N-C-CMC1C')
	Set @DebitSomajActivi=dbo.iauParA('PS','N-ASSJ1AD')
	Set @DebitSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BD')
	Set @DebitImpozitActivi=dbo.iauParA('PS','N-I-PMACD')
	Set @DebitImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOD')
	Select @SomajLucrat=0, @SomajCMUnitate=0, @SomajCMCas=0, @ImpozitLucrat=0, @ImpozitCMUnitate=0, @ImpozitCMCas=0

	Select @Somaj_1=Somaj_1, @Cas_individual=Pensie_suplimentara_3, @Cass_individual=Asig_sanatate_din_net,
		@Impozit=Impozit+Diferenta_impozit, @Venit_total=Venit_total, @Salar_net=Venit_net, 
		@Venit_net_in_imp=Ven_net_in_imp, @CMunitate=isnull(b.CMUnitate,0), @CMCAS=isnull(b.CMCAS,0),
		@CMNeimpozabil=isnull(c.CMNeimpozabil,0)
	from net n 
		left outer join (select Data, Marca, sum(Ind_c_medical_unitate+CMunitate) as CMUnitate, 
		sum(Ind_c_medical_cas+Spor_cond_9+CMCas) as CMCAS from brut where data=@DataS and Marca=@Marca group by Data, Marca) b on n.Data=b.Data and n.Marca=b.Marca
		left outer join (select Data, Marca, sum(Indemnizatie_CAS) as CMNeimpozabil from conmed where data=@DataS and Marca=@Marca and Tip_diagnostic in ('8-','9-','15') group by Data, Marca) c on n.Data=c.Data and n.Marca=c.Marca
	where n.Data=@DataS and n.Marca=@Marca

	if @DebitSomajActivi<>@DebitSomajBolnavi and @DebitSomajBolnavi=@CreditCMUnitate1 and @Somaj_1<>0
		Set @SomajCMUnitate=round(@Somaj_1*@CMUnitate/@Venit_total,0)
	if @DebitSomajActivi<>@DebitSomajBolnavi and @DebitSomajBolnavi=@CreditCMCas1
		Set @SomajCMCas=0

	Set @SomajLucrat=@Somaj_1-@SomajCMUnitate-@SomajCMCas

	if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMUnitate1 and @Venit_net_in_imp<>0
		Set @ImpozitCMUnitate=round((@CMUnitate-@SomajCMUnitate)*@Impozit/@Venit_net_in_imp,0)

	if @DebitImpozitActivi<>@DebitImpozitBolnavi and @DebitImpozitBolnavi=@CreditCMCas1 and @Venit_net_in_imp<>0
		Set @ImpozitCMcas=round((@CMCas-@CMNeimpozabil-@SomajCMCas)*@Impozit/@Venit_net_in_imp,0)

	Set @ImpozitLucrat=@Impozit-@ImpozitCMUnitate-@ImpozitCMcas

	if @CreditChelt<>@CreditCMUnitate1
		Set @NetCMUnitate_marca=@CMUnitate-@SomajCMUnitate-@ImpozitCMUnitate

	if @CreditChelt<>@CreditCMCas1
		Set @NetCMCas_marca=@CMCas-@SomajCMCas-@ImpozitCMcas

	Set @NetLucrat_marca=@Salar_net-@NetCMUnitate_marca-@NetCMCas_marca
	
End
