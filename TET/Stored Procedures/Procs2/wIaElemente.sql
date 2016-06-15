--***
create procedure wIaElemente @sesiune varchar(50),@parXML XML
as
declare @eroare varchar(1000),@utilizatorASiS varchar(50)
set @eroare=''
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	declare @element varchar(50), @denElement varchar(50)
	select	@element=isnull(@parXML.value('(row/@element)[1]','varchar(50)'),''),
			@denElement=replace(isnull(@parXML.value('(row/@denElement)[1]','varchar(50)'),''),' ','%')
	select 
	rtrim(Cod) cod, 
	rtrim(Denumire) denumire, 
	rtrim(Tip) tip, 
	(case when rtrim(UM2)='D' then 'D' else 'A' end) as tipInterval, 
	(case when UM2='D' then 'Data' else 'Activitate' end) as denTipInterval,
	RTRIM(um) as um,
	rtrim(Interval) as valoare
	from elemente e
		where e.Cod like @element+'%' and e.Denumire like '%'+@denElement+'%'
	for xml raw
end try
begin catch
	set @eroare='wIaElemente'+char(10)+ERROR_MESSAGE()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
