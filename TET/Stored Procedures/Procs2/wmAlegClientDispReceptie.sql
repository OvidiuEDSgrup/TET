
create procedure wmAlegClientDispReceptie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegClientDispReceptieSP' and type='P')
begin
	exec wmAlegClientDispReceptieSP @sesiune, @parXML 
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
	return 0
end

/*if @parXML.value('(/row/@tert)[1]', 'varchar(13)') is not null                        
			set @parXML.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
		else
			set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
*/
exec wmScriuAntetDispReceptie @sesiune=@sesiune, @parXML=@parXML

/*SELECT 'back(1)' AS actiune
FOR XML RAW,ROOT('Mesaje')
*/
