--***
/**	functia lista istoric personal	*/
Create 
function [dbo].[fLista_istoric_personal]
	(@DataJos datetime, @DataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9),
	@Ordonare int, @Filtru_grupa int, @Grupa char(1), @Filtru_sex int, @Sex int, @lTip_salarizare int, @Tip_salarizare char(1), 
	@l_drept char(1), @User char(30), @User_windows int)
returns @date_istoric table
	(data datetime,marca char(6),loc_de_munca char(9),denumire_loc_munca char(30),ore_concediu_fara_salar int, 
	zile_concediu_fara_salar int, ore_concediu_medical int, zile_concediu_medical int, ore_concediu_de_odihna int, 
	zile_concediu_de_odihna int, nume char(50), cod_functie char(6), grupa_de_munca char(1), data_angajarii_in_unitate char(10), 
	categoria_salarizare char(4), salar_de_incadrare_pers int, denumire_functie char(30), regim_de_lucru int, salar_de_incadrare_ist int,
	spor_vechime int, zile_lucratoare_cm int,data_plec char(10),loc_munca_grupare char(30),ordonare1 char(50),ordonare2 char(50)) 
As 
Begin
	declare @drept_conducere int, @liste_drept char(1), @drept int
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
	select a.data, a.marca, max(a.loc_de_munca), max(e.denumire), sum(a.ore_concediu_fara_salar), 
		(case when isnull(max(ca.Zile_CFS),0)<>0 and max(a.Spor_cond_10)<1 then isnull(max(ca.Zile_CFS),0) else round(sum(a.ore_concediu_fara_salar/(case when a.spor_cond_10=0 then 8 else a.spor_cond_10 end)),0) end), sum(a.ore_concediu_medical), round(sum(a.ore_concediu_medical/(case when a.spor_cond_10=0 then 8 else a.spor_cond_10 end)),0),
		sum(a.ore_concediu_de_odihna), round(sum(a.ore_concediu_de_odihna/(case when a.spor_cond_10=0 then 8 else a.spor_cond_10 end)),0), max(b.nume), max(c.cod_functie), max(b.grupa_de_munca), max(convert(char(10),b.data_angajarii_in_unitate,104)), max(b.categoria_salarizare), max(b.salar_de_incadrare), max(d.denumire), (case when max(a.spor_cond_10)=0 then 8 else max(a.spor_cond_10) end) as regim_de_lucru, max(c.salar_de_incadrare),max(c.spor_vechime), 
		(select sum(h.zile_lucratoare) from conmed h where a.data=h.data and a.marca=h.marca)  as zile_lucratoare_cm, 
		(case when max(convert(int,b.loc_ramas_vacant))=1 and max(b.data_plec)<>'01/01/1901' and max(isnull(b.data_plec,''))<>'' and(max(b.mod_angajare)='D' or (month(a.data)=month(max(b.data_plec)) and year(a.data)=year(max(b.data_plec))))then max(convert(char(10),b.data_plec,104)) else '' end ),
		(case when @ordonare=3 then a.loc_de_munca else '' end),
		(case when @ordonare=2 then max(b.nume) when @ordonare=1 then a.marca else max(a.loc_de_munca) end) as Ordonare_1,
		(case when @ordonare=3 then a.marca else '' end) as Ordonare_2
	from brut a
		left outer join personal b on b.marca=a.marca
		inner join istpers c on c.data=a.data and c.marca=a.marca 
		left outer join functii d on c.cod_functie=d.cod_functie
		left outer join lm e on e.cod=a.loc_de_munca
		left outer join (select data, marca, sum(Zile) as Zile_CFS from conalte where data between @DataJos and @DataSus and Tip_concediu='1' group by data, marca) ca on a.data=ca.data and a.marca=ca.marca
	where a.data between @DataJos and @DataSus and a.marca between @MarcaJos and @MarcaSus 
		and	a.loc_de_munca between @LocmJos and @LocmSus and (@Filtru_grupa=0 or b.grupa_de_munca=@Grupa) 
		and (@Filtru_sex=0 or b.sex=@Sex) and (@ltip_salarizare=0 or (@tip_salarizare='T' and b.tip_salarizare in ('1','2')) 
		or (@tip_salarizare='M' and b.tip_salarizare in ('3','4','5','6','7'))) 
		and (@drept_conducere=0 or (@drept_conducere=1 and @drept=1 and (@liste_drept='T' or @liste_drept='C' and b.pensie_suplimentara=1 or @liste_drept='S' and b.pensie_suplimentara<>1)) 
		or (@drept_conducere=1 and @drept=0 and @liste_drept='S' and b.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=a.Loc_de_munca))
	group by (case when @ordonare=3 then a.loc_de_munca else '' end), a.marca, a.data
	order by Ordonare_1, Ordonare_2, a.data

	Return 
End
