
create procedure wIaExceptiiSoldTert @sesiune varchar(50), @parXML XML
as

declare
	@tert varchar(13)

select
	@tert = @parXML.value('(/row/@tert)[1]','varchar(13)')

select top 100
	idExceptie,
	convert(varchar(10),dela,101) as dela,
	convert(varchar(5),dela,108) as ora_start,
	convert(varchar(10),panala,101) as panala,
	convert(varchar(5),panala,108) as ora_stop,
	rtrim(explicatii) as explicatii,
	convert(decimal(17,2),sold_max) as sold_max,
	rtrim(utilizator) as utilizator,
	convert(varchar(10),data_operarii,101) + '   ' + convert(varchar(10),data_operarii,108) as data_operarii
from ExceptiiSoldTert
where tert=@tert
order by dela desc
for xml raw
