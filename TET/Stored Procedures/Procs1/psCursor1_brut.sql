--***
/**	proc. cursor1 brut	*/
Create
procedure  [dbo].[psCursor1_brut]  @DataJ datetime,@DataS datetime,@MarcaJ char(6),@LocmJ char(9)
As
Begin
	declare @STOUG28 int,@Cassimps_K int,@Subtipret int,@Subtipcor int,@Sal_comp int,@Cor_salcomp char(20),@Aloc_hrana int,@Cor_aloc_hrana char(20),
	@Data1_an datetime,@DataS_ant datetime, @ImpozitTichete int, @DataImpTicJ datetime, @DataImpTicS datetime,@HostID char(8)
	Set @STOUG28=dbo.iauParLL(@DataS,'PS','STOUG28')
	Set @Cassimps_K=dbo.iauParL('PS','ASSIMPS-K')
	Set @Subtipret=dbo.iauParL('PS','SUBTIPRET')
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Set @Sal_comp=dbo.iauParL('PS','SALCOMP')
	Set @Cor_salcomp=dbo.iauParA('PS','SALCOMP')
	Set @Aloc_hrana=dbo.iauParL('PS','ALOCHRANA')
	Set @Cor_aloc_hrana=dbo.iauParA('PS','ALOCHRANA')
	Set @Data1_an=dbo.boy(@DataJ)
	Set @DataS_ant=@DataJ-1
	Set @ImpozitTichete=dbo.iauParLL(@DataS,'PS','DJIMPZTIC')
	Set @DataImpTicJ=dbo.iauParLD(@DataS,'PS','DJIMPZTIC')
	Set @DataImpTicS=dbo.iauParLD(@DataS,'PS','DSIMPZTIC')
	Set @DataImpTicJ=(case when @DataImpTicJ='01/01/1901' then @DataJ else @DataImpTicJ end)
	Set @DataImpTicS=(case when @DataImpTicS='01/01/1901' then @DataS else @DataImpTicS end)
	Set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
	exec pSume_cm_marca @DataJ,@DataS,@MarcaJ
	exec pPontaj_marca_locm @DataJ,@DataS,@MarcaJ,@LocmJ

	If not exists (Select * from tempdb..sysobjects where name = '##cursor1_brut' and type = 'U') 
	Begin
		Create table dbo.##cursor1_brut (HostID char(8),Data datetime,Marca char(6),BazaCN float,BazaCD float,
		BazaCS float, indcmunit19 float, indcmcas19 float, orelunacm float, indcm float, indcmcas18 float, zcm18 int, 
		zcm18ant int, bazacasiant float, bazacascmant float, zcm2341011 int, indcm234 float, indcmunit234 float, zcm15 int, 
		zcm8915 int, indcm8915 float, zcm78 int, indcm78 float, indcmsomaj float, Ingrcopsarcina int, zcm_unitate int, zcm_fonduri int, 
		uMarca2CNP int,uMarca2CNPCM int, Pensmax_ded float,Pensded_lun float,Pensded_ant float, Pensluna float, SalComp float, 
		AlocHrana float, SomajTehn float, OreST int, SumaNeimp float, ValTichete float, uMarca2CNPSomaj int, AvantajeMat float, PensieFUnitate float) 
		Create Unique Clustered Index [Data_Marca] ON dbo.##cursor1_brut (HostID Asc, Data Asc, Marca Asc)
	End
	if (select count(1) from tempdb..sysobjects where name='##cursor1_brut')>0 
	and isnull((select tempdb..syscolumns.length from tempdb..syscolumns,tempdb..sysobjects where tempdb..sysobjects.name='##cursor1_brut' and tempdb..sysobjects.id=tempdb..syscolumns.id and tempdb..syscolumns.name='PensieFUnitate'),0)=0 
		alter table ##cursor1_brut add PensieFUnitate int not null default 0
	delete from dbo.##cursor1_brut where HostID=@HostID

	insert into ##cursor1_brut
	Select @HostID,b.Data,b.marca,
	sum(b.venit_cond_normale-(case when t.grupa_de_munca='N' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='N' or p.grupa_de_munca='P' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
	-(case when t.grupa_de_munca='N' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='N' or p.grupa_de_munca='P' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
	-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='N' and p.grupa_de_munca<>'P' then b.cons_admin when p.grupa_de_munca='N' then b.cons_admin else 0 end) else 0 end)
	-(case when @STOUG28=1 then (case when t.grupa_de_munca='N' then round(b.Ind_invoiri,0) when p.grupa_de_munca='N' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
	-(case when t.grupa_de_munca='N' then isnull(pf.Suma_corectie,0) else 0 end)),
	sum(b.venit_cond_deosebite-(case when t.grupa_de_munca='D' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='D' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
	-(case when t.grupa_de_munca='D' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='D' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
	-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='D' then b.cons_admin when p.grupa_de_munca='D' then b.cons_admin else 0 end) else 0 end)
	-(case when @STOUG28=1 then (case when t.grupa_de_munca='D' then round(b.Ind_invoiri,0) when p.grupa_de_munca='D' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
	-(case when t.grupa_de_munca='D' then isnull(pf.Suma_corectie,0) else 0 end)),
	sum(b.venit_cond_speciale-(case when t.grupa_de_munca='S' then b.ind_c_medical_unitate+b.cmunitate when p.grupa_de_munca='S' then b.ind_c_medical_unitate+b.cmunitate else 0 end)
	-(case when t.grupa_de_munca='S' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 when p.grupa_de_munca='S' then b.ind_c_medical_cas+b.cmcas+b.spor_cond_9 else 0 end)
	-(case when @Cassimps_K=1 then (case when t.grupa_de_munca='S' then b.cons_admin when p.grupa_de_munca='S' then b.cons_admin else 0 end) else 0 end)
	-(case when @STOUG28=1 then (case when t.grupa_de_munca='S' then round(b.Ind_invoiri,0) when p.grupa_de_munca='S' then round(b.Ind_invoiri,0) else 0 end) else 0 end)
	-(case when t.grupa_de_munca='S' then isnull(pf.Suma_corectie,0) else 0 end)),
	isnull(max(m.indcm_unit_19),0), isnull(max(m.indcm_cas_19),0),isnull(max(m.ore_luna_cm),0),isnull(max(m.indcm),0), isnull(max(m.indcm_cas_18),0), isnull(max(m.zcm_18),0), isnull(max(zcm_18_ant),0), isnull(max(baza_casi_ant),0),
	isnull(max(baza_cascm_ant),0), isnull(max(zcm_2341011),0),isnull(max(indcm_234),0), isnull(max(indcm_unit_234),0), isnull(max(zcm15),0), isnull(max(zcm_8915),0), isnull(max(indcm_8915),0), isnull(max(zcm_78),0), isnull(max(indcm_78),0),isnull(max(indcm_somaj),0), 
	(case when isnull(max(m.ingrijire_copil_sarcina),0)<>0 then 1 else 0 end), isnull(max(zcm_unitate),0), isnull(max(zcm_fonduri),0), 
	isnull((select count(1) from brut b1 where max(p.Tip_colab) not in ('CCC','DAC') and b1.data=@DataS and b1.marca<b.marca and b1.marca in (select p1.marca from personal p1 where p1.cod_numeric_personal=max(p.cod_numeric_personal) and (p1.loc_ramas_vacant=0 or p1.Data_plec>@DataJ) and p1.Grupa_de_munca in ('N','D','S','C','P') and p1.Tip_colab not in ('CCC','DAC')) 
	/*and (select count(1) from brut b2 where b2.data=@DataS and b2.marca>b.marca and b2.marca in (select p2.marca from personal p2 where p2.cod_numeric_personal=max(p.cod_numeric_personal) and (p2.loc_ramas_vacant=0 or p2.Data_plec>@DataJ)))=0*/),0),
	isnull((select count(1) from brut b1 where b1.data=@DataS and b1.marca<>b.marca and b1.marca in (select p1.marca from personal p1 where p1.cod_numeric_personal=max(p.cod_numeric_personal) and p1.Grupa_de_munca in ('N','D','S','C','P'))),0),
	max(convert(float,isnull(e1.val_inf,''))) as Pensie_max_ded,max(isnull(e1.procent,0)),
	isnull((select sum(n.ded_baza) from net n where n.data between @Data1_an and @DataS_ant and n.marca=b.marca and day(n.data)=1),0),
	isnull((select sum(r1.Retinere_progr_la_avans+r1.Retinere_progr_la_lichidare) from resal r1 where r1.data between @DataJ and @DataS and r1.marca=b.marca and r1.cod_beneficiar in  
	(select cod_beneficiar from benret where @Subtipret=0 and tip_retinere='5' or @Subtipret=1 and tip_retinere in (select subtip from tipret where tip_retinere='5'))),0),
	isnull((select sum(suma_corectie) from corectii c4 where @Sal_comp=1 and c4.data between @DataJ and @DataS and c4.marca=b.marca 
	and (@Subtipcor=0 and c4.tip_corectie_venit=@Cor_salcomp or @Subtipcor=1 and c4.Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit=@Cor_salcomp))),0),
	isnull((select sum(suma_corectie) from corectii c5 where @Aloc_hrana=1 and c5.data between @DataJ and @DataS and c5.marca=b.marca and (@Subtipcor=0 and charindex(c5.tip_corectie_venit,@Cor_aloc_hrana)<>0 or @Subtipcor=1 
	and c5.Tip_corectie_venit in (select s.Subtip from Subtipcor s where charindex(s.tip_corectie_venit,@Cor_aloc_hrana)<>0))),0),
	sum((case when @STOUG28=1 then round(b.Ind_invoiri,0) else 0 end)),sum(isnull(t.Ore_intr_tehn_2,0)),max(isnull(n.Suma_neimpozabila,0)), max(isnull(ft.Valoare_tichete,0)), 
	(case when year(@DataS)<=2010 then isnull((select count(1) from brut b1 where max(p.Tip_colab) not in ('CCC','DAC') and max(p.Grupa_de_munca)<>'C' and max(p.Somaj_1)<>0 and b1.data=@DataS and b1.marca<b.marca and b1.marca in (select p1.marca from personal p1 where p1.cod_numeric_personal=max(p.cod_numeric_personal) and (p1.loc_ramas_vacant=0 or p1.Data_plec>@DataJ) and p1.Somaj_1<>0 
	and p1.Grupa_de_munca in ('N','D','S','O','P') and p1.Tip_colab not in ('CCC','DAC')) and (select count(1) from brut b2 where b2.data=@DataS and b2.marca>b.marca and b2.marca in (select p2.marca from personal p2 where p2.cod_numeric_personal=max(p.cod_numeric_personal) and p2.Somaj_1<>0 and p2.Grupa_de_munca<>'C' and (p2.loc_ramas_vacant=0 or p2.Data_plec>@DataJ)))=0),0)
	else isnull((select count(1) from brut b1 where max(p.Somaj_1)<>0 and b1.data=@DataS and b1.marca<b.marca and b1.marca in (select p1.marca from personal p1 left outer join fDeclaratia112TagAsigurat (@DataJ, @DataS) a2 on b1.data=a2.data and b1.marca=a2.marca where p1.cod_numeric_personal=max(p.cod_numeric_personal) and a2.Tip_asigurat=max(a1.Tip_asigurat) and a2.Tip_contract=max(a1.Tip_contract) and (p1.loc_ramas_vacant=0 or p1.Data_plec>@DataJ) and p1.Somaj_1<>0 and p1.Tip_colab not in ('CCC','DAC')) 
	and (select count(1) from brut b2 where b2.data=@DataS and b2.marca>b.marca and b2.marca in (select p2.marca from personal p2 left outer join fDeclaratia112TagAsigurat (@DataJ, @DataS) a3 on b2.data=a3.data and b2.marca=a3.marca where p2.cod_numeric_personal=max(p.cod_numeric_personal) and a3.Tip_asigurat=max(a1.Tip_asigurat)  and a3.Tip_contract=max(a1.Tip_contract) and p2.Somaj_1<>0  and (p2.loc_ramas_vacant=0 or p2.Data_plec>@DataJ)))=0),0) end),
	sum(isnull(q.Suma_corectie,0)), max(isnull(pf.Suma_corectie,0)) as PensieFUnitate
	from brut b
	left outer join personal p on p.marca=b.marca
	left outer join net n on n.Data=b.Data and n.marca=b.marca
	left outer join extinfop e1 on e1.marca=b.marca and e1.cod_inf='PENSIIF' and e1.data_inf=@Data1_an
	left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @MarcaJ, @LocmJ, 1) pf on pf.Data=b.Data and pf.Marca=b.Marca and pf.Loc_de_munca=b.Loc_de_munca
	left outer join ##Pontaj_marca_locm t on t.hostid=@HostID and t.data=b.data and t.marca=b.marca and t.loc_de_munca=b.loc_de_munca
	left outer join ##Sume_cm_marca m on m.hostid=@HostID and b.data=m.data and b.marca=m.marca
	left outer join infopers i on i.marca=b.marca
	left outer join dbo.fNC_tichete (@DataImpTicJ, @DataImpTicS, @MarcaJ, 1) ft on @ImpozitTichete=1 and b.Marca=ft.Marca /*and b.Data=ft.Data*/
	left outer join fDeclaratia112TagAsigurat (@DataJ, @DataS) a1 on b.data=a1.data and b.marca=a1.marca 
	left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'Q-', @MarcaJ, @LocmJ, 1) q on q.Data=b.Data and q.Marca=b.Marca and q.Loc_de_munca=b.Loc_de_munca
	where b.data between @DataJ and @DataS and (@MarcaJ='' or p.marca=@MarcaJ) 
	and (@LocmJ='' or p.loc_de_munca like rtrim(@LocmJ)+'%')
	group by b.data, b.marca
	order by b.data, b.marca

	update ##cursor1_brut set BazaCN=(case when BazaCN<0 then 0 else BazaCN end), 
	BazaCD=(case when BazaCD<0 then 0 else BazaCD end), 
	BazaCS=(case when BazaCS<0 then 0 else BazaCS end)
	where HostID=@HostID and (BazaCN<0 or BazaCD<0 or BazaCS<0) and (@MarcaJ='' or Marca=@MarcaJ) 

	delete from dbo.##Sume_cm_marca where HostID=@HostID
	delete from dbo.##Pontaj_marca_locm where HostID=@HostID
End
