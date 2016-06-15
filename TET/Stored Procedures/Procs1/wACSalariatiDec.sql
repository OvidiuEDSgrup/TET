--***
CREATE procedure wACSalariatiDec @sesiune varchar(50), @parXML XML  
as  

declare @faraRestrictiiPlecat int 
set @faraRestrictiiPlecat=1 -- fara restrictii dupa activ/plecat
if @parXML.value('(/row/@faraRestrictiiPlecat)[1]', 'int') is not null                          
	set @parXML.modify('replace value of (/row/@faraRestrictiiPlecat)[1] with sql:variable("@faraRestrictiiPlecat")') 
else
	set @parXML.modify ('insert attribute faraRestrictiiPlecat {sql:variable("@faraRestrictiiPlecat")} into (/row)[1]')

declare @cuSold int 
set @cuSold=1 -- afisare sold dec. 
if @parXML.value('(/row/@cuSold)[1]', 'int') is not null                          
	set @parXML.modify('replace value of (/row/@cuSold)[1] with sql:variable("@cuSold")') 
else
	set @parXML.modify ('insert attribute cuSold {sql:variable("@cuSold")} into (/row)[1]')

exec wACSalariati @sesiune, @parXML

