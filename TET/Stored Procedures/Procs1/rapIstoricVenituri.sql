/**	procedura pentru raporttul istoric venituri	*/
Create procedure rapIstoricVenituri
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @grupamunca char(1)=null, @sex int=null, @tippersonal char(1)=null, 
	@ordonare int, @l_drept char(1))
As
Begin try
	set transaction isolation level read uncommitted
	Declare @dreptConducere int, @liste_drept char(1), @areDreptCond int
	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @liste_drept=@l_drept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @liste_drept='S'
	end

	select a.data, a.marca, max(isnull(i.Nume,p.Nume)) as nume, max(n.loc_de_munca) as lm, max(lm.denumire) as den_lm, 
		max(isnull(f2.Cod_functie,i.Cod_functie)) as cod_functie, max(f.Denumire) as den_functie, max(i.salar_de_baza) as salar_de_baza, 
		max(i.grupa_de_munca) as grupa_de_munca, max(isnull(d.regim_de_lucru,8)) as regim_de_lucru,
		sum(a.total_ore_lucrate) as total_ore_lucrate, round(sum(a.total_ore_lucrate/isnull(d.regim_de_lucru,8)),0) as zile_lucrate, 
		sum(a.ore_nemotivate) as ore_nemotivate, round(sum(a.ore_nemotivate/isnull(d.regim_de_lucru,8)),0) as zile_nemotivate, 
		sum(a.ore_concediu_medical) as ore_cm, round(sum(a.ore_concediu_medical/isnull(d.regim_de_lucru,8)),0) as zile_cm, 
		sum(a.ore_concediu_de_odihna) as ore_co, round(sum(a.ore_concediu_de_odihna/isnull(d.regim_de_lucru,8)),0) as zile_co, 
		sum(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4) as ore_suplimentare,
		round(sum(a.ore_suplimentare_1/isnull(d.regim_de_lucru,8)+a.ore_suplimentare_2/isnull(d.regim_de_lucru,8)+a.ore_suplimentare_3/
		isnull(d.regim_de_lucru,8)+a.ore_suplimentare_4/isnull(d.regim_de_lucru,8)),0) as zile_suplimentare,
		sum(a.ore_de_noapte) as ore_noapte, 
		sum(a.ore_invoiri) as ore_invoiri, round(sum(a.ore_invoiri/isnull(d.regim_de_lucru,8)),0) as zile_invoiri, 
		sum(a.ore_intrerupere_tehnologica) as ore_intrerupere_tehnologica, round(sum(a.ore_intrerupere_tehnologica/isnull(d.regim_de_lucru,8)),0) as zile_intrerupere_tehnologica, 
		sum(a.ore_obligatii_cetatenesti) as ore_obligatii_cetatenesti, round(sum(a.ore_obligatii_cetatenesti/isnull(d.regim_de_lucru,8)),0) as zile_obligatii_cetatenesti, 
		sum(a.ore_concediu_fara_salar) as ore_cfs, 
		(case when isnull(max(ca.Zile_CFS),0)<>0 and max(a.Spor_cond_10)<1 then isnull(max(ca.Zile_CFS),0) else round(sum(a.ore_concediu_fara_salar/isnull(d.regim_de_lucru,8)),0) end) as zile_cfs, 
		sum(a.realizat__regie) as realizat_regie, sum(a.realizat_acord) as realizat_acord, sum(a.indemnizatie_ore_supl_1) as indemnizatie_ore_supl_1, sum(a.indemnizatie_ore_supl_2) as indemnizatie_ore_supl_2, 
		sum(a.indemnizatie_ore_supl_3) as indemnizatie_ore_supl_3, sum(a.indemnizatie_ore_supl_4) as indemnizatie_ore_supl_4, 
		sum(a.indemnizatie_ore_spor_100) as indemnizatie_ore_spor_100, sum(a.ind_ore_de_noapte) as ind_ore_de_noapte, sum(a.ind_obligatii_cetatenesti) as ind_obligatii_cetatenesti, 
		sum(a.ind_concediu_de_odihna) as ind_concediu_de_odihna, sum(a.ind_c_medical_CAS) as ind_cm_cas, sum(a.ind_c_medical_unitate) as ind_cm_unitate, 
		sum(a.premiu) as premiu, max(n.VENIT_TOTAL) as venit_total, max(n.VEN_NET_IN_IMP) as ven_net_in_imp, max(n.Impozit) as Impozit, max(n.VENIT_NET) as venit_net, 
		isnull(max(d.Loc_de_munca),'') as lm_brut, 
		isnull((select sum(convert(int,h.data_sfarsit-h.data_inceput+1)) from conmed h where a.data=h.data and a.marca=h.marca),0) as zile_calend_cm, 
		(case when @ordonare=3 then n.loc_de_munca else '' end) as lm_grupare, 
		(case when @ordonare=2 then max(i.Nume) when @ordonare=1 then a.marca else max(n.loc_de_munca) end) as ordonare_1, 
		(case when @ordonare =3 then a.marca else '' end) as ordonare_2
	from brut a 
		left outer join (select data, marca, loc_de_munca, max(regim_de_lucru) as regim_de_lucru from pontaj where data between @dataJos and @dataSus Group by data, marca, loc_de_munca) d 
			on a.data=d.data and a.marca=d.marca and a.loc_de_munca=d.loc_de_munca 
		left outer join personal p on a.marca=p.marca 
		left outer join net n on a.data=n.data and a.marca=n.marca
		left outer join istpers i on a.data=i.data and a.marca=i.marca
		left outer join lm on n.loc_de_munca=lm.cod
		left outer join functii f on i.Cod_functie=f.Cod_functie
		left outer join extinfop f1 on i.Cod_functie=f1.Marca and f1.Cod_inf='#CODCOR'
		left outer join functii_COR f2 on f1.Val_inf=f2.Cod_functie
		left outer join (select data, marca, sum(Zile) as Zile_CFS from conalte where data between @dataJos and @dataSus and Tip_concediu='1' group by data, marca) ca on a.data=ca.data and a.marca=ca.marca
	where a.data between @dataJos and @dataSus and (@marca is null or a.marca=@marca)
		and (@locm is null or n.loc_de_munca like RTRIM(@locm)+(case when @strict=1 then '' else '%' end))
		and (@grupamunca is null or i.grupa_de_munca=@grupamunca) and (@sex is null or p.sex=@sex) 
		and (@tippersonal is null or (@tippersonal='T' and i.tip_salarizare in ('1','2')) or (@tippersonal='M' and i.tip_salarizare in ('3','4','5','6','7'))) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @liste_drept='S' and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=n.Loc_de_munca))
	group by (case when @ordonare=3 then n.loc_de_munca else '' end), a.marca, a.data
	order by Ordonare_1, Ordonare_2, a.data
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapIstoricVenituri (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
/*
	exec rapIstoricVenituri '03/01/2011', '03/31/2012', null, null, 0, null, null, null, '1', 'T'
*/	
