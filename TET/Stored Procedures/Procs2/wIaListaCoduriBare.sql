
create procedure wIaListaCoduriBare @sesiune varchar(50), @parXML xml
as

	declare 
		@utilizator varchar(100)

	IF OBJECT_ID('temp_ListareCodBare') IS NULL
		create table temp_ListareCodBare(utilizator varchar(100), cod varchar(20) )

	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select @utilizator utilizator,count(*) as nrarticole
	from temp_ListareCodBare where utilizator=@utilizator
	for xml raw, root('Date')
