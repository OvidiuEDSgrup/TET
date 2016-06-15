--***
/**	functie lista personal	*/
Create 
function  [dbo].[fLista_personal]
	(@DataJos datetime, @DataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9), 
	@Cod_functie_Jos char(6), @Cod_functie_Sus char(6), @GrupaJos char(1), @GrupaSus char(1), @unTipStat int, @Tipstat char(10),
	@l_drept char(1), @User char(30), @User_windows int, @Ordonare char(1), @Alfabetic int)
returns @date_personal table
	(marca char(6),nume char(50),cod_functie char(6),denumire_functie char(30),loc_de_munca char(9), denumire_locm char(30), 
	grupa_de_munca char(1), categoria_salarizare char(4), salar_de_incadrare int, indemnizatia_de_conducere int, religia char(10), 
	data_angajarii_in_unitate datetime, data_plec datetime, profesia char(10), studii char(10), salar_orar float, pensie_suplimentara int, 
	spor_cond_7 float, salar_de_baza int, spor_vechime float, spor_de_noapte float, spor_sistematic_peste_program float,
	spor_de_functie_suplimentara float, loc_ramas_vacant int, spor_specific float, spor_conditii_1 float, spor_conditii_2 float, 
	spor_conditii_3 float, spor_conditii_4 float, spor_conditii_5 float, spor_conditii_6 float, regim_de_lucru float, 
	sex char(1), total_salar int, sal_inc_calc int, ind_cond int, sp_vech int, sp_sist int, sp_func_supl int, 
	sp_spec int, sp1_calc int, sp2_calc int, sp3_calc int, sp4_calc int, sp5_calc int, sp6_calc int, sp7_calc int, 
	sal_spor1 int, sal_spor2 int, ordonare1 char(50), ordonare2 char(50)) 
as
begin

	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)
	
	declare @drept_conducere int,@liste_drept char(1),@drept int
	Set @drept_conducere=dbo.iauParL('PS','DREPTCOND')
	declare @lbugetari int,@lindc_sum int,@lf_supl_sum int,@lspec_sum int,@lspor_sp1 int,
		@lc1_sum int,@lc2_sum int,@lc3_sum int,@lc4_sum int,@lc5_sum int,@lc6_sum int,@lbaza_ind int,
		@lbaza_spec int,@lbaza_sp1 int,@lbaza_sp2 int,@lbaza_sp3 int,@lbaza_sp4 int,@lbaza_sp5 int,@lbaza_sp6 int
	Set @lbugetari=dbo.iauParL('PS','UNITBUGET')
	Set @lindc_sum=dbo.iauParL('PS','INDC-SUMA')
	Set @lf_supl_sum=dbo.iauParL('PS','SPFS-SUMA')
	Set @lspec_sum=dbo.iauParL('PS','SSP-SUMA')
	Set @lc1_sum=dbo.iauParL('PS','SC1-SUMA')
	Set @lspor_sp1=dbo.iauParL('PS','SPOR-SP1')
	Set @lc2_sum=dbo.iauParL('PS','SC2-SUMA')
	Set @lc3_sum=dbo.iauParL('PS','SC3-SUMA')
	Set @lc4_sum=dbo.iauParL('PS','SC4-SUMA')
	Set @lc5_sum=dbo.iauParL('PS','SC5-SUMA')
	Set @lc6_sum=dbo.iauParL('PS','SC6-SUMA')
	Set @lbaza_ind=dbo.iauParL('PS','SBAZA-IND')
	Set @lbaza_spec=dbo.iauParL('PS','S-BAZA-SP')
	Set @lbaza_sp1=dbo.iauParL('PS','S-BAZA-S1')
	Set @lbaza_sp2=dbo.iauParL('PS','S-BAZA-S2')
	Set @lbaza_sp3=dbo.iauParL('PS','S-BAZA-S3')
	Set @lbaza_sp4=dbo.iauParL('PS','S-BAZA-S4')
	Set @lbaza_sp5=dbo.iauParL('PS','S-BAZA-S5')
	Set @lbaza_sp6=dbo.iauParL('PS','S-BAZA-S6')
	if  @drept_conducere=1 
	begin
		set @drept=isnull((select dbo.verifica_dreptul(@user,@user_windows,'SALCOND')),0)
		if @drept=1
			set @liste_drept=@l_drept
		else
		begin
			set @liste_drept=@l_drept
			if @liste_drept='T'
				set @liste_drept='S'
		end
	end
	else
	begin
		set @liste_drept=@l_drept
		set @drept=0
	end

	declare @tmp table (marca char(6), total_salar int, sal_inc_calc int, ind_cond int)
	insert into @tmp
	select a.marca, isnull(b.salar_de_incadrare,a.salar_de_incadrare)+round((case when @lindc_sum=1 then isnull(b.indemnizatia_de_conducere,a.indemnizatia_de_conducere) else isnull(b.salar_de_incadrare,a.salar_de_incadrare)*isnull(b.indemnizatia_de_conducere,a.indemnizatia_de_conducere)/100 end),0) as total_salar,
		(case when @lbugetari=1 then a.salar_de_baza else isnull(b.salar_de_incadrare,a.salar_de_incadrare) end) as sal_inc_calc,
		round(isnull(b.salar_de_incadrare,a.salar_de_incadrare)*(case when @lindc_sum=1 then 0 else isnull(b.indemnizatia_de_conducere,a.indemnizatia_de_conducere)/100 end ),0)+(case when @lindc_sum=1 then isnull(b.indemnizatia_de_conducere,a.indemnizatia_de_conducere) else 0 end) as ind_cond
	from personal a
		left outer join istpers b on b.data=@DataSus and b.marca=a.marca
	
	insert into @date_personal
	select a.marca, a.nume, a.cod_functie, a.denumire_functie, a.loc_de_munca, a.denumire_locm, a.grupa_de_munca, a.categoria_salarizare, 
		a.salar_de_incadrare, a.indemnizatia_de_conducere, a.religia, a.data_angajarii_in_unitate, a.data_plec, a.profesia, a.studii, a.salar_orar, 
		a.pensie_suplimentara, a.spor_cond_7, a.salar_de_baza, a.spor_vechime, a.spor_de_noapte, a.spor_sistematic_peste_program, a.spor_de_functie_suplimentara, 
		a.loc_ramas_vacant, a.spor_specific,a.spor_conditii_1, a.spor_conditii_2, a.spor_conditii_3, a.spor_conditii_4, a.spor_conditii_5, a.spor_conditii_6, 
		a.regim_de_lucru, a.sex, a.total_salar, a.sal_inc_calc, a.ind_cond, a.sp_vech, a.sp_sist, a.sp_func_supl, a.sp_spec, a.sp1_calc, a.sp2_calc, a.sp3_calc, a.sp4_calc,
		a.sp5_calc, a.sp6_calc, sp7_calc,
		a.sal_inc_calc+a.sp_vech+(case when @lbaza_ind=1 then 0 else a.ind_cond end)+a.sp_sist+a.sp_func_supl+(case when @lbaza_spec=1 then 0 else a.sp_spec end),
		(case when @lbaza_sp1=1 then 0 else a.sp1_calc end)+(case when @lbaza_sp2=1 then 0 else a.sp2_calc end)+(case when @lbaza_sp3=1 then 0 else a.sp3_calc end)+
		(case when @lbaza_sp4=1 then 0 else a.sp4_calc end)+(case when @lbaza_sp5=1 then 0 else a.sp5_calc end)+(case when @lbaza_sp6=1 then 0 else a.sp6_calc end)+a.sp7_calc, 
		(case when @ordonare='1' then (case when @alfabetic=1 then a.nume else a.marca end) else (case when @ordonare='2' then a.cod_functie else a.loc_de_munca end) end) as ordonare1,
		(case when @ordonare='1' then '' else (case when @alfabetic=1 then a.nume else a.marca end) end) as ordonare2
		from (select a.marca,a.nume,isnull(b.cod_functie,a.cod_functie) as cod_functie,c.denumire as denumire_functie, isnull(b.loc_de_munca,a.loc_de_munca) as loc_de_munca, d.denumire as denumire_locm,
		isnull(b.grupa_de_munca,a.grupa_de_munca) as grupa_de_munca, isnull(b.categoria_salarizare,a.categoria_salarizare) as categoria_salarizare, isnull(b.salar_de_incadrare,a.salar_de_incadrare) as salar_de_incadrare,
		isnull(b.indemnizatia_de_conducere,a.indemnizatia_de_conducere) as indemnizatia_de_conducere, e.religia,
		a.data_angajarii_in_unitate, a.data_plec, a.profesia, a.studii, a.salar_orar, a.pensie_suplimentara, e.spor_cond_7, 
		a.salar_de_baza, a.spor_vechime, a.spor_de_noapte, a.spor_sistematic_peste_program, a.spor_de_functie_suplimentara, 
		a.loc_ramas_vacant, a.spor_specific, a.spor_conditii_1, a.spor_conditii_2, a.spor_conditii_3, a.spor_conditii_4, a.spor_conditii_5, a.spor_conditii_6, 
		dbo.iau_regim_lucru(a.marca,@datasus) as regim_de_lucru,(case when a.sex=1 then 'M' else 'F'  end) as sex,
		f.total_salar,f.sal_inc_calc,f.ind_cond,round(f.sal_inc_calc*a.spor_vechime/100,0) as sp_vech,
		round(f.sal_inc_calc*a.spor_sistematic_peste_program/100,0) as sp_sist,
		round(f.sal_inc_calc*(case when @lf_supl_sum=1 then 0 else a.spor_de_functie_suplimentara/100 end),0)+(case when @lf_supl_sum=1 then a.spor_de_functie_suplimentara else 0 end) as sp_func_supl,
		round((isnull(b.salar_de_incadrare,a.salar_de_incadrare)+f.ind_cond)*(case when @lspec_sum=1 then 0 else a.spor_specific/100 end ),0)+(case when @lspec_sum=1 then a.spor_specific else 0 end ) as sp_spec,
		round((case when @lc1_sum=0 then (case when @lspor_sp1=1 then isnull(b.salar_de_incadrare,a.salar_de_incadrare)+f.ind_cond else f.sal_inc_calc end)*a.spor_conditii_1/100 else a.spor_conditii_1 end),0) as sp1_calc,
		round((case when @lc2_sum=0 then f.sal_inc_calc *a.spor_conditii_2/100 else a.spor_conditii_2 end),0) as sp2_calc,
		round((case when @lc3_sum=0 then f.sal_inc_calc *a.spor_conditii_3/100 else a.spor_conditii_3 end),0) as sp3_calc,
		round((case when @lc4_sum=0 then f.sal_inc_calc *a.spor_conditii_4/100 else a.spor_conditii_4 end),0) as sp4_calc,
		round((case when @lc5_sum=0 then f.sal_inc_calc *a.spor_conditii_5/100 else a.spor_conditii_5 end),0) as sp5_calc,
		round((case when @lc6_sum=0 then f.sal_inc_calc *a.spor_conditii_6/100 else a.spor_conditii_6 end),0) as sp6_calc,
		round(f.sal_inc_calc *e.spor_cond_7/100,0) as sp7_calc
	from personal a
		left outer join istpers b on b.data=@datasus and b.marca=a.marca
		left outer join functii c on c.cod_functie=isnull(b.cod_functie,a.cod_functie)
		left outer join lm d on d.cod=isnull(b.loc_de_munca,a.loc_de_munca)
		left outer join infopers e on e.marca=a.marca
		left outer join @tmp f on f.marca=a.marca
	where a.marca between @MarcaJos and @MarcaSus and a.data_angajarii_in_unitate<=@DataSus
		and isnull(b.cod_functie,a.cod_functie) between @Cod_functie_Jos and @Cod_functie_Sus and isnull(b.loc_de_munca,a.loc_de_munca) between @LocmJos and @LocmSus and isnull(b.grupa_de_munca,a.grupa_de_munca) between @GrupaJos and @GrupaSus
		and (@unTipStat=0 or @Tipstat=e.religia)
		and (@drept_conducere=0 or (@drept_conducere=1 and @drept=1 and (@liste_drept='T' or @liste_drept='C' and a.pensie_suplimentara=1 or @liste_drept='S' and a.pensie_suplimentara<>1)) 
		or (@drept_conducere=1 and @drept=0 and @liste_drept='S' and a.pensie_suplimentara<>1))
		and (convert(char(1),a.loc_ramas_vacant)='0' or convert(char(1),a.loc_ramas_vacant)='1' and a.data_plec>=@DataJos)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(b.loc_de_munca,a.loc_de_munca)))
	) a 
	order by ordonare1,ordonare2

	return
end
