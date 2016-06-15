--***
create procedure wIaPlinLei @sesiune varchar(50), @parXML xml
as

declare @tipRegistru int 
set @tipRegistru=0 -- Lei 

if @parXML.value('(/row/@tipRegistru)[1]', 'int') is null                          
	set @parXML.modify ('insert attribute tipRegistru {sql:variable("@tipRegistru")} into (/row)[1]')
else
	set @parXML.modify('replace value of (/row/@tipRegistru)[1] with sql:variable("@tipRegistru")') 

exec wIaPlin @sesiune=@sesiune, @parXML=@parXML
