--***
/**	procedura calcul corectii	*/
create procedure calcul_corectii
	@datajos datetime, @datasus datetime, @pmarca char(6), @plocm char(9)
As
Begin try
	declare @data datetime, @marca char(6), @loc_de_munca char(9), @tip_corectie char(2), @suma_corectie float,	@procent_corectie float, @expand_locm int, @CMCAS float, @CMUnitate float, 
	@CO float, @Restituiri float, @Diminuari float, @Suma_impoz float, @Premiu float, @Diurna float, @Cons_admin float, @Procent_lucrat_acord float, @Suma_imp_sep float, @Aj_deces float, 
	@CM_incasat float, @CO_incasat float, @suma_incasata float, @Suma_neimp float, @Dif_impozit float, @salar_incadrare float, @salar_baza float, @salar_calcul float, @IndRN float, 
	@ore_lucrate int, @baza_CorG float, @Realizat_acord float, @regim_variabil float, @regim_de_lucru float, @TipS_pontaj char(1), @TipS_pers char(1), @Sal_catl float, @STip_corectie char(2),
	@REGIMLV int, @PASMATEX int, @SPICUL int, @MODATIM int, @SALUBRIS int, @DRUMOR int, @SOMESANA int, @Unit_bug int, @Ore_luna float, @Nrm_luna float, 
	@CorL_OreAC int, @CorL_SREAC int, @CorL_locm int, @OS1_OreAC int, @OS2_OreAC int, @lSubtip int

	Set @REGIMLV=dbo.iauParL('PS','REGIMLV')
	Set @PASMATEX=dbo.iauParL('SP','PASMATEX')
	Set @SPICUL=dbo.iauParL('SP','SPICUL')
	Set @MODATIM=dbo.iauParL('SP','MODATIM')
	Set @SALUBRIS=dbo.iauParL('SP','SALUBRIS')
	Set @DRUMOR=dbo.iauParL('SP','DRUMOR')
	Set @SOMESANA=dbo.iauParL('SP','SOMESANA')
	Set @Unit_bug=dbo.iauParL('PS','UNITBUGET')
	Set @CorL_OreAC=dbo.iauParL('PS','OREAC-L')
	Set @CorL_SREAC=dbo.iauParL('PS','SREAC-L')
	Set @CorL_locm=dbo.iauParL('PS','CORMLM-L')
	Set @OS1_OreAC=dbo.iauParL('PS','ACORD-OS1')
	Set @OS2_OreAC=dbo.iauParL('PS','ACORD-OS2')
	Set @lSubtip=dbo.iauParL('PS','SUBTIPCOR')
	Set @Ore_luna=dbo.iauParLN(@datasus,'PS','ORE_LUNA')
	Set @Nrm_luna=dbo.iauParLN(@datasus,'PS','NRMEDOL')

	set transaction isolation level read uncommitted
	
	Exec completez_curscor @datajos, @datasus, @pmarca, @plocm

	if exists (select * from sysobjects where name ='calcul_corectiiSP')
		exec calcul_corectiiSP @datajos=@datajos, @datasus=@datasus, @pmarca=@pmarca, @plocm=@plocm

	update net set CM_incasat=0, CO_incasat=0, Suma_incasata=0, Suma_neimpozabila=0, Diferenta_impozit=0 
	where data = @datasus and (@pmarca='' or marca=@pmarca)
		and (@plocm='' or loc_de_munca between rtrim(@plocm) and rtrim(@plocm)+'ZZZ')

	Declare cursor_corectii Cursor For
	Select c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit, c.suma_corectie, c.procent_corectie, c.expand_locm, p.salar_de_incadrare, p.salar_de_baza, p.salar_lunar_de_baza, 
		isnull((select Ind_regim_normal from brut b where b.data=@datasus and b.marca=c.marca and b.loc_de_munca=c.loc_de_munca),0),
		isnull((select (case when @DRUMOR=1 or @MODATIM=1 and p.tip_salarizare='4' 
			and (c.tip_corectie_venit='G-' or @lSubtip=1 and  s.tip_corectie_venit='G-') or (c.tip_corectie_venit='L-' or @lSubtip=1 and s.tip_corectie_venit='G-') and @CorL_OreAC=1 then 0 
			else sum(b.ore_lucrate__regie) end)+sum((case when @SOMESANA=1 then 0 else b.ore_lucrate_acord-(case when @OS1_OreAC=1 then b.ore_suplimentare_1 else 0 end)
			-(case when @OS2_OreAC=1 then b.ore_suplimentare_2 else 0 end) end))
		from brut b where b.data=@datasus and b.marca = c.marca and (c.expand_locm=0 and @CorL_locm=0 or b.loc_de_munca = c.loc_de_munca)),0),
		isnull((select sum(b.realizat__regie+b.realizat_acord+b.indemnizatie_ore_supl_1+b.indemnizatie_ore_supl_2+
		b.indemnizatie_ore_supl_3+b.indemnizatie_ore_supl_4+b.indemnizatie_ore_spor_100+b.ind_intrerupere_tehnologica+
		b.ind_invoiri+ind_obligatii_cetatenesti+b.spor_cond_1+b.spor_cond_2+b.spor_cond_3+b.spor_vechime)
		from brut b where b.data=@datasus and b.marca = c.marca and (c.expand_locm=0 and @CorL_locm=0 or b.loc_de_munca = c.loc_de_munca)),0),
		isnull((select b.realizat_acord from brut b where b.data=@datasus and b.marca=c.marca and b.loc_de_munca=c.loc_de_munca),0),
		isnull((select max(j.regim_de_lucru) from pontaj j where j.data between @datajos and @datasus and j.marca=c.marca and j.loc_de_munca=c.loc_de_munca),
			(case when @REGIMLV=0 and p.salar_lunar_de_baza<>0 then p.salar_lunar_de_baza else 8 end)),
		isnull((select max(j.tip_salarizare) from pontaj j where j.data between @datajos and @datasus and j.marca=c.marca and j.loc_de_munca=c.loc_de_munca),''), p.tip_salarizare,
		isnull((select max(j.salar_categoria_lucrarii) from pontaj j where j.data between @datajos and @datasus and j.marca=c.marca and j.loc_de_munca=c.loc_de_munca),0), s.Tip_corectie_venit
	from curscor c 
		left outer join personal p on c.marca = p.marca
		left outer join subtipcor s on c.tip_corectie_venit = s.Subtip
	where c.data between @datajos and @datasus and (@pmarca='' or c.marca=@pmarca) and (c.tip_corectie_venit<>'U-' or p.Loc_ramas_vacant=0 or p.Data_plec>=@datajos)
	order by c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit

	open cursor_corectii
	fetch next from cursor_corectii into @data, @marca, @loc_de_munca, @tip_corectie, @suma_corectie, @procent_corectie, @expand_locm, @salar_incadrare, @salar_baza, @regim_variabil, 
		@IndRN, @ore_lucrate, @baza_CorG, @Realizat_acord, @regim_de_lucru, @TipS_pontaj, @TipS_pers, @Sal_catl, @STip_corectie
	While @@fetch_status = 0 
	Begin
		Select @Salar_calcul=0, @CMCAS=0, @CMUnitate=0, @CO=0, @Restituiri=0, @Diminuari=0, @Suma_impoz=0, @Premiu=0, @Diurna=0, @Cons_admin=0, @Procent_lucrat_acord=0, @Suma_imp_sep=0, 
			@Aj_deces=0, @CM_incasat=0, @CO_incasat=0, @suma_incasata=0, @Suma_neimp=0, @Dif_impozit=0

		Set @CMCAS=(case when @tip_corectie='A-' or @lSubtip=1 and @STip_corectie='A-' then @suma_corectie else 0 end)
		Set @CMUnitate=(case when @tip_corectie='B-' or @lSubtip=1 and @STip_corectie='B-' then @suma_corectie else 0 end)
		Set @CO=(case when @tip_corectie in ('D-','Z-') or @lSubtip=1 and @STip_corectie in ('D-','Z-') then @suma_corectie else 0 end)
		Set @Restituiri = (case when @tip_corectie='F-' or @lSubtip=1 and @STip_corectie='F-' then @suma_corectie+
			round((case when @PASMATEX=1 then @IndRN else @salar_incadrare end)*@procent_corectie/100,0) else 0 end)
		Set @Diminuari = round((case when @tip_corectie='G-' or @lSubtip=1 and @STip_corectie='G-' then @suma_corectie+
			(case when @SALUBRIS=1 and 1=0 then @Baza_corG else @salar_incadrare end)*@procent_corectie/100*
			(case when @MODATIM=1 then @Ore_lucrate/@Ore_luna else 1 end) else 0 end),0)
		Set @Suma_impoz = (case when @tip_corectie='H-' or @lSubtip=1 and @STip_corectie='H-' then @suma_corectie+round(@salar_incadrare*@procent_corectie/100,0) else 0 end)
		Set @Premiu = (case when @tip_corectie in ('I-','S-','X-') or @lSubtip=1 and @STip_corectie in ('I-','S-','X-') then @suma_corectie+round(@salar_incadrare*@procent_corectie/100,0) else 0 end)
		Set @Diurna = (case when @tip_corectie in ('J-','Y-') or @lSubtip=1 and @STip_corectie in ('J-','Y-') then @suma_corectie else 0 end)
		Set @Cons_admin=(case when @tip_corectie='K-' or @lSubtip=1 and @STip_corectie='K-' then @suma_corectie else 0 end)
		Set @Salar_calcul = (case when @Unit_bug=1 then @salar_baza else @salar_incadrare end)
		Set @Procent_lucrat_acord = round((case when (@tip_corectie='L-' or @lSubtip=1 and @STip_corectie='L-') and @SPICUL=0 and @CorL_SREAC=0 
			then (case when @procent_corectie=0 then @suma_corectie 
				else (case when @DRUMOR=1 or @MODATIM=1 then @Realizat_acord 
					else @Ore_lucrate*(case when @RegimLV=1 and @regim_variabil<>0 then @Salar_calcul/@regim_variabil else 8/(case when @regim_de_lucru<>0 then @regim_de_lucru else 8 end)*
						(case when @TipS_pontaj in ('6','7') then @Sal_catl else @Salar_calcul/(case when charindex((case when @TipS_pontaj<>'' then @TipS_pontaj else @TipS_pers end),'12')<>0 
							then @Ore_luna else @Nrm_luna end) end) end) end)*@procent_corectie/100 end) else 0 end),0)
		Set @Suma_imp_sep=(case when @tip_corectie='O-' or @lSubtip=1 and @STip_corectie='O-' then @suma_corectie else 0 end)
		Set @Aj_deces=(case when @tip_corectie='R-' or @lSubtip=1 and @STip_corectie='R-' then @suma_corectie else 0 end)
		Set @CM_incasat=(case when @tip_corectie='C-' or @lSubtip=1 and @STip_corectie='C-' then @suma_corectie else 0 end)
		Set @CO_incasat=(case when @tip_corectie='E-' or @lSubtip=1 and @STip_corectie='E-' then @suma_corectie else 0 end)
		Set @Suma_incasata=(case when @tip_corectie in ('M-','S-') or @lSubtip=1 and @STip_corectie in ('M-','S-') then @suma_corectie+round(@salar_incadrare*@procent_corectie/100,0) else 0 end)
		Set @Suma_neimp=(case when @tip_corectie in ('N-','N2') or @lSubtip=1 and @STip_corectie in ('N-','N2') then @suma_corectie+round(@salar_incadrare*@procent_corectie/100,0) else 0 end)
		Set @Dif_impozit=(case when @tip_corectie='P-' or @lSubtip=1 and @STip_corectie='P-' then @suma_corectie else 0 end)

		exec scriu_brut_net @datajos, @datasus, @marca, @loc_de_munca, @CMCAS, @CMUnitate, @CO, @Restituiri, @Diminuari, @Suma_impoz, @Premiu, @Diurna, @Cons_admin, @Procent_lucrat_acord, 
			@Suma_imp_sep, @Aj_deces, @Regim_de_lucru, @CM_incasat, @CO_incasat, @Suma_incasata, @Suma_neimp, @Dif_impozit

		fetch next from cursor_corectii into @data, @marca, @loc_de_munca, @tip_corectie, @suma_corectie, @procent_corectie, @expand_locm, @salar_incadrare, @salar_baza, @regim_variabil, 
			@IndRN, @ore_lucrate, @baza_CorG, @Realizat_acord, @regim_de_lucru, @TipS_pontaj, @TipS_pers, @Sal_catl, @STip_corectie
	End
	close cursor_corectii
	Deallocate cursor_corectii

	if exists (select * from sysobjects where name ='calcul_corectiiSP1')
		exec calcul_corectiiSP1 @datajos=@datajos, @datasus=@datasus, @pmarca=@pmarca, @plocm=@plocm
End	try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura calcul_corectii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
