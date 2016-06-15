--***
/**	procedura pentru calcul venit total in tabelele brut si net */
create procedure CalculVenitTotal
	@datajos datetime, @datasus datetime, @marca varchar(6)=null, @lm varchar(9)=null, @din_inversare int=0
As
Begin try
	declare @Pasmatex int, @Dafora int, @Generalcom int, @Elcond int, @Dsvet int, @Abrom int, @Comp_SN int, @Salnetv int, @Salnetv_CM int, @Sbaza_SP int, @Sbaza_S1 int, @Sbaza_indc int, 
	@FaraCAS_H int, @CAS_J int, @Faraasig_N int, @indc_fore int, @indc_suma int, @Calc_CAS_U bit, @Cor_U float, @lBuget int, @COEV_macheta int, @Ore_luna float, @Nrm_luna float, 
	@indc_calc float, @Suma_except_invers float, @Suma_timp_nelucrat float, @venit_total float, @Suma_net_condN float, @Suma_net_condD float, @Suma_net_condS float, @spor_cond_2 float

	Exec Luare_date_par 'SP', 'PASMATEX', @Pasmatex output , 0, 0
	Exec Luare_date_par 'SP', 'DAFORA', @Dafora output, 0, 0
	Exec Luare_date_par 'SP', 'GENCOM', @Generalcom output , 0, 0
	Exec Luare_date_par 'SP', 'ELCOND', @Elcond output , 0, 0
	Exec Luare_date_par 'SP', 'DSVET', @Dsvet output , 0, 0
	Exec Luare_date_par 'SP', 'ABROM', @Abrom output , 0, 0
	Exec Luare_date_par 'PS', 'COMPSALN', @Comp_SN output , 0, 0
	Exec Luare_date_par 'PS', 'SALNETV', @Salnetv output , 0, 0
	Exec Luare_date_par 'PS', 'SALNPO-CM', @Salnetv_CM output , 0, 0
	Exec Luare_date_par 'PS', 'IND-FORE', @indc_fore output , 0, 0
	Exec Luare_date_par 'PS', 'INDC-SUMA', @indc_suma output , 0, 0
	Exec Luare_date_par 'PS', 'SBAZA-IND', @Sbaza_indc output , 0, 0
	Exec Luare_date_par 'PS', 'S-BAZA-SP', @Sbaza_SP output , 0, 0
	Exec Luare_date_par 'PS', 'S-BAZA-S1', @Sbaza_S1 output , 0, 0
	Exec Luare_date_par 'PS', 'UNITBUGET', @lBuget output , 0, 0
	Exec Luare_date_par 'PS', 'NUCAS-H', @FaraCAS_H output , 0, 0
	Exec Luare_date_par 'PS', 'CAS-J', @CAS_J output , 0, 0
	Exec Luare_date_par 'PS', 'NUASS-N', @Faraasig_N output , 0, 0
	Exec Luare_date_par 'PS', 'CALCAS-U', @Calc_CAS_U output , 0, 0
	Exec Luare_date_par 'PS', 'COEVMCO', @COEV_macheta output , 0, 0
	Set @Ore_luna = dbo.iauParLN(@datasus,'PS','ORE_LUNA')
	Set @Nrm_luna = dbo.iauParLN(@datasus,'PS','NRMEDOL')

	if @marca is null set @marca=''
	if @lm is null set @lm=''
	select @indc_calc = 0, @Suma_except_invers = 0, @Venit_total = 0, @Suma_timp_nelucrat = 0, @Suma_net_condN=0, @Suma_net_condD=0, @Suma_net_condS=0

	if object_id('tempdb..#cpersonal') is not null drop table #cpersonal
	if object_id('tempdb..#pontaj_grpm') is not null drop table #pontaj_grpm
	if object_id('tempdb..#corectiiU') is not null drop table #corectiiU
	if object_id('tempdb..#corectiiAMI') is not null drop table #corectiiAMI	--	tabela pentru corectii avantaje materiale impozabile.

	select * into #cpersonal
	from personal
	where (@marca='' or marca=@marca) 
		and (@lm='' or loc_de_munca between rtrim(@lm) and rtrim(@lm)+'ZZZ')
	create index marca on #cpersonal (marca)

--	anulare calcul anterior
	update b set b.venit_total = 0 
	from brut b
		inner join #cpersonal p on p.marca = b.marca
	where b.data = @datasus 

--	pun datele citite mai jos in tabele temporare; cu outer apply mergea greu
	select j.marca, j.loc_de_munca, max(j.grupa_de_munca) as grupa_de_munca into #pontaj_grpm
	from pontaj j 
		inner join #cpersonal p on p.marca=j.marca
	where j.data between @datajos and @datasus 
	group by j.marca, j.loc_de_munca

	select c.marca, c.Loc_de_munca, sum(suma_corectie) as corectie_U 
	into #corectiiU
	from corectii c 
		inner join #cpersonal p on p.marca=c.marca
	where c.data between @datajos and @datasus and c.tip_corectie_venit='U-'
	group by c.marca, c.Loc_de_munca

	select a.marca, a.Loc_de_munca, sum(a.suma_corectie) as avantaj_impozabil
	into #corectiiAMI
	from dbo.fSumeCorectie (@dataJos, @dataSus, 'AI', @marca, @lm, 1) a
		inner join #cpersonal p on p.marca=a.marca
	group by a.marca, a.Loc_de_munca

--	calcul venit total, indemnizatie conducere in brut
	update b set 
--	calcul indemnizatie de conducere
		@indc_calc=isnull(round(p.indemnizatia_de_conducere*(case when @indc_suma=0 then p.Salar_de_incadrare/100 else 1 end)*
			(case when b.ore_lucrate_regim_normal>=@ore_luna or @indc_fore=1 then 1 else b.ore_lucrate_regim_normal/(@ore_luna/8*(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)) end),0),0)
--	calcul sume exceptate de la inversare
		,@Suma_except_invers = (case when (@Comp_SN=1 or @Salnetv=1 or @Salnetv_CM=1) AND @din_inversare=1 then 0 else b.ind_c_medical_unitate+b.ind_c_medical_cas+b.cmcas+b.cmunitate+b.spor_cond_9 end)
			+(case when @Comp_SN=1 and @din_inversare=1 then 0 else round(ind_concediu_de_odihna,0)+(case when @Salnetv_CM=1 and @din_inversare=1 then 0 else b.premiu end)+b.co end)
			+(case when @Salnetv_CM=1 and @din_inversare=1 then 0 else b.restituiri+b.Cons_admin+b.sp_salar_realizat+b.Suma_imp_separat-b.Diminuari+isnull(am.avantaj_impozabil,0) end)
--	calcul venit total
		,@Venit_total = b.realizat__regie+b.realizat_acord+b.indemnizatie_ore_supl_1+b.indemnizatie_ore_supl_2+b.indemnizatie_ore_supl_3+b.indemnizatie_ore_supl_4
			+b.indemnizatie_ore_spor_100+round(b.ind_ore_de_noapte,0)+round(b.ind_intrerupere_tehnologica,0)
			+round(ind_obligatii_cetatenesti,0)+round(b.ind_concediu_fara_salar,0)+round(b.salar_categoria_lucrarii,0)+@Suma_except_invers
			+b.Suma_impozabila+(case when @Dafora=1 then 0 else b.Diurna end)+round(b.ind_invoiri,0)
			+(case when @lBuget=1 and @Sbaza_sp=1 then 0 else round(b.spor_specific,0) end)+round(b.spor_de_functie_suplimentara,0)
				+(case when @lBuget=1 and @Sbaza_s1=1 then 0 else round(b.spor_cond_1,0) end)+round(b.Spor_cond_2,0)+round(b.Spor_cond_3,0)
				+round(b.spor_cond_4,0)+round(b.spor_cond_5,0)+round(b.Spor_cond_6,0)+round(b.spor_cond_7,0)+round(b.Spor_cond_8,0)
				+round(b.spor_sistematic_peste_program,0)+round(b.spor_vechime,0)+(case when @lBuget=1 and @Sbaza_indc=1 then 0 else @indc_calc end)
--	calcul sume aferente timpului nelucrat
		,@Suma_timp_nelucrat = @Suma_except_invers + (case when @FaraCAS_H=1 then 0 else b.suma_impozabila end)
			+b.Spor_vechime+round(b.spor_de_functie_suplimentara,0)+(case when @lBuget=1 and @Sbaza_indc=1 then 0 else @indc_calc end)
			+(case when @ABROM=1 or @DAFORA=1 or @PASMATEX=1 or @CAS_J=1 then b.Diurna else 0 end)
			+(case when @ELCOND=1 or @COEV_macheta=1 then round(ind_obligatii_cetatenesti,0) else 0 end)
			+(case when @DSVET=1 then (case when 1=0 then round(b.spor_cond_1,0) else 0 end)+round(b.spor_cond_3,0)+round(b.spor_cond_4,0) else 0 end)
			+(case when @Calc_CAS_U=1 then isnull(corectie_U,0) else 0 end)
		,b.Ind_nemotivate = @indc_calc, b.venit_total = @venit_total
		,b.venit_cond_normale = b.venit_cond_normale + (case when pj.Grupa_de_munca='N' then @Suma_timp_nelucrat 
				when p.Grupa_de_munca in ('N','C','P') or p.Grupa_de_munca='O' and @Pasmatex=1 then @Suma_timp_nelucrat else 0 end)
		,b.venit_cond_deosebite = b.venit_cond_deosebite + (case when pj.Grupa_de_munca='D' then @Suma_timp_nelucrat 
				when p.Grupa_de_munca='D' then @Suma_timp_nelucrat else 0 end)
		,b.venit_cond_speciale = b.venit_cond_speciale + (case when pj.Grupa_de_munca='S' then @Suma_timp_nelucrat 
				when p.Grupa_de_munca='S' then @Suma_timp_nelucrat else 0 end) 
	from brut b
		inner join #cpersonal p on p.marca = b.marca
		left outer join #pontaj_grpm pj on pj.marca=b.marca and pj.loc_de_munca=b.loc_de_munca
		left outer join #corectiiU c on c.marca=b.marca and c.loc_de_munca=b.Loc_de_munca
		left outer join #corectiiAMI am on am.marca=b.marca and am.loc_de_munca=b.Loc_de_munca
	where b.data = @datasus 

--	specific Generalcom
	if @Generalcom = 1
	Begin
		update b set @spor_cond_2 = (b.realizat__regie+b.spor_vechime)*p.spor_conditii_2/100
			,b.Spor_cond_2=@spor_cond_2
			,b.venit_total = b.venit_total+@spor_cond_2
			,b.venit_cond_normale = b.venit_cond_normale+(case when pj.grupa_de_munca='N' then @spor_cond_2 when p.Grupa_de_munca in ('N','C','P') then @spor_cond_2 else 0 end)
			,b.venit_cond_deosebite = b.venit_cond_deosebite+(case when pj.grupa_de_munca='D' then @spor_cond_2 when p.Grupa_de_munca='D' then @spor_cond_2 else 0 end)
			,b.venit_cond_speciale = b.venit_cond_speciale+(case when pj.grupa_de_munca='S' then @spor_cond_2 when p.grupa_de_munca='S' then @spor_cond_2  else 0 end)
		from brut b
			inner join #cpersonal p on p.marca = b.marca
			outer apply (select max(j.grupa_de_munca) as grupa_de_munca from pontaj j where j.data between @datajos and @datasus and j.marca=b.marca and j.loc_de_munca=b.loc_de_munca) pj 
		where b.data = @datasus 
	End

--	inlocuit procedura calcul_vt_net cu scriptul de mai jos 
--	Exec calcul_vt_net @datajos, @datasus, @marca, @lm
--	calcul venit total din brut tinand cont de suma neimpozabila si premiu la avans
	update b set 
		@Suma_net_condN=(case when pj.grupa_de_munca in ('N','O') then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) 
				when p.Grupa_de_munca in ('N','P','O') then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) else 0 end)
		,@Suma_net_condD=(case when pj.grupa_de_munca='D' then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) 
				when p.Grupa_de_munca='D' then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) else 0 end)
		,@Suma_net_condS=(case when pj.grupa_de_munca='S' then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) 
				when p.Grupa_de_munca='S' then isnull(x.premiu_la_avans,0)+(case when @Faraasig_N=1 then 0 else isnull(n.Suma_neimpozabila,0) end) else 0 end)
		,b.Venit_total=b.Venit_total+@Suma_net_condN+@Suma_net_condD+@Suma_net_condS 
		,venit_cond_normale = venit_cond_normale+@Suma_net_condN
		,venit_cond_deosebite = venit_cond_deosebite+@Suma_net_condD
		,venit_cond_speciale = venit_cond_speciale+@Suma_net_condS 
	from brut b
		inner join #cpersonal p on p.marca = b.marca
		left outer join net n on n.Data=b.Data and n.Marca=b.Marca
		left outer join avexcep x on x.marca = n.marca and x.data = n.data
		outer apply (select top 1 loc_de_munca from brut b1 where b1.data=b.data and b1.marca=b.marca order by b1.data, b1.marca,b1.loc_de_munca) bt
		left outer join #pontaj_grpm pj on pj.marca=b.marca and pj.loc_de_munca=isnull(bt.loc_de_munca,n.Loc_de_munca)
	where b.data = @datasus and b.Loc_de_munca=isnull(bt.loc_de_munca,n.loc_de_munca)

End try 

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura CalculVenitTotal (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
