--***
Create procedure rapAnchetaSalarii2 
	(@dataJos datetime, @dataSus datetime, @setlm varchar(20)=null)
as
declare @eroare varchar(2000)
begin try
	select isnull((case when len(fc.Cod_functie)=1 then 'GM '+rtrim(fc.Cod_functie)+':' else '' end)+max(fc.denumire),'   ') as Ocupatie, 
	fc.Cod_functie as Cod_COR, 'Ambele' as Sex,
	sum(case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then 1 else 0 end) as Salariati_cu_luna_completa,
	sum((case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end)
		then (a.venit_total-a.indemnizatie_ore_supl_1-a.indemnizatie_ore_supl_2-a.indemnizatie_ore_supl_3-a.indemnizatie_ore_supl_4
		-a.ind_c_medical_unitate-a.ind_c_medical_cas-a.cmfambp) else 0 end)) as Fond_salarii,
	sum((case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) 
		then a.indemnizatie_ore_supl_1+a.indemnizatie_ore_supl_2+a.indemnizatie_ore_supl_3+a.indemnizatie_ore_supl_4+a.ore_spor_100 else 0 end)) as Ore_suplimentare, 
	0 as Alte_fonduri, max(l.val_numerica) as Ore_normate,
	round(sum(case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then
		(a.ore_lucrate_regim_normal+a.ore_concediu_de_odihna+a.ore_intrerupere_tehnologica
		+a.ore_obligatii_cetatenesti+a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4) else 0 end)/
		count(case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=l.val_numerica/8*
		(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then 1 else 0 end),0) as Ore_remunerate
	from dbo.fluturas_centralizat (@datajos,@datasus, '', 'zzzzzz', '', 'ZZZZZZZ', 0, 'N', 0, '3', '7', 0, '', 0, '', 0, '', 0, '', 0, '1', 0, '', 1, 'T', 0, 'P', 0, ',', '', 0, 0, 'MARCA', Null, @setlm, null) a
		inner join istpers i on a.marca=i.marca and a.data=i.data
		left outer join personal p on a.marca=p.marca
		left outer join extinfop e on i.cod_functie=e.marca and e.Cod_inf='#CODCOR'
		left outer join functii_cor f on e.val_inf=f.Cod_functie
		left outer join par_lunari l on l.Data=a.Data and l.parametru='ORE_LUNA'
		left outer join functii_cor fc on fc.cod_functie=left(f.cod_functie,len(fc.cod_functie)) 
			and (len(fc.cod_functie)=1 or fc.cod_functie=f.Cod_functie /*and f.numar_curent=fc.numar_curent*/)
	where i.grupa_de_munca in ('N','D','S') 
	--and a.marca='5927'
	group by fc.Cod_functie

	union all

	select isnull((case when len(fc.Cod_functie)=1 then 'GM '+rtrim(fc.Cod_functie)+':' else '' end)+max(fc.denumire),'   ') as Ocupatie, 
	fc.Cod_functie as Cod_COR, 'Femei' as Sex,
	sum(case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then 1 else 0 end) as Salariati_cu_luna_completa,
	sum((case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end)
		then (a.venit_total-a.indemnizatie_ore_supl_1-a.indemnizatie_ore_supl_2-a.indemnizatie_ore_supl_3-a.indemnizatie_ore_supl_4
		-a.ind_c_medical_unitate-a.ind_c_medical_cas-a.cmfambp) else 0 end)) as Fond_salarii,
	sum((case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) 
		then a.indemnizatie_ore_supl_1+a.indemnizatie_ore_supl_2+a.indemnizatie_ore_supl_3+a.indemnizatie_ore_supl_4+a.ore_spor_100 else 0 end)) as Ore_suplimentare, 
	0 as Alte_fonduri, max(l.val_numerica) as Ore_normate,
	round(sum(case when ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=
		l.val_numerica/8*(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then
		(a.ore_lucrate_regim_normal+a.ore_concediu_de_odihna+a.ore_intrerupere_tehnologica
		+a.ore_obligatii_cetatenesti+a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4) else 0 end)/
		count(case when ore_lucrate_regim_normal+ore_concediu_de_odihna
		+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti>=l.val_numerica/8*
		(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) then 1 else 0 end),0) as Ore_remunerate
	from dbo.fluturas_centralizat (@datajos,@datasus, '', 'zzzzzz', '', 'ZZZZZZZ', 0, 'N', 0, '3', '7', 0, '', 0, '', 0, '', 0, '', 0, '1', 0, '', 1, 'T', 0, 'P', 0, ',', '', 0, 0, 'MARCA', Null, @setlm, null) a
		inner join istpers i on a.marca=i.marca and a.data=i.data
		left outer join personal p on a.marca=p.marca
		left outer join extinfop e on i.cod_functie=e.marca and e.Cod_inf='#CODCOR'
		left outer join functii_cor f on e.val_inf=f.Cod_functie
		left outer join par_lunari l on l.Data=a.Data and l.parametru='ORE_LUNA'
		left outer join functii_cor fc on fc.cod_functie=left(f.cod_functie,len(fc.cod_functie)) 
		and (len(fc.cod_functie)=1 or fc.cod_functie=f.Cod_functie /*and f.numar_curent=fc.numar_curent*/)
	where i.grupa_de_munca in ('N','D','S') and p.Sex=0
	group by fc.Cod_functie, p.Sex
	order by fc.Cod_functie, Sex

end try

begin catch
	set @eroare='Procedura rapAnchetaSalarii2 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
