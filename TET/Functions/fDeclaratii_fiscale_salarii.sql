--***
/**	functie declaratii fiscale salarii */
Create 
function [dbo].[fDeclaratii_fiscale_salarii] 
	(@DataJos datetime, @DataSus datetime, @Data_scadentei datetime, @Cod_declaratie char(20), @pLmjos char(20), @pLmsus char(20))
returns @Sume_contributii table 
	(Cod_contributie char(20), Cod_declaratie char(20), Punct_de_lucru char(20), Data datetime, Cod_bugetar char(20), 
	Numar_evidenta_platii char(40), Suma_datorata decimal(10), Suma_deductibila decimal(10), Suma_de_plata decimal(10), Suma_de_recuperat decimal(10), 
	Explicatii char(200), Notatie char(100))
as
begin
	declare @sume table 
	(DataJos datetime, DataSus datetime, Impozit float, CASI float, CASSI float, SomajI float, CASU float, CASU_ded float, CASSU float, 
	SomajU float, SomajU_ded float, FAMBP float, FAMBP_ded float, CCI float, CCI_ded float, Fond_garantare float, 
	CASIAlte decimal(7), SomajIAlte decimal(7), ImpozitDAC decimal(10), ImpozitCCC decimal(10), CassAngFambp float, CassFambp float, Locm char(20)) 

	declare @InstPubl int, @Judet char(25), @pCASind char(10), @pCASunit char(10), @pFaambp char(10), 
	@pCASSind char(10), @pCASSunit char(10), @pCCI char(10), @pSomajInd char(10), @pSomajUnit char(10), @pFondGar char(10), 
	@cNumar_evidenta char(100), @Somaj_ded float, @CCI_ded float, @Fambp_ded float, @lCNPH int, @Cod_declaratie_100 char(20), 
	@Cod_declaratie_102 char(20), @CASIAlte decimal(7), @SomajIAlte decimal(7), @ImpozitDAC decimal(10), @ImpozitCCC decimal(10),
	@AjDecesUnit int, @Cotiz_hand decimal(10), @ImpozitZilieri decimal(10)

	Set @InstPubl=dbo.iauParL('PS','INSTPUBL')
	Set @pCASind=ltrim(str(dbo.iauParLN(@datasus,'PS','CASINDIV'),4,2))+'%'
	Set @pCASunit=ltrim(str(dbo.iauParLN(@datasus,'PS','CASGRUPA3')-dbo.iauParLN(@datasus,'PS','CASINDIV'),4,1))+'%'
	Set @pFaambp=ltrim(str(dbo.iauParLN(@datasus,'PS','0.5%ACCM'),4,2))+'%'
	Set @pCASSind=ltrim(str(dbo.iauParLN(@datasus,'PS','CASSIND'),4,2))+'%'
	Set @pCASSunit=ltrim(str(dbo.iauParLN(@datasus,'PS','CASSUNIT'),4,2))+'%'
	Set @pCCI=ltrim(str(dbo.iauParLN(@datasus,'PS','COTACCI'),4,2))+'%'
	Set @pSomajInd=ltrim(str(dbo.iauParLN(@datasus,'PS','SOMAJIND'),4,2))+'%'
	Set @pSomajUnit=ltrim(str(dbo.iauParLN(@datasus,'PS','3.5%SOMAJ'),4,2))+'%'
	Set @pFondGar=ltrim(str(dbo.iauParLN(@datasus,'PS','FONDGAR'),4,2))+'%'
	Set @AjDecesUnit=dbo.iauParL('PS','AJDUNIT-R')
	Set @Judet=dbo.iauParA('PS','JUDET')
	Set @lCNPH=dbo.iauParL('PS','NC-CPHAND')
	Set @cNumar_evidenta=(case when month(@DataSus)<10 then '0' else '' end)+rtrim(convert(char(2),month(@DataSus)))+ right(convert(char(4),year(@DataSus)),2)+'25'+(case when month(@Data_scadentei)<10 then '0' else '' end)+ rtrim(convert(char(2),month(@Data_scadentei)))+right(convert(char(4),year(@Data_scadentei)),2)
	Set @Cod_declaratie_100=(case when @Cod_declaratie<>'' then @Cod_declaratie else 100 end) 
	Set @Cod_declaratie_102=(case when @Cod_declaratie<>'' then @Cod_declaratie else 102 end) 
	Set @ImpozitZilieri=0

	select @CASIAlte=sum(isnull(n.pensie_suplimentara_3,0)), @SomajIAlte=sum(isnull(n.Somaj_1,0)),
		@ImpozitDAC=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='DAC' then n.Impozit else 0 end),0)),
		@ImpozitCCC=sum(isnull((case when i.Grupa_de_munca='O' and i.Tip_colab='CCC' then n.Impozit else 0 end),0))
	from net n
		left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
	where n.data=@DataSus and i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC')
	select @Cotiz_hand=isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
		and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
		and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @DataJos and @DataSus),0)

	if exists (select * from sysobjects where name ='SalariiZilieri')
		select @ImpozitZilieri=isnull(sum(Impozit),0) from SalariiZilieri  where Data between @DataJos and @DataSus

	insert into @sume
	select @DataJos, @DataSus, sum(n.Impozit+n.Diferenta_impozit)-max(isnull(@ImpozitDAC,0))-max(isnull(@ImpozitCCC,0)), 
		sum(n.Pensie_suplimentara_3)-max(isnull(@CASIAlte,0)) as CASI, sum(n.Asig_sanatate_din_net) as CASSI, 
		sum(n.Somaj_1)-max(isnull(@SomajIAlte,0)) as SomajI, round(sum(n.CAS+isnull(n1.CAS,0)),0) as CASU, sum((case when @AjDecesUnit=1 then 0 else b.Aj_deces end)) as CASU_ded, 
		sum(n.Asig_sanatate_pl_unitate) as CASSU, round(sum(n.Somaj_5),0) as SomajU, 
		sum((case when (p.coef_invalid=2 or p.coef_invalid=3 or p.coef_invalid=4) then n.chelt_prof else 0 end)
		+(case when p.coef_invalid=1 then n.chelt_prof else 0 end)+(case when p.coef_invalid=7 then n.chelt_prof else 0 end))
		+round(sum(isnull(ss.Scutire_art80,0)),0)+round(sum(isnull(ss.Scutire_art85,0)),0) as SomajU_ded,
		round(sum(n.Fond_de_risc_1),0) as FAMBP, sum(n.Asig_sanatate_din_impozit+b.CMFAMBP+n1.Ded_suplim) as FAMBP_ded, 
		round(sum(n.Ded_suplim+n1.Ded_suplim),0) as CCI, round(sum(b.Ind_c_medical_cas+b.CMCAS),0) as CCI_ded, round(sum(n1.Somaj_5),0) as Fond_garantare, 
		max(isnull(@CASIAlte,0)), max(isnull(@SomajIAlte,0)), max(isnull(@ImpozitDAC,0)), max(isnull(@ImpozitCCC,0)), 
		sum(n1.Asig_sanatate_din_impozit) as CassAngFambp, sum(n.Asig_sanatate_din_impozit) as CassFambp, 
		(case when @pLmjos='' then 'Unitate' else '' end) as Locm
	from net n 
		left outer join personal p on p.Marca=n.Marca
		left outer join net n1 on n1.Data=dbo.bom(n.Data) and n1.Marca=n.Marca
		left outer join (select Data, Marca, sum(Ind_c_medical_unitate) as Ind_c_medical_unitate, sum(Ind_c_medical_CAS) as Ind_c_medical_CAS, 
		sum(CMCAS) as CMCAS, sum(Spor_cond_9) as CMFAMBP, sum(Compensatie) as Aj_Deces from brut where Data=@DataSus group by Data, Marca) b on b.Data=n.Data and b.Marca=n.Marca
		left outer join dbo.fScutiriSomaj (@DataJos, @DataSus, '', 'ZZZ', @pLmJos, @pLmSus) ss on ss.data=n.data and ss.marca=n.marca
	where n.Data=@DataSus
	update @sume set Impozit=Impozit+@ImpozitZilieri where @ImpozitZilieri<>0

	insert into @Sume_contributii
	select '602', @Cod_declaratie_100, @pLmjos, @DataSus, '20470101XX', '1060201'+rtrim(@cNumar_evidenta), Impozit, 0, Impozit, 0, 
		'Imp.pe. ven. din salarii','Impozit 16%' 
	from @sume a where Impozit is not NULL
	union all 
	select '810', @Cod_declaratie_100, @pLmjos, @DataSus, '20470101XX', '1081001'+rtrim(@cNumar_evidenta),@Cotiz_hand,0,@Cotiz_hand,0, 
		'Varsam.de la PJ pt.pers.cu handicap neincadrate - angajator','CNPH'
	from @sume a 
	where @lCNPH=1 and @Cotiz_hand is not NULL
	union all 
	select '412', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1041201'+rtrim(@cNumar_evidenta), isnull(CASI,0), 0, isnull(CASI,0), 0, 
		'CAS individ. - asigurati', 'CAS individual '+ @pCASind
	from @sume a where Locm='Unitate'
	union all 
	select '411', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1041101'+rtrim(@cNumar_evidenta), isnull(CASU,0), dbo.valoare_minima(isnull(CASU,0),isnull(CASU_ded,0),isnull(CASU_ded,0)), (case when isnull(CASU,0)>isnull(CASU_ded,0) then isnull(CASU,0)-isnull(CASU_ded,0) else 0 end), 0,
		'CAS - angajator','CAS '+@pCASunit
	from @sume a where Locm='Unitate'
	union all 
	select '419', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1041901'+rtrim(@cNumar_evidenta), CASIAlte, 0, CASIAlte, 0, 
		'CAS individ. - alti asigurati', 'CAS individual '+ @pCASind
	from @sume a where Locm='Unitate' and CASIAlte<>0
	union all 
	select '416', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1041601'+rtrim(@cNumar_evidenta), isnull(Fambp,0), dbo.valoare_minima(isnull(Fambp,0),isnull(Fambp_ded,0),isnull(@Fambp_ded,0)), (case when isnull(Fambp,0)>isnull(Fambp_ded,0) then isnull(Fambp,0)-isnull(Fambp_ded,0) else 0 end), 0, 
		'CA pt. accid.de munca si boli prof.- angajator', 'Acc. Munca '+@pFaambp
	from @sume a where Locm='Unitate'
	union all 
	select '432', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1043201'+rtrim(@cNumar_evidenta), isnull(CASSI,0), 0, isnull(CASSI,0), 0, 
		'CAS Sanatate - asigurati', 'Sanatate asigurati '+@pCASSind
	from @sume a where Locm='Unitate'
	union all 
	select '431', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1043101'+rtrim(@cNumar_evidenta), isnull(CASSU,0), 0, isnull(CASSU,0), 0, 
		'CAS Sanatate - angajator', 'Sanatate angajator '+@pCASSunit
	from @sume a where Locm='Unitate'
	union all 
	select '438', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1043801'+rtrim(@cNumar_evidenta), CassAngFambp, 0, CassAngFambp, 0, 
		'CAS Sanatate - angajator pt. Fambp', 'Sanatate angajator pt. Fambp'+@pCASSunit
	from @sume a where Locm='Unitate' and CassAngFambp<>0
	union all 
	select '448', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1044801'+rtrim(@cNumar_evidenta), CassFambp, 0, CassFambp, 0, 
		'CAS Sanatate - din Fambp', 'Sanatate suportata de Fambp'+@pCASSunit
	from @sume a where Locm='Unitate' and CassFambp<>0
	union all 
	select '439', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1043901'+rtrim(@cNumar_evidenta), isnull(CCI,0), dbo.valoare_minima(isnull(CCI,0),isnull(CCI_ded,0),isnull(@CCI_ded,0)), (case when isnull(CCI,0)>isnull(CCI_ded,0) then isnull(CCI,0)-isnull(CCI_ded,0) else 0 end), 0, 
		'Contrib.pt.concedii si indemnizatii - angajator','CCI '+@pCCI
	from @sume a where Locm='Unitate'
	union all 
	select '422', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1042201'+rtrim(@cNumar_evidenta), isnull(SomajI,0), 0, isnull(SomajI,0), 0, 
		'CA somaj individ. - asigurati', 'Somaj '+@pSomajInd
	from @sume a where Locm='Unitate'
	union all 
	select '421', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1042101'+rtrim(@cNumar_evidenta), isnull(SomajU,0), dbo.valoare_minima(isnull(SomajU,0),isnull(SomajU_ded,0),isnull(@Somaj_ded,0)), (case when isnull(SomajU,0)>isnull(SomajU_ded,0) then isnull(SomajU,0)-isnull(SomajU_ded,0) else 0 end), 0, 
		'CA somaj - angajator', 'Somaj '+@pSomajUnit
	from @sume a where Locm='Unitate'
	union all 
	select '424', @Cod_declaratie_102, '', @DataSus, '5502XXXXXX', '1042401'+rtrim(@cNumar_evidenta), SomajIAlte, 0, SomajIAlte, 0, 
		'CA somaj individ. - alti asigurati', 'Somaj '+@pSomajInd
	from @sume a where Locm='Unitate' and SomajIAlte<>0
	union all 
	select '423', @Cod_declaratie_102, '',@DataSus,'5502XXXXXX','1042301'+rtrim(@cNumar_evidenta), isnull(Fond_garantare,0), 0, isnull(Fond_garantare,0),0, 
		'Contrib.la Fd.de garantare pt.plata creantelor salariale - angajator', 'Fond garantare '+@pFondGar
	from @sume a where Locm='Unitate' and (@InstPubl=0 or Fond_garantare<>0)
	union all
	select '611', @Cod_declaratie_100, @pLmjos, @DataSus, '20470101XX', '1061101'+rtrim(@cNumar_evidenta), ImpozitDAC, 0, ImpozitDAC, 0, 
		'Imp.pe. ven. din drepturi de autor', 'Impozit 16%'
	from @sume a where ImpozitDAC<>0
	union all
	select '616', @Cod_declaratie_100, @pLmjos, @DataSus, '20470101XX', '1061601'+rtrim(@cNumar_evidenta), ImpozitCCC, 0, ImpozitCCC, 0, 
		'Imp.pe. ven. din conventii civile', 'Impozit 16%'
	from @sume a where ImpozitCCC<>0

	update @Sume_contributii Set Numar_evidenta_platii=rtrim(Numar_evidenta_platii)+
		(case when Cod_contributie in ('602','611','616','810') then '1' else '2' end)+'000'
	update @Sume_contributii Set Numar_evidenta_platii=rtrim(Numar_evidenta_platii)+
		right(rtrim(convert(char(10),dbo.fSuma_cifrelor(Numar_evidenta_platii))),2)

	return
end

/*
select * from fDeclaratii_fiscale_salarii ('01/01/2011', '01/31/2011', '02/25/2011', '112', '', 'ZZZ')
*/
