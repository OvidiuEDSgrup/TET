--***
/**	functie calcul Coef acord ARL	*/
Create
function calcul_coeficient_acord_ARL
	(@dDataJ datetime, @dDataS datetime, @pLoc_de_munca char(9))
returns float
As
Begin
	declare @Coef_acord_ARL float, @nNrm_luna float
	Set @nNrm_luna=dbo.iauParLN(@dDataS,'PS','NRMEDOL')
	Set @Coef_acord_ARL=isnull((select round(convert(decimal(15,6),sum(round((case when a.Tip_salarizare='7' then a.Coeficient_acord*a.Ore_acord*a.Salar_categoria_lucrarii else a.Realizat end),6))
	/sum(round(a.Ore_acord*(p.Salar_de_incadrare/@nNrm_luna),6))),6) from pontaj a
	left outer join personal p on a.marca=p.marca
	where a.Data between @dDataJ and @dDataS and a.loc_de_munca like rtrim(@pLoc_de_munca)+'%' 
	and a.tip_salarizare between '4' and '7'),0)
	return @Coef_acord_ARL 
End
