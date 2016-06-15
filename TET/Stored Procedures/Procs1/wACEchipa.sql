
create procedure [dbo].[wACEchipa] @sesiune varchar(50), @parXML XML
as

select distinct valoare as cod, valoare as denumire from proprietati where Cod_proprietate='ECHIPA' and tip='TERT'
order by proprietati.valoare
for xml raw