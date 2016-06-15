/*
	functia returneaza diferentele pe tabela net rezultate dintr-un calcul de lichidare pe o luna inchisa in raport cu calculul initial (cand s-a depus D112)
	@locapelare='LR' - > apelare procedura din luna rectificata (inchisa dpdv. contabil) - cea pe care se declara diferentele in D112
	@locapelare='LC' - > apelare procedura din luna curenta - cea pe care se inregistreaza contabil diferentele
*/	
Create function fRectificariNet (@parXML xml)
returns @rectificarinet table
	(Data datetime, Marca char(6), Loc_de_munca char(9), VENIT_TOTAL float, CM_incasat float, CO_incasat float, Suma_incasata float, Suma_neimpozabila float,
	Diferenta_impozit float, Impozit float, Pensie_suplimentara_3 float, Somaj_1 float, Asig_sanatate_din_impozit float, Asig_sanatate_din_net float, Asig_sanatate_din_CAS float,
	VENIT_NET float, Avans float, Premiu_la_avans float, Debite_externe float, Rate float, Debite_interne float, Cont_curent float, REST_DE_PLATA float, CAS float,
	Somaj_5 float, Fond_de_risc_1 float, Camera_de_Munca_1 float, Asig_sanatate_pl_unitate float, Coef_tot_ded real, Grad_invalid char(1), Coef_invalid real, Alte_surse bit,
	VEN_NET_IN_IMP float, Ded_baza float, Ded_suplim float, VENIT_BAZA float, Chelt_prof float, Baza_CAS float, Baza_CAS_cond_norm float, Baza_CAS_cond_deoseb float, Baza_CAS_cond_spec float) 
as
Begin
	declare @datajos datetime, @datasus datetime, @lunaApelare char(2), @marca varchar(6), @nc int
	set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	set @lunaApelare = @parXML.value('(/*/@lunaApelare)[1]', 'char(2)')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @nc = isnull(@parXML.value('(/*/@nc)[1]', 'int'),0)

--	formez datele sub forma tabelei net
	insert into @rectificarinet
	select dbo.bom(b.datalunii) as data, b.Marca, b.Loc_de_munca, sum(isnull(VENIT_TOTAL,0)) as VENIT_TOTAL, 
		sum(isnull(CM_incasat,0)) as CM_incasat, sum(isnull(CO_incasat,0)) as CO_incasat, 
		sum(isnull(Suma_incasata,0)) as Suma_incasata, sum(isnull(Suma_neimpozabila,0)) as Suma_neimpozabila, sum(isnull(Diferenta_impozit,0)) as Diferenta_impozit, 
		sum(isnull(Impozit,0)) as Impozit, sum(isnull(Pensie_suplimentara_3,0)) as Pensie_suplimentara_3, sum(isnull(Somaj_1,0)) as Somaj_1,
		sum(isnull(Asig_sanatate_din_impozit,0)) as Asig_sanatate_din_impozit, sum(isnull(Asig_sanatate_din_net,0)) as Asig_sanatate_din_net, 
		sum(isnull(Asig_sanatate_din_CAS,0)) as Asig_sanatate_din_CAS, sum(isnull(VENIT_NET,0)) as VENIT_NET, sum(isnull(Avans,0)) as Avans, sum(isnull(Premiu_la_avans,0)) as Premiu_la_avans, 
		sum(isnull(Debite_externe,0)) as Debite_externe, sum(isnull(Rate,0)) as Rate, sum(isnull(Debite_interne,0)) as Debite_interne, sum(isnull(Cont_curent,0)) as Cont_curent, 
		sum(isnull(REST_DE_PLATA,0)) as REST_DE_PLATA, 
		sum(isnull(CAS,0)) as CAS, sum(isnull(Somaj_5,0)) as Somaj_5, sum(isnull(Fond_de_risc_1,0)) as Fond_de_risc_1, 
		sum(isnull(Camera_de_Munca_1,0)) as Camera_de_Munca_1, sum(isnull(Asig_sanatate_pl_unitate,0)) as Asig_sanatate_pl_unitate, 
		0 as Coef_tot_ded, isnull(max(i.grad_invalid),0) as grad_invalid, isnull(max(i.coef_invalid),0) as coef_invalid, isnull(max(convert(int,i.alte_surse)),0) as alte_surse, 
		sum(isnull(VEN_NET_IN_IMP,0)) as VEN_NET_IN_IMP, sum(isnull(Ded_baza,0)) as Ded_baza, sum(isnull(Ded_suplim,0)) as Ded_suplim, 
		sum(isnull(VENIT_BAZA,0)) as VENIT_BAZA, sum(isnull(Chelt_prof,0)) as Chelt_prof, 
		sum(isnull(Baza_CAS,0)) as Baza_CAS, sum(isnull(Baza_CAS_cond_norm,0)) as Baza_CAS_cond_norm, sum(isnull(Baza_CAS_cond_deoseb,0)) as Baza_CAS_cond_deoseb, 
		sum(isnull(Baza_CAS_cond_spec,0)) as Baza_CAS_cond_spec
	from
	(select (case when @lunaApelare='LR' and @nc=0 then pr.data_rectificata else ar.data end) as datalunii, pr.data_rectificata, 
		(case when @lunaApelare='LR' then pr.data_rectificata else ar.data end) as data, ar.marca, pr.loc_de_munca, pr.tip_suma, 
		convert(decimal(12,2),pr.suma) as suma, ts.camp_tabela as camp
	from PozRectificariSalarii pr
		inner join AntetRectificariSalarii ar on ar.idRectificare=pr.idRectificare
		left outer join fTipSumeSalarii () ts on ts.tabela='net1' and ts.tip_suma=pr.tip_suma
	where ts.tabela='net1' and (@lunaApelare='LC' and ar.data between @datajos and @datasus or @lunaApelare='LR' and pr.data_rectificata between @datajos and @datasus)
		and (@marca is null or ar.marca=@marca)) a
		pivot (sum(suma) for camp in 
			(VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, 
			REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b
	left outer join istPers i on i.Data=b.data_rectificata and i.Marca=b.marca
	group by b.datalunii, b.marca, b.loc_de_munca
	union all
	select b.datalunii, b.Marca, b.Loc_de_munca, sum(isnull(VENIT_TOTAL,0)) as VENIT_TOTAL, 
		sum(isnull(CM_incasat,0)) as CM_incasat, sum(isnull(CO_incasat,0)) as CO_incasat, 
		sum(isnull(Suma_incasata,0)) as Suma_incasata, sum(isnull(Suma_neimpozabila,0)) as Suma_neimpozabila, sum(isnull(Diferenta_impozit,0)) as Diferenta_impozit, 
		sum(isnull(Impozit,0)) as Impozit, sum(isnull(Pensie_suplimentara_3,0)) as Pensie_suplimentara_3, sum(isnull(Somaj_1,0)) as Somaj_1,
		sum(isnull(Asig_sanatate_din_impozit,0)) as Asig_sanatate_din_impozit, sum(isnull(Asig_sanatate_din_net,0)) as Asig_sanatate_din_net, 
		sum(isnull(Asig_sanatate_din_CAS,0)) as Asig_sanatate_din_CAS, sum(isnull(VENIT_NET,0)) as VENIT_NET, sum(isnull(Avans,0)) as Avans, sum(isnull(Premiu_la_avans,0)) as Premiu_la_avans, 
		sum(isnull(Debite_externe,0)) as Debite_externe, sum(isnull(Rate,0)) as Rate, sum(isnull(Debite_interne,0)) as Debite_interne, sum(isnull(Cont_curent,0)) as Cont_curent, 
		sum(isnull(REST_DE_PLATA,0)) as REST_DE_PLATA, 
		sum(isnull(CAS,0)) as CAS, sum(isnull(Somaj_5,0)) as Somaj_5, sum(isnull(Fond_de_risc_1,0)) as Fond_de_risc_1, 
		sum(isnull(Camera_de_Munca_1,0)) as Camera_de_Munca_1, sum(isnull(Asig_sanatate_pl_unitate,0)) as Asig_sanatate_pl_unitate, 
		0 as Coef_tot_ded, isnull(max(i.grad_invalid),0) as grad_invalid, isnull(max(i.coef_invalid),0) as coef_invalid, isnull(max(convert(int,i.alte_surse)),0) as alte_surse, 
		sum(isnull(VEN_NET_IN_IMP,0)) as VEN_NET_IN_IMP, sum(isnull(Ded_baza,0)) as Ded_baza, sum(isnull(Ded_suplim,0)) as Ded_suplim, 
		sum(isnull(VENIT_BAZA,0)) as VENIT_BAZA, sum(isnull(Chelt_prof,0)) as Chelt_prof, 
		sum(isnull(Baza_CAS,0)) as Baza_CAS, sum(isnull(Baza_CAS_cond_norm,0)) as Baza_CAS_cond_norm, sum(isnull(Baza_CAS_cond_deoseb,0)) as Baza_CAS_cond_deoseb, 
		sum(isnull(Baza_CAS_cond_spec,0)) as Baza_CAS_cond_spec
	from
	(select (case when @lunaApelare='LR' and @nc=0 then pr.data_rectificata else ar.data end) as datalunii, pr.data_rectificata, 
		(case when @lunaApelare='LR' then pr.data_rectificata else ar.data end) as data, ar.marca, pr.loc_de_munca, pr.tip_suma, 
		convert(decimal(12,2),pr.suma) as suma, ts.camp_tabela as camp
	from PozRectificariSalarii pr
		inner join AntetRectificariSalarii ar on ar.idRectificare=pr.idRectificare
		left outer join fTipSumeSalarii () ts on ts.tabela='net' and ts.tip_suma=pr.tip_suma
	where ts.tabela='net' and (@lunaApelare='LC' and ar.data between @datajos and @datasus or @lunaApelare='LR' and pr.data_rectificata between @datajos and @datasus)
		and (@marca is null or ar.marca=@marca)) a
		pivot (sum(suma) for camp in 
			(VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, 
			REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b
	left outer join istPers i on i.Data=b.data_rectificata and i.Marca=b.marca
	group by b.datalunii, b.marca, b.loc_de_munca

	return
End
/*
	select * from fRectificariNet ('01/30/2011', '11/30/2011', 'LR', null)
*/	
