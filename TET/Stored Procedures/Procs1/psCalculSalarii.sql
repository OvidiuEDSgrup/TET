--***
/*
	exemplu de apel
	declare @dataJos datetime, @dataSus datetime, @marcaJos char(6)
	select @dataJos='12/01/2014', @dataSus='12/31/2014', @marcaJos='1268'
	exec psCalculSalarii @dataJos=@dataJos, @dataSus=@dataSus, @marcaJos=@marcaJos, @locmJos='', @CalculCM=0, @CalculCO=0, @CalculAcord=0, @CalculLichidare=1, @CalculBrutNet=0, @Precizie=0, @GenDimL118=0
*/
/**	proc.calcul salarii	*/
Create procedure psCalculSalarii 
	@dataJos datetime, @dataSus datetime, @marcaJos char(6)='', @locmJos char(9)='', @CalculCM int=0, @CalculCO int=0, @CalculAcord int=0, 
	@CalculLichidare int=1, @CalculBrutNet int=0, @Precizie int=0, @GenDimL118 int=0
As
Begin try
	declare @nLunaInch int, @nAnulInch int, @dDataInch datetime, @utilizator char(10), @par_calc char(9), @val_a char(200), @val_d datetime, 
	@Avans0SPL int, @GenerareCORI int, @ReCalcMZ int, @ReCalcCOTip78 int, @multiFirma int, @parXML xml

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)

	SET @utilizator = dbo.fIaUtilizator('')
	if @utilizator IS NULL or @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		RETURN -1
	set @dDataInch=dbo.EOM(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	
--	verific luna inchisa	
	IF @dataSus<=@dDataInch
	Begin
		raiserror('(psCalculSalarii) Luna pe care doriti sa efectuati calcul salarii este inchisa!' ,16,1)
		RETURN -1
	End	

	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Avans0SPL=dbo.iauParL('PS','AV0_SPL')
	set @GenerareCORI=dbo.iauParL('PS','CAV_GCORI')
	set @ReCalcMZ=1 --dbo.iauParL('PS','RMZCALCM')
	set @ReCalcCOTip78=dbo.iauParL('PS','CO-RCIT78')

	/*	Apelaz procedura care verifica daca mai exista un calcul de lichidare in derulare. Sa nu se poata rula alta pana ce nu se termina cea care ruleaza. */
	set @parXML=(select convert(char(10),@dataSus,101) as datal, rtrim(@locmJos) as locm, 'CS' as tip, rtrim(OBJECT_NAME(@@PROCID)) as obiectSQL for xml raw)
	exec pContorizareOperatiiSalarii @sesiune=null, @parXML=@parXML

--	preluare parametrii lunarii
	exec psInitParLunari @dataJos, @dataSus, 0

--	apelare procedura pt. scriere date in salariati (din extinfop). Datele operate in avans in CTRL+D din macheta salariati.
--	trebuie apelata procedura si la calcul salarii (nu doar la Inchidere de luna) pt. datele inregistrate dupa inchiderea lunii anterioare.
		exec Actualizare_date_salariati @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@marcaJos, @pLocm=@locmJos, @calculLich=1

	if @CalculCM=1
		exec calcul_concedii_medicale @dataJos, @dataSus, @marcaJos, '01/01/1901', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @ReCalcMZ, @locmJos

	if @CalculCO=1
		exec calcul_concedii_de_odihna @dataJos,@dataSus,@marcaJos,'01/01/1901',0,0,@locmJos,0,0,0,0,0,'01/01/1901',0,@ReCalcCOTip78

	if @CalculAcord=1
		exec calcul_acord_salarii @dataJos, @dataSus, 1, 0, 1, '', @locmJos

	if @CalculLichidare=1
	Begin
		exec psCalcul_lichidare @dataJos, @dataSus, @marcaJos, @locmJos, 1, 0, 0, 0, 0, @CalculBrutNet, @Precizie, 0, 0, 0, 0, 0, @GenDimL118
		exec psCalcul_lichidare @dataJos, @dataSus, @marcaJos, @locmJos, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @GenDimL118
		exec psCalcul_lichidare @dataJos, @dataSus, @marcaJos, @locmJos, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @GenDimL118
		exec psCalcul_lichidare @dataJos, @dataSus, @marcaJos, @locmJos, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		exec psCalcul_lichidare @dataJos, @dataSus, @marcaJos, @locmJos, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	End

	if @marcaJos='' and (@locmJos='' or exists (select * from sysobjects where name ='par_lunari' and xtype='V'))
	Begin
		Set @val_a=rtrim(@Utilizator)+' '+convert(char(10),@dataSus,103)+' '+convert(char(8),GETDATE(),108)
		Set @val_d=convert(datetime,convert(char(10),getdate(),101),101)
		exec setare_par_lunari @dataSus, 'PS', 'CALCLICH', 'S-a efectuat calcul lichidare', 1, 0, @val_a, @val_d
	End
	/*	Daca s-a ajuns la final de calcul salarii, se goleste tabela. */
	delete from contorOperatiiSalarii where tip='CS' and data_lunii=@dataSus and (@multiFirma=0 or Loc_de_munca=@locmJos)
End try

Begin catch
	declare @eroare varchar(2000)
	/*	Daca s-a ajuns aici cu eroare, se goleste tabela. */
	delete from contorOperatiiSalarii where tip='CS' and data_lunii=@dataSus and (@multiFirma=0 or Loc_de_munca=@locmJos)

	set @eroare='Procedura psCalculSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
