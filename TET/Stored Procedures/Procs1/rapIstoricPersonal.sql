/**	procedura pentru raportul istoric personal */
Create procedure rapIstoricPersonal
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @grupamunca char(1)=null, @sex int=null, @tippersonal char(1)=null, 
	@ordonare int, @l_drept char(1))
As
Begin try
	declare @dreptConducere int, @liste_drept char(1), @areDreptCond int
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

	select b.data, b.marca, max(isnull(i.Nume,p.nume)) as nume, max(b.loc_de_munca) as lm, max(lm.denumire) as den_lm, 
		max(i.cod_functie) as cod_functie, max(f.denumire) as den_functie, max(p.grupa_de_munca) as grupa_de_munca, max(p.categoria_salarizare) as categoria_salarizare, 
		max(isnull(i.Salar_de_incadrare,p.salar_de_incadrare)) as salar_de_incadrare, 
		(case when max(i.Mod_angajare)='D' then 'Determinata' when max(i.Mod_angajare)='R' then 'Detasare' else 'Nedeterminata' end) as mod_angajare,
		max(convert(char(10),p.data_angajarii_in_unitate,104)) as data_angajarii, 
		(case when max(convert(int,p.loc_ramas_vacant))=1 and max(p.data_plec)<>'01/01/1901' and max(isnull(p.data_plec,''))<>'' and(max(p.mod_angajare)='D' or (month(b.data)=month(max(p.data_plec)) and year(b.data)=year(max(p.data_plec))))then max(convert(char(10),p.data_plec,104)) else '' end ) as data_plec,
		sum(b.ore_concediu_fara_salar) as ore_cfs, (case when isnull(max(ca.Zile_CFS),0)<>0 and max(b.Spor_cond_10)<1 then isnull(max(ca.Zile_CFS),0) else round(sum(b.ore_concediu_fara_salar/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) end) as zile_cfs, 
		sum(b.ore_concediu_medical) as ore_cm, round(sum(b.ore_concediu_medical/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) as zile_cm,
		sum(b.ore_concediu_de_odihna) as ore_co, round(sum(b.ore_concediu_de_odihna/(case when b.spor_cond_10=0 then 8 else b.spor_cond_10 end)),0) as zile_co, 
		(case when max(b.spor_cond_10)=0 then 8 else max(b.spor_cond_10) end) as regim_de_lucru, max(i.spor_vechime) as spor_vechime, 
		isnull(max(cm.zile_lucratoare_cm),0) as zile_lucratoare_cm, 
		(case when @ordonare=3 then b.loc_de_munca else '' end) as lm_grupare,
		(case when @ordonare=2 then max(p.nume) when @ordonare=1 then b.marca else max(b.loc_de_munca) end) as ordonare_1,
		(case when @ordonare=3 then b.marca else '' end) as ordonare_2
	from brut b
		left outer join personal p on p.marca=b.marca
		inner join istpers i on i.data=b.data and i.marca=b.marca 
		left outer join functii f on i.cod_functie=f.cod_functie
		left outer join lm on lm.cod=b.loc_de_munca
		left outer join (select data, marca, sum(Zile) as Zile_CFS from conalte where data between @dataJos and @dataSus and Tip_concediu='1' group by data, marca) ca on b.data=ca.data and b.marca=ca.marca
		left outer join (select data, marca, sum(Zile_lucratoare) as zile_lucratoare_cm from conmed where data between @dataJos and @dataSus group by data, marca) cm on b.data=cm.data and b.marca=cm.marca
	where b.data between @dataJos and @dataSus and (@marca is null or b.marca=@marca) 
		and	(@locm is null or b.loc_de_munca like RTRIM(@locm)+(case when @strict=1 then '' else '%' end)) and (@grupamunca is null or p.grupa_de_munca=@grupamunca) 
		and (@sex is null or p.sex=@sex) and (@tippersonal is null or (@tippersonal='T' and p.tip_salarizare in ('1','2')) or (@tippersonal='M' and p.tip_salarizare in ('3','4','5','6','7'))) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @liste_drept='S' and p.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=b.Loc_de_munca))
	group by (case when @ordonare=3 then b.loc_de_munca else '' end), b.marca, b.data
	order by Ordonare_1, Ordonare_2, b.data

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapIstoricPersonal (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
/*
	exec rapIstoricPersonal '04/01/2011', '03/31/2012', null, null, 0, null, null, null, '1', 'T'
*/
