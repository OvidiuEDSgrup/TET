--***
Create procedure wIaInformatiiPersonal @sesiune varchar(50), @parXML xml
as  
declare @tiptab varchar(2), @userASiS varchar(10)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @tiptab='IN'
set @parXML.modify ('insert attribute tiptab {sql:variable("@tiptab")} into (/row)[1]') 

exec wIaExtinfop @sesiune=@sesiune, @parXML=@parXML
