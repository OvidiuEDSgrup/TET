--***
/**	fluturasi timp nelucrat	*/
Create procedure fluturasi_timp_nelucrat
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit
as
Begin
	declare @Marca char(6),@Ore_intr_tehn1 int,@Ind_intr_tehn1 float,@Ore_intr_tehn2 int,@Ind_intr_tehn2 float, @Ore_intr_tehn3 int, @Ind_intr_tehn3 float, 
	@Ore_obl_cet int, @Ind_obl_cet float, @Ore_cfs int, @Ind_conducere float, @pInd_cond float, @Ore_co int, @Ind_co float, 
	@Ore_cm int, @Ind_cm_unitate float, @Zile_cm_CAS int, @Ind_cm_CAS float, @Ore_invoiri int, @Ore_nemotivate int, @Ind_nemotivate float,
	@Salar_categoria_lucrarii float,@Drumco_TM int,@Salubris int,@Colas int,@den_intr1 char(30),@den_intr2 char(30), @den_intr3 char(30), @den_indcond char(30), 
	@lOZCMMP int, @cOZCMMP char(1), @lFLDTIPCO int, @INDC_suma int, @ore char(20), @cand_scriu bit

	set @den_intr1=dbo.iauParA('PS','PROCINT')
	set @den_intr1=(case when isnull(@den_intr1,'')='' then 'Intrerupere tehn. 1' else @den_intr1 end)
	set @den_intr2=dbo.iauParA('PS','PROC2INT')
	set @den_intr2=(case when isnull(@den_intr2,'')='' then 'Intrerupere tehn. 2' else @den_intr2 end)
	set @Drumco_TM=dbo.iauParL('SP','DRUMCO')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')
	exec Luare_date_par 'PS', 'FLOZCMMP', @lOZCMMP output, 0, @cOZCMMP output
	set @lFLDTIPCO=dbo.iauParL('PS','FLDTIPCO')
	set @INDC_suma=dbo.iauParL('PS','INDC-SUMA')
	set @den_intr3=dbo.iauParA('PS','SCOND8')
	if @den_intr3='' set @den_intr3=dbo.iauParA('PS','PROC3INT')

	set @den_indcond=dbo.iauParA('PS','INDCOND')
	if @den_indcond='' set @den_indcond='Ind. de conducere'

	Declare cursor_fluturasi_timp_nelucrat Cursor For
	select a.Marca, sum(a.Ore_intrerupere_tehnologica), sum(round(a.Ind_intrerupere_tehnologica,0)), sum(a.Ore_intr_tehn_2), 
		sum(round(a.Ind_invoiri,0)), sum(a.Ore_intr_tehn_3), sum(round(a.Spor_cond_8,0)), sum(a.Ore_obligatii_cetatenesti), 
		sum(round(a.Ind_obligatii_cetatenesti,0)), sum(a.Ore_concediu_fara_salar), sum(a.Ind_concediu_fara_salar), 
		max(i.Indemnizatia_de_conducere), sum(a.Ore_concediu_de_odihna), sum(round(a.Ind_concediu_de_odihna,0)), 
		(case when @lOZCMMP=1 then max((case when @cOZCMMP='1' then b.Zile_unitate*a.Spor_cond_10 else b.Zile_unitate end)) else sum(a.Ore_concediu_medical) end), sum(a.Ind_c_medical_unitate), 
		max(case when @lOZCMMP=1 then (case when @cOZCMMP='1' then b.Zile_Stat*a.Spor_cond_10 else b.Zile_Stat end) else 0 end), sum(a.Ind_c_medical_CAS+a.spor_cond_9), 
		sum(a.Ore_invoiri), sum(a.Ore_nemotivate), sum((case when @Salubris=1 and 1=0 then 0 else a.Ind_nemotivate end)), 
		sum((case when @Salubris=1 then 0 else a.Salar_categoria_lucrarii end)) 
	from tmpfluturi a
		left outer join istpers i on i.data=a.data and i.marca=a.marca
		left outer join (select Data, Marca, sum(Zile_cu_reducere) as Zile_Unitate, sum(Zile_lucratoare-Zile_cu_reducere) as Zile_Stat from conmed c where c.Data between @Datajos and @Datasus and c.Data_inceput between @Datajos and @Datasus Group by Data,Marca) b on a.Data=b.Data and a.Marca=b.Marca
	where a.Host_ID=@HostID and a.marca=@pmarca
	group by a.data, a.marca

	open cursor_fluturasi_timp_nelucrat
	fetch next from cursor_fluturasi_timp_nelucrat into
		@Marca, @Ore_intr_tehn1, @Ind_intr_tehn1, @Ore_intr_tehn2, @Ind_intr_tehn2, @Ore_intr_tehn3, @Ind_intr_tehn3, @Ore_obl_cet, @Ind_obl_cet, @Ore_cfs, @Ind_conducere, @pInd_cond, 
		@Ore_co, @Ind_co, @Ore_cm, @Ind_cm_unitate, @Zile_cm_CAS, @Ind_cm_CAS, @Ore_invoiri, @Ore_nemotivate, @Ind_nemotivate, @Salar_categoria_lucrarii

	While @@fetch_status = 0 
	Begin
		if @Ore_intr_tehn1<>0 or @Ind_intr_tehn1<>0
		Begin
			Set @ore=str(@ore_intr_tehn1,3)+' ore'
			Set @cand_scriu=(case when @Ore_intr_tehn1<>0 or @Ind_intr_tehn1<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_intr1, @ore, @Ind_intr_tehn1, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if @Ore_intr_tehn2<>0 or @Ind_intr_tehn2<>0
		Begin
			Set @ore=str(@ore_intr_tehn2,3)+(case when @Drumco_TM=1 then ' zile' else ' ore' end)
			Set @cand_scriu=(case when @Ore_intr_tehn2<>0 or @Ind_intr_tehn2<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_intr2, @ore, @Ind_intr_tehn2, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if @Ore_intr_tehn3<>0
		Begin
			Set @ore=str(@ore_intr_tehn3,3)+' ore'
			Set @cand_scriu=(case when @Ore_intr_tehn3<>0 or @Ind_intr_tehn3<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_intr3, @ore, @Ind_intr_tehn3, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if @Ind_obl_cet<>0
		Begin
			Set @ore=str(@Ore_obl_cet,3)+' ore'
			exec scriu_fluturasi @HostID, @marca, 'V', 'Obligatii cetatenesti', @Ore, @Ind_obl_cet, @conditie1, @conditie2, @conditie3, 0, 'V'
		End
		if @Ore_cfs<>0
		Begin
			Set @ore=str(@Ore_cfs,3)+' ore'
			Set @cand_scriu = (case when @ore_cfs<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', 'Concediu fara salar', @Ore, 0, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if @Ind_conducere<>0
			exec scriu_fluturasi @HostID, @marca, 'V', 'Donare de sange', '', @Ind_conducere, @conditie1, @conditie2, @conditie3, 0, 'V'
		if (@Ore_co<>0 or @Ind_co<>0) and @lFLDTIPCO=0
		Begin
			Set @ore=str(@ore_co,3)+' ore'
			Set @cand_scriu=(case when @Ore_co<>0 or @Ind_co<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', 'Concediu de odihna', @Ore, @Ind_co, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if (@Ore_co<>0 or @Ind_co<>0) and @lFLDTIPCO=1
		Begin
			if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'fluturasi_tip_COSP') and type='P')
				exec fluturasi_tip_COSP @datajos, @datasus, @HostID, @marca, @conditie1, @conditie2, @conditie3
			else 
				exec fluturasi_tip_CO @datajos, @datasus, @HostID, @marca, @conditie1, @conditie2, @conditie3
		End	
		if @ore_cm<>0 or @Ind_cm_unitate<>0
		Begin
			Set @ore=str(@ore_cm,3)+(case when @lOZCMMP=1 and @cOZCMMP='2' then ' zile' else ' ore' end)
			Set @cand_scriu = (case when @ore_cm<>0 or @Ind_cm_unitate<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', 'Concediu medical', @ore, @Ind_cm_unitate, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End	
		If @Ind_cm_cas<>0
		Begin
			Set @ore=(case when @lOZCMMP=1 then str(@Zile_cm_CAS,3)+(case when @cOZCMMP='1' then ' ore' else ' zile' end) else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', 'Ind c medical (CAS)', @Ore, @Ind_cm_cas, @conditie1, @conditie2, @conditie3, 0, 'V'
		End
		if @Ore_invoiri<>0
		Begin
			Set @ore=str(@ore_invoiri,3)+' ore'
			Set @cand_scriu = (case when @ore_invoiri<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca,'V','Invoiri', @Ore, 0, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		If @ore_nemotivate<>0
		Begin
			Set @ore=str(@ore_nemotivate,3)+' ore'
			Set @cand_scriu = (case when @ore_nemotivate<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', 'Ore nemotivate', @Ore, 0, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		if @Ind_nemotivate<>0
		Begin
			Set @ore = (case when @INDC_suma=0 then ltrim(str(@pInd_cond,10,2))+'%' else '' end)
			exec scriu_fluturasi @HostID, @marca, 'V', @den_indcond, @Ore, @Ind_nemotivate, @conditie1, @conditie2, @conditie3, 0, 'V'
		End
		if @Salar_categoria_lucrarii<>0
			exec scriu_fluturasi @HostID, @marca, 'V', 'Sal. categ. lucrarii', '', @Salar_categoria_lucrarii, @conditie1, @conditie2, @conditie3, 0, 'V'

		fetch next from cursor_fluturasi_timp_nelucrat into
			@Marca, @Ore_intr_tehn1, @Ind_intr_tehn1, @Ore_intr_tehn2, @Ind_intr_tehn2, @Ore_intr_tehn3, @Ind_intr_tehn3, @Ore_obl_cet, @Ind_obl_cet, @Ore_cfs, @Ind_conducere, @pInd_cond, 
			@Ore_co, @Ind_co, @Ore_cm, @Ind_cm_unitate, @Zile_cm_CAS, @Ind_cm_CAS, @Ore_invoiri, @Ore_nemotivate, @Ind_nemotivate, @Salar_categoria_lucrarii 
	End
	close cursor_fluturasi_timp_nelucrat 
	Deallocate cursor_fluturasi_timp_nelucrat
End
