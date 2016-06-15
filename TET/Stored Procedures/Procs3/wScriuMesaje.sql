--***
create procedure wScriuMesaje @sesiune varchar(50), @parXML xml
as
begin
	delete from mesaje where DATEDIFF(MINUTE,dataora,GETDATE())<1
	declare @sursa varchar(40),@destinatie varchar(40),@mesaj varchar(8000),@versiune int
	select @sursa= isnull(@parXML.value('(/row/@sursa)[1]', 'varchar(40)'),0),
		@destinatie= isnull(@parXML.value('(/row/@destinatie)[1]', 'varchar(40)'),''),
		@mesaj=isnull(@parXML.value('(/row/@mesaj)[1]', 'varchar(8000)'),''),
		@versiune=isnull(@parXML.value('(/row/@versiune)[1]', 'int'),0)
	
	insert into asisria..mesaje(sursa,destinatie,mesaj,tip)
	values(@sursa,@destinatie,@mesaj,'ch')
	declare @par varchar(1000)
	set @par='<row versiune="'+ltrim(str(@versiune))+'"/>'
	exec wIaMesaje '',@par
end
