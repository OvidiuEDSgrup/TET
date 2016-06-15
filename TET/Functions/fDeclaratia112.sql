--***
Create
function [dbo].[fDeclaratia112] (@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @Lm char(9), @Strict int, @unSirMarci int, @SirMarci char(200), @TagAsigurat char(20))
returns @datedecl table 
	(Data datetime, TagAsigurat char(20), Marca char(6), Nume char(50), CNP char(13), Tip_asigurat int, Pensionar int, Tip_contract char(2), 
	Data_angajarii datetime, Total_zile int, Zile_CN int, Zile_CD int, Zile_CS int, TV decimal (10), TVN decimal (10), TVD decimal (10), TVS decimal (10), 
	Ore_norma int, IND_CS int, NRZ_CFP int, Norma_luna int,
	Zile_lucrate int, Ore_lucrate int, Zile_suspendate int, Ore_suspendate int, OreSST int, ZileSST int, BazaST int, 
	Venit_total decimal(10), Venit_fara_CM decimal(10), Baza_CAS decimal(10), CAS_individual decimal (10), 
	Baza_somaj decimal(10), Somaj_individual decimal(7), Baza_CASS decimal(10), CASS_individual decimal(7), Baza_FG decimal(10), Regim_de_lucru float)
as
begin
	declare @Bugetari int, @InstPubl int, @Elite int, @Somesana int, @Pasmatex int, @Salubris int, @Colas int, 
	@STOUG28 int, @vSTOUG28 int, @IT2SuspContr int , @ScadOSRN int, @ScadO100RN int, @NuCAS_H int, @NuCASS_H int, @ASSImpS_K int, 
	@OreLuna int, @pCASIndiv decimal(4,2), @SalMin decimal(7), @SalMediu decimal(7), @Data1_an datetime
	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	set @InstPubl=dbo.iauParL('PS','INSTPUBL')
	set @Elite=dbo.iauParL('SP','ELITE')
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @STOUG28=dbo.iauParLL(@DataS,'PS','STOUG28')
	set @vSTOUG28=(case when @STOUG28=1 and 1=0 then 1 else 0 end)
	Set @IT2SuspContr=dbo.iauParL('PS','PROC2INT')
	set @ScadOSRN=dbo.iauParL('PS','OSNRN')
	set @ScadO100RN=dbo.iauParL('PS','O100NRN')
	set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	set @NuCAS_H=(case when @NuCAS_H=1 and 1=0 then 1 else 0 end)
	set @NuCASS_H=dbo.iauParL('PS','NUASS-H')
	set @ASSImpS_K=dbo.iauParL('PS','ASSIMPS-K')
	set @OreLuna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	set @pCASIndiv=dbo.iauParLN(@DataS,'PS','CASINDIV')
	set @SalMin=dbo.iauParLN(@DataS,'PS','S-MIN-BR')
	set @SalMediu=dbo.iauParLN(@DataS,'PS','SALMBRUT')
	set @Data1_an=dbo.boy(@DataJ)

	--	tabela temporara pt. datele centralizate pe grupe de munca catre BASS 
	declare @pontajGrpM table
	(Data datetime, Marca char(6), Loc_de_munca char(9), Grupa_de_munca char(1), Zile_asigurate decimal(5,2), Zile_CM int)
	insert into @pontajGrpM
	select dbo.eom(a.data) as Data, a.Marca, a.Loc_de_munca, a.Grupa_de_munca, 
	sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+
	(case when @Pasmatex=0 then a.ore_intrerupere_tehnologica+(case when @Elite=0 and @STOUG28=0 then a.ore else 0 end) else 0 end)-@ScadOSRN*(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)
	-@ScadO100RN*(a.ore_spor_100)+(case when @Colas=1 then a.spor_cond_8 else 0 end))/a.regim_de_lucru,2)+
	(case when @Salubris=1 then round((a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3)/a.regim_de_lucru,2) else 0 end)) as Zile_asigurate, 
	sum(a.ore_concediu_medical/a.regim_de_lucru) as Zile_CM
	from pontaj a
		left outer join istpers b on b.Data=@DataS and b.Marca=a.Marca
	where a.data between @DataJ and @DataS and (@oMarca=0 or a.Marca=@Marca) and b.grupa_de_munca<>'O' 
		and (b.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@unSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
	group by dbo.eom(a.data), a.Marca, a.Loc_de_munca, a.grupa_de_munca

	--	tabela temporara pt. datele de somaj centralizate pe marca
	declare @pontajMarca table
		(Data datetime, Marca char(6), RegimLucru decimal(5,2), Zile_lucrate int, Ore_lucrate int, Zile_suspendate int, Ore_suspendate int, 
		OreSST int, ZileSST int, SB int)
	insert into @pontajMarca
	select dbo.eom(a.Data) as Data, a.marca, (case when max(a.Regim_de_lucru)=0 then 8 else max(a.Regim_de_lucru) end), 
	round((sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+ 
	(case when @Pasmatex=0 then a.ore_intrerupere_tehnologica+(case when @Elite=0 and @STOUG28=0 and @IT2SuspContr=0 then a.ore else 0 end) else 0 end)
	+(case when @Colas=1 then a.spor_cond_8 else 0 end)
	-@ScadOSRN*(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)
	-@ScadO100RN*(a.ore_spor_100) +@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3))/a.regim_de_lucru,2,3))),0)
	+max(isnull(cm.ZileCM_angajator,0)) as Zile_lucrate, 
	(sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+ 
	(case when @Pasmatex=0 then a.ore_intrerupere_tehnologica+(case when @Elite=0 and @STOUG28=0 and @IT2SuspContr=0 then a.ore else 0 end) else 0 end)+(case when @Colas=1 then a.spor_cond_8 else 0 end)
	-@ScadOSRN*(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)-@ScadO100RN*(a.ore_spor_100) +@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)),3,3))) 
	+max(isnull(cm.ZileCM_angajator,0))*max(a.regim_de_lucru) as Ore_lucrate, 
	(sum(round((a.ore_concediu_fara_salar+a.ore_nemotivate+a.ore_invoiri+(case when @STOUG28=1 or @IT2SuspContr=1 then a.ore else 0 end))/(case when a.regim_de_lucru=0 then 8 else a.regim_de_lucru end),2)))+
	max(isnull(cm.ZileCM_fonduri,0)) as Zile_suspendate, 
	(sum(round((a.ore_concediu_fara_salar+a.ore_nemotivate+a.ore_invoiri+(case when @STOUG28=1 or @IT2SuspContr=1 then a.ore else 0 end)),3)))+
	max(isnull(cm.ZileCM_fonduri,0)) *max(a.regim_de_lucru) as Ore_suspendate, 
	(case when @STOUG28=1 then sum(a.ore) else 0 end) as OreSST, 
	(case when @STOUG28=1 then sum(a.ore/a.regim_de_lucru) else 0 end) as ZileSST, 
	(case when @STOUG28=1 then round(@SalMin*sum(a.ore/a.regim_de_lucru)/(@OreLuna/8),0) else 0 end) as SB
	from pontaj a
		left outer join net n on n.data=dbo.eom(a.Data) and a.marca=n.marca
		left outer join Personal p on a.marca=p.marca
		left outer join istPers i on i.data=dbo.eom(a.Data) and a.marca=i.marca
		left outer join (select data, marca, sum(Zile_cu_reducere*(case when tip_diagnostic='10' then 0.25 else 1 end)) as ZileCM_angajator, 
		sum((Zile_lucratoare-Zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end)) as ZileCM_fonduri from conmed 
		where data between @DataJ and @DataS group by data, marca) cm on cm.Data=dbo.eom(a.Data) and cm.Marca=a.Marca
		left outer join dbo.fDeclaratia112TagAsigurat (@DataJ, @DataS) ta on dbo.eom(a.Data)=ta.data and a.marca=ta.marca
	where a.data between @DataJ and @DataS and (@oMarca=0 or a.marca=@Marca)  
		and (@Lm='' or i.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@unSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
		and (@TagAsigurat='' or @TagAsigurat like rtrim(ta.TagAsigurat)+'%')
	group by dbo.eom(a.Data), a.Marca
	order by dbo.eom(a.Data), a.Marca

	insert into @datedecl
	select a.Data, ta.TagAsigurat, a.Marca as Marca, a.Nume as Nume, p.cod_numeric_personal as CNP, 
	ta.Tip_asigurat, ta.Pensionar, ta.Tip_contract, p.Data_angajarii_in_unitate, 
	isnull((select round(sum(b.Zile_asigurate+b.Zile_CM),0) from @pontajGrpM b where b.data=a.Data and b.marca=a.marca),0) as TT, 
	isnull((select round(sum(b.Zile_asigurate),0) from @pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='N' and b.marca=a.marca),0) as NN,
	isnull((select round(sum(b.Zile_asigurate),0) from @pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='D' and b.marca=a.marca),0) as DD,
	isnull((select round(sum(b.Zile_asigurate),0) from @pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='S' and b.marca=a.marca),0) as SS,
	isnull((select sum(c.venit_cond_normale+c.venit_cond_deosebite+c.venit_cond_speciale- @NuCAS_H*c.suma_impozabila-(case when i.grupa_de_munca<>'P' then @ASSImpS_K*c.cons_admin else 0 end)-(c.ind_c_medical_unitate+c.ind_c_medical_cas+c.CMCAS+c.CMunitate+ c.spor_cond_9)-@vSTOUG28*round(c.Ind_invoiri,0))
	-max(isnull(pf1.Suma_corectie,0)) 
	from brut c
		left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=c.Data and pf1.Marca=c.Marca and pf1.Loc_de_munca=c.Loc_de_munca
		, istpers i 
	where c.data=@DataS and c.marca=a.marca and c.data=i.data and c.marca=i.marca),0) as TV, 
	isnull((select sum(c.venit_cond_normale) from brut c where c.data=@DataS and c.marca=a.marca),0)-isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+(case when i.grupa_de_munca<>'P' then @ASSImpS_K*g.cons_admin else 0 end)+g.spor_cond_9+@vSTOUG28*round(g.Ind_invoiri,0))
	+max(isnull(pf1.Suma_corectie,0))
	from brut g
		left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=g.Data and pf1.Marca=g.Marca and pf1.Loc_de_munca=g.Loc_de_munca
		left outer join @pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca = f.loc_de_munca and f.grupa_de_munca='N'
		left outer join istpers i on g.data=i.data and g.marca=i.marca
	where g.data=@DataS and g.marca=a.marca and f.grupa_de_munca='N'),0) - isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate+g.spor_cond_9-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+ @vSTOUG28*round(g.Ind_invoiri,0)) from brut g where g.data=@DataS and g.marca=a.marca and a.grupa_de_munca='N' and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @DataJ and @DataS)),0) as TVN, 
	isnull((select sum (c.venit_cond_deosebite) from brut c where c.data=@DataS and c.marca=a.marca),0)-isnull((select sum(g.ind_c_medical_unitate+ g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+g.spor_cond_9+ @vSTOUG28*round(g.Ind_invoiri,0)) 
	+max(isnull(pf1.Suma_corectie,0))
	from brut g 
		left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=g.Data and pf1.Marca=g.Marca and pf1.Loc_de_munca=g.Loc_de_munca
		left outer join @pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca=f.loc_de_munca and f.grupa_de_munca='D' 
	where g.data=@DataS and g.marca=a.marca and f.grupa_de_munca='D'),0) - isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila +@ASSImpS_K*g.cons_admin+g.spor_cond_9+ @vSTOUG28*round(g.Ind_invoiri,0)) from brut g where g.data=@DataS and g.marca=a.marca and a.grupa_de_munca='D' and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @DataJ and @DataS)),0) as TVD, 
	isnull((select sum(c.venit_cond_speciale) from brut c where c.data=@DataS and c.marca=a.marca),0) - isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+g.spor_cond_9+ @vSTOUG28*round(g.Ind_invoiri,0)) 
	+max(isnull(pf.Suma_corectie,0))
	from brut g 
		left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @Marca, @Lm, 1) pf on pf.Data=g.Data and pf.Marca=g.Marca and pf.Loc_de_munca=g.Loc_de_munca
		left outer join @pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca=f.loc_de_munca and f.grupa_de_munca='S'
	where g.data=@DataS and g.marca=a.marca and f.grupa_de_munca='S'),0)-isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate- @NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin +g.spor_cond_9+ @vSTOUG28*round(g.Ind_invoiri,0)) from brut g where g.data=@DataS and g.marca=a.marca and a.grupa_de_munca='S' and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @DataJ and @DataS)),0) as TVS, 
	(case when a.Grupa_de_munca in ('C','O') then 8 else isnull((select (case when max(d.spor_cond_10)>8 or max(d.spor_cond_10)=0 or a.grupa_de_munca='P' then 8 else max(d.spor_cond_10) end) from brut d where d.data=@DataS and d.marca=a.marca),8) end) as NORMA, 
	(case when a.grupa_de_munca='S' then isnull((select top 1 convert(int,val_inf) from extinfop x where x.marca=a.marca and x.cod_inf='INDCS' and x.data_inf<=@DataS order by x.data_inf desc),0) else 0 end) as IND_CS, 0 as NRZ_CFP, 
	round((case when isnull(pm.RegimLucru,0)=0 then 8 else isnull(pm.RegimLucru,0) end)*(case when a.Data<@DataS then (case when dbo.iauParLN(a.Data,'PS','ORE_LUNA')=0 then dbo.Zile_lucratoare(dbo.bom(a.Data),a.Data)*8 else dbo.iauParLN(a.Data,'PS','ORE_LUNA') end) else @OreLuna end)/8,0) as Norma_luna, 
	isnull(pm.Zile_lucrate,0) as Zile_lucrate, isnull(pm.Ore_lucrate,0) as Ore_lucrate, 
	isnull(pm.Zile_suspendate,0) as Zile_suspendate, isnull(pm.Ore_suspendate,0) as Ore_suspendate, 
	isnull(pm.OreSST,0) as OreSST, isnull(pm.ZileSST,0) as ZileSST, isnull(pm.SB,0) as BazaST, 
	b.Venit_total, b.Venit_total-(b.Indemniz_angajator+b.Indemniz_fnuass+b.Indemniz_faambp), 
	n.Baza_CAS, n.pensie_suplimentara_3 - isnull((select round(convert(float,0.35*@SalMediu)*sum(m.zile_lucratoare)/max(m.zile_lucratoare_in_luna)*@pCASIndiv/100,0) from conmed m where year(m.data)>=2006 and m.data=@DataS and m.data_inceput<@DataJ and m.marca=a.marca and (m.tip_diagnostic not in ('2-','3-','4-','0-') and (m.tip_diagnostic<>'10' and m.tip_diagnostic<>'11' or m.suma<>1))),0) as CAS_individual, 
	(case when n.Somaj_1<>0 or n.Asig_sanatate_din_cas<>0 and p.Somaj_1<>0 then n.Asig_sanatate_din_cas else 0 end), n.Somaj_1, 
	(case when n.Asig_sanatate_din_net<>0 or n1.Asig_sanatate_din_net<>0 and p.As_sanatate<>0  then b.venit_total-(b.Indemniz_Fnuass+b.Indemniz_Faambp+b.CMCAS)-1*(b.Indemniz_angajator+b.CMunitate)-@NuCASS_H*b.suma_impozabila-(case when @STOUG28=1 then b.Somaj_tehnic else 0 end) else 0 end) as Baza_CASS, 
	n.Asig_sanatate_din_net, 
	(case when @InstPubl=1 or n1.somaj_5=0 then 0 else n.Asig_sanatate_din_cas end) as Baza_FG, 
	ta.Regim_de_lucru
	from istpers a 
		left outer join dbo.fDeclaratia112TagAsigurat (@DataJ, @DataS) ta on a.data=ta.data and a.marca=ta.marca
		left outer join personal p on a.marca=p.marca 
		left outer join infopers i on i.marca=a.marca 
		inner join net n on n.data=a.data and n.marca=a.marca
		left outer join net n1 on n1.data=dbo.bom(a.data) and n1.marca=a.marca
		left outer join (select data, marca, sum(venit_total) as venit_total, sum(ind_c_medical_unitate) as Indemniz_angajator, 
		sum(ind_c_medical_cas) as Indemniz_fnuass, sum(spor_cond_9) as Indemniz_faambp, sum(Ind_invoiri) as Somaj_tehnic, 
		sum(CMCas) as CMCas, sum(CMunitate) as CMunitate, sum(suma_impozabila) as suma_impozabila, max(spor_cond_10) as RegimL 
		from brut where data=@DataS group by data, marca) b on a.data=b.data and a.marca=b.marca
		left outer join @pontajMarca pm on a.data=pm.data and a.marca=pm.marca 
	where a.data=@DataS and (@oMarca=0 or a.Marca=@Marca) --and (a.grupa_de_munca<>'O' or a.tip_colab in ('DAC','CCC'))
		and (@Lm='' or a.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@unSirMarci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
		and (@TagAsigurat='' or @TagAsigurat like rtrim(ta.TagAsigurat)+'%')
	order by Marca

	update @datedecl set TV=(case when TV<0 then 0 else TV end), 
		TVN=(case when TVN<0 then 0 else TVN end), TVD=(case when TVD<0 then 0 else TVD end), 
		TVS=(case when TVS<0 then 0 else TVS end)
	where (TVN<0 or TVD<0 or TVS<0) and (@oMarca=0 or Marca=@Marca) 

	return
end

/*
	select * from fDeclaratia112 ('10/01/2011', '10/31/2011', 0, '', '', 0, 0, '', '')
	select * from fDeclaratia112TagAsigurat ('01/01/2011', '01/31/2011')
	select sum(Baza_somaj) from fDeclaratia112 ('01/01/2011', '01/31/2011', 0, '', '', 0, 0, '', 'asiguratB')
	select sum(Baza_somaj) from fDeclaratia112 ('01/01/2011', '01/31/2011', 0, '', '', 0, 0, '', 'asiguratA')
*/
