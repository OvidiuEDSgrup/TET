create procedure wACPersonal @sesiune varchar(50), @parXML xml
as

declare @faraRestrictiiPlecat int 
set @faraRestrictiiPlecat=1 -- fara restrictii dupa activ/plecat
if @parXML.value('(/row/@faraRestrictiiPlecat)[1]', 'int') is not null                          
	set @parXML.modify('replace value of (/row/@faraRestrictiiPlecat)[1] with sql:variable("@faraRestrictiiPlecat")') 
else
	set @parXML.modify ('insert attribute faraRestrictiiPlecat {sql:variable("@faraRestrictiiPlecat")} into (/row)[1]')

exec wACSalariati @sesiune, @parXML
