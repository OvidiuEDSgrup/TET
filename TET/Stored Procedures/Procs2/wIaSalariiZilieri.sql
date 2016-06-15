--***
Create 
procedure wIaSalariiZilieri @sesiune varchar(50), @parXML xml
as
Begin
	declare @userASiS varchar(20), @LunaInch int, @AnulInch int, @DataInch datetime, 
	@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
	@tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @lmantet varchar(9), @f_lm varchar(9), 
	@f_salariat varchar(50), @DataLJ datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
	@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
	@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
	@lmantet=xA.row.value('@lmantet','varchar(9)'), @f_lm=xA.row.value('@f_lm','varchar(9)')
	from @parXML.nodes('row') as xA(row)  
	set @DataLJ=dbo.Bom(@datasus)

	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

	set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
	set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
	set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

	select rtrim(rtrim(max(fc.LunaAlfa))+' '+convert(char(4),max(fc.An))) as luna, count(distinct z.Marca) as nrzilieri ,
		(case ISNULL(@lmantet,'') when '' then RTRIM(z.Loc_de_munca) else rtrim(@lmantet) end) as lmantet, rtrim(max(convert(char(10),dbo.eom(s.data),101))) as data, 
		sum(s.Ore_lucrate) as orelucrate, convert(decimal(12,0),sum(s.Diferenta_salar)) as difsal, 
		convert(decimal(12,0),sum(s.Venit_total)) as venittotal, convert(decimal(12,0),sum(s.impozit)) as impozit, convert(decimal(12,0),sum(s.Rest_de_plata)) as restplata, 
		rtrim(max(c.descriere)) as dencomanda,(case ISNULL(@lmantet,'') when '' then  rtrim (max(l.denumire)) else (select denumire from lm where lm.cod=@lmantet)end)  as denlmantet,
		(case when dbo.eom(s.data)<=@DataInch then '#808080' else '#000000' end) as culoare,
		(case when dbo.eom(s.data)<=@DataInch or dbo.eom(s.data)<=@DataBloc then 1 else 0 end) as _nemodificabil
	from SalariiZilieri s
		left outer join Zilieri z on z.Marca=s.marca
		left outer join comenzi c on c.Comanda=s.comanda
		left outer join lm l on l.cod=z.loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and s.Loc_de_munca=lu.cod
		inner join fCalendar (@datajos, @datasus) fc on fc.Data=dbo.eom(s.data)
	where s.Data between @datajos and @datasus
		and ((rtrim(s.loc_de_munca) like '%' + isnull(rtrim(@f_lm),'') + '%') or (rtrim(l.denumire) like '%' + isnull(rtrim(@f_lm),'') + '%'))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by dbo.eom(s.data), z.Loc_de_munca
	union all
	select rtrim(rtrim(max(fc.LunaAlfa))+' '+convert(char(4),max(fc.An))) as luna, 0 as nrzilieri ,
		RTRIM(z.Loc_de_munca) as lmantet, rtrim(max(convert(char(10),@datasus,101))) as data, 
		0 as orelucrate, 0 as difsal, 0 as venittotal, 0 as impozit, 0 as restplata, 
		rtrim(max(c.descriere)) as dencomanda, rtrim (max(l.denumire)) as denlmantet,
		(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
		(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
	from zilieri z
		left outer join lm l on l.Cod=z.Loc_de_munca
		left outer join comenzi c on c.Comanda=z.Comanda 
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and z.Loc_de_munca=lu.cod
		inner join fCalendar (@datajos, @datasus) fc on fc.data=@datasus
	where not exists (select 1 from SalariiZilieri s where s.data between @datajos and @datasus and (s.marca=z.marca or s.Loc_de_munca=z.Loc_de_munca)) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by z.Loc_de_munca
	for xml raw
End
