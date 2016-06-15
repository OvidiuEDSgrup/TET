create procedure wpopSalariati (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @dataangajarii datetime, @dataplec datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select @dataangajarii=isnull(@parXML.value('(/row/@dataangajarii)[1]','datetime'),''), 
		@dataplec=isnull(@parXML.value('(/row/@dataplec)[1]','datetime'),'')
	
	select convert(char(10),(case when @dataangajarii is null then DateADD(day,1,getdate()) end),101) dataangajarii, 
		(case when @dataplec is null then '01-01-1901' end) as dataplec
	for xml raw
end
