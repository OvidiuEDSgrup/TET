
create procedure wACTipButonPV @sesiune varchar(50), @parXML xml
as

select distinct rtrim(tipButon) as cod, rtrim(tipButon) as denumire 
from butoanePv
for xml raw
