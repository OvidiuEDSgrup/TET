--***
/*	functie utilizata pentru generarea formularului de adeverinta cass (partea de concedii medicale)
	am facut functie pentru a genera o pozitie fara date, daca marca nu are concedii medicale pentru a se afisa urmatorul subformular cu coasigurati */

Create function dbo.fFormAdeverintaCassCM()
returns @cass_cm table
	(marca char(6), luna char(15), an char(4), zile_cm int, total_zile_cm int, zile_calend_cm int, total_zile_calend_cm int)
as
begin
	declare @utilizator varchar(20), @cTerm char(8), @marca char(6)
	
	set @utilizator=dbo.fIaUtilizator(null)
	set @cTerm=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
	select @marca=Numar from avnefac where Terminal=@cTerm
	
	insert into @cass_cm 
	select c.Marca, dbo.fDenumireLuna(c.Data) as luna,
		convert(char(4),year(c.data)) as an, sum(c.zile_lucratoare) as zile_cm,
		isnull((select sum(c1.zile_lucratoare) from conmed c1 
			where c1.marca=c.marca and c1.data>=max(dbo.EOM(a.data_facturii)) and c1.data<=max(dbo.EOM(a.data)) and c1.Tip_diagnostic not in ('0-','8-','9-')),0) as total_zile_cm,
		sum(DATEDIFF(day,c.Data_inceput,c.Data_sfarsit)+1) as zile_calend_cm,
		isnull((select sum(DATEDIFF(day,c1.Data_inceput,c1.Data_sfarsit)+1) from conmed c1 
			where c1.marca=c.marca and c1.data>=max(dbo.EOM(a.data_facturii)) and c1.data<=max(dbo.EOM(a.data)) and c1.Tip_diagnostic not in ('0-','8-','9-')),0) as total_zile_calend_cm
	from conmed c
		left outer join personal p on p.Marca=c.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca, avnefac a
	where a.Terminal=@cTerm 
		and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=a.numar)
		and c.data>=dbo.EOM(a.data_facturii) and c.data<=dbo.EOM(a.data)
		and c.Tip_diagnostic not in ('0-','8-','9-')
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	GROUP BY c.marca, c.data
	
	if not exists (select Marca from @cass_cm) 
		insert into @cass_cm
		select @Marca, '', '', '', '', '', ''


	return
End

/*
	select * from fFormAdeverintaCassCM()
*/
