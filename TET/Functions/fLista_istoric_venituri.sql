--***
/**	functie lista istoric venituri	*/
Create 
function [dbo].[fLista_istoric_venituri]
	(@DataJos datetime, @DataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9), 
	@Ordonare int, @Filtru_grupa int, @Grupa char(1), @Filtru_sex int, @Sex int, @lTip_salarizare int, @Tip_salarizare char(1), 
	@l_drept char(1), @User char(30), @User_windows int)
returns @date_istoric table
	(data datetime,marca char(6),loc_de_munca char(9),nume char(50),grupa_de_munca char(1), regim_de_lucru float,
	total_ore_lucrate int,zile_lucrate int,ore_nemotivate int,zile_nemotivate int, ore_concediu_medical int, zile_concediu_medical int, ore_concediu_de_odihna int,zile_concediu_de_odihna int, ore_suplimentare int, zile_suplimentare int, ore_invoiri int, zile_invoiri int,
	ore_intrerupere_tehnologica int, zile_intrerupere_tehnologica int, ore_obligatii_cetatenesti int, zile_obligatii_cetatenesti int,
	ore_concediu_fara_salar int, zile_concediu_fara_salar int, realizat_regie int,realizat_acord int,indemnizatie_ore_supl_1 int, indemnizatie_ore_supl_2 int, indemnizatie_ore_supl_3 int, indemnizatie_ore_supl_4 int, indemnizatie_ore_spor_100 int,
	ind_ore_de_noapte int, ind_obligatii_cetatenesti int, ind_concediu_de_odihna int, ind_c_medical_CAS int, ind_c_medical_unitate int, 
	Premiu int, VENIT_TOTAL int, VEN_NET_IN_IMP int, Impozit int, VENIT_NET int, Loc_de_munca1 char(9), Loc_munca_grupare char(30),
	Salar_de_baza int, Denumire_locm char(50), Cod_functie char(30), Denumire_functie char(30), Td_zile_calend_cm int, 
	Ordonare_1 char(50), Ordonare_2 char(30))
As
Begin
	Declare @drept_conducere int, @liste_drept char(1), @drept int
	Set @drept_conducere=dbo.iauParL('PS','DREPTCOND')
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

	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)

	insert into @date_istoric
	select a.data, a.marca, max(e.loc_de_munca), max(c.nume), max(c.grupa_de_munca), max(isnull(d.regim_de_lucru,8)),
		sum(a.total_ore_lucrate), round(sum(a.total_ore_lucrate/isnull(d.regim_de_lucru,8)),0), sum(a.ore_nemotivate), round(sum(a.ore_nemotivate/isnull(d.regim_de_lucru,8)),0), sum(a.ore_concediu_medical), round(sum(a.ore_concediu_medical/isnull(d.regim_de_lucru,8)),0), sum(a.ore_concediu_de_odihna), round(sum(a.ore_concediu_de_odihna/isnull(d.regim_de_lucru,8)),0), 
		sum(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4),
		round(sum(a.ore_suplimentare_1/isnull(d.regim_de_lucru,8)+a.ore_suplimentare_2/isnull(d.regim_de_lucru,8)+a.ore_suplimentare_3/
		isnull(d.regim_de_lucru,8)+a.ore_suplimentare_4/isnull(d.regim_de_lucru,8)),0),
		sum(a.ore_invoiri), round(sum(a.ore_invoiri/isnull(d.regim_de_lucru,8)),0), sum(a.ore_intrerupere_tehnologica), round(sum(a.ore_intrerupere_tehnologica/isnull(d.regim_de_lucru,8)),0), sum(a.ore_obligatii_cetatenesti), round(sum(a.ore_obligatii_cetatenesti/isnull(d.regim_de_lucru,8)),0), sum(a.ore_concediu_fara_salar), (case when isnull(max(ca.Zile_CFS),0)<>0 and max(a.Spor_cond_10)<1 then isnull(max(ca.Zile_CFS),0) else round(sum(a.ore_concediu_fara_salar/isnull(d.regim_de_lucru,8)),0) end), sum(a.realizat__regie), sum(a.realizat_acord), sum(a.indemnizatie_ore_supl_1), sum(a.indemnizatie_ore_supl_2), sum(a.indemnizatie_ore_supl_3), sum(a.indemnizatie_ore_supl_4), sum(a.indemnizatie_ore_spor_100), sum(a.ind_ore_de_noapte), sum(a.ind_obligatii_cetatenesti), sum(a.ind_concediu_de_odihna), sum(a.ind_c_medical_CAS), sum(a.ind_c_medical_unitate), sum(a.premiu),  max(e.VENIT_TOTAL),max(e.VEN_NET_IN_IMP), max(e.Impozit), max(e.VENIT_NET), max(d.Loc_de_munca), 
		(case when @ordonare=3 then e.loc_de_munca else '' end), max(i.salar_de_baza), max(g.denumire), 
		max(isnull(f2.Cod_functie,c.Cod_functie)), max(f.Denumire), 
		(select sum(convert(int,h.data_sfarsit-h.data_inceput+1)) from conmed h where a.data=h.data and a.marca=h.marca) as td_zile_calend_cm, (case when @ordonare=2 then max(c.nume) when @ordonare=1 then a.marca else max(e.loc_de_munca) end) as Ordonare_1, 
		(case when @ordonare =3 then a.marca else '' end) as Ordonare_2
	from brut a 
		left outer join (select data, marca, loc_de_munca, max(regim_de_lucru) as regim_de_lucru from pontaj 
		where data between @DataJos and @DataSus Group by data, marca, loc_de_munca) d on a.data=d.data 
		and a.marca=d.marca and a.loc_de_munca=d.loc_de_munca 
		left outer join personal c on a.marca=c.marca 
		left outer join net e on a.data=e.data and a.marca=e.marca
		left outer join istpers i on a.data=i.data and a.marca=i.marca
		left outer join lm g on e.loc_de_munca=g.cod
		left outer join functii f on c.Cod_functie=f.Cod_functie
		left outer join extinfop f1 on c.Cod_functie=f1.Marca and f1.Cod_inf='#CODCOR'
		left outer join functii_COR f2 on f1.Val_inf=f2.Numar_curent
		left outer join (select data, marca, sum(Zile) as Zile_CFS from conalte where data between @DataJos and @DataSus and Tip_concediu='1' group by data, marca) ca on a.data=ca.data and a.marca=ca.marca
	where a.data between @DataJos and @DataSus and  a.marca between @MarcaJos and @MarcaSus 
		and e.loc_de_munca between @LocmJos and @LocmSus 
		and (@Filtru_grupa=0 or c.grupa_de_munca=@Grupa) and (@Filtru_sex=0 or c.sex=@Sex) 
		and (@lTip_salarizare=0 or (@Tip_salarizare='T' and c.tip_salarizare in ('1','2')) or (@Tip_salarizare='M' and c.tip_salarizare in ('3','4','5','6','7'))) and (@drept_conducere=0 or (@drept_conducere=1 and @drept=1 and (@liste_drept='T' or @liste_drept='C' and c.pensie_suplimentara=1 or @liste_drept='S' and c.pensie_suplimentara<>1)) or (@drept_conducere=1 and @drept=0 and @liste_drept='S' and c.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=e.Loc_de_munca))
	group by (case when @ordonare=3 then e.loc_de_munca else '' end), a.marca, a.data
	order by Ordonare_1, Ordonare_2, a.data

	Return 
End
