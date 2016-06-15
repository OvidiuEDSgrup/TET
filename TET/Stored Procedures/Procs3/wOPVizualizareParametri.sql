
Create procedure wOPVizualizareParametri @sesiune varchar(50), @parXML xml
as

select 'OK' as VizualizareParametri
for xml raw, root('Date')
