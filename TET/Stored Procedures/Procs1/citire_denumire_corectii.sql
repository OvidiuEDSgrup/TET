--***
/**	citire denumire corectii	*/
Create procedure  citire_denumire_corectii
	@den_cmcas char(30) output, @den_cmunitate char(30) output, @den_cm_incasat char(30) output, @den_co char(30) output, 
	@den_corZ char(30) output, @den_co_incasat char(30) output, @den_restituiri char(30) output, @den_diminuari char(30) output, 
	@den_suma_impozabila char(30) output, @den_premiu char(30) output, @den_corX char(30) output, @den_diurna char(30) output, 
	@den_corY char(30) output, @den_cons_admin char(30) output, @den_sp_salar_realizat char(30) output, 
	@den_suma_incasata char(30) output, @den_suma_neimp char(30) output, @den_suma_neimp2 char(30) output, 
	@den_suma_imp_separat char(30) output, @den_dif_impozit char(30) output, @den_avantaje_mat char(30) output, 
	@den_compensatie char(30) output, @den_premii_neimp char(30) output, @den_pensiefunit char(30)='' output, 
	@den_diurna_neimp char(30)='' output, @den_avmat_impozabil char(30)='' output
as
Begin
	Select @den_cmcas = isnull((case when tip_corectie_venit='A-' then denumire else @den_cmcas end),''),
	@den_cmunitate = isnull((case when tip_corectie_venit='B-' then denumire else @den_cmunitate end),''),
	@den_cm_incasat = isnull((case when tip_corectie_venit='C-' then denumire else @den_cm_incasat end),''),
	@den_co = isnull((case when tip_corectie_venit='D-' then denumire else @den_co end),''),
	@den_corZ = isnull((case when tip_corectie_venit='Z-' then denumire else @den_corZ end),''),
	@den_co_incasat = isnull((case when tip_corectie_venit='E-' then denumire else @den_co_incasat end),''),
	@den_restituiri = isnull((case when tip_corectie_venit='F-' then denumire else @den_restituiri end),''),
	@den_diminuari = isnull((case when tip_corectie_venit='G-' then denumire else @den_diminuari end),''),
	@den_suma_impozabila = isnull((case when tip_corectie_venit='H-' then denumire else @den_suma_impozabila end),''),
	@den_premiu = isnull((case when tip_corectie_venit='I-' then denumire else @den_premiu end),''),
	@den_corX = isnull((case when tip_corectie_venit='X-' then denumire else @den_corX end),''),
	@den_diurna = isnull((case when tip_corectie_venit='J-' then denumire else @den_diurna end),''),
	@den_corY = isnull((case when tip_corectie_venit='Y-' then denumire else @den_corY end),''),
	@den_cons_admin = isnull((case when tip_corectie_venit='K-' then denumire else @den_cons_admin end),''),
	@den_sp_salar_realizat = isnull((case when tip_corectie_venit='L-' then denumire else @den_sp_salar_realizat end),''),
	@den_suma_incasata = isnull((case when tip_corectie_venit='M-' then denumire else @den_suma_incasata end),''),
	@den_suma_neimp = isnull((case when tip_corectie_venit='N-' then denumire else @den_suma_neimp end),''),
	@den_suma_neimp2 = isnull((case when tip_corectie_venit='N2' then denumire else @den_suma_neimp2 end),''),
	@den_suma_imp_separat = isnull((case when tip_corectie_venit='O-' then denumire else @den_suma_imp_separat end),''),
	@den_dif_impozit = isnull((case when tip_corectie_venit='P-' then denumire else @den_dif_impozit end),''),
	@den_avantaje_mat = isnull((case when tip_corectie_venit='Q-' then denumire else @den_avantaje_mat end),''),
	@den_compensatie = isnull((case when tip_corectie_venit='R-' then denumire else @den_compensatie end),''),
	@den_premii_neimp = isnull((case when tip_corectie_venit='U-' then denumire else @den_premii_neimp end),''),
	@den_pensiefunit = isnull((case when tip_corectie_venit='T-' then denumire else @den_pensiefunit end),''),
	@den_diurna_neimp = isnull((case when tip_corectie_venit='W-' then denumire else @den_diurna_neimp end),''),
	@den_avmat_impozabil = isnull((case when tip_corectie_venit='AI' then denumire else @den_avmat_impozabil end),'')
	from tipcor
End
