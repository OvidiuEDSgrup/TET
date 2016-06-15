--***
/**	proc. calcul acord global val.	*/
Create 
procedure calcul_acord_global_valoric
	(@dDataJ datetime, @dDataS datetime, @pMarca char(6), @pLoc_de_munca char(9))
As
Begin
	declare @Loc_de_munca char(9), @Manop_realiz_locm float, @Ore_realiz_locm int, @Manop_pontaj_locm float, @Ore_pontaj_locm int, @Coef_acord_locm float, @Coef_timp_locm float, @Samobil int, @Modatim int, @lAcord_global_Tesa_acord int, @lOresupl1_oreac int, @lOresupl2_oreac int, @lOresupl3_oreac int, @lOresupl4_oreac int, @nOre_luna float, @nNrm_luna float
	Set @Modatim=dbo.iauParL('SP','MODATIM')
	Set @Samobil=dbo.iauParL('SP','SAMOBIL')
	Set @lAcord_global_Tesa_acord=dbo.iauParL('PS','ACGLOTESA')
	Set @lOresupl1_oreac=dbo.iauParL('PS','ACORD-OS1')
	Set @lOresupl2_oreac=dbo.iauParL('PS','ACORD-OS2')
	Set @lOresupl3_oreac=dbo.iauParL('PS','ACORD-OS3')
	Set @lOresupl4_oreac=dbo.iauParL('PS','ACORD-OS4')
	Set @nOre_Luna=dbo.iauParLN(@dDataS,'PS','ORE_LUNA')
	Set @nNrm_luna=dbo.iauParLN(@dDataS,'PS','NRMEDOL')

	declare cursor_acord_valoric cursor for
	select Loc_de_munca, sum(round(convert(decimal(10,2),Valoare_manopera),2)), sum(Ore_realizate_in_acord),
		isnull((select sum(round((case when a.Tip_salarizare='7' then a.Salar_categoria_lucrarii else 
		p.Salar_de_incadrare/((case when a.Tip_salarizare='2' then @nOre_luna else @nNrm_Luna end)
		*(case when p.Grupa_de_munca in ('C','O','P') then a.Regim_de_lucru/8 else 1 end )) end)
		*(a.Ore_acord-(case when @lOresupl1_oreac=1 then a.Ore_suplimentare_1 else 0 end)
		-(case when @lOresupl2_oreac=1 then a.Ore_suplimentare_2 else 0 end)
		-(case when @lOresupl3_oreac=1 then a.Ore_suplimentare_3 else 0 end)
		-(case when @lOresupl4_oreac=1 then a.Ore_suplimentare_4 else 0 end)
		+(case when @Samobil=1 then a.Ore_suplimentare_1 else 0 end)),2)) 
		from pontaj a left outer join personal p on a.marca=p.marca
		where a.data between @dDataJ and @dDataS and a.Loc_de_munca=r.Loc_de_munca
		and (a.Tip_salarizare in ('5','7') or @lAcord_global_Tesa_acord=1 and a.Tip_salarizare='2')),0),
		isnull((select sum(a.Ore_acord-(case when @lOresupl1_oreac=1 then a.Ore_suplimentare_1 else 0 end)
		-(case when @lOresupl2_oreac=1 then a.Ore_suplimentare_2 else 0 end)
		-(case when @lOresupl3_oreac=1 then a.Ore_suplimentare_3 else 0 end)
		-(case when @lOresupl4_oreac=1 then a.Ore_suplimentare_4 else 0 end)
		+(case when @Samobil=1 then a.Ore_suplimentare_1 else 0 end))
		from pontaj a where a.data between @dDataJ and @dDataS and a.Loc_de_munca=r.Loc_de_munca
		and (a.Tip_salarizare in ('5','7') or @lAcord_global_Tesa_acord=1 and a.Tip_salarizare='2')),0)
	from reallmun r
	where data between @dDataJ and @dDataS and (@pLoc_de_munca='' or Loc_de_munca=@pLoc_de_munca)
	Group By Loc_de_munca

	open cursor_acord_valoric
	fetch next from cursor_acord_valoric into @Loc_de_munca, @Manop_realiz_locm, @Ore_realiz_locm, @Manop_pontaj_locm, @Ore_pontaj_locm
	while @@fetch_status = 0
	Begin
		Set @Coef_acord_locm=round(convert(decimal(15,6),@Manop_realiz_locm/@Manop_pontaj_locm),6)
		Set @Coef_timp_locm=round(convert(decimal(15,6),@Ore_realiz_locm/convert(float,@Ore_pontaj_locm)),6)

		update pontaj set Coeficient_acord=(case when @Modatim=0 then @Coef_acord_locm else Coeficient_acord end), 
		--Coeficient_de_timp=@Coef_timp_locm,
		Ore_realizate_acord=round(@Coef_timp_locm*(Ore_acord-(case when @lOresupl1_oreac=1 then Ore_suplimentare_1 else 0 end)
			-(case when @lOresupl2_oreac=1 then Ore_suplimentare_2 else 0 end)
			-(case when @lOresupl3_oreac=1 then Ore_suplimentare_3 else 0 end)
			-(case when @lOresupl4_oreac=1 then Ore_suplimentare_4 else 0 end)),2), 
		Realizat=round((case when pontaj.Tip_salarizare='7' then Salar_categoria_lucrarii else 
			p.Salar_de_incadrare/((case when pontaj.Tip_salarizare='2' then @nOre_luna else @nNrm_Luna end)
			*(case when p.Grupa_de_munca in ('C','O','P') then Regim_de_lucru/8 else 1 end )) end)
			*(Ore_acord-(case when @lOresupl1_oreac=1 then Ore_suplimentare_1 else 0 end)
			-(case when @lOresupl2_oreac=1 then Ore_suplimentare_2 else 0 end)
			-(case when @lOresupl3_oreac=1 then Ore_suplimentare_3 else 0 end)
			-(case when @lOresupl4_oreac=1 then Ore_suplimentare_4 else 0 end))
			*(case when @Modatim=0 then @Coef_acord_locm else Coeficient_acord end),2)
		from personal p
		where data between @dDataJ and @dDataS and pontaj.marca=p.marca and pontaj.Loc_de_munca=@Loc_de_munca
		and (pontaj.Tip_salarizare in ('5','7') or @lAcord_global_Tesa_acord=1 and pontaj.Tip_salarizare='2')

		update reallmun Set Coeficient_de_acord=@Coef_acord_locm, Coeficient_de_timp=@Coef_timp_locm 
		where Loc_de_munca=@Loc_de_munca and data=@dDataS
		fetch next from cursor_acord_valoric into @Loc_de_munca, @Manop_realiz_locm, @Ore_realiz_locm, @Manop_pontaj_locm, 		@Ore_pontaj_locm
	End
	Close cursor_acord_valoric
	Deallocate cursor_acord_valoric
End
