
create procedure wACTipIncasarePV @sesiune varchar(50), @parXML xml
as

select distinct tipIncasare as cod, dbo.denTipIncasare(tipIncasare) as denumire 
from butoanePv
where isnull(tipIncasare,'')<>''
for xml raw
