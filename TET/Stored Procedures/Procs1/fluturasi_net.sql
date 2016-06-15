--***
/**	fluturasi net */
Create procedure fluturasi_net
	@dataJos datetime, @dataSus datetime, @HostID char(10), @pmarca char(6), @cond1 bit, @cond2 bit, @cond3 bit
as
Begin
	declare @Data datetime,@Marca char(6),@Banca char(50),@nloc_de_munca char(9),@venit_total float,@TotalStoehr float,
	@Diminuari float,@ncm_incasat float,@nco_incasat float,@nsuma_incasata float,@nsuma_neimpozabila float,
	@ndiferenta_impozit float, @nimpozit float,@npensie_suplimentara_3 float,@nsomaj_1 float,@nasig_sanatate_din_net float,
	@nvenit_net float,@navans float, @npremiu_la_avans float,@ndebite_externe float,@ndebite_interne float,@nrate float,@ncont_curent float,
	@nrest_de_plata float, @nven_net_in_imp float,@nchelt_prof float,@nded_baza float,@nvenit_baza float,@n1ded_baza float,
	@dedSindicat float,@sindicat float,@Total_taxe float, @CorU float,@tichete float,@val_tichete float, @Avantaje_materiale float,
	@cCASind char(10),@cCASSIND char(10),@lProc_sind float,@nProc_sind float,@cCod_sind char(13), @Retinere_neef float,
	@extensie_inf int,@FLDR_FSIND int,@FLtichet int,@FLFPlat int,@Compexit int,@Vestiro int,@Elite int,@Salubris int, @Stoehr int, @Grup7 int, 
	@den_cm_incasat char(30),@den_co_incasat char(30),@den_suma_incasata char(30),@den_premii_neimp char(30), @den_avantaje_mat char(30), 
	@CandScriu int, @ore char(20),@cSomajInd char(10),@nValTichet float, @ImpozitTichete int, @DataImpTicJ datetime, 
	@DataImpTicS datetime, @denImpozitIpotetic varchar(50), @denImpozit varchar(50)

	Set @ImpozitTichete=dbo.iauParLL(@dataSus,'PS','DJIMPZTIC')
	Set @DataImpTicJ=dbo.iauParLD(@dataSus,'PS','DJIMPZTIC')
	Set @DataImpTicS=dbo.iauParLD(@dataSus,'PS','DSIMPZTIC')
	Set @DataImpTicJ=(case when @DataImpTicJ='01/01/1901' then @dataJos else @DataImpTicJ end)
	Set @DataImpTicS=(case when @DataImpTicS='01/01/1901' then @dataSus else @DataImpTicS end)
	Set @den_cm_incasat=isnull((select denumire from tipcor where tip_corectie_venit='C-'),'')
	Set @den_co_incasat=isnull((select denumire from tipcor where tip_corectie_venit='E-'),'')
	Set @den_suma_incasata=isnull((select denumire from tipcor where tip_corectie_venit='M-'),'')
	Set @den_premii_neimp=isnull((select denumire from tipcor where tip_corectie_venit='U-'),'')
	Set @den_avantaje_mat=isnull((select denumire from tipcor where tip_corectie_venit='Q-'),'')
	Set @cCASind=ltrim(str((case when dbo.iauParLN(@dataSus,'PS','CASINDIV')=0 then dbo.iauParN('PS','CASINDIV') else dbo.iauParLN(@dataSus,'PS','CASINDIV') end),4,1))+'%'
	Set @cCASSind=ltrim(str((case when dbo.iauParLN(@dataSus,'PS','CASSIND')=0 then dbo.iauParN('PS','CASSIND') else dbo.iauParLN(@dataSus,'PS','CASSIND') end),4,1))+'%'
	Set @nValTichet=(case when dbo.iauParLN(@dataSus,'PS','VALTICHET')=0 then dbo.iauParN('PS','VALTICHET') else dbo.iauParLN(@dataSus,'PS','VALTICHET') end)
	Set @cSomajInd=ltrim(str((case when dbo.iauParLN(@dataSus,'PS','SOMAJIND')=0 then dbo.iauParN('PS','SOMAJIND') else dbo.iauParLN(@dataSus,'PS','SOMAJIND') end),4,1))+'%'
	Exec Luare_date_par 'PS','SIND%',@lProc_sind output,@nProc_Sind output,@cCod_sind output
	Set @extensie_inf=dbo.iauParL('PS','FLDETRET')
	Set @FLDR_FSIND=dbo.iauParL('PS','FLFDSIND')
	Set @FLtichet=dbo.iauParL('PS','FLDTICHET')
	Set @FLFPlat=dbo.iauParL('PS','FLDFPLAT')
	Set @Stoehr=dbo.iauParL('SP','STOEHR')
	Set @Compexit=dbo.iauParL('SP','COMPEXIT')
	Set @Vestiro=dbo.iauParL('SP','VESTIRO')
	Set @Elite=dbo.iauParL('SP','ELITE')
	Set @Salubris=dbo.iauParL('SP','SALUBRIS')
	Set @Grup7=dbo.iauParL('SP','GRUP7')

	select @denImpozitIpotetic=denumire from catinfop where Cod='IMPOZIPOTETIC'
	if @denImpozitIpotetic is null set @denImpozitIpotetic='Impozit'

	Declare cursor_fluturasi_net Cursor For
	select a.Marca,(case when max(p.banca)<>'' then 'PLATIT PRIN '+max(p.banca) else '' end), max(n.loc_de_munca),sum(a.venit_total),sum(a.venit_total)+sum(a.diminuari),sum(a.diminuari),
	max(n.cm_incasat),max(n.co_incasat), max(n.suma_incasata),max(n.suma_neimpozabila),max(n.diferenta_impozit),max(n.impozit),max(n.pensie_suplimentara_3),max(n.somaj_1), max(n.asig_sanatate_din_net),
	max(n.venit_net),max(n.avans)-(case when max(n.premiu_la_avans)<>0 then 0 else isnull(max(x.premiu_la_avans),0) end), 
	(case when max(n.premiu_la_avans)<>0 then max(n.premiu_la_avans) else isnull(max(x.premiu_la_avans),0) end),max(n.debite_externe),max(n.debite_interne),max(n.rate),max(n.cont_curent),
	max(n.rest_de_plata)+isnull((case when @Salubris=1 and max(r1.retinut_la_lichidare)<max(r1.retinere_progr_la_lichidare) then 
	max(r1.retinut_la_lichidare)-max(r1.retinere_progr_la_lichidare) else 0 end),0), 
	max(n.ven_net_in_imp),max(n.chelt_prof),max(n.ded_baza),max(n.venit_baza),isnull(max(n1.ded_baza),0),
	(case when isnull(max(r.retinut_la_lichidare),0)>0 
			then (case when @lProc_sind=0 and @nProc_Sind>1 and isnull(max(r.retinut_la_lichidare),0)>round(max(a.Venit_total)*1/100,0) 
				then round(max(a.Venit_total)*1/100,0) 
				else isnull(max(r.retinut_la_lichidare),0)*(case when @lProc_sind=1 and @nProc_Sind>1 and @nProc_Sind<100 then 1/@nProc_Sind else 1 end) end)
			else 0 end),
	isnull(max(r.retinut_la_lichidare),0),
	(case when @Compexit=1 then max(n.pensie_suplimentara_3+n.somaj_1+n.asig_sanatate_din_net+n.impozit) else 0 end),
	max(isnull(u.suma_corectie,0)),
	(case when @Elite=1 then isnull((select sum(nr_tichete) from tichete t where t.marca=a.marca and t.data_lunii=a.data and tip_operatie='P'),0) else isnull(max(t2.Numar_tichete),0) end),
	(case when @Elite=1 then isnull((select sum(nr_tichete*Valoare_tichet) from tichete t where t.marca=a.marca and t.data_lunii=a.data and tip_operatie='P'),0) else isnull(max(t2.Valoare_tichete),0) end),
	max(isnull(q.Suma_corectie,0)), max(case when upper(isnull(ii.ImpozitIpotetic,''))='DA' then @denImpozitIpotetic else 'Impozit' end)
	from tmpfluturi a
		left outer join personal p on p.marca=a.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'U-', @pMarca, '', 0) u on u.Data=a.Data and u.Marca=a.Marca and @Grup7=0
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', @pMarca, '', 0) q on q.Data=a.Data and q.Marca=a.Marca
		left outer join net n on n.data=a.data and n.marca=a.marca
		left outer join net n1 on n1.marca=a.marca and n1.data=dbo.bom(a.data)
		left outer join resal r on r.data=a.data and r.marca=a.marca and r.cod_beneficiar in (dbo.fCodb_sindicat(a.marca,a.data),@cCod_sind) 
			and (p.sindicalist=0 or r.numar_document='SINDICAT')
		left outer join resal r1 on r1.data=a.data and r1.marca=a.marca and r1.cod_beneficiar='1256'
		left outer join avexcep x on x.data=a.data and x.marca=a.marca
		left outer join dbo.fNC_tichete (@DataImpTicJ, @DataImpTicS, @pmarca, 1) t2 on @ImpozitTichete=1 and a.Marca=t2.Marca /*a.Data=t2.Data*/
		left outer join #impozitIpotetic ii on ii.marca=a.marca
	where a.Host_ID=@HostID and a.marca=@pmarca
	group by a.data,a.marca

	open cursor_fluturasi_net
	fetch next from cursor_fluturasi_net into
		@Marca,@Banca,@nloc_de_munca,@venit_total,@TotalStoehr,@Diminuari,@ncm_incasat,@nco_incasat,@nsuma_incasata, @nsuma_neimpozabila,
		@ndiferenta_impozit,@nimpozit,@npensie_suplimentara_3,@nsomaj_1,@nasig_sanatate_din_net,@nvenit_net, 
		@navans,@npremiu_la_avans,@ndebite_externe,@ndebite_interne,@nrate,@ncont_curent,@nrest_de_plata,@nven_net_in_imp, 
		@nchelt_prof,@nded_baza,@nvenit_baza,@n1ded_baza,@dedSindicat,@sindicat,@Total_taxe,@CorU,@tichete,@val_tichete,@Avantaje_materiale,@denImpozit
	While @@fetch_status=0 
	Begin
		exec scriu_fluturasi @HostID,@marca,'V','VENIT TOTAL','',@venit_total,@cond1,@cond2,@cond3,0,''
		If @venit_total<>0 and @Stoehr=1 and @Diminuari<>0
			exec scriu_fluturasi @HostID,@marca,'V','TOTAL LUCRAT','',@TotalStoehr,@cond1,@cond2,@cond3,0,'V'
		exec scriu_fluturasi @HostID,@marca,'V','-------------------','','',@cond1,@cond2,@cond3,1,'V'
		exec scriu_fluturasi @HostID,@marca,'V','CAS individual',@cCASind,@nPensie_suplimentara_3,@cond1,@cond2,@cond3,0,'C'
		exec scriu_fluturasi @HostID,@marca,'V','Somaj',@cSomajInd,@nSomaj_1,@cond1,@cond2,@cond3,0,'C'
		exec scriu_fluturasi @HostID,@marca,'V','Asigurare sanatate',@cCASSIND,@nasig_sanatate_din_net,@cond1,@cond2,@cond3,0,'C'
--		setarea din Configurari, General, Fluturasi
		if @extensie_inf=1
		Begin	
			exec scriu_fluturasi @HostID,@marca,'V','VENIT NET','',@nven_net_in_imp,@cond1,@cond2,@cond3,0,'C'
			exec scriu_fluturasi @HostID,@marca,'V','Deducere personala','',@nded_baza,@cond1,@cond2,@cond3,0,'C'
			exec scriu_fluturasi @HostID,@marca,'V','Ded pensie facultativa','',@n1ded_baza,@cond1,@cond2,@cond3,0,'C'
			if @FLDR_FSIND=0
				exec scriu_fluturasi @HostID,@marca,'V','SINDICAT','',@sindicat,@cond1,@cond2,@cond3,0,'C'
			exec scriu_fluturasi @HostID,@marca,'V',@den_avantaje_mat,'',@Avantaje_materiale,@cond1,@cond2,@cond3,0,'C'
			exec scriu_fluturasi @HostID,@marca,'V','VENIT BAZA DE CALCUL','',@nvenit_baza,@cond1,@cond2,@cond3,0,'C'
		End
		exec scriu_fluturasi @HostID,@marca,'V',@denImpozit,'',@nimpozit,@cond1,@cond2,@cond3,0,'C'
		if @Total_taxe<>0
			exec scriu_fluturasi @HostID,@marca,'V','TOTAL TAXE','',@Total_taxe,@cond1,@cond2,@cond3,0,'C'
		exec scriu_fluturasi @HostID,@marca,'V','SALAR NET','',@nVenit_net,@cond1,@cond2,@cond3,0,'C'
		if @nCO_incasat<>0
			exec scriu_fluturasi @HostID,@marca,'V',@den_co_incasat,'',@nCO_incasat,@cond1,@cond2,@cond3,0,'R'
		if @nDiferenta_impozit<>0
			exec scriu_fluturasi @HostID,@marca,'V','Diferenta impozit','',@nDiferenta_impozit,@cond1,@cond2,@cond3,0,'R'
		if @CorU<>0
			exec scriu_fluturasi @HostID,@marca,'V',@den_premii_neimp,'',@CorU,@cond1,@cond2,@cond3,0,'V'
		if @nAvans<>0
			exec scriu_fluturasi @HostID,@marca,'V','Avans','',@nAvans,@cond1,@cond2,@cond3,0,'R'
		if @nPremiu_la_avans<>0
			exec scriu_fluturasi @HostID,@marca,'V','Premiu la avans','',@nPremiu_la_avans,@cond1,@cond2,@cond3,0,'R'
		if @nSuma_incasata<>0
			exec scriu_fluturasi @HostID,@marca,'V',@den_suma_incasata,'',@nSuma_incasata,@cond1,@cond2,@cond3,0,'R'
		if @nCM_incasat<>0
			exec scriu_fluturasi @HostID,@marca,'V',@den_cm_incasat,'',@nCM_incasat,@cond1,@cond2,@cond3,0,'R'

		exec fluturasi_retineri @dataJos,@dataSus,@HostID,@marca,@cond1,@cond2,@cond3,1,0
		exec scriu_fluturasi @HostID,@marca,'V','-------------------','',0,@cond1,@cond2,@cond3,1,'R'
		if (@Elite=1 or @FLtichet=1) and (@tichete<>0 or @val_tichete<>0) 
		Begin
			Set @ore=ltrim(str(@tichete,6,2))
			exec scriu_fluturasi @HostID,@marca,'V','Tichete',@Ore,@Val_tichete,@cond1,@cond2,@cond3,0,''
		End
		exec scriu_fluturasi @HostID,@marca,'V','REST DE PLATA','',@nRest_de_plata,@cond1,@cond2,@cond3,1,''
		If @Banca<>'' and @Banca<>'PLATIT PRIN NECOMPLETAT' and @FLFPlat=0
			exec scriu_fluturasi @HostID,@marca,'V',@Banca,'',@nRest_de_plata,@cond1,@cond2,@cond3,0,'R'
		If @Vestiro=1
			exec fluturasi_retineri @dataJos,@dataSus,@HostID,@marca,@cond1,@cond2,@cond3,1,1
			
		fetch next from cursor_fluturasi_net into @Marca,@Banca,@nloc_de_munca,@venit_total,
		@TotalStoehr,@Diminuari,@ncm_incasat,@nco_incasat,@nsuma_incasata,@nsuma_neimpozabila,
		@ndiferenta_impozit,@nimpozit,@npensie_suplimentara_3,@nsomaj_1,@nasig_sanatate_din_net,
		@nvenit_net,@navans,@npremiu_la_avans,@ndebite_externe,@ndebite_interne,@nrate,@ncont_curent,@nrest_de_plata,
		@nven_net_in_imp, @nchelt_prof,@nded_baza,@nvenit_baza,@n1ded_baza,@dedSindicat,@sindicat,
		@Total_taxe,@CorU,@tichete,@val_tichete,@Avantaje_materiale,@denImpozit
	End
	close cursor_fluturasi_net
	Deallocate cursor_fluturasi_net
End
