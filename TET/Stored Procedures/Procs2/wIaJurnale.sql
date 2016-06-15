
create  procedure wIaJurnale @sesiune varchar(50), @parXML xml
as 

declare
	@f_jurnal varchar(20), @f_descriere varchar(75)

select
	@f_jurnal = isnull(@parXML.value('(/row/@f_jurnal)[1]','varchar(20)'),''),
	@f_descriere = '%' + replace(isnull(@parXML.value('(/row/@f_descriere)[1]','varchar(75)'),''),' ','%') + '%'

select 
	rtrim(jurnal) as jurnal,rtrim(descriere) as descriere,rtrim(utilizator) as utilizator, detalii
from jurnale
where 
	(@f_jurnal='' or jurnal like @f_jurnal + '%')
	and (descriere like @f_descriere)
order by jurnal
for xml raw

select '1' as areDetaliiXml for xml raw, root('Mesaje')
