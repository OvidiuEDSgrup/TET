--***
/**	fluturasi corectii	*/
Create procedure fluturasi_corectii
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit
as
Begin
	declare @Marca char(6), @Premiu_la_avans float, @corZ float, @corZ_net float, @corX float, @corX_net float, @corY float, @corY_net float, @CMCAS float,@CMunitate float,
	@CO float, @CO_net float, @Restituiri float, @Restituiri_net float, @Diminuari float, @Suma_impozabila float, @Suma_impozabila_net float, 
	@Premiu float, @Premiu_net float, @Diurna float, @Diurna_net float, @Cons_admin float, @Cons_admin_net float, @Sp_salar_realizat float, 
	@Suma_neimp float, @Suma_neimp2 float,@Suma_imp_separat float, @Suma_imp_separat_net float, @Compensatie float,@Diurna_neimp float,@Realizat_acord float,@Salubris int,@Colas int,
	@den_cmcas char(30), @den_cmunitate char(30), @den_co char(30), @den_corZ char(30), @den_restituiri char(30), 
	@den_diminuari char(30), @den_suma_impoz char(30), @den_premiu char(30), @den_corX char(30), @den_diurna char(30), 
	@den_corY char(30), @den_cons_admin char(30), @den_sp_salar_realizat char(30), @den_suma_neimp char(30), 
	@den_suma_neimp2 char(30), @den_suma_imp_separat char(30), @den_compensatie char(30), @den_diurna_neimp char(30), @den_avmat_impozabil char(30), @cand_scriu bit, 
	@Subtipcor int, @AfisezCorL int, @ReglSalarNetTotalNet int, @ore_procent varchar(20), @avmat_impozabil_net float, @avmat_impozabil float

	exec citire_denumire_corectii @den_cmcas output, @den_cmunitate output, '', @den_co output, @den_corZ output, 
		'', @den_restituiri output, @den_diminuari output, @den_suma_impoz output, @den_premiu output, @den_corX output, 
		@den_diurna output, @den_corY output, @den_cons_admin output, @den_sp_salar_realizat output, '', @den_suma_neimp output, 
		@den_suma_neimp2 output, @den_suma_imp_separat output, '', '', @den_compensatie output, '', '', @den_diurna_neimp output, @den_avmat_impozabil output

	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @AfisezCorL=dbo.iauParL('PS','FLDR-CORL')
	set @ReglSalarNetTotalNet=dbo.iauParL('PS','REGSALNTN')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')

	if object_id('tempdb..#tmpFluturiCorectii') is not null 
		drop table #tmpFluturiCorectii
	if object_id('tempdb..#tmpcorectii1') is not null 
		drop table #tmpcorectii1
	if object_id('tempdb..#tmpcorectii2') is not null 
		drop table #tmpcorectii2
	if object_id('tempdb..#tmpcorectii3') is not null 
		drop table #tmpcorectii3

	/*	Am spart selectul initial in tabele temporare, intrucat din cauza prea multor left join se bloca. */
	select a.Marca, a.data, max(isnull(ax.Premiu_la_avans,0)) as Premiu_la_avans, sum(a.CMCAS) as CMCAS, sum(a.CMunitate) as CMunitate, sum(a.CO) as CO, 
		sum(a.Restituiri) as Restituiri, sum(a.Diminuari) as Diminuari, sum(a.Suma_impozabila) as Suma_impozabila, sum(a.Premiu) as Premiu, 
		sum(a.Diurna) as Diurna, sum(a.Cons_admin) as Cons_admin, sum(a.Sp_salar_realizat) as Sp_salar_realizat, sum(a.Suma_imp_separat) as Suma_imp_separat, 
		sum((case when @Salubris=1 then 0 else a.compensatie end)) as compensatie, sum(a.Realizat_acord) as Realizat_acord, 
		max(n.Suma_neimpozabila) as Suma_neimpozabila
	into #tmpFluturiCorectii
	from tmpfluturi a
		left outer join net n on n.data=a.data and n.marca=a.marca
		left outer join avexcep ax on ax.data=a.data and ax.marca=a.marca 
	where a.Host_ID=@HostID and a.marca=@pmarca
	group by a.data, a.marca

	select	a.marca, a.data, 
			isnull(z.suma_corectie,0) as corectieZ, isnull(x.suma_corectie,0) as corectieX, isnull(y.suma_corectie,0) as corectieY, isnull(n2.suma_corectie,0) as corectieN2,
			isnull(z.Suma_neta,0) as corectieZ_net, isnull(x.Suma_neta,0) as corectieX_net, isnull(y.Suma_neta,0) as corectieY_net, 
			isnull(w.Suma_corectie,0) as corectieW
	into #tmpcorectii1
	from #tmpFluturiCorectii a
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'Z-', '', '', 0) z on z.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'X-', '', '', 0) x on x.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'Y-', '', '', 0) y on y.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'N2', '', '', 0) n2 on n2.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'W-', '', '', 0) w on w.marca=a.marca
		
	select	a.marca, a.data, 
		isnull(d.Suma_neta,0) as corectieD_net, isnull(f.Suma_neta,0) as corectieF_net, isnull(h.Suma_neta,0) as corectieH_net, isnull(i.Suma_neta,0) as corectieI_net
	into #tmpcorectii2
	from #tmpFluturiCorectii a
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'D-', '', '', 0) d on d.marca=a.marca
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'F-', '', '', 0) f on f.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'H-', '', '', 0) h on h.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'I-', '', '', 0) i on i.marca=a.marca 

	select	a.marca, a.data, 
		isnull(j.Suma_neta,0) as corectieJ_net, isnull(o.Suma_neta,0) as corectieO_net, isnull(k.Suma_neta,0) as corectieK_net, 
		isnull(ai.Suma_neta,0) as corectieAI_net, isnull(ai.Suma_corectie,0) as corectieAI
	into #tmpcorectii3
	from #tmpFluturiCorectii a
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'J-', '', '', 0) j on j.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'K-', '', '', 0) k on k.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'O-', '', '', 0) o on o.marca=a.marca 
		left outer join dbo.fSumeCorectie (@datajos, @datasus, 'AI', '', '', 0) ai on ai.marca=a.marca 
	
	Declare cursor_fluturasi_corectii Cursor For
	select a.Marca, a.Premiu_la_avans, c1.corectieZ, c1.corectieX, c1.corectieY, a.CMCAS, a.CMunitate, a.CO-c1.corectieZ, 
		a.Restituiri, a.Diminuari, a.Suma_impozabila, a.Premiu-c1.corectieX, 
		a.Diurna-c1.corectieY, a.Cons_admin, a.Sp_salar_realizat, a.Suma_neimpozabila-c1.corectieN2, c1.corectieN2, a.Suma_imp_separat, a.compensatie, a.Realizat_acord, 
		c1.corectieZ_net, c1.corectieX_net, c1.corectieY_net, c2.corectieD_net, c2.corectieF_net, c2.corectieH_net, c2.corectieI_net, 
		c3.corectieJ_net, c3.corectieK_net, c3.corectieO_net, c1.corectieW, c3.corectieAI_net, c3.corectieAI
	from #tmpFluturiCorectii a
		left outer join #tmpcorectii1 c1 on c1.marca=a.marca 
		left outer join #tmpcorectii2 c2 on c2.marca=a.marca 
		left outer join #tmpcorectii3 c3 on c3.marca=a.marca 

	open cursor_fluturasi_corectii
	fetch next from cursor_fluturasi_corectii into
		@Marca, @Premiu_la_avans, @corZ, @corX, @corY, @CMCAS, @CMunitate, @CO, @Restituiri, @Diminuari, @Suma_impozabila, @Premiu, 
		@Diurna, @Cons_admin, @Sp_salar_realizat, @Suma_neimp, @Suma_neimp2, @Suma_imp_separat, @Compensatie, @Realizat_acord, 
		@CorZ_net, @CorX_net, @CorY_net, @CO_net, @Restituiri_net, @Suma_impozabila_net, @Premiu_net, @Diurna_net, @Cons_admin_net, @Suma_imp_separat_net, 
		@Diurna_neimp, @avmat_impozabil_net, @avmat_impozabil
	While @@fetch_status = 0 
	Begin
		if @Premiu_la_avans<>0
			exec scriu_fluturasi @HostID, @marca, 'V', 'Premiu la avans', '', @Premiu_la_avans, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @CMCAS<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_cmcas, '', @CMCAS, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @CMunitate<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_cmunitate, '', @CMunitate, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @CO<>0
		Begin
			set @ore_procent=(case when @CO_net<>0 then 'net '+rtrim(CONVERT(char(10),@CO_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_co, @ore_procent, @CO, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @corZ<>0
		Begin
			set @ore_procent=(case when @corZ_net<>0 then 'net '+rtrim(CONVERT(char(10),@corZ_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_corZ, @ore_procent, @corZ, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @Restituiri<>0
		Begin
			set @ore_procent=(case when @Restituiri_net<>0 then 'net '+rtrim(CONVERT(char(10),@Restituiri_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_restituiri, @ore_procent, @Restituiri,@conditie1,@conditie2,@conditie3,0,'V'
		End	
		if @Diminuari<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_diminuari, '', @Diminuari,@conditie1,@conditie2,@conditie3,0,'V'
		if @Suma_impozabila<>0
		Begin
			set @ore_procent=(case when @Suma_impozabila_net<>0 and @ReglSalarNetTotalNet=0 then 'net '+rtrim(CONVERT(char(10),@Suma_impozabila_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_suma_impoz,@ore_procent,@Suma_impozabila,@conditie1,@conditie2, @conditie3, 0, 'V'
		End
		if @Premiu<>0
		Begin
			set @ore_procent=(case when @Premiu_net<>0 then 'net '+rtrim(CONVERT(char(10),@Premiu_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_premiu, @ore_procent, @Premiu, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @CorX<>0
		Begin
			set @ore_procent=(case when @corX_net<>0 then 'net '+rtrim(CONVERT(char(10),@corX_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_corX, @ore_procent, @CorX, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @Diurna<>0
		Begin
			set @ore_procent=(case when @Diurna_net<>0 then 'net '+rtrim(CONVERT(char(10),@Diurna_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_diurna, @ore_procent, @Diurna, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @CorY<>0
		Begin
			set @ore_procent=(case when @corY_net<>0 then 'net '+rtrim(CONVERT(char(10),@corY_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_corY, @ore_procent, @CorY, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		if @Cons_admin<>0
		Begin
			set @ore_procent=(case when @Cons_admin_net<>0 then 'net '+rtrim(CONVERT(char(10),@Cons_admin_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_cons_admin, @ore_procent, @Cons_admin, @conditie1, @conditie2, @conditie3, 0, 'V'
		End	
		If @Sp_salar_realizat<>0 and (@Realizat_acord<>0 or @Colas=1 or @AfisezCorL=1)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_sp_salar_realizat,'',@Sp_salar_realizat,@conditie1,@conditie2, @conditie3, 0, 'V'
		if @Suma_neimp<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_suma_neimp, '', @Suma_neimp, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @Suma_neimp2<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_suma_neimp2, '', @Suma_neimp2, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @Suma_imp_separat<>0
		Begin
			set @ore_procent=(case when @Suma_imp_separat_net<>0 then 'net '+rtrim(CONVERT(char(10),@Suma_imp_separat_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca,'V',@den_suma_imp_separat,@ore_procent,@Suma_imp_separat,@conditie1, @conditie2, @conditie3, 0, 'V'
		End
		if @compensatie<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_compensatie, '', @compensatie, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @Diurna_neimp<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_diurna_neimp, '', @Diurna_neimp, @conditie1, @conditie2, @conditie3, 0, 'V'
		if @avmat_impozabil<>0
		Begin
			set @ore_procent=(case when @avmat_impozabil_net<>0 then 'net '+rtrim(CONVERT(char(10),@avmat_impozabil_net)) else '' end)
			exec scriu_fluturasi @HostID, @marca,'V',@den_avmat_impozabil,@ore_procent,@avmat_impozabil,@conditie1, @conditie2, @conditie3, 0, 'V'
		End

		fetch next from cursor_fluturasi_corectii into
			@Marca, @Premiu_la_avans, @corZ, @corX, @corY, @CMCAS, @CMunitate, @CO,@Restituiri, @Diminuari, @Suma_impozabila, @Premiu, 
			@Diurna, @Cons_admin, @Sp_salar_realizat, @Suma_neimp, @Suma_neimp2, @Suma_imp_separat, @Compensatie, @Realizat_acord,
			@CorZ_net, @CorX_net, @CorY_net, @CO_net, @Restituiri_net, @Suma_impozabila_net, @Premiu_net, @Diurna_net, @Cons_admin_net, 
			@Suma_imp_separat_net, @Diurna_neimp, @avmat_impozabil_net, @avmat_impozabil
	End
	close cursor_fluturasi_corectii 
	Deallocate cursor_fluturasi_corectii
End
