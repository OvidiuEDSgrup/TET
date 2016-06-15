--***
/**	procedura calcul acord salarii	*/
Create procedure calcul_acord_salarii
	(@dDataJ datetime, @dDataS datetime, @Acord_individual int, @Cu_validare_pontaj int, @Acord_global int, @pMarca char(6), @pLoc_de_munca char(9))
As
Begin
	declare @Utilizator char(10), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @nRealizari int, @lAcord_global_Tesa_acord int, @lAcord_indiv_Tesa_acord int, @lIndici_pontaj_lm int, 
	@Dafora int, @lApelare_proc_acord_1 int, @lApelare_proc_acord_2 int

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	SET @Utilizator = dbo.fIaUtilizator('')
	IF @Utilizator IS NULL or @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		RETURN -1
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
--	verific luna inchisa	
	IF @dDataS<=@dDataInch
	Begin
		raiserror('(calcul_acord_salarii) Luna pe care doriti sa efectuati calcul acord este inchisa!' ,16,1)
		RETURN -1
	End	

	Set @nRealizari=dbo.iauParN('PS','REALIZARI')
	Set @lAcord_global_Tesa_acord=dbo.iauParL('PS','ACGLOTESA')
	Set @lAcord_indiv_Tesa_acord=dbo.iauParL('PS','ACINDTESA')
	Set @lIndici_pontaj_lm=dbo.iauParL('PS','INDICIPLM')
	Set @Dafora=dbo.iauParL('SP','DAFORA')
	Set	@lApelare_proc_acord_1=dbo.iauParL('PS','PROC1')
	Set @lApelare_proc_acord_2=dbo.iauParL('PS','PROC2')

	If @lApelare_proc_acord_1=1
		exec calcsalariisp1 @dDataJ, @dDataS, @pMarca
	if @lIndici_pontaj_lm=0
		update pontaj set realizat=0, coeficient_acord=0, ore_realizate_acord=0 where data between @dDataJ and @dDataS and tip_salarizare in ('1','3')
	If @Acord_individual=1
		exec psacord_ind @dDataJ, @dDataS, @Cu_validare_pontaj, @pMarca
	If @Acord_global=1
	Begin
		If @nRealizari<>3
			exec calcul_acord_global_comenzi @dDataJ, @dDataS, @pMarca, @pLoc_de_munca
		Else
			exec calcul_acord_global_valoric @dDataJ, @dDataS, @pMarca, @pLoc_de_munca

		If not(@lAcord_global_Tesa_acord=1 or @lAcord_indiv_Tesa_acord=1)
			exec dbo.calcul_Tesa_acord @dDataJ, @dDataS, @pMarca, @pLoc_de_munca
		If @Dafora=0
			exec dbo.calcul_acord_categoria_lucrarii @dDataJ, @dDataS, @pMarca, @pLoc_de_munca
	End
	If @lApelare_proc_acord_2=1
		exec calcsalariisp2 @dDataJ, @dDataS, @pMarca
End
