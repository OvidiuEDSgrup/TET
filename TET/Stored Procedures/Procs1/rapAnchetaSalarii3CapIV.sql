--***
Create procedure rapAnchetaSalarii3CapIV
	(@dataJos datetime, @dataSus datetime, @judet varchar(20)=null, @marca varchar(6)=null)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted

	declare @q_dataJos datetime, @q_dataSus datetime, @zile_cal float, @utilizator varchar(20)
	select @q_dataJos=dbo.BOM(@dataJos), @q_dataSus=dbo.EOM(@dataSus)	-- se va genera raportul pe luni intregi
	set @zile_cal = datediff(day,@q_dataJos,@q_dataSus)+1
	
	set @utilizator = dbo.fIaUtilizator(null)	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)

--	scos rollup pentru ca merge doar pe compatilitate 100
/*
	select (case when grouping(isnull(l.cod_oras,isnull(pr.Valoare,'')))=1 then 'Total' else max(isnull(l.oras,isnull(pr.Valoare,'NECOMPLETAT'))) end) as localitate, 
		(case when grouping(isnull(l.cod_oras,isnull(pr.Valoare,'')))=1 then '' else max(isnull(l.cod_postal,'')) end) as cod_siruta, 
		round(sum(a.ore*(case when i.Grupa_de_munca='C' then 8/(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end) else 1 end))/@zile_cal,1) as numar_salariati
	from fOreNumarMediuSalariati (@q_datajos,@q_dataSus, '', '', 'zzz', '', @judet, null) a
		left outer join istPers i on i.Data=a.data and i.Marca=a.marca
		left outer join lm on lm.Cod=i.Loc_de_munca
		left outer join proprietati pr on pr.Tip='LM' and pr.Cod=i.Loc_de_munca and pr.Cod_proprietate='LOCALITATE' and pr.Valoare<>''
		left outer join Localitati l on l.cod_oras=pr.Valoare
	where (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.loc_de_munca))

	Group by rollup(isnull(l.cod_oras,isnull(pr.Valoare,'')))
	Order by grouping(isnull(l.cod_oras,isnull(pr.Valoare,''))) desc
*/
	select 'Total' as localitate, '' as cod_siruta, 
		round(sum(a.ore*(case when i.Grupa_de_munca='C' then 8/(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end) else 1 end))/@zile_cal,1) as numar_salariati
	from fOreNumarMediuSalariati (@q_datajos,@q_dataSus, '', '', 'zzz', '', @judet, null) a
		left outer join istPers i on i.Data=a.data and i.Marca=a.marca
		left outer join lm on lm.Cod=i.Loc_de_munca
		left outer join proprietati pr on pr.Tip='LM' and pr.Cod=i.Loc_de_munca and pr.Cod_proprietate='LOCALITATE' and pr.Valoare<>''
		left outer join Localitati l on l.cod_oras=pr.Valoare
	where (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.loc_de_munca))
	union all
	select max(isnull(l.oras,isnull(pr.Valoare,'NECOMPLETAT'))) as localitate, max(isnull(l.cod_postal,'')) as cod_siruta, 
		round(sum(a.ore*(case when i.Grupa_de_munca='C' then 8/(case when i.Salar_lunar_de_baza=0 then 8 else i.Salar_lunar_de_baza end) else 1 end))/@zile_cal,1) as numar_salariati
	from fOreNumarMediuSalariati (@q_datajos,@q_dataSus, '', '', 'zzz', '', @judet, null) a
		left outer join istPers i on i.Data=a.data and i.Marca=a.marca
		left outer join lm on lm.Cod=i.Loc_de_munca
		left outer join proprietati pr on pr.Tip='LM' and pr.Cod=i.Loc_de_munca and pr.Cod_proprietate='LOCALITATE' and pr.Valoare<>''
		left outer join Localitati l on l.cod_oras=pr.Valoare
	where (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.loc_de_munca))
	Group by isnull(l.cod_oras,isnull(pr.Valoare,''))

End	try

begin catch
	set @eroare='Procedura rapAnchetaSalarii3CapIV (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
