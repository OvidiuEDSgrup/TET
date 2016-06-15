
create procedure wmAlegGestiuneDispReceptie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegGestiuneDispReceptieSP' and type='P')
begin
	exec wmAlegGestiuneDispReceptieSP @sesiune, @parXML 
	return -1
end

	set transaction isolation level READ UNCOMMITTED
	declare 
		@gestiune varchar(13)
	select 
		@gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(13)')

	if @gestiune is null
	begin
		set @parXML.modify ('insert attribute wmIaGestiuni.procdetalii {"wmAlegGestiuneDispReceptie"} into (/row)[1]')
		exec wmIaGestiuni @sesiune=@sesiune, @parXML=@parXML
		select @gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(13)')
		return 0
	end

	exec wmScriuAntetDispReceptie @sesiune=@sesiune, @parXML=@parXML
