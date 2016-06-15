
create procedure wOPExportDoc_p @sesiune varchar(50), @parXML xml
as

exec wOPExportDoc @sesiune=@sesiune, @parXML=@parXML

select '1' as 'inchideFereastra' for xml raw, root('Mesaje')
