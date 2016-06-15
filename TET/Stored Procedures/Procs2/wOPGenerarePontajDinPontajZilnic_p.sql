create procedure wOPGenerarePontajDinPontajZilnic_p (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @datalunii datetime, @dataJos datetime, @dataSus datetime, @utilizatorASiS varchar(50), @marca varchar(6), @densalariat varchar(100)

	set @datalunii = @parXML.value('(/row/@data)[1]', 'datetime')
	set @marca = @parXML.value('(/row/row/@marca)[1]', 'varchar(6)')
	select @dataJos = dbo.BOM(@datalunii)
	select @dataSus = dbo.EOM(@datalunii)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	if nullif(@marca,'') is not null and exists (select 1 from personal where marca=@marca)
		select @densalariat=rtrim(nume) from personal where marca=@marca
	else 
		set @marca=null

	select convert(varchar(10),@datajos,101) as datajos, convert(varchar(10),@datasus,101) as datasus, 
			@marca as marca, @densalariat as densalariat
	for xml raw
end
