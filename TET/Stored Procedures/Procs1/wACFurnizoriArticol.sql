
create procedure  wACFurnizoriArticol @sesiune varchar(30), @parXML XML
as

declare @cod varchar(20)
select @cod = isnull(@parXML.value('(/*/@cod)[1]','varchar(20)'),'')

select rtrim(t.tert) as cod, rtrim(t.Denumire) as denumire
from ppreturi p
inner join terti t on p.tert=t.tert
where cod_resursa=@cod
for xml raw
