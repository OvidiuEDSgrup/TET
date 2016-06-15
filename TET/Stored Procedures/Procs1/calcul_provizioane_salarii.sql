--***
/**	procedura provizioane Colas	*/
Create 
procedure calcul_provizioane_salarii
	@datajos datetime, @datasus datetime, @pmarca char(6), @ploc_de_munca char(9), @Stergere int, @Scriere int
As
Begin
	declare @nPrima_co float, @nProc_prov_prima_anuala float, @nOre_luna float, @nZile_lucr_an float, 
	@nCas_gr3 float, @nCas_indiv float, @nCCI float, @nCASS float, @nSomaj float, @nFond_gar float, @nFambp float, @nITM float, @nProc_chelt float
	Set @nOre_luna = dbo.iauParLN(@datasus,'PS','ORE_LUNA')
	Set @nZile_lucr_an=dbo.zile_lucratoare(dbo.boy(@datasus),dbo.eoy(@datasus))
	Set @nPrima_co = dbo.iauParN('PS','PV%-INDCO')
	Set @nProc_prov_prima_anuala = dbo.iauParN('PS','PRPROVPA')
	Set @nCAS_gr3 = dbo.iauParLN(@datasus,'PS','CASGRUPA3')
	Set @nCAS_indiv = dbo.iauParLN(@datasus,'PS','CASINDIV')
	Set @nCCI = dbo.iauParLN(@datasus,'PS','COTACCI')
	Set @nCASS = dbo.iauParLN(@datasus,'PS','CASSUNIT')
	Set @nSomaj = dbo.iauParLN(@datasus,'PS','3.5%SOMAJ')
	Set @nFond_gar = dbo.iauParLN(@datasus,'PS','FONDGAR')
	Set @nFambp = dbo.iauParLN(@datasus,'PS','0.5%ACCM')
	Set @nITM = dbo.iauParLN(@datasus,'PS','1%-CAMERA')
	Set @nProc_chelt=@nCAS_gr3-@nCAS_indiv+@nCCI+@nCASS+@nSomaj+@nFond_gar+@nFambp+@nITM
	If @Stergere=1 
		delete from concodih where data=@datasus and tip_concediu in ('C','P','V') and (@pmarca='' or marca=@pmarca)
		and marca in (select marca from personal where (@ploc_de_munca='' or loc_de_munca like rtrim(@ploc_de_munca)+'%'))

	If @Scriere=1 
	Begin
--inserare indemnizatie CO
		Insert into concodih 
			(data, marca, tip_concediu, data_inceput, data_sfarsit, zile_co, introd_manual, indemnizatie_co, zile_prima_vacanta, prima_vacanta)
		Select i.data, i.marca, 'C', @datajos, @datasus, round((p.zile_concediu_de_odihna_an+Zile_concediu_efectuat_an)/(convert(float,@nZile_lucr_an)-(p.zile_concediu_de_odihna_an+ Zile_concediu_efectuat_an))*
			(select isnull(sum((ore_lucrate_regim_normal+ore_intrerupere_tehnologica)/(case when spor_cond_10=0 then 8 else spor_cond_10 end)),0) from brut where brut.marca=i.marca and brut.data=@datasus),2), 0,  
			round(((select isnull(sum(venit_total),0) from brut where brut.marca=i.marca and brut.data=@datasus)/(@nOre_luna/8))* round((p.zile_concediu_de_odihna_an+Zile_concediu_efectuat_an)/(convert(float,@nZile_lucr_an)-(p.zile_concediu_de_odihna_an+ Zile_concediu_efectuat_an))*
			(select isnull(sum((ore_lucrate_regim_normal+ore_intrerupere_tehnologica)/(case when spor_cond_10=0 then 8 else spor_cond_10 end)),0) from brut where brut.marca=i.marca and brut.data=@datasus),2),0), 0, 
			round(((select isnull(sum(venit_total),0) from brut where brut.marca=i.marca and brut.data=@datasus)/(@nOre_luna/8))* round((p.zile_concediu_de_odihna_an+Zile_concediu_efectuat_an)/(convert(float,@nZile_lucr_an)-(p.zile_concediu_de_odihna_an+ Zile_concediu_efectuat_an))*(select isnull(sum((ore_lucrate_regim_normal+ore_intrerupere_tehnologica)/(case when spor_cond_10=0 then 8 else spor_cond_10 end)),0) from brut where brut.marca=i.marca and brut.data=@datasus),2)*(@nProc_chelt)/100,0) 
		from istpers i 
			left outer join personal p on p.marca = i.marca
		where i.data = @datasus and (@pmarca='' or i.marca=@pmarca)
--inserare prima de vacanta
		Insert into concodih 
			(data, marca, tip_concediu, data_inceput, data_sfarsit, zile_co, introd_manual, indemnizatie_co, zile_prima_vacanta, prima_vacanta)
		Select i.data, i.marca, 'V', @datajos, @datasus, 0, 0,  round((@nPrima_CO)*
			(select isnull(sum((ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti/*+ore_concediu_medical+ ore_concediu_de_odihna*/)/(case when spor_cond_10=0 then 8 else spor_cond_10 end)),0) from brut where brut.marca=i.marca and brut.data=@datasus)/@nZile_lucr_an,0), 0, 
			round((@nPrima_CO)*(select isnull(sum((ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti/*+ore_concediu_medical+ ore_concediu_de_odihna*/)/(case when spor_cond_10=0 then 8 else spor_cond_10 end)),0) from brut where brut.marca=i.marca and brut.data=@datasus)/@nZile_lucr_an*(@nProc_chelt)/100,0) 
		from istpers i 
			left outer join personal p on p.marca = i.marca
		where i.data = @datasus and (@pmarca='' or i.marca=@pmarca)
--inserare premiu anual
		Insert into concodih 
			(data, marca, tip_concediu, data_inceput, data_sfarsit, zile_co, introd_manual, indemnizatie_co, zile_prima_vacanta, prima_vacanta)
		Select i.data, i.marca, 'P', @datajos, @datasus, 0, 0, round((select isnull(sum(realizat__regie+realizat_acord+indemnizatie_ore_supl_1+indemnizatie_ore_supl_2+indemnizatie_ore_supl_3+ indemnizatie_ore_supl_4+cons_admin+ind_intrerupere_tehnologica+restituiri)*@nProc_prov_prima_anuala/100,0) from brut where brut.marca=i.marca and brut.data=@datasus),0), 0, 
			round(round((select isnull(sum(realizat__regie+realizat_acord+indemnizatie_ore_supl_1+indemnizatie_ore_supl_2+indemnizatie_ore_supl_3+ indemnizatie_ore_supl_4+cons_admin+ind_intrerupere_tehnologica+restituiri)*@nProc_prov_prima_anuala/100,0) from brut where brut.marca=i.marca and brut.data=@datasus),0)*(@nProc_chelt)/100,0) 
		from istpers i 
			left outer join personal p on p.marca = i.marca
		where i.data = @datasus and (@pmarca='' or i.marca=@pmarca) 
		and (@ploc_de_munca='' or i.loc_de_munca like rtrim(@ploc_de_munca)+'%')
	End
End
