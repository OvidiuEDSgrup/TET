--***
/**	functie pentru rapoartele Stat cu date de personal / Stat cu date de salarizare */
Create function frapStatCuDatePersSal
	(@dataJos datetime, @dataSus datetime, @grupaMarca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @filtruFunctieArbore int=0, 
	@grupamunca char(1)=null, @tipstat varchar(30)=null, @l_drept char(1), @ordonare char(1), @alfabetic int, @tippersonal char(1)=null, @SiSporNoapte int=0)
returns @date_personal table
	(marca char(6),nume char(50),cod_functie char(6),denumire_functie char(30),loc_de_munca char(9), denumire_locm char(30), grupa_de_munca char(1), categoria_salarizare char(4), 
	salar_de_incadrare int, indemnizatia_de_conducere int, religia char(10), data_angajarii_in_unitate datetime, data_plec datetime, profesia char(10), studii char(10), salar_orar float, 
	pensie_suplimentara int, spor_cond_7 float, salar_de_baza int, spor_vechime float, spor_de_noapte float, spor_sistematic_peste_program float, spor_de_functie_suplimentara float, 
	loc_ramas_vacant int, spor_specific float, spor_conditii_1 float, spor_conditii_2 float, spor_conditii_3 float, spor_conditii_4 float, spor_conditii_5 float, spor_conditii_6 float, 
	regim_de_lucru float, sex char(1), total_salar int, sal_inc_calc int, ind_cond int, sp_vech int, sp_sist int, sp_func_supl int, 
	sp_spec int, sp1_calc int, sp2_calc int, sp3_calc int, sp4_calc int, sp5_calc int, sp6_calc int, sp7_calc int, spnoapte_calc float, 
	sal_spor1 int, sal_spor2 int, ordonare1 char(50), ordonare2 char(50)) 
as
begin 
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)
	
	declare @dreptConducere int, @listaDrept char(1), @areDreptCond int
	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	
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

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @listaDrept=@l_drept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @listaDrept='S'
	end

	declare @tmp table (marca char(6), total_salar int, sal_inc_calc int, ind_cond int)
	insert into @tmp
	select p.marca, isnull(i.salar_de_incadrare,p.salar_de_incadrare)+round((case when @lindc_sum=1 then isnull(i.indemnizatia_de_conducere,p.indemnizatia_de_conducere) else isnull(i.salar_de_incadrare,p.salar_de_incadrare)*isnull(i.indemnizatia_de_conducere,p.indemnizatia_de_conducere)/100 end),0) as total_salar,
		(case when @lbugetari=1 then p.salar_de_baza else isnull(i.salar_de_incadrare,p.salar_de_incadrare) end) as sal_inc_calc,
		round(isnull(i.salar_de_incadrare,p.salar_de_incadrare)*(case when @lindc_sum=1 then 0 else isnull(i.indemnizatia_de_conducere,p.indemnizatia_de_conducere)/100 end ),0)+(case when @lindc_sum=1 then isnull(i.indemnizatia_de_conducere,p.indemnizatia_de_conducere) else 0 end) as ind_cond
	from personal p
		left outer join istpers i on i.data=@dataSus and i.marca=p.marca

	insert into @date_personal
	select a.marca, a.nume, a.cod_functie, a.denumire_functie, a.loc_de_munca, a.denumire_locm, a.grupa_de_munca, a.categoria_salarizare, 
		a.salar_de_incadrare, a.indemnizatia_de_conducere, a.religia, a.data_angajarii_in_unitate, a.data_plec, a.profesia, a.studii, convert(decimal(10,3),a.salar_orar) as salar_orar, 
		a.pensie_suplimentara, a.spor_cond_7, a.salar_de_baza, a.spor_vechime, a.spor_de_noapte, a.spor_sistematic_peste_program, a.spor_de_functie_suplimentara, 
		a.loc_ramas_vacant, a.spor_specific,a.spor_conditii_1, a.spor_conditii_2, a.spor_conditii_3, a.spor_conditii_4, a.spor_conditii_5, a.spor_conditii_6, 
		a.regim_de_lucru, a.sex, a.total_salar, a.sal_inc_calc, a.ind_cond, a.sp_vech, a.sp_sist, a.sp_func_supl, a.sp_spec, a.sp1_calc, a.sp2_calc, a.sp3_calc, a.sp4_calc,
		a.sp5_calc, a.sp6_calc, sp7_calc, spnoapte_calc, 
		a.sal_inc_calc+a.sp_vech+(case when @lbaza_ind=1 then 0 else a.ind_cond end)+a.sp_sist+a.sp_func_supl+(case when @lbaza_spec=1 then 0 else a.sp_spec end) as sal_spor1,
		(case when @lbaza_sp1=1 then 0 else a.sp1_calc end)+(case when @lbaza_sp2=1 then 0 else a.sp2_calc end)+(case when @lbaza_sp3=1 then 0 else a.sp3_calc end)+
		(case when @lbaza_sp4=1 then 0 else a.sp4_calc end)+(case when @lbaza_sp5=1 then 0 else a.sp5_calc end)+(case when @lbaza_sp6=1 then 0 else a.sp6_calc end)+a.sp7_calc+spnoapte_calc as sal_spor2, 
		(case when @ordonare='1' then (case when @alfabetic=1 then a.nume else a.marca end) else (case when @ordonare='2' then a.cod_functie else a.loc_de_munca end) end) as ordonare1,
		(case when @ordonare='1' then '' else (case when @alfabetic=1 then a.nume else a.marca end) end) as ordonare2
		
	from 
	(select p.marca,isnull(i.Nume,p.nume) as Nume,isnull(i.cod_functie,p.cod_functie) as cod_functie, f.denumire as denumire_functie, isnull(i.loc_de_munca,p.loc_de_munca) as loc_de_munca, lm.denumire as denumire_locm,
		isnull(i.grupa_de_munca,p.grupa_de_munca) as grupa_de_munca, isnull(i.categoria_salarizare,p.categoria_salarizare) as categoria_salarizare, isnull(i.salar_de_incadrare,p.salar_de_incadrare) as salar_de_incadrare,
		isnull(i.indemnizatia_de_conducere,p.indemnizatia_de_conducere) as indemnizatia_de_conducere, e.religia,
		p.data_angajarii_in_unitate, p.data_plec, p.profesia, p.studii, p.salar_orar, p.pensie_suplimentara, e.spor_cond_7, 
		p.salar_de_baza, p.spor_vechime, p.spor_de_noapte, p.spor_sistematic_peste_program, p.spor_de_functie_suplimentara, 
		p.loc_ramas_vacant, p.spor_specific, p.spor_conditii_1, p.spor_conditii_2, p.spor_conditii_3, p.spor_conditii_4, p.spor_conditii_5, p.spor_conditii_6, 
		dbo.iau_regim_lucru(p.marca,@dataSus) as regim_de_lucru,(case when p.sex=1 then 'M' else 'F'  end) as sex,
		d.total_salar,d.sal_inc_calc,d.ind_cond,round(d.sal_inc_calc*p.spor_vechime/100,0) as sp_vech,
		round(d.sal_inc_calc*p.spor_sistematic_peste_program/100,0) as sp_sist,
		round(d.sal_inc_calc*(case when @lf_supl_sum=1 then 0 else p.spor_de_functie_suplimentara/100 end),0)+(case when @lf_supl_sum=1 then p.spor_de_functie_suplimentara else 0 end) as sp_func_supl,
		round((isnull(i.salar_de_incadrare,p.salar_de_incadrare)+d.ind_cond)*(case when @lspec_sum=1 then 0 else p.spor_specific/100 end ),0)+(case when @lspec_sum=1 then p.spor_specific else 0 end ) as sp_spec,
		round((case when @lc1_sum=0 then (case when @lspor_sp1=1 then isnull(i.salar_de_incadrare,p.salar_de_incadrare)+d.ind_cond else d.sal_inc_calc end)*p.spor_conditii_1/100 else p.spor_conditii_1 end),0) as sp1_calc,
		round((case when @lc2_sum=0 then d.sal_inc_calc *p.spor_conditii_2/100 else p.spor_conditii_2 end),0) as sp2_calc,
		round((case when @lc3_sum=0 then d.sal_inc_calc *p.spor_conditii_3/100 else p.spor_conditii_3 end),0) as sp3_calc,
		round((case when @lc4_sum=0 then d.sal_inc_calc *p.spor_conditii_4/100 else p.spor_conditii_4 end),0) as sp4_calc,
		round((case when @lc5_sum=0 then d.sal_inc_calc *p.spor_conditii_5/100 else p.spor_conditii_5 end),0) as sp5_calc,
		round((case when @lc6_sum=0 then d.sal_inc_calc *p.spor_conditii_6/100 else p.spor_conditii_6 end),0) as sp6_calc,
		round(d.sal_inc_calc*e.spor_cond_7/100,0) as sp7_calc,
		(case when isnull(x.Val_inf,'') in ('Inegal','OreDeNoapte') or @SiSporNoapte=1 then round(d.sal_inc_calc*p.Spor_de_noapte/100 ,0) else 0 end) as spnoapte_calc
	from personal p
		left outer join istpers i on i.data=@dataSus and i.marca=p.marca
		left outer join functii f on f.cod_functie=isnull(i.cod_functie,p.cod_functie)
		left outer join lm on lm.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		left outer join infopers e on e.marca=p.marca
		left outer join @tmp d on d.marca=p.marca
		left outer join extinfop x on x.Marca=p.Marca and x.Cod_inf='REPTIMPMUNCA'
	where (@grupaMarca is null or p.marca like rtrim(@grupaMarca)+'%') and p.data_angajarii_in_unitate<=@dataSus
		and (@functie is null or isnull(i.cod_functie,p.cod_functie) like rtrim(@functie)+(case when @filtruFunctieArbore=1 then '%' else '' end)) 
		and (@locm is null or isnull(i.loc_de_munca,p.loc_de_munca) like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@grupamunca is null or isnull(i.grupa_de_munca,p.grupa_de_munca)=@grupamunca)
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare)  in ('1','2')) or (@tippersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7'))) 
		and (@tipstat is null or e.religia=@tipstat)
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@listaDrept='T' or @listaDrept='C' and p.pensie_suplimentara=1 or @listaDrept='S' and p.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @listaDrept='S' and p.pensie_suplimentara<>1))
		and (convert(char(1),p.loc_ramas_vacant)='0' or convert(char(1),p.loc_ramas_vacant)='1' and p.data_plec>=@dataJos)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.loc_de_munca,p.loc_de_munca)))
	) a 
	order by ordonare1, ordonare2

	return
end 

/*
	select * from frapStatCuDatePersSal ('04/01/2012', '04/30/2012', null, null, 0, null, 0, null, null, 'T', 1, 0, null, 0)
*/
