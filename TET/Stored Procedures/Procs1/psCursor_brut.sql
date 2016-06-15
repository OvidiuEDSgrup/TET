--***
/**	proc. cursor brut	*/
Create
procedure  [dbo].[psCursor_brut] 
@DataJ datetime,@DataS datetime,@MarcaJ char(6),@LocmJ char(9)
As
Begin
	declare @AnRegCom int, @DataExpOUG6 datetime, @Colas int, @STOUG28 int, @Adun_OIT_RN int, 
	@cod_sindicat char(13), @proc_sind float, @LM_statpl int, @HostID char(8)
	Exec Luare_date_par 'PS','SIND%',0,@proc_sind OUTPUT,@cod_sindicat OUTPUT
	Set @AnRegCom=dbo.iauParN('PS','REGCOMAN')
	Set @DataExpOUG6=dbo.EOY(convert(datetime,'01/01/'+str(@AnRegCom+3,4)))
	Set @Colas=dbo.iauParL('SP','COLAS')
	Set @STOUG28=dbo.iauParLL(@DataS,'PS','STOUG28')
	Set @Adun_OIT_RN=dbo.iauParL('PS','OINTNRN')
	Set @LM_statpl=dbo.iauParL('PS','LOCMSALAR')
	Set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
	exec pPontaj_marca_locm @DataJ,@DataS,@MarcaJ,@LocmJ

	if (select count(1) from tempdb..sysobjects where name='##cursor_brut')>0 
	and isnull((select tempdb..syscolumns.length from tempdb..syscolumns,tempdb..sysobjects where tempdb..sysobjects.name='##cursor1_brut' and tempdb..sysobjects.id=tempdb..syscolumns.id and tempdb..syscolumns.name='OUG6'),0)=0 
		drop table ##cursor_brut

	If not exists (Select * from tempdb..sysobjects where name = '##cursor_brut' and type = 'U') 
	Begin
		Create table dbo.##cursor_brut (HostID char(8),Data datetime,Marca char(6),OreLucr int,OreNoapte int,OreRN int,OreIT int, OreOblig int,OreCFS int,OreCO int,OreCM int,Invoiri int,Nemotivate int,OreSupl int,OreJust int,Baza_somaj_1 float, IndFAMBP float,CMunitate float, CMCAS float,Diurna float,SumaImpoz float,ConsAdmin float,SumaImpsep float, AjDeces float, Venit_total float,spor_specific float, spor_cond_1 float,spor_cond_2 float,spor_cond_3 float,spor_cond_4 float,spor_cond_5 float, spor_cond_6 float, Salar_orar float,
		RegimL float,Locm char(9),CorQ float,CorT float,CorU float,Ret_sindicat float,RLpontaj float, GrupaMpontaj char(1),Somaj1P int,
		As_sanP int,TipImpozP char(1),ProcImpoz int,CheltDed decimal(10),GrupaMP char(1),Salar_de_incadrareP float, Salar_de_bazaP float,Tip_salarizareP char(1),Ind_condP float, Spor_vechimeP float,Spor_de_noapteP float,Spor_sist_prgP float, Spor_functie_suplP float, Spor_specificP float,Spor_conditii_1P float, Spor_conditii_2P float,Spor_conditii_3P float,Spor_conditii_4P float,Spor_conditii_5P float,Spor_conditii_6P float, TipColabP char(3), AlteSurseP char(1),GradInvP char(1),Tipded_somajP float,DataAng datetime,Plecat char(1),ModAngP char(1),DataPlecP datetime,
		Sind char(1),DataIcvsom datetime, DataEcvsom datetime,NrPersintr int, CNP char(13), PersNecontractual char(1), OUG13 int, OUG6 int) 
		Create Unique Clustered Index [Data_Marca] ON dbo.##cursor_brut (HostID Asc, Data Asc, Marca Asc)
	End
	delete from dbo.##cursor_brut where HostID=@HostID

	insert into ##cursor_brut
	Select @HostID,b.data,b.marca,sum(b.total_ore_lucrate),
	sum(b.ore_de_noapte),sum(b.ore_lucrate_regim_normal),sum(b.Ore_intrerupere_tehnologica),sum(b.ore_obligatii_cetatenesti),
	sum(b.ore_concediu_fara_salar),sum(b.ore_concediu_de_odihna),sum(b.ore_concediu_medical),sum(b.ore_invoiri),
	sum(b.ore_nemotivate),sum(b.ore_suplimentare_1+b.ore_suplimentare_2+b.ore_suplimentare_3+b.ore_suplimentare_4+b.ore_spor_100),
	sum(b.ore_lucrate_regim_normal+(case when @Adun_OIT_RN=1 then 0 else b.Ore_intrerupere_tehnologica-isnull(t.Ore_Intr_tehn_2,0) end)+b.ore_obligatii_cetatenesti+b.ore_concediu_de_odihna+b.ore_concediu_medical+b.ore_invoiri +b.ore_nemotivate+b.ore_concediu_fara_salar+isnull(t.Ore_intemperii,0)+(case when @Colas=1 and @Adun_OIT_RN=1 or 1=1 then isnull(t.Ore_Intr_tehn_2,0) else 0 end)),
	sum(round((b.ore_lucrate_regim_normal+(case when @Adun_OIT_RN=1 then b.Ore_intrerupere_tehnologica-isnull(t.Ore_Intr_tehn_2,0) else 0 end)+b.ore_obligatii_cetatenesti+b.ore_concediu_de_odihna+b.ore_concediu_medical+ b.ore_invoiri+b.ore_nemotivate+b.ore_concediu_fara_salar+t.Ore_intemperii)*b.salar_orar,0)),sum(b.spor_cond_9),sum(b.cmunitate),
	sum(b.cmcas),sum(b.diurna),sum(b.suma_impozabila),sum(b.cons_admin),sum(b.suma_imp_separat),sum(b.compensatie),sum(b.venit_total),
	sum(b.spor_specific),sum(b.spor_cond_1),sum(b.spor_cond_2),sum(b.spor_cond_3),sum(b.spor_cond_4),sum(b.spor_cond_5),
	sum(b.spor_cond_6),max(b.salar_orar),max(b.spor_cond_10),
	(case when @LM_statpl=1 then max(p.loc_de_munca) else isnull((select max(c.loc_de_munca) from brut c where 
	c.data=b.data and c.marca=b.marca and convert(char(1),c.Loc_munca_pt_stat_de_plata)='1'),max(p.loc_de_munca)) end), 
	isnull(max(c1.suma_corectie),0),isnull(sum(c2.suma_corectie),0),isnull(sum(c3.suma_corectie),0),isnull(max(r.retinut_la_lichidare),0),
	isnull(max(t.regim_de_lucru),max(b.spor_cond_10)),isnull(max(t.grupa_de_munca),max(p.grupa_de_munca)),
	max(p.somaj_1),max(p.as_sanatate),max(p.tip_impozitare),isnull(max(e3.Procent),0),round(sum(b.Venit_total)*isnull(max(e4.Procent/100),0),0),max(p.grupa_de_munca),max(p.salar_de_incadrare),max(salar_de_baza),
	max(p.tip_salarizare),max(p.indemnizatia_de_conducere),max(p.spor_vechime),max(p.spor_de_noapte),
	max(p.spor_sistematic_peste_program),max(p.spor_de_functie_suplimentara),max(p.spor_specific),max(p.spor_conditii_1),
	max(p.spor_conditii_2),max(p.spor_conditii_3),max(p.spor_conditii_4),max(p.spor_conditii_5),max(p.spor_conditii_6),
	max(p.tip_colab),max(convert(char(1),p.alte_surse)),max(p.grad_invalid),max(p.coef_invalid),max(p.data_angajarii_in_unitate), max(convert(char(1),loc_ramas_vacant)),max(p.mod_angajare),max(p.data_plec),max(convert(char(1),p.sindicalist)),
	max((case when isnull(e2.data_inf,'01/01/1901')='01/01/1901' then p.data_angajarii_in_unitate else isnull(e2.data_inf,'01/01/1901') end)),
	max(isnull(e.data_inf,'01/01/1901')),isnull((select count(1) from persintr s where s.data=b.data and s.marca=b.marca and s.coef_ded<>0),0),
	max(p.cod_numeric_personal) as CNP, max(convert(char(1),i.actionar)) as PersNecontractual, 
	(case when (day(max(p.Data_angajarii_in_unitate))=1 and b.data>=dbo.eom(max(p.Data_angajarii_in_unitate))
	and b.data<=dbo.eom(DateAdd(month,5,max(p.Data_angajarii_in_unitate))) 
	or day(max(p.Data_angajarii_in_unitate))<>1 and b.data>=dbo.eom(DateAdd(month,1,max(p.Data_angajarii_in_unitate)))
	and b.data<=dbo.eom(DateAdd(month,6,max(p.Data_angajarii_in_unitate)))) and upper(max(rtrim(isnull(e5.Val_inf,''))))='DA' then 1 else 0 end) as OUG13,
	(case when b.data<=@DataExpOUG6 and upper(max(rtrim(isnull(e6.Val_inf,''))))='DA' then 1 else 0 end) as OUG6
	from brut b
	left outer join personal p on p.marca=b.marca
	left outer join net n on n.Data=b.Data and n.marca=b.marca
	left outer join curscor c1 on c1.data=@DataS and c1.marca=b.marca and c1.tip_corectie_venit='Q-'
	--	S-a tranformat corectia T (selectat mai jos) din Diferenta CASS in Pensie facultativa suportata de angajator
	left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'T-', @MarcaJ, @LocmJ, 1) c2 on c2.Data=b.Data and c2.Marca=b.Marca and c2.Loc_de_munca=b.Loc_de_munca and 1=0
	left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'U-', @MarcaJ, @LocmJ, 1) c3 on c3.Data=b.Data and c3.Marca=b.Marca and c3.Loc_de_munca=b.Loc_de_munca
	left outer join resal r on r.data=@DataS and r.marca=b.marca and r.cod_beneficiar in (dbo.fCodb_sindicat(b.marca,@DataS),@cod_sindicat)
	and (not(p.sindicalist=1 and @proc_sind<>0) or r.numar_document='SINDICAT')
	left outer join extinfop e on e.marca=b.marca and e.cod_inf='DEXPSOMAJ'
	left outer join extinfop e2 on e2.marca=b.marca and e2.cod_inf='DCONVSOMAJ'
	left outer join extinfop e3 on e3.marca=b.marca and e3.cod_inf='PROCIMPOZ' and p.Grupa_de_munca in ('P','O')
	left outer join extinfop e4 on e4.marca=b.marca and e4.cod_inf='PROCCHDED' and p.Grupa_de_munca in ('O') and p.Tip_colab='DAC'
	left outer join extinfop e5 on e5.marca=b.marca and e5.cod_inf='OUG13' and upper(e5.val_inf)='DA' 
	left outer join extinfop e6 on e6.marca=b.marca and e6.cod_inf='OUG6' and upper(e6.val_inf)='DA' 
	left outer join ##Pontaj_marca_locm t on t.hostid=@HostID and t.data=b.data and t.marca=b.marca and t.loc_de_munca=b.loc_de_munca
	left outer join infopers i on i.marca=b.marca
	where b.data between @DataJ and @DataS and (@MarcaJ='' or p.marca=@MarcaJ) 
	and (@LocmJ='' or p.loc_de_munca like rtrim(@LocmJ)+'%')
	group by b.data, b.marca
	order by b.data, b.marca
	delete from dbo.##Pontaj_marca_locm where HostID=@HostID
End
