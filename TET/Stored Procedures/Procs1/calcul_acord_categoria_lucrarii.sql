--***
/**	proc. calcul acord categ.lucr.	*/
Create
procedure calcul_acord_categoria_lucrarii
(@dDataJ datetime, @dDataS datetime, @pMarca char(6), @pLoc_de_munca char(9))
As
Begin
	declare @Salimob int, @ARLCJ int, @lIndici_pontaj_lm int
	Set @Salimob=dbo.iauParL('SP','SALIMOB')
	Set @ARLCJ=dbo.iauParL('SP','ARLCJ')
	Set @lIndici_pontaj_lm=dbo.iauParL('PS','INDICIPLM')

	update pontaj set Ore_realizate_acord=Ore_acord,
		Realizat=round(Salar_categoria_lucrarii*Ore_acord*
		(case when @Salimob=1 or @lIndici_pontaj_lm=1 or Tip_salarizare='7' then 
		(case when Coeficient_acord=0 then 1 else Coeficient_acord end) else 1 end),2)
	where data between @dDataJ and @dDataS 
		and (@pMarca='' or Marca=@pMarca) and (@pLoc_de_munca='' or Loc_de_munca=@pLoc_de_munca)
		and Tip_salarizare between '6' and (case when @ARLCJ=0 or 1=1 then '7' else '6' end)
End
