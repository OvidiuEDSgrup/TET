/* operatie pt. generare NC pt. sume din net (contributii angajat, avans, etc.) */
Create procedure GenerareNCContributiiAngajatiBug
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int=1 output, @NrPozitie int=0 output, @NumarDoc char(8)
As
Begin try
	declare @userASiS char(10), @Sub char(9), @NCIndBug int, @NCTaxePLM int, @AnPLImpozit int, @CondAnPLImpozit int, 
	@CreditCheltOcazO varchar(20), @CreditCheltOcazP varchar(20), @AtribuireCreditCheltOcazO int, @AtribuireCreditCheltOcazP int, 
	@CreditSomajActivi varchar(20), @CreditSomajBolnavi varchar(20), @CreditSomajOcaz varchar(20), 
	@CreditCASActivi varchar(20), @CreditCASOcaz varchar(20), @CreditCASBoln varchar(20), 
	@CreditCassActivi varchar(20), @DebitCassOcazO varchar(20), @CreditCassOcazO varchar(20), 
	@DebitCassOcazP varchar(20), @CreditCassOcazP varchar(20), @AtribContDebitCassOcazO int, @AtribContDebitCassOcazP int, 
	@DebitCassFaambp varchar(20), @CreditCassFaambp varchar(20), 
	@CreditImpozitOcazO varchar(20), @CreditImpozitOcazP varchar(20), @CreditFaambp varchar(20), @CreditCCI varchar(20), 
	@CreditImpozitActivi varchar(20), @CreditImpozitBolnavi varchar(20),
	@DebitCMCas2 varchar(20), @CreditCMCas2 varchar(20)

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
	set @AnPLImpozit=dbo.iauParL('PS','AN-PL-IMP')
	set @CreditCheltOcazO=dbo.iauParA('PS','N-C-SAL2C')
	set @CreditCheltOcazP=dbo.iauParA('PS','N-C-SAL3C')
	select @AtribuireCreditCheltOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
	select @AtribuireCreditCheltOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP
	set @CreditSomajActivi=dbo.iauParA('PS','N-ASSJ1AC')
	set @CreditSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BC')
	set @CreditSomajOcaz=dbo.iauParA('PS','N-ASSJ1OC')
	set @CreditCASActivi=dbo.iauParA('PS','N-AS-P3AC')
	set @CreditCASOcaz=dbo.iauParA('PS','N-AS-P3OC')
	set @CreditCASBoln=dbo.iauParA('PS','N-AS-P3BC')
	set @CreditCassActivi=dbo.iauParA('PS','N-ASNEAC')
	set @DebitCassOcazO=dbo.iauParA('PS','N-ASNEOD')
	set @CreditCassOcazO=dbo.iauParA('PS','N-ASNEOC')
	set @DebitCassOcazP=dbo.iauParA('PS','N-ASNEOPD')
	set @CreditCassOcazP=dbo.iauParA('PS','N-ASNEOPC')
	select @AtribContDebitCassOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazO
	select @AtribContDebitCassOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazP
	set @DebitCassFaambp=dbo.iauParA('PS','N-ASFABPD')
	set @CreditCassFaambp=dbo.iauParA('PS','N-ASFABPC')
	set @CreditImpozitActivi=dbo.iauParA('PS','N-I-PMACC')
	set @CreditImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOC')
	set @CreditImpozitOcazO=dbo.iauParA('PS','N-I-OCAZC')
	set @CreditImpozitOcazP=dbo.iauParA('PS','N-I-OCZPC')
	set @CreditFaambp=dbo.iauParA('PS','N-AS-FR1C')
	set @CreditCCI=dbo.iauParA('PS','N-AS-CCIC')
	set @DebitCMCas2=dbo.iauParA('PS','N-C-CMC2D')
	set @CreditCMCas2=dbo.iauParA('PS','N-C-CMC2C')

	set @CondAnPLImpozit=(case when @AnPLImpozit=1 then 1 else 0 end)

	if object_id('tempdb..#tmpcontributii') is not null drop table #tmpcontributii
	if object_id('tempdb..#nc_contributii') is not null drop table #nc_contributii
	if object_id('tempdb..#config_nc_sal') is not null drop table #config_nc_sal

	select * into #config_nc_sal from config_nc
	insert into #config_nc_sal (Numar_pozitie, Denumire, Cont_debitor, Cont_creditor, Comanda, Analitic, Expresie, Identificator)
	select 200, 'CCI din Faambp', @CreditFaambp, @CreditCCI, '', 0, '', 'CCIFAAMBP'
	union all
	select 201, 'CASS din Faambp', @DebitCassFaambp, @CreditCassFaambp, '', 0, '', 'CASSFAAMBP'

	CREATE TABLE dbo.#tmpcontributii
		(Data datetime, TipSuma varchar(30), Marca varchar(6), lm varchar(9), Indicator varchar(20), Suma float, ExplicatiiSuma varchar(1000), 
		TipContributii varchar(30), ExplicatiiContributii varchar(1000), idpoz int) 

	insert into #tmpcontributii
	exec calculOrdonantariSalarii @dataJos=@dataJos, @dataSus=@dataSus, @marca=@pmarca, @tipCalcul=3

	select a.Data, a.TipSuma, (case when @NCTaxePLM=1 then a.lm /* n.Loc_de_munca */ else '' end) as loc_de_munca, a.Indicator, 
		max((case when a.TipContributii in ('CASANGAJAT','CASSANGAJAT','SOMAJANGAJAT','IMPOZIT','AVANS') 
			then (case when a.tipSuma='CMFNUASS' and c.Cont_creditor=@DebitCMCas2 then @CreditCMCas2 else c.Cont_creditor end)
			else c.Cont_debitor end)) as Cont_debitor, 
		max((case when a.TipContributii='CASANGAJAT' then isnull(nullif(c.Cont_CAS,''),@CreditCASActivi) 
			when a.TipContributii='CASSANGAJAT' then isnull(nullif(c.Cont_CASS,''),@CreditCassActivi)
			when a.TipContributii='SOMAJANGAJAT' then isnull(nullif(c.Cont_somaj,''),@CreditSomajActivi)
			when a.TipContributii='IMPOZIT' then isnull(nullif(c.Cont_Impozit,''),@CreditImpozitActivi) 
			else c.Cont_creditor end)) as Cont_creditor, 
		sum(a.Suma) as suma, a.ExplicatiiSuma, a.TipContributii, a.ExplicatiiContributii
	into #nc_contributii
	from #tmpcontributii a
		left outer join net n on n.data=a.data and n.marca=a.marca
		left outer join istPers i on i.data=a.data and i.marca=a.marca
		outer apply (select * from #config_nc_sal c where c.Identificator=a.TipSuma and (a.lm like RTRIM(c.Loc_de_munca)+'%' 
			or c.Loc_de_munca is null and not exists (select 1 from #config_nc_sal c1 where a.lm like RTRIM(c1.Loc_de_munca)+'%'))) c
	group by a.Data, a.TipSuma, (case when @NCTaxePLM=1 then a.lm else '' end), a.Indicator, a.ExplicatiiSuma, a.TipContributii, a.ExplicatiiContributii

	insert into #docPozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Explicatii, Nr_pozitie, Loc_munca, Comanda, Jurnal)
	select @Sub, 'PS', @NumarDoc, Data, Cont_debitor, Cont_creditor, sum(Suma) as suma, ExplicatiiContributii, 
		@NrPozitie+ROW_NUMBER() over(order by Cont_debitor, Cont_creditor), Loc_de_munca, '', ''
	from #nc_contributii
	group by Data, Cont_debitor, Cont_creditor, Loc_de_munca, ExplicatiiContributii

	select @NrPozitie=isnull(max(Nr_pozitie),0)+1 from #docPozncon

	exec completareNCsalarii @dataJos=@dataJos, @dataSus=@dataSus, @NumarDoc=@NumarDoc
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenerareNCContributiiAngajatiBug (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec GenNCDinNet '01/01/2011', '01/31/2011', '', 1, 1
*/
