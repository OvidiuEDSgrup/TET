--***
create procedure wLogout @sesiune varchar(50), @parXML xml
as
delete from ASiSRIA.dbo.sesiuniRIA where token=@sesiune
