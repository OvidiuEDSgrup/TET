--***
Create function wfIaDLConcedii 
	(@sesiune varchar(50), @parXML xml)
returns @wIaConcedii table (Data varchar(10), Marca varchar(6), Nume varchar(50), numar_pozitie int, subtip varchar(2), tip varchar(2), 
	denumire varchar(40), nrdoc varchar(10), tipconcediu varchar(2), denconcediu varchar(30), 
	datainceput varchar(10), orainceput varchar(10), datasfarsit varchar(10), orasfarsit varchar(10), 
	cantitate int, valoare decimal(12,2), zileunitate int, zilecas int, indunitate decimal(12,2), indcas decimal(12,2), 
	seriecm varchar(5), numarcm varchar(10), cminitial varchar(15), dencminitial varchar(50), 
	coddiagnostic varchar(10), codurgenta varchar(10), codgrupaa varchar(10), 
	dataacordarii varchar(10), cnpcopil varchar(13), locprescriere int, medicprescriptor varchar(50), unitatesanitara varchar(50), nravizme varchar(10),
	mediazilnica decimal(10,4), procent decimal(10,2), bazastagiu decimal(10), zilestagiu int, calculmanual int, Numar_curent int, 
	lm varchar(9), denlm varchar(30), comanda varchar(20), dencomanda varchar(50),
	zileco int, indemnizatieco decimal(10), indnetaco decimal(10), dataoperarii datetime, zileconalte int, oreconalte int)
As
Begin
	declare @userASiS varchar(10), @tip varchar(2), @subtip varchar(2), @data datetime, @datajos datetime, 
	@datasus datetime, @Marca varchar(6), @sub varchar(9)
	Set @userASiS=dbo.wfIaUtilizator(@sesiune)

	select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)') 
	from @parXML.nodes('row') as xA(row)
	set @datajos=dbo.bom(@data)
	set @datasus=dbo.eom(@data)
	set @sub=dbo.iauParA('GE','SUBPRO')

	insert into @wIaConcedii
	select 
	convert(char(10),@datasus,101) as data, cm.marca as marca,  p.nume as nume, 
	7 as numarpozitie, (case when @tip='SL' then 'M1' else 'M2' end) as subtip, @tip as tip, 'Medical' as denumire, 
	'' as nrdoc,
	rtrim(cm.Tip_diagnostic) as tipconcediu, rtrim(d.Denumire) as denconcediu, 
	convert(char(10),cm.data_inceput,101) as datainceput, '' as orainceput, convert(char(10),cm.data_sfarsit,101) as datasfarsit, '' as orasfarsit, 
	cm.Zile_lucratoare as cantitate, convert(decimal(12,2),cm.Indemnizatie_unitate+cm.Indemnizatie_CAS) as valoare, 
	cm.Zile_cu_reducere as zileunitate, cm.Zile_lucratoare-cm.Zile_cu_reducere as zilecas, 
	convert(decimal(12,2),cm.Indemnizatie_unitate) as indunitate, convert(decimal(12,2),cm.Indemnizatie_CAS) as indcas, 
	i.Serie_certificat_CM as seriecm, i.Nr_certificat_CM as numarcm, 
	rtrim(rtrim(i.Serie_certificat_CM_initial)+' '+rtrim(i.Nr_certificat_CM_initial)) as cminitial, 
	rtrim(rtrim(i.Serie_certificat_CM_initial)+' '+rtrim(i.Nr_certificat_CM_initial)+' '+
	(case when rtrim(i.Nr_certificat_CM_initial)<>'' then rtrim(d.Denumire) else '' end)) as dencminitial, 
	i.Alfa as coddiagnostic, i.Cod_urgenta as codurgenta, i.Cod_boala_grpA as codgrupaa, 
	convert(char(10),i.Data_acordarii,101) as dataacordarii, i.Cnp_copil as cnpcopil, i.Loc_prescriere as locprescriere, i.Medic_prescriptor as medicprescriptor, 
	i.Unitate_sanitara as unitatesanitara, i.Nr_aviz_me as nravizme, convert(decimal(10,3),cm.Indemnizatia_zi) as mediazilnica, convert(decimal(10,2),cm.Procent_aplicat) as procent, 
	isnull((select Baza_Stagiu from dbo.stagiu_cm (cm.Data, cm.Marca, cm.Data_inceput, dbo.data_inceput_cm(cm.Data, cm.marca, cm.Data_inceput, 1), (case when cm.Zile_luna_anterioara>0 or i.Serie_certificat_cm_initial<>'' then 1 else 0 end), 6)),0) as bazastagiu, 
	isnull((select Zile_Stagiu from dbo.stagiu_cm (cm.Data, cm.Marca, cm.Data_inceput, dbo.data_inceput_cm(cm.Data, cm.marca, cm.Data_inceput, 1), (case when cm.Zile_luna_anterioara>0 or i.Serie_certificat_cm_initial<>'' then 1 else 0 end), 6)),0) as zilestagiu, 
	cm.Indemnizatii_calc_manual as calculmanual, 
	Null as nrcrt, isnull(po.loc_de_munca,ip.Loc_de_munca) as lm, lm.denumire as denlm, po.comanda as comanda, c.descriere as dencomanda,
	Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataoperarii, Null as zileconalte, Null as oreconalte
	from conmed cm
		left outer join infoconmed i on cm.Data=i.Data and cm.Marca=i.Marca and cm.Data_inceput=i.Data_inceput
		left outer join dbo.fDiagnostic_CM() d on cm.tip_diagnostic=d.Tip_diagnostic
		left outer join (select a.marca, max(a.loc_de_munca) as loc_de_munca, max(isnull(b.comanda,'')) as comanda from pontaj a
		left outer join realcom b on a.data=b.data and a.marca=b.marca and a.loc_de_munca=b.loc_de_munca and a.numar_curent=substring(b.numar_document,3,10) where a.data between @datajos and @datasus and a.ore_concediu_medical<>0  group by a.marca) po on cm.marca=po.marca
		left outer join istpers ip on ip.Data=cm.Data and ip.Marca=cm.Marca 
		left outer join lm on lm.cod=isnull(po.loc_de_munca,ip.Loc_de_munca)
		left outer join comenzi c on c.subunitate=@sub and c.comanda=po.comanda
		left outer join personal p on p.marca=cm.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and isnull(ip.Loc_de_munca,p.Loc_de_munca)=lu.cod
		,@parXML.nodes('row') as xA(row)
	where cm.data between @datajos and @datasus
		and (@tip='ME' and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) or @tip='SL' and cm.marca=xA.row.value('@marca','varchar(6)'))
	union all
	select 
	convert(char(10),@datasus,101) as data, co.marca as marca,  p.nume as nume, 
	9 as numarpozitie, (case when @tip='SL' then 'O1' else 'O2' end) as subtip, @tip as tip, 'CO' as denumire, 
	'' as nrdoc, rtrim(co.Tip_concediu) as tipconcediu, rtrim(f.Denumire) as denconcediu, 
	convert(char(10),co.data_inceput,101) as datainceput, '' as orainceput, convert(char(10),co.data_sfarsit,101) as datasfarsit, '' as orasfarsit, 
	co.Zile_CO as cantitate, convert(decimal(12,2),co.Indemnizatie_CO) as valoare, 
	Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas,
	Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, 
	Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, Null as dataacordarii, 
	Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
	Null as nravizme, Null as mediazilnica, Null as procent, Null as bazastagiu, Null as zilestagiu, co.Introd_manual as calculmanual, 
	Null as nrcrt, isnull(po.loc_de_munca,i.Loc_de_munca) as lm, lm.denumire as denlm, po.comanda as comanda, c.descriere as dencomanda,
	co.Zile_CO as zileco, convert(decimal(12,2),co.Indemnizatie_CO) as indemnizatieco, isnull(convert(decimal(12,2),cn.Indemnizatie_CO),0) as indnetaco, 
	convert(char(10),DateAdd(day,co.Prima_vacanta-693961,'01/01/1901'),101) as dataoperarii, 
	Null as zileconalte, Null as oreconalte
	from concodih co
		left outer join fTip_CO() f on co.Tip_concediu=f.Tip_concediu
		left outer join (select a.marca, max(a.loc_de_munca) as loc_de_munca, max(isnull(b.comanda,'')) as comanda 
			from pontaj a
			left outer join realcom b on a.data=b.data and a.marca=b.marca and a.loc_de_munca=b.loc_de_munca and a.numar_curent=substring(b.numar_document,3,10) 
			where a.data between @datajos and @datasus and (a.ore_concediu_de_odihna<>0 or a.Ore_obligatii_cetatenesti<>0) group by a.marca) po on co.marca=po.marca
		left outer join istpers i on i.Data=co.Data and i.Marca=co.Marca 
		left outer join lm on lm.cod=isnull(po.loc_de_munca,i.Loc_de_munca)
		left outer join comenzi c on c.subunitate=@sub and c.comanda=po.comanda
		left outer join personal p on p.marca=co.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and isnull(i.Loc_de_munca,p.Loc_de_munca)=lu.cod
		left outer join concodih cn on cn.Data=co.Data and cn.marca=co.marca and cn.Data_inceput=co.Data_inceput and cn.Tip_concediu='9'
		,@parXML.nodes('row') as xA(row)
	where co.data between @datajos and @datasus and co.tip_concediu not in ('9','C','P','V')
		and (@tip='OD' and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
		or @tip='SL' and co.marca=xA.row.value('@marca','varchar(6)'))
	union all
	select 
	convert(char(10),@datasus,101) as data, ca.marca as marca,  p.nume as nume, 
	9 as numarpozitie, (case when @tip='SL' then 'E1' else 'E2' end) as subtip, @tip as tip, 'CA' as denumire, 
	'' as nrdoc, rtrim(ca.Tip_concediu) as tipconcediu, rtrim(f.Denumire) as denconcediu, 
	convert(char(10),ca.data_inceput,101) as datainceput, (case when ca.Tip_concediu in ('2','3') then left(convert(char(10),ca.data_inceput,108),5) else '' end) as orainceput, 
	convert(char(10),ca.data_sfarsit,101) as datasfarsit, (case when ca.Tip_concediu in ('2','3') then left(convert(char(10),ca.data_sfarsit,108),5) else '' end) as orasfarsit, 
	ca.Zile as cantitate, 0 as valoare, 
	Null as zileunitate, Null as zilecas, Null as indunitate, Null as indcas,
	Null as seriecm, Null as numarcm, Null as cminitial, Null as dencminitial, 
	Null as coddiagnostic, Null as codurgenta, Null as codgrupaa, Null as dataacordarii, 
	Null as cnpcopil, Null as locprescriere, Null as medicprescriptor, Null as unitatesanitara, 
	Null as nravizme, Null as mediazilnica, Null as procent, Null as bazastagiu, Null as zilestagiu, Null as calculmanual, 
	Null as nrcrt, isnull(po.loc_de_munca,i.Loc_de_munca) as lm, lm.denumire as denlm, po.comanda as comanda, c.descriere as dencomanda,
	Null as zileco, Null as indemnizatieco, Null as indnetaco, Null as dataoperarii, ca.Zile as zileconalte, indemnizatie as oreconalte
	from conalte ca
		left outer join fTip_ConcediiAlte() f on ca.Tip_concediu=f.Tip_concediu
		left outer join (select a.marca, max(a.loc_de_munca) as loc_de_munca, max(isnull(b.comanda,'')) as comanda 
			from pontaj a
			left outer join realcom b on a.data=b.data and a.marca=b.marca and a.loc_de_munca=b.loc_de_munca and a.numar_curent=substring(b.numar_document,3,10) 
			where a.data between @datajos and @datasus and (a.ore_concediu_fara_salar<>0 or a.ore_nemotivate<>0 or a.spor_cond_10<>0) group by a.marca) po on ca.marca=po.marca
		left outer join istpers i on i.Data=ca.Data and i.Marca=ca.Marca 
		left outer join lm on lm.cod=isnull(po.loc_de_munca,i.Loc_de_munca)
		left outer join comenzi c on c.subunitate=@sub and c.comanda=po.comanda
		left outer join personal p on p.marca=ca.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
		,@parXML.nodes('row') as xA(row)
	where ca.data between @datajos and @datasus 
		and (@tip='CA' and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
		or @tip='SL' and ca.marca=xA.row.value('@marca','varchar(6)'))
	return
End
