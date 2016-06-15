--***
CREATE procedure wmModificareTertDispReceptie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmModificareTertDispReceptieSP' and type='P')
begin
	exec wmModificareTertDispReceptieSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @tert varchar(13)
select @tert = @parXML.value('(/row/@tert)[1]', 'varchar(13)')

if @tert is null
	--pentru alegerea tertului fortam trimiterea prin catalogul de terti
begin
	set @parXML.modify ('insert attribute wmIaTerti.procdetalii {"wmAlegClientDispReceptie"} into (/row)[1]')
	exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
	select @tert = @parXML.value('(/row/@tert)[1]', 'varchar(13)')
	exec wmScriuAntetDispReceptie @sesiune=@sesiune, @parXML=@parXML
	return 0
end

SELECT 'back(1)' AS actiune
FOR XML RAW,ROOT('Mesaje')
