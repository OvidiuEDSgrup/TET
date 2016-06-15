/* operatie pt. generare NC pt. sume operate pe macheta de corectii pe marci: corectiile U,Q,W,AI. */
Create procedure GenNCCorectii
	@dataJos datetime, @dataSus datetime, @Continuare int output, @NrPozitie int output
As
Begin
	declare @Sub varchar(9), @NCIndBug int, @LucrCuDiurneNeimpoz int, @CorectieDiurneNeimpoz varchar(2), @Salubris int, 
	@NumarDoc varchar(8), @cDataDoc varchar(4), 
	@ContDebitCorU varchar(20), @ContCreditCorU varchar(20), @ContDebitCorQ varchar(20), @ContCreditCorQ varchar(20), @ContDebitCorW varchar(20), @ContCreditCorW varchar(20), 
	@ContDebitCorAI varchar(20), @ContCreditCorAI varchar(20)	--	Conturi pentru avantaje materiale impozabile.

	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NumarDoc='SAL'+@cDataDoc
	select 
		@sub=max(case when Parametru='SUBPRO' then Val_alfanumerica else '' end),
		@NCIndBug=max(case when Parametru='NC-INDBUG' then Val_logica else 0 end),
		@LucrCuDiurneNeimpoz=max(case when Parametru='DIUNEIMP' then Val_logica else 0 end),
		@CorectieDiurneNeimpoz=max(case when Parametru='DIUNEIMP' then Val_alfanumerica else '' end),
		@ContDebitCorU=max(case when Parametru='N-C-PNEID' then Val_alfanumerica else '' end),
		@ContCreditCorU=max(case when Parametru='N-C-PNEIC' then Val_alfanumerica else '' end),
		@ContDebitCorQ=max(case when Parametru='N-C-AVMD' then Val_alfanumerica else '' end),
		@ContCreditCorQ=max(case when Parametru='N-C-AVMC' then Val_alfanumerica else '' end),
		@ContDebitCorW=max(case when Parametru='N-C-DNIDB' then Val_alfanumerica else '' end),
		@ContCreditCorW=max(case when Parametru='N-C-DNICR' then Val_alfanumerica else '' end),
		@ContDebitCorAI=max(case when Parametru='N-C-AVMID' then Val_alfanumerica else '' end),
		@ContCreditCorAI=max(case when Parametru='N-C-AVMIC' then Val_alfanumerica else '' end),
		@Salubris=max(case when Parametru='SALUBRIS' then Val_logica else 0 end)
	from par 
	where Tip_parametru='GE' and parametru='SUBPRO'
		or Tip_parametru='PS' and parametru in ('NC-INDBUG','N-C-PNEID','N-C-PNEIC','N-C-AVMD','N-C-AVMC','DIUNEIMP','N-C-DNIDB','N-C-DNICR','N-C-AVMID','N-C-AVMIC')
		or Tip_parametru='SP' and parametru='SALUBRIS'

	create table #config_nc (Identificator varchar(20), Cont_debitor varchar(40), Cont_creditor varchar(40))
	insert into #config_nc (Cont_debitor, Cont_creditor, Identificator)
	select @ContDebitCorU, @ContCreditCorU, 'U-'
	union all
	select @ContDebitCorQ, @ContCreditCorQ, 'Q-'
	union all
	select @ContDebitCorW, @ContCreditCorW, 'W-'
	union all
	select @ContDebitCorAI, @ContCreditCorAI, 'AI'

	Create table #nccorectii
		(tip_corectie varchar(2), data datetime, loc_de_munca varchar(9), comanda varchar(40), suma float, cont_debitor varchar(40), cont_creditor varchar(40), explicatii varchar(50))
	insert into #nccorectii (tip_corectie, data, loc_de_munca, comanda, suma)
	select 'U-' as tip_corectie, max(Data), Loc_de_munca, Comanda, sum(Valoare)
	from dbo.fNCCorectiiU (@dataJos, @dataSus, '') 
	where (@Salubris=1 or @ContDebitCorU<>'')
	Group by Loc_de_munca, Comanda
	union all
	select tip_corectie_venit as tip_corectie, Data, Loc_de_munca, '' as Comanda, sum(case when a.Tip_corectie_venit='AI' and a.Suma_neta<>0 then a.Suma_neta else Suma_corectie end) as Valoare
	from fSumeCorectie (@dataJos, @dataSus, '', '', '', 1) a
	where (tip_corectie_venit='Q-' and @ContDebitCorQ<>'' and @NCIndBug=0
			or tip_corectie_venit='W-' and @LucrCuDiurneNeimpoz=1 and @ContDebitCorW<>''
			or tip_corectie_venit='AI' and @ContDebitCorAI<>'')
	GROUP by a.tip_corectie_venit, a.Data, a.Loc_de_munca
	ORDER by Loc_de_munca, Comanda

	update nc set cont_debitor=c.cont_debitor, cont_creditor=c.cont_creditor, explicatii=tc.denumire
	from #nccorectii nc
	left outer join #config_nc c on c.identificator=nc.tip_corectie
	left outer join tipcor tc on tc.tip_corectie_venit=nc.tip_corectie

	insert into #docPozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Explicatii, Nr_pozitie, Loc_munca, Comanda, Jurnal)
	select @Sub, 'PS', @NumarDoc, Data, Cont_debitor, Cont_creditor, sum(Suma) as suma, Explicatii, 
		@NrPozitie+ROW_NUMBER() over(order by Cont_debitor, Cont_creditor), Loc_de_munca, '', ''
	from #nccorectii
	group by Data, Cont_debitor, Cont_creditor, Loc_de_munca, Comanda, Explicatii

	select @NrPozitie=isnull(max(Nr_pozitie),0)+1 from #docPozncon

	exec completareNCsalarii @dataJos=@dataJos, @dataSus=@dataSus, @NumarDoc=@NumarDoc
End
