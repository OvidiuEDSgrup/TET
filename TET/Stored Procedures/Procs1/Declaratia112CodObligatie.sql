--***
/**	procedura pentru afisarea obligatiilor bugetare pe coduri */
Create procedure Declaratia112CodObligatie
	(@dataJos datetime, @dataSus datetime, @Data_scadentei datetime, @Cod_declaratie char(20), @lm char(20), @ContCASSAgricol char(30), @ContImpozitAgricol char(30))
as
begin
/*
	tip colaborator=DAC -> Venituri din Drepturi de autor si conexe
	tip colaborator=DPI -> Venituri din Drepturi de proprietate intelectuala
	tip colaborator=CCC -> Venituri din Contracte/Conventii civile 
	tip colaborator=21	-> Venituri din Activitati agricole (acestea provin din CG)
*/	
	declare @InstPubl int, @Judet char(25), @pCASind char(10), @pCASunit char(10), @pFaambp char(10), @pCASSind char(10), 
		@pCASSunit char(10), @pCCI char(10), @pSomajInd char(10), @pSomajUnit char(10), @pFondGar char(10), 
		@cNumar_evidenta char(100), @somaj_ded float, @cci_ded float, @faambp_ded float, @lCNPH int, @Cod_declaratie_100 char(20), 
		@Cod_declaratie_102 char(20), @cas_indiv_alte decimal(7), @somaj_indiv_alte decimal(7), @impozit_dac decimal(10), @impozit_ccc decimal(10), @impozit_ect decimal(10),
		@cas_dpi decimal(7), @cass_dpi decimal(7), @cas_ccc decimal(7), @cass_ccc decimal(7), @cas_ect decimal(7), @cass_ect decimal(7), 
		@cass_activ_agricole decimal(7), @impozit_activ_agricole  decimal(10), @AjDecesUnit int, @cotiz_hand decimal(10), @impozit_zilieri decimal(10), @lmsus varchar(20)

	set @InstPubl=dbo.iauParL('PS','INSTPUBL')
	set @pCASind=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASINDIV'),4,2))+'%'
	set @pCASunit=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASGRUPA3')-dbo.iauParLN(@dataSus,'PS','CASINDIV'),4,1))+'%'
	set @pFaambp=ltrim(str(dbo.iauParLN(@dataSus,'PS','0.5%ACCM'),4,2))+'%'
	set @pCASSind=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASSIND'),4,2))+'%'
	set @pCASSunit=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASSUNIT'),4,2))+'%'
	set @pCCI=ltrim(str(dbo.iauParLN(@dataSus,'PS','COTACCI'),4,2))+'%'
	set @pSomajInd=ltrim(str(dbo.iauParLN(@dataSus,'PS','SOMAJIND'),4,2))+'%'
	set @pSomajUnit=ltrim(str(dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ'),4,2))+'%'
	set @pFondGar=ltrim(str(dbo.iauParLN(@dataSus,'PS','FONDGAR'),4,2))+'%'
	set @AjDecesUnit=dbo.iauParL('PS','AJDUNIT-R')
	set @Judet=dbo.iauParA('PS','JUDET')
	set @lCNPH=dbo.iauParL('PS','NC-CPHAND')
	set @cNumar_evidenta=(case when month(@dataSus)<10 then '0' else '' end)+rtrim(convert(char(2),month(@dataSus)))+ right(convert(char(4),year(@dataSus)),2)
		+'25'+(case when month(@Data_scadentei)<10 then '0' else '' end)+rtrim(convert(char(2),month(@Data_scadentei)))+right(convert(char(4),year(@Data_scadentei)),2)
	set @Cod_declaratie_100=(case when @Cod_declaratie<>'' then @Cod_declaratie else 100 end) 
	set @Cod_declaratie_102=(case when @Cod_declaratie<>'' then @Cod_declaratie else 102 end) 
	set @impozit_zilieri=0
	set @lmsus=rtrim(@lm)+'ZZ'

	create table #Sume_contributii 
		(Cod_contributie char(20), Cod_declaratie char(20), Punct_de_lucru char(20), Data datetime, 
		Cod_bugetar char(20), Numar_evidenta_platii char(40), Suma_datorata decimal(10), Suma_deductibila decimal(10), 
		Suma_de_plata decimal(10), Suma_de_recuperat decimal(10), Explicatii char(200), Notatie char(100))

	create table #sume
		(data_jos datetime, data_sus datetime, impozit float, cas_indiv float, cass_indiv float, somaj_indiv float, cas_unit float, cas_unit_ded float, cass_unit float, 
		somaj_unit float, somaj_unit_ded float, faambp float, faambp_ded float, cci float, cci_ded float, fond_garantare float, 
		cas_indiv_alte decimal(7), somaj_indiv_alte decimal(7), impozit_dac decimal(10), impozit_ccc decimal(10), impozit_ect decimal(10), 
		cas_dpi decimal(7), cass_dpi decimal(7), cas_ccc decimal(7), cass_ccc decimal(7), cas_ect decimal(7), cass_ect decimal(7), 
		cass_activ_agricole decimal(7), impozit_activ_agricole  decimal(10), cass_unit_faambp float, cass_faambp float) 

	select @cas_indiv_alte=sum(isnull(n.pensie_suplimentara_3,0)), @somaj_indiv_alte=sum(isnull(n.Somaj_1,0)),
		@impozit_dac=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='DAC' then n.Impozit else 0 end),0)),
		@impozit_ccc=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='CCC' then n.Impozit else 0 end),0)),
		@impozit_ect=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='ECT' then n.Impozit else 0 end),0)),
		@cas_dpi=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='DAC' then n.pensie_suplimentara_3 else 0 end),0)),
		@cass_dpi=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='DAC' then n.Asig_sanatate_din_net else 0 end),0)), 
		@cas_ccc=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='CCC' then n.pensie_suplimentara_3 else 0 end),0)),
		@cass_ccc=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='CCC' then n.Asig_sanatate_din_net else 0 end),0)),
		@cas_ect=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='ECT' then n.pensie_suplimentara_3 else 0 end),0)),
		@cass_ect=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='ECT' then n.Asig_sanatate_din_net else 0 end),0))
	from #net n
		left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
	where n.data=@dataSus and i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT')
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')

	select @Cotiz_hand=isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
		and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
		and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @dataJos and @dataSus),0)

	select @impozit_zilieri=isnull(sum(Impozit),0) from #SalariiZilieri 
	select @cass_activ_agricole=sum((case when tip_contributie='AS' then Contributie else 0 end)), 
		@impozit_activ_agricole=sum((case when tip_contributie='IM' then Contributie else 0 end))
	from fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol)

	insert into #sume
	select @dataJos, @dataSus, isnull(sum(n.Impozit+n.Diferenta_impozit)-isnull(@impozit_dac,0)-isnull(@impozit_ccc,0)-isnull(@impozit_ect,0),0), 
		sum(n.Pensie_suplimentara_3)-isnull(@cas_indiv_alte,0) as cas_indiv, sum(n.Asig_sanatate_din_net)-isnull(@cass_ccc,0)-isnull(@cass_dpi,0)-isnull(@cass_ect,0) as cass_indiv, 
		sum(n.Somaj_1)-isnull(@somaj_indiv_alte,0) as somaj_indiv, round(sum(n.CAS+isnull(n1.CAS,0)),0) as cas_unit, 
		sum((case when @AjDecesUnit=1 then 0 else b.Compensatie end)) as cas_unit_ded, 
		sum(n.Asig_sanatate_pl_unitate) as cass_unit, round(sum(n.Somaj_5),0) as somaj_unit, 
		sum((case when p.coef_invalid in (1,2,3,4,7,8,9) then n.chelt_prof else 0 end))
		+round(sum(isnull(ss.Scutire_art80,0)),0)+round(sum(isnull(ss.Scutire_art85,0)),0) as somaj_unit_ded,
		round(sum(n.Fond_de_risc_1),0) as faambp, sum(n.Asig_sanatate_din_impozit+b.Spor_cond_9+n1.Ded_suplim) as faamb_ded, 
		round(sum(n.Ded_suplim+n1.Ded_suplim),0) as cci, round(sum(b.Ind_c_medical_cas+b.CMCAS),0) as CCI_ded, round(sum(n1.Somaj_5),0) as fond_garantare, 
		isnull(@cas_indiv_alte,0), isnull(@somaj_indiv_alte,0), isnull(@impozit_dac,0), isnull(@impozit_ccc,0), isnull(@impozit_ect,0), 
		isnull(@cas_dpi,0) as cas_dpi, isnull(@cass_dpi,0) as cass_dpi, isnull(@cas_ccc,0) as cas_ccc, isnull(@cass_ccc,0) as cass_ccc,
		isnull(@cas_ect,0) as cas_ect, isnull(@cass_ect,0) as cass_ect,
		isnull(@cass_activ_agricole,0) as cass_activ_agricole, isnull(@impozit_activ_agricole,0) as impozit_activ_agricole,
		sum(n1.Asig_sanatate_din_impozit) as cass_unit_fambp, sum(n.Asig_sanatate_din_impozit) as cass_fambp 
	from #net n 
		left outer join personal p on p.Marca=n.Marca
		left outer join #net n1 on n1.Data=dbo.bom(n.Data) and n1.Marca=n.Marca
		left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
		left outer join #brutMarca b on b.Data=n.Data and b.Marca=n.Marca
		left outer join dbo.fScutiriSomaj (@dataJos, @dataSus, '', 'ZZZ', @lm, @lmsus) ss on ss.data=n.data and ss.marca=n.marca
	where n.Data=@dataSus
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')

	update #sume set Impozit=Impozit+@impozit_zilieri where @impozit_zilieri<>0

	insert into #Sume_contributii
	select '602', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1060201'+rtrim(@cNumar_evidenta), Impozit, 0, Impozit, 0, 
		'Imp.pe. ven. din salarii','Impozit 16%' 
	from #sume a where Impozit is not NULL
	union all 
	select '810', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1081001'+rtrim(@cNumar_evidenta),@cotiz_hand, 0, @cotiz_hand,0, 
		'Varsam.de la PJ pt.pers.cu handicap neincadrate - angajator','CNPH'
	from #sume a 
	where @lCNPH=1 and @Cotiz_hand is not NULL
	union all 
	select '412', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1041201'+rtrim(@cNumar_evidenta), isnull(cas_indiv,0), 0, isnull(cas_indiv,0), 0, 
		'CAS individ. - asigurati', 'CAS individual '+ @pCASind
	from #sume a 
	union all 
	select '411', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1041101'+rtrim(@cNumar_evidenta), isnull(cas_unit,0), dbo.valoare_minima(isnull(cas_unit,0),isnull(cas_unit_ded,0), 
		isnull(cas_unit_ded,0)), (case when isnull(cas_unit,0)>isnull(cas_unit_ded,0) then isnull(cas_unit,0)-isnull(cas_unit_ded,0) else 0 end), 0,
		'CAS - angajator','CAS '+@pCASunit
	from #sume a 
--	acesta cod (419) s-a desfintat incepand cu luna iulie 2012, dar ramine de completat pt. declaratiile rectificative anterioare
	union all 
	select '419', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1041901'+rtrim(@cNumar_evidenta), cas_indiv_alte, 0, cas_indiv_alte, 0, 
		'CAS individ. - alti asigurati', 'CAS individual '+ @pCASind
	from #sume a where cas_indiv_Alte<>0 and @dataJos<'07/01/2012'
	union all 
	select '416', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1041601'+rtrim(@cNumar_evidenta), isnull(faambp,0), dbo.valoare_minima(isnull(faambp,0),isnull(faambp_ded,0),
		isnull(@faambp_ded,0)), (case when isnull(faambp,0)>isnull(faambp_ded,0) then isnull(faambp,0)-isnull(faambp_ded,0) else 0 end), 0, 
		'CA pt. accid.de munca si boli prof.- angajator', 'Acc. Munca '+@pFaambp
	from #sume a 
	union all 
	select '432', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1043201'+rtrim(@cNumar_evidenta), isnull(cass_indiv,0), 0, isnull(cass_indiv,0), 0, 
		'CAS Sanatate - asigurati', 'Sanatate asigurati '+@pCASSind
	from #sume a 
	union all 
	select '431', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1043101'+rtrim(@cNumar_evidenta), isnull(cass_unit,0), 0, isnull(cass_unit,0), 0, 
		'CAS Sanatate - angajator', 'Sanatate angajator '+@pCASSunit
	from #sume a 
	union all 
	select '438', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1043801'+rtrim(@cNumar_evidenta), cass_unit_faambp, 0, cass_unit_faambp, 0, 
		'CAS Sanatate - angajator pt. Fambp', 'Sanatate angajator pt. Fambp'+@pCASSunit
	from #sume a where cass_unit_faambp<>0
	union all 
	select '448', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1044801'+rtrim(@cNumar_evidenta), cass_faambp, 0, cass_faambp, 0, 
		'CAS Sanatate - din Fambp', 'Sanatate suportata de Fambp'+@pCASSunit
	from #sume a where cass_faambp<>0
	union all 
	select '439', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1043901'+rtrim(@cNumar_evidenta), isnull(CCI,0), dbo.valoare_minima(isnull(CCI,0),isnull(CCI_ded,0),isnull(@CCI_ded,0)), 
		(case when isnull(CCI,0)>isnull(CCI_ded,0) then isnull(CCI,0)-isnull(CCI_ded,0) else 0 end), 0, 
		'Contrib.pt.concedii si indemnizatii - angajator','CCI '+@pCCI
	from #sume a 
	union all 
	select '422', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1042201'+rtrim(@cNumar_evidenta), isnull(somaj_indiv,0), 0, isnull(somaj_indiv,0), 0, 
		'CA somaj individ. - asigurati', 'Somaj '+@pSomajInd
	from #sume a 
	union all 
	select '421', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1042101'+rtrim(@cNumar_evidenta), isnull(somaj_unit,0), dbo.valoare_minima(isnull(somaj_unit,0),isnull(somaj_unit_ded,0), 
		isnull(@somaj_ded,0)), (case when isnull(somaj_unit,0)>isnull(somaj_unit_ded,0) then isnull(somaj_unit,0)-isnull(somaj_unit_ded,0) else 0 end), 0, 
		'CA somaj - angajator', 'Somaj '+@pSomajUnit
	from #sume a 
--	acesta cod (424) s-a desfintat incepand cu luna iulie 2012, dar ramine de completat pt. declaratiile rectificative anterioare
	union all 
	select '424', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1042401'+rtrim(@cNumar_evidenta), somaj_indiv_alte, 0, somaj_indiv_alte, 0, 
		'CA somaj individ. - alti asigurati', 'Somaj '+@pSomajInd
	from #sume a where somaj_indiv_alte<>0 and @dataJos<'07/01/2012'
	union all 
	select '423', @Cod_declaratie_102, '',@dataSus,'5502XXXXXX','1042301'+rtrim(@cNumar_evidenta), isnull(Fond_garantare,0), 0, isnull(Fond_garantare,0),0, 
		'Contrib.la Fd.de garantare pt.plata creantelor salariale - angajator', 'Fond garantare '+@pFondGar
	from #sume a where (@InstPubl=0 or fond_garantare<>0)
	union all
	select '611', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1061101'+rtrim(@cNumar_evidenta), impozit_dac, 0, impozit_dac, 0, 
		'Imp.pe. ven. din drepturi de autor', 'Impozit 16%'
	from #sume a where impozit_dac<>0
	union all
	select '616', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1061601'+rtrim(@cNumar_evidenta), impozit_ccc, 0, impozit_ccc, 0, 
		'Imp.pe. ven. din conventii civile', 'Impozit 16%'
	from #sume a where impozit_ccc<>0
	union all
	select '615', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1061501'+rtrim(@cNumar_evidenta), impozit_ect, 0, impozit_ect, 0, 
		'Imp.pe. ven. din expertiza contabila si tehnica', 'Impozit 16%'
	from #sume a where impozit_ect<>0
--	contributiile de mai jos se declara incepand cu luna iulie 2012
	union all
	select '613', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1061301'+rtrim(@cNumar_evidenta), impozit_activ_agricole, 0, impozit_activ_agricole, 0, 
		'Imp.pe. ven. din activitati agricole', 'Impozit 16%'
	from #sume a where impozit_activ_agricole<>0 and @dataJos>='07/01/2012' and @dataJos<'07/01/2013'
	union all 
	select '451', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1045101'+rtrim(@cNumar_evidenta), cas_dpi, 0, cas_dpi, 0, 
		'CAS individ. - drepturi de proprietate intelectuala', 'CAS individual pt. drepturi de proprietate intelectuala '+ @pCASind
	from #sume a where cas_dpi<>0 and @dataJos>='07/01/2012'
	union all 
	select '461', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1046101'+rtrim(@cNumar_evidenta), cass_dpi, 0, cass_dpi, 0, 
		'CAS Sanatate - drepturi de proprietate intelectuala', 'Sanatate pt. drepturi de proprietate intelectuala '+ @pCASSind
	from #sume a where cass_dpi<>0 and @dataJos>='07/01/2012'
	union all 
	select '452', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1045201'+rtrim(@cNumar_evidenta), cas_ccc, 0, cas_ccc, 0, 
		'CAS individ. - contracte/conventii civile', 'CAS individual pt. contracte/conventii civile '+ @pCASind
	from #sume a where cas_ccc<>0 and @dataJos>='07/01/2012'
	union all 
	select '453', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1045301'+rtrim(@cNumar_evidenta), cas_ect, 0, cas_ect, 0, 
		'CAS individ. - expertiza contabila si tehnica', 'CAS individ. - expertiza contabila si tehnica '+ @pCASind
	from #sume a where cas_ect<>0 and @dataJos>='07/01/2012'
	union all 
	select '462', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1046201'+rtrim(@cNumar_evidenta), cass_ccc, 0, cass_ccc, 0, 
		'CAS Sanatate - contracte-conventii civile', 'Sanatate pt. contracte/conventii civile '+ @pCASSind
	from #sume a where cass_ccc<>0 and @dataJos>='07/01/2012'
	union all 
	select '463', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1046301'+rtrim(@cNumar_evidenta), cass_ect, 0, cass_ect, 0, 
		'CAS Sanatate - expertiza contabila si tehnica', 'Sanatate pt. expertiza contabila si tehnica '+ @pCASSind
	from #sume a where cass_ect<>0 and @dataJos>='07/01/2012'
	union all 
	select '466', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1046601'+rtrim(@cNumar_evidenta), cass_activ_agricole, 0, cass_activ_agricole, 0, 
		'CAS Sanatate - activitati agricole', 'Sanatate pt. activitati agricole '+ @pCASSind
	from #sume a where cass_activ_agricole<>0 and @dataJos>='07/01/2012' and @dataJos<'07/01/2013'
--	contributiile de mai jos se declara incepand cu luna ianuarie 2014. Nu stim inca daca clientii nostrii au acest caz
	union all
	select '619', @Cod_declaratie_100, @lm, @dataSus, '20470101XX', '1061901'+rtrim(@cNumar_evidenta), impozit_activ_agricole, 0, impozit_activ_agricole, 0, 
		'Imp.pe. ven. din arendare bunuri agricole', 'Impozit 16%'
	from #sume a where impozit_activ_agricole<>0 and @dataJos>='01/01/2014'
	union all 
	select '469', @Cod_declaratie_102, '', @dataSus, '5502XXXXXX', '1046901'+rtrim(@cNumar_evidenta), cass_activ_agricole, 0, cass_activ_agricole, 0, 
		'CAS Sanatate - activitati agricole', 'Sanatate pt. venituri din arendare bunuri agricole '+ @pCASSind
	from #sume a where cass_activ_agricole<>0 and @dataJos>='01/01/2014'

	update #Sume_contributii set Numar_evidenta_platii=rtrim(Numar_evidenta_platii)+
		(case when Cod_contributie in ('602','611','616','613','619','810') then '1' else '2' end)+'000'
	update #Sume_contributii set Numar_evidenta_platii=rtrim(Numar_evidenta_platii)+
		right(rtrim(convert(char(10),dbo.fSuma_cifrelor(Numar_evidenta_platii))),2)

	select Cod_contributie, Cod_declaratie, Punct_de_lucru, Data, 
		Cod_bugetar, Numar_evidenta_platii, Suma_datorata, Suma_deductibila, 
		Suma_de_plata, Suma_de_recuperat, Explicatii, Notatie
	from #sume_contributii	

	return
end

/*
	exec Declaratia112CodObligatie '11/01/2012', '11/30/2012', '12/25/2012', '112', '', 'ZZZ', '4478', '4471'
*/
