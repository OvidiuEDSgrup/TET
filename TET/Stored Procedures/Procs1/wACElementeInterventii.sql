--***
create procedure wACElementeInterventii @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wACElementeInterventiiSP' and type='P')
	exec wACElementeInterventiiSP @sesiune,@parXML      
else      
begin
	if @parXML.exist('(/row/tipelement)[1]' ) = 1
		set @parXML.modify('replace value of (/row/@tipelement)[1]	with "I"')
	else
		set @parXML.modify ('insert attribute tipelement {"I"} as last into (/row)[1]') 

	exec wACElemente @sesiune,@parXML
end
