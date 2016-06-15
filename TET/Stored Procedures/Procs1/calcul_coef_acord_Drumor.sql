--***
/**	proc. coef. Acord Drumor	*/
Create procedure calcul_coef_acord_Drumor
	@DataJos datetime, @DataSus datetime, @pMarca char(6), @pLocmJos char(9)
As
Begin
	update pontaj set coeficient_acord=(brut.realizat_acord+brut.realizat__regie+brut.sp_salar_realizat)/(pontaj.salar_orar*pontaj.ore_lucrate)
	from brut 
	where pontaj.data between @DataJos and @DataSus and (@pMarca='' or pontaj.marca=@pMarca) 
		and (@pLocmJos='' or pontaj.loc_de_munca like rtrim(@pLocmJos)+'%')
		and pontaj.ore_lucrate<>0 and pontaj.marca=brut.marca and pontaj.loc_de_munca=brut.loc_de_munca and brut.data=@DataSus
End
