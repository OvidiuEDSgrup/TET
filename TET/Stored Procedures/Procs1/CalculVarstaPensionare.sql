--***
/*
	exemplu de apel
	exec CalculVarstaPensionare @datalunii='10/31/2013', @sex=''
*/
create procedure CalculVarstaPensionare @datalunii datetime, @sex char(1)=null
As
Begin try
	declare @datainiFemei datetime, @datainiBarbati datetime, @faraReturnareDate int
	select @datainiFemei='04/01/1944', @datainiBarbati='01/01/1939'

	select @faraReturnareDate=0
	if OBJECT_ID ('tempdb..#tmpVarste') is not null drop table #tmpVarste
	create table #tmpVarste (sex char(1), datan datetime, data_pensionarii datetime, varsta_ani int, varsta_luni int, ordine int identity, pas int) --datan => data nasterii

	if OBJECT_ID ('tempdb..#VarstePensionare') is not null 
		set @faraReturnareDate=1
	if OBJECT_ID ('tempdb..#VarstePensionare') is null 
		create table #VarstePensionare (sex char(1), data_nasterii datetime, data_pensionarii datetime, varsta_ani int, varsta_luni int, stagiu_complet varchar(10), stagiu_minim varchar(10))

	if @sex is null set @sex=''
--	Barbati - pun datele intr-o tabela temporara, cate o pozitie pt. fiecare luna de la @dataini pana la @datalunii
	if @sex in ('','M')
		insert into #tmpVarste (sex, datan, data_pensionarii, varsta_ani, varsta_luni)
		select 'M', fc.data, '01/01/1901', 0, 0
		from fCalendar (@datainiBarbati, @datalunii) fc where Data=Data_lunii

-- stabilesc pas de incrementare al numarului de luni
	update a set a.pas=(case when a.datan<'04/01/1940' or a.datan>='01/01/1950' then 0 
			when pas5 is not null then pas5/5+(case when pas5%5=0 then 0 else 1 end) 
			when pas3 is not null then 6+pas3/3+(case when pas3%3=0 then 0 else 1 end) else 0 end)
	from #tmpVarste a
--	pentru perioada dintre cele 2 date de mai jos, varsta salariatului la iesirea la pensie creste cu cate 1 luna din 5 in 5 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pas5 from #tmpVarste b where b.sex='M' and b.datan between '04/01/1940' and '09/30/1942') p5 on p5.ordine=a.ordine
--	pentru perioada dintre cele 2 date de mai jos, varsta salariatului la iesirea la pensie creste cu cate 1 luna din 3 in 3 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pas3 from #tmpVarste b where b.sex='M' and b.datan between '10/01/1942' and '12/31/1949') p3 on p3.ordine=a.ordine
	where a.sex='M'

--	Femei
	if @sex in ('','F')
		insert into #tmpVarste (sex, datan, data_pensionarii, varsta_ani, varsta_luni)
		select 'F', fc.data, '01/01/1901', 0, 0
		from fCalendar (@datainiFemei, @datalunii) fc where Data=Data_lunii

-- stabilesc pas de incrementare al numarului de luni din varsta de pensionare
	update a set a.pas=(case when a.datan<'04/01/1945' or a.datan>='01/01/1967' then 0 
			when pas5 is not null then pas5/5+(case when pas5%5=0 then 0 else 1 end) 
			when pas3 is not null then 6+pas3/3+(case when pas3%3=0 then 0 else 1 end) 
			when pasf is not null then 11+pasf/5+(case when pasf%5=0 then 0 else 1 end) 
			when pas11 is not null then 9+pas11/11+(case when pas11%11=0 then 0 else 1 end) 
			else 0 end)
	from #tmpVarste a
--	pentru perioada dintre cele 2 date de mai jos varsta salariatului la iesirea la pensie creste cu cate 1 luna din 5 in 5 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pas5 from #tmpVarste b where b.sex='F' and b.datan between '04/01/1945' and '09/30/1947') p5 on p5.ordine=a.ordine
--	pentru perioada dintre cele 2 date de mai jos varsta salariatului la iesirea la pensie creste cu cate 1 luna din 3 in 3 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pas3 from #tmpVarste b where b.sex='F' and b.datan between '10/01/1947' and '12/31/1960') p3 on p3.ordine=a.ordine
--	pentru perioada dintre cele 2 date de mai jos varsta salariatului la iesirea la pensie creste cu cate 1 luna din 5 in 5 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pasf from #tmpVarste b where b.sex='F' and b.datan between '01/01/1961' and '02/28/1965') pf on pf.ordine=a.ordine
--	pentru perioada dintre cele 2 date de mai jos varsta salariatului la iesirea la pensie creste cu cate 1 luna din 11 in 11 luni
		left outer join (select datan, ordine, row_number() over (order by datan) as pas11 from #tmpVarste b where b.sex='F' and b.datan between '03/01/1965' and '12/31/1966') p11 on p11.ordine=a.ordine
	where a.sex='F'

-- stabilesc ani / luni de pensionare
	update #tmpVarste set 
		varsta_ani=(case 
			when sex='M' then 
				(case when datan>='01/01/1950' then 65 when datan>='01/01/1947' then 64 when datan>='01/01/1944' then 63 else 62 end)
			else (case when datan>='01/01/1967' then 63 when datan>='01/01/1961' then 62 when datan>='01/01/1958' then 61
				when datan>='01/01/1955' then 60 when datan>='01/01/1952' then 59 when datan>='01/01/1949' then 58 else 57 end) 
			end),
		varsta_luni=(case when pas%12=0 then 0 else pas%12 end)

	update #tmpVarste set data_pensionarii=dbo.EOM(DateADD(month,varsta_luni,DateADD(year,varsta_ani,datan)))

	insert into #VarstePensionare (sex, data_nasterii, data_pensionarii, varsta_ani, varsta_luni, stagiu_complet, stagiu_minim)
	select sex, datan, data_pensionarii, varsta_ani, varsta_luni, '', ''
	from #tmpVarste

	if @faraReturnareDate=0
		select sex, data_nasterii, data_pensionarii, varsta_ani, varsta_luni, stagiu_complet, stagiu_minim
		from #VarstePensionare
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura CalculVarstaPensionare (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
