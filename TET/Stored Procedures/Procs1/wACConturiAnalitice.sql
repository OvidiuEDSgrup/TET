
create procedure wACConturiAnalitice @sesiune varchar(50), @parXML XML  
as 

if @parXML.exist('/row/@doarAnalitice')=1
	set @parXML.modify('replace value of (/row/@doarAnalitice)[1] with 1')
else
	set @parXML.modify('insert attribute doarAnalitice {"1"} into (/row)[1]')

exec wACConturi @sesiune=@sesiune, @parXML=@parXML
