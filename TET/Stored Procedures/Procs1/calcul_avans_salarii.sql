--***
/**	procedura calcul avans salarii	*/
Create procedure calcul_avans_salarii
	@DataJ datetime,@DataS datetime,@pMarca char(6),@pLocmJ char(9),@pLocmS char(9),@Generare_corI int,@Avans_0_plecati int
As
Begin
	declare @Utilizator char(10), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @marca char(6), @Locm char(9), @Salar_calcul float, @Data_ang datetime, @Plecat int, @Data_plecarii datetime, 
	@Gasit_avexcep int, @Ore_lucrate_la_avans float, @Suma_avans float, @Premiu_la_avans float, @Gasit_CM int, @Zile_lucratoare_CM int, @Gasit_CM2ani int, @Gasit_CM85 int, @Zile_lucrate int, 
	@Impozit float, @Zile_pt_avans int, @Avans_de_dat float, @Avans_programat float, @Avans_CM float, @Zile_lucr_CM115 int, @Ore_luna float, @Ore_luna_marca float, @Zile_luna float, 
	@nProcent_avans float, @nOre_avans float, @nOre_avans_marca int, @Oreav_baza_cavexcep int, @Avans_plecati_luna int, @NUavans_ang_luna int, @Ziua_ang_luna int, 
	@NUavans_CM85 int, @Avans_proc_CM int, @Proc_avans_CM float, @Config_avans_marca int, @Rot_avans int, @lBuget int, @Dafora int, @CondCM1 int, @CondCM2 int, @lApel_procav1 int, @lApel_procav2 int, 
	@suspendat int, @data_inc_susp datetime, @data_sf_susp datetime

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	SET @Utilizator = dbo.fIaUtilizator('')
	IF @Utilizator IS NULL or @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		RETURN -1
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
--	verific luna inchisa
	IF @DataS<=@dDataInch
	Begin
		raiserror('(calcul_avans_salarii) Luna pe care doriti sa efectuati calcul avans este inchisa!' ,16,1)
		RETURN -1
	End	

	Set @Ore_luna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	Set @Zile_luna=@Ore_luna/8
	Set @nProcent_avans=dbo.iauParN('PS','PROCAV')
	Set @nOre_avans=dbo.iauParN('PS','OREAVANS')
	Set @Oreav_baza_cavexcep=dbo.iauParL('PS','BAZAOREAV')
	Set @Avans_plecati_luna=dbo.iauParL('PS','AV_SPLUNA')
	Set @NUavans_ang_luna=dbo.iauParL('PS','AV_ANGLUN')
	Set @Ziua_ang_luna=dbo.iauParN('PS','AV_ANGLUN')
	Set @Ziua_ang_luna=(case when @Ziua_ang_luna=0 then 1 else @Ziua_ang_luna-1 end)
	Set @NUavans_CM85=dbo.iauParL('PS','AV_NUCM85')
	Set @Avans_proc_CM=dbo.iauParL('PS','AV_%CM')
	Set @Proc_avans_CM=dbo.iauParN('PS','AV_%CM')
	Set @Config_avans_marca=dbo.iauParL('PS','CAV_MARCA')
	Set @Rot_avans=(case when dbo.iauParN('PS','ROTAV')=0 then 1 else dbo.iauParN('PS','ROTAV') end)
	Set @lBuget=dbo.iauParL('PS','UNITBUGET')
	Set @Dafora=dbo.iauParL('SP','DAFORA')
	Set @lApel_procav1=dbo.iauParL('PS','PROCAV1')
	Set @lApel_procav2=dbo.iauParL('PS','PROCAV2')
	If @lApel_procav1=1
		exec calcavanssp1 @DataJ, @DataS, @pMarca

--	sterg avans pt. cei plecati anterior lunii de lucru
	delete net from personal p 
	where data between @DataJ and @DataS and net.marca=p.marca and (@pmarca='' or net.marca=@pmarca) 
	and (@pLocmJ='' or net.loc_de_munca between rtrim(@pLocmJ) and rtrim(@pLocmS)) and p.loc_ramas_vacant=1
--	anulare calcul anterior
	update net set avans=0
	where data between @DataJ and @DataS and (@pmarca='' or marca=@pmarca) 
	and (@pLocmJ='' or loc_de_munca between rtrim(@pLocmJ) and rtrim(@pLocmS))

--	selectare salariati suspendati in luna.
	if OBJECT_ID('tempdb..#suspendari') is not null drop table #suspendari
	select Marca, min(data_inceput) as data_inceput, max(data_final) as data_final 
	into #suspendari
	from fRevisalSuspendari (@DataJ, @DataS, @pMarca)
	group by Marca

	Declare cursor_avans Cursor For
	Select p.Marca, p.Loc_de_munca, (case when @lBuget=0 then p.Salar_de_incadrare else p.Salar_de_baza end), 
		p.Data_angajarii_in_unitate,p.Loc_ramas_vacant, p.Data_plec, isnull(a.Gasit_avexcep,0), isnull(a.Ore_lucrate_la_avans,0), isnull(a.Suma_avans,0), 
		isnull(a.Premiu_la_avans,0), isnull(cm.CM,0), isnull(cm.Zile_lucratoare,0), isnull(cm2.CM2ani,0), isnull(cm85.CM85,0),
		(case when p.Loc_ramas_vacant=1 and month(p.Data_plec)=month(@DataS) and year(p.Data_plec)=year(@DataS) and @Avans_plecati_luna=1 then dbo.Zile_lucratoare(@DataJ, p.Data_plec) else 0 end), 
		@nOre_avans/8*(case when p.Grupa_de_munca='C' and p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end),
		@Ore_luna/8*(case when p.Grupa_de_munca='C' and p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end), 
		(case when s.Marca is not null then 1 else 0 end), isnull(s.Data_inceput,'01/01/1901'), isnull(s.Data_final,'01/01/1901')
	from personal p 
		left outer join (select marca, sum(Zile_lucratoare) as Zile_lucratoare, count(1) as CM from conmed where data between @DataJ and @DataS group by marca ) cm on @NUavans_CM85=1 and cm.Marca=p.Marca
		left outer join (select marca, count(1) as CM85 from conmed where data between @DataJ and @DataS and tip_diagnostic in ('0-','8-') 
			group by marca having sum(zile_lucratoare)=@Zile_luna) cm85 on @NUavans_CM85=1 and cm85.Marca=p.Marca
		left outer join (select marca, sum(Zile_lucratoare) as Zile_CM2ani, count(1) as CM2ani from conmed where data between @DataJ and @DataS and tip_diagnostic='0-' 
			group by marca having sum(zile_lucratoare)=@Zile_luna) cm2 on cm2.Marca=p.Marca
		left outer join (select Marca, Ore_lucrate_la_avans, Suma_avans, Premiu_la_avans, 1 as Gasit_avexcep from avexcep where data between @DataJ and @DataS) a on p.Marca=a.Marca
		left outer join #suspendari s on s.Marca=p.Marca
	where (@pmarca='' or p.marca=@pmarca) and (@pLocmJ='' or p.loc_de_munca between rtrim(@pLocmJ) and rtrim(@pLocmS)) 
		and p.data_angajarii_in_unitate<=@DataS 
	order by p.marca

	open cursor_avans
	fetch next from cursor_avans into @Marca, @Locm, @Salar_calcul, @Data_ang, @Plecat, @Data_plecarii, @Gasit_avexcep, @Ore_lucrate_la_avans, @Suma_avans, @Premiu_la_avans, 
		@Gasit_CM, @Zile_lucratoare_CM, @Gasit_CM2ani, @Gasit_CM85, @Zile_lucrate, @nOre_avans_marca, @Ore_luna_marca, @suspendat, @data_inc_susp, @data_sf_susp
	While @@fetch_status = 0 
	Begin
		Select @Avans_de_dat=0, @Avans_programat=0, @Avans_CM=0, @Zile_lucr_CM115=0
		if (@Plecat=0 or (@Avans_plecati_luna=0 and @Data_plecarii>@DataS or @Avans_plecati_luna=1 and @Data_plecarii>@DataJ)) 
			and (@NUavans_ang_luna=0 or @Data_ang<=dateadd(day,@Ziua_ang_luna,@DataJ) and (@suspendat=0 or @data_inc_susp<=dateadd(day,@Ziua_ang_luna,@DataJ)))
			and (@suspendat=0 or (@Avans_plecati_luna=0 and @data_sf_susp>@DataS or @Avans_plecati_luna=1 and @data_sf_susp between @DataJ and @DataS))
		Begin
			if @Avans_proc_CM=1 and (@Gasit_avexcep=1 and (@Proc_avans_CM=0 or @Suma_avans=0) or @Proc_avans_CM<>0 and @Gasit_avexcep=0)
				exec calcul_avans_CM @DataJ, @DataS, @Marca, @Avans_CM output, @Zile_lucr_CM115 output

			Set @CondCM1=(case when @Gasit_avexcep=1 and @Oreav_baza_cavexcep=1 and @Ore_lucrate_la_avans=0 and @Suma_avans=0 and @Proc_avans_CM<>0 and @Zile_lucr_CM115<>0 
				and (case when @Zile_lucrate<>0 then @Zile_lucrate else @nOre_avans/8 end)-@Zile_lucr_CM115>0 then 1 else 0 end)
			Set @CondCM2=(case when @Oreav_baza_cavexcep=1 and @Proc_avans_CM<>0 and @Zile_lucr_CM115<>0 then 1 else 0 end)
			Set @Avans_programat=round((case when @Gasit_avexcep=1 and not(@Config_avans_marca=1 and @Suma_avans=0 and @Ore_lucrate_la_avans=1) 
				then @Suma_avans+(case when @Oreav_baza_cavexcep=1 then (case when @CondCM1=1 then 0 else @Salar_calcul*@nProcent_avans/100*@Ore_lucrate_la_avans/@nOre_avans_marca end) 
				else @Salar_calcul/@Ore_luna_marca*@Ore_lucrate_la_avans end) else (case when @Gasit_CM2ani=1 then 0 
				else @nProcent_avans*@Salar_calcul/100*(case when @CondCM2=1 then (@nOre_avans/8-@Zile_lucr_CM115)/(@nOre_avans/8) else 1 end)
					+(case when @Oreav_baza_cavexcep=1 then 0 else @Salar_calcul/@Ore_luna_marca*@nOre_avans end) end) end),0)
			if @Dafora=1
			Begin
				Set @Impozit=0
				exec calcul_impozit_salarii @Salar_calcul, @Impozit output, 0
				Set @Zile_pt_avans=11-@Zile_lucratoare_CM
				Set @Avans_programat=round((case when @nProcent_avans=0 then 0 
				when @Zile_pt_avans>5 and (@Gasit_avexcep=0 or @Gasit_avexcep=1 
				and @Suma_avans=0 and @Ore_lucrate_la_avans=1) then (@Salar_calcul-@Impozit)/22*@Zile_pt_avans else 0 end)
				+(case when @Gasit_avexcep=1 then @Suma_avans else 0 end),0)
			End
			if @Avans_proc_CM=1 and (@Gasit_avexcep=1 and (@Proc_avans_CM=0 or @Suma_avans=0 and @CondCM1=0) or 
			@Proc_avans_CM<>0 and @Gasit_avexcep=0)
				Set @Avans_programat=@Avans_programat+@Avans_CM

			Set @Avans_de_dat=(case when @NUavans_CM85=1 and @Gasit_CM85<>0 then 0 else @Avans_programat end)
			update resal set Retinut_la_avans=(case when Valoare_totala_pe_doc>0 then 
				dbo.Valoare_minima(@Avans_de_dat,dbo.valoare_minima(Retinere_progr_la_avans,(case when Valoare_totala_pe_doc-
					isnull((select top 1 Valoare_retinuta_pe_doc from resal r where r.Data<=dbo.bom(resal.Data)-1 and r.Marca=resal.Marca and r.Cod_beneficiar=resal.Cod_beneficiar 
						and r.Numar_document=resal.Numar_document order by data desc),0)<0 
				then 0 else Valoare_totala_pe_doc-isnull((select top 1 Valoare_retinuta_pe_doc from resal r where r.Data<=dbo.bom(resal.Data)-1 and r.Marca=resal.Marca and r.Cod_beneficiar=resal.Cod_beneficiar 
					and r.Numar_document=resal.Numar_document order by data desc),0) end),0),0) else dbo.valoare_minima(Retinere_progr_la_avans,@Avans_de_dat,0) end), 
				Valoare_retinuta_pe_doc=isnull((select top 1 Valoare_retinuta_pe_doc from resal r where r.Data<=dbo.bom(resal.Data)-1 and r.Marca=resal.Marca and r.Cod_beneficiar=resal.Cod_beneficiar 
					and r.Numar_document=resal.Numar_document order by data desc),0)
				+(case when Valoare_totala_pe_doc>0 then dbo.Valoare_minima(@Avans_de_dat,dbo.valoare_minima(Retinere_progr_la_avans,(case when Valoare_totala_pe_doc
					-isnull((select top 1 Valoare_retinuta_pe_doc from resal r where r.Data<=dbo.bom(resal.Data)-1 and r.Marca=resal.Marca and r.Cod_beneficiar=resal.Cod_beneficiar 
						and r.Numar_document=resal.Numar_document order by data desc),0)<0 
				then 0 else Valoare_totala_pe_doc-isnull((select top 1 Valoare_retinuta_pe_doc from resal r where r.Data<=dbo.bom(resal.Data)-1 and r.Marca=resal.Marca and r.Cod_beneficiar=resal.Cod_beneficiar 
					and r.Numar_document=resal.Numar_document order by data desc),0) end),0),0) else dbo.valoare_minima(Retinere_progr_la_avans,@Avans_de_dat,0) end)
			where data=@DataS and Marca=@Marca
			Set @Avans_de_dat=(case when @Gasit_avexcep=1 and @Ore_lucrate_la_avans=0 and @Suma_avans<>0 then @Avans_de_dat else (case when @Dafora=1 then round(@Avans_de_dat/@Rot_avans,0,1) 
				else round(@Avans_de_dat/@Rot_avans,0) end)*@Rot_avans end)
			if @Generare_corI=1
				exec scriuCorectii @DataS, @Marca, @Locm, 'I-', @Premiu_la_avans, 0, 0
		End
		if (@Gasit_CM2ani=0 or @Avans_de_dat<>0) 
			and (@Plecat=0 or (@Avans_plecati_luna=0 and (@Data_plecarii>@DataS or @Avans_0_plecati=1 and @Data_plecarii>@DataJ) or @Avans_plecati_luna=1 and @Data_plecarii>@DataJ))
			exec scriuNet_salarii @DataJ, @DataS, @marca, @Locm, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @Avans_de_dat, @Premiu_la_avans, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

		fetch next from cursor_avans into @Marca, @Locm, @Salar_calcul, @Data_ang, @Plecat, @Data_plecarii, @Gasit_avexcep, @Ore_lucrate_la_avans, @Suma_avans, @Premiu_la_avans, 
			@Gasit_CM, @Zile_lucratoare_CM, @Gasit_CM2ani, @Gasit_CM85, @Zile_lucrate, @nOre_avans_marca, @Ore_luna_marca, @suspendat, @data_inc_susp, @data_sf_susp
	End
	exec scriuIstPers @DataJ, @DataS, @pMarca, @pLocmJ, 1, 1
	close cursor_avans
	Deallocate cursor_avans 
	If @lApel_procav2=1
		exec calcavanssp2 @DataJ, @DataS, @pMarca
End
