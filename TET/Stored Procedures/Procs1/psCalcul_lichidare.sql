--***
/**	proc.calcul lichidare	*/
Create procedure psCalcul_lichidare 
	@dataJos datetime, @dataSus datetime, @marcaJos char(6), @locmJos char(9)='', @CePartePrg int=0, @Din_inversare int=0, @Venit_baza_calcul float=0 OUTPUT, @Salar_net float=0 OUTPUT, 
	@Venit_baza_CAS float=0 OUTPUT, @Calcul_brut_net int=0, @Precizie int=0, @Venit_salar_net float=0 OUTPUT, @Dif_venit_net float=0 OUTPUT, @Venit_brut float=0 OUTPUT, 
	@Venit_net_in_impoz float=0 OUTPUT, @Pensie_facultativa float=0 OUTPUT, @GenDimL118 int=0
As
Begin try
	declare @utilizator char(10), @lunaInch int, @anulInch int, @dataInch datetime, @CompSalNet int,@SalNetValuta int,@Salubris int, @Colas int, @Drumor int, @Pyrostop int, 
	@Codben_CONET char(13), @Calcul_GarMat int, @marcaSus char(6), @locmSus char(9), @lApelProc3 int, @lApelProc4 int, @lApelProc5 int, @lApelProc6 int, @lApelProc7 int, @userASiS varchar(20), 
	@par_calc char(9), @val_a char(200), @TipCorectieDiminuare char(2), @multiFirma int, @parXML xml

	SET @Utilizator = dbo.fIaUtilizator('')
	set @lunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @anulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	if @Utilizator IS NULL or @lunaInch not between 1 and 12 or @anulInch<=1901
		RETURN -1
	set @dataInch=dbo.eom(convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))

--	verific luna inchisa	
	IF @dataSus<=@dataInch
	Begin
		raiserror('(psCalcul_lichidare) Luna pe care doriti sa efectuati calcul lichidare este inchisa!' ,16,1)
		RETURN -1
	End	
--	am pus mesajul de mai jos pt. inceput pe BD unde sunt mai multe firme (Angajator). Daca va fi util il vom generaliza
--	mesajul s-a pus pt. a nu permite calculul de lichidare pe o luna > luna inchisa+1
	IF @dataSus>dbo.EOM(DateAdd(month,1,@dataInch)) and exists (select * from sysobjects where name ='par' and xtype='V')
	Begin
		raiserror('(psCalcul_lichidare) Nu puteti efectua calcul lichidare pe aceasta luna, intrucat luna anterioara nu este inchisa!',16,1)
		RETURN -1
	End	

	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @marcaSus=(case when @marcaJos<>'' then @marcaJos else 'ZZZZZZ' end)
	set @locmSus=(case when @locmJos<>'' then rtrim(@locmJos)+'ZZZZZZ' else 'ZZZZZZZZZ' end)
	set @CompSalNet=dbo.iauParL('PS','COMPSALN')
	set @SalNetValuta=dbo.iauParL('PS','SALNETV')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @Drumor=dbo.iauParL('SP','DRUMOR')
	set @Pyrostop=dbo.iauParL('SP','PYROSTOP')
	set @Codben_CONET=dbo.iauParA('PS','CODBCO')
	set @Calcul_GarMat=dbo.iauParL('PS','CALCGMAT')
	set @lApelProc3=dbo.iauParL('PS','PROC3')
	set @lApelProc4=dbo.iauParL('PS','PROC4')
	set @lApelProc5=dbo.iauParL('PS','PROC5')
	set @lApelProc6=dbo.iauParL('PS','PROC6')
	set @lApelProc7=dbo.iauParL('PS','PROC7')
	set @TipCorectieDiminuare=dbo.iauParA('PS','DIML118')
	
	set transaction isolation level read uncommitted

	if @CePartePrg=0 or @CePartePrg=1
	Begin
		/*	Apelez procedura care verifica daca mai exista un calcul de lichidare in derulare. Sa nu se poata rula alta pana ce nu se termina cea care ruleaza. */
		if @Din_inversare=0
		begin
			set @parXML=(select convert(char(10),@dataSus,101) as datal, rtrim(@locmJos) as locm, 'CL' as tip, rtrim(OBJECT_NAME(@@PROCID)) as obiectSQL for xml raw)
			exec pContorizareOperatiiSalarii @sesiune=null, @parXML=@parXML
		end

--	preluare parametrii lunarii
		exec psInitParLunari @dataJos, @dataSus, 0
--	generare corectii pentru diurne (neimpozabile si impozabile) inregistrate in macheta de diurne.
		if exists (select * from sysobjects where name ='pCalculDiurne')
			exec pCalculDiurne @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marcaJos, @lm=@locmJos, @genCorectii=1
--	generare concedii\alte pe luni ulterioare
		exec psGenerareConAlte @dataJos, @dataSus, @marcaJos, @locmJos
		if @lApelProc3=1 and @Din_inversare=0 -- and 1=0
			exec calcsalariisp3 @dataJos, @dataSus, @marcaJos

		if @Calcul_brut_net=1 and @Din_inversare=0 -- and 1=0
		Begin
			if @CompSalNet=1
				exec psCalculComponenteSN @dataJos, @dataSus, @marcaJos 
			if @SalNetValuta=1
				exec psGenerareSalarNet @dataJos, @dataSus, @marcaJos, @locmJos 
			exec psCorectiiBrutNet @dataJos, @dataSus, @marcaJos, @locmJos, @Precizie
		End
--	sterg net, brut, corecti(generate anterior) 
		delete net where data between @dataJos and @dataSus and day(data)<>15 and marca between @marcaJos and @marcaSus 
			and loc_de_munca between @locmJos and @locmSus and avans=0 and premiu_la_avans=0
		delete brut where data between @dataJos and @dataSus and marca between @marcaJos and @marcaSus 
			and loc_de_munca between @locmJos and @locmSus
		delete corectii where @GenDimL118=1 and data=@dataJos and marca between @marcaJos and @marcaSus 
			and loc_de_munca between @locmJos and @locmSus and tip_corectie_venit=@TipCorectieDiminuare
		exec pCalcul_salarii_realizate @dataJos, @dataSus, @marcaJos, @marcaSus, @locmJos, @locmSus
		if @lApelProc4=1
			exec calcsalariisp4 @dataJos, @dataSus, @marcaJos
	End
	if @CePartePrg=0 or @CePartePrg=2
	Begin
		exec Calcul_corectii @dataJos, @dataSus, @marcaJos, @locmJos
		if @Drumor=1
			exec Calcul_coef_acord_Drumor @dataJos, @dataSus, @marcaJos, @locmJos
		exec scriu_brut_din_CM @dataJos, @dataSus, @marcaJos, @locmJos, @Din_inversare
		if @lApelProc5=1
			exec calcsalariisp5 @dataJos, @dataSus, @marcaJos, @locmJos
	End
	if @CePartePrg=0 or @CePartePrg=3
	Begin
		exec CalculVenitTotal @datajos=@dataJos, @datasus=@dataSus, @marca=@marcaJos, @lm=@locmJos, @din_inversare=@Din_inversare

		if @GenDimL118=1
			exec psCalculDiminuariL118 @dataJos, @dataSus, @marcaJos, @locmJos
		if @lApelProc6=1
			exec calcsalariisp6 @dataJos, @dataSus, @marcaJos
	End
	if @CePartePrg=0 or @CePartePrg=4
	Begin
--	scriere in istpers
		exec scriuistPers @dataJos, @dataSus, @marcaJos, @locmJos, 1, 1
--	calcul net
		exec psCalcul_net @dataJos, @dataSus, @marcaJos, @locmJos, @Din_inversare, 0
	End
	if @CePartePrg=0 or @CePartePrg=5
	Begin
		exec psCalcul_net @dataJos, @dataSus, @marcaJos, @locmJos, @Din_inversare, 1
		exec ActExtinfop @dataJos, @dataSus, @marcaJos, @locmJos
		if @Colas=1
			exec calcul_provizioane_salarii @dataJos, @dataSus, @marcaJos, @locmJos, 1, 1
		if @lApelProc7=1
			exec calcsalariisp7 @dataJos, @dataSus, @marcaJos

		Set @par_calc='CAL'+(case when month(@dataSus)<10 then ' ' else '' end)+rtrim(convert(char(2),month(@dataSus)))+convert(char(4),year(@dataSus))
		Set @val_a=rtrim(@Utilizator)+' '+convert(char(10),GETDATE(),103)+' '+convert(char(8),GETDATE(),108)
		exec setare_par 'PS', @par_calc, 'Ultimul calcul', 0, 0, @val_a

		/*	Daca s-a ajuns la final de calcul lichidare, se goleste tabela. */
		delete from contorOperatiiSalarii where tip='CL' and data_lunii=@dataSus and (@multiFirma=0 or Loc_de_munca=@locmJos)
	End

	Select	@Venit_baza_calcul=(case when @Pyrostop=1 then Rest_de_plata else Venit_baza end), @Salar_net=Venit_baza-Impozit, 
			@Venit_baza_CAS=Baza_CAS, @Venit_salar_net=Venit_net, @Dif_venit_net=Ven_net_in_imp-Ded_baza, @Venit_brut=Venit_total, 
			@Venit_net_in_impoz=Ven_net_in_imp
	from net where @Din_inversare=1 and data=@dataSus and marca=@marcaJos

	Select @Pensie_facultativa=Ded_baza
	from net where @Din_inversare=1 and data=@dataJos and marca=@marcaJos
End try

Begin catch
	declare @eroare varchar(2000)
	/*	Daca s-a ajuns aici cu eroare, se goleste tabela. */
	delete from contorOperatiiSalarii where tip='CL' and data_lunii=@dataSus and (@multiFirma=0 or Loc_de_munca=@locmJos)

	set @eroare='Procedura psCalcul_lichidare (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
