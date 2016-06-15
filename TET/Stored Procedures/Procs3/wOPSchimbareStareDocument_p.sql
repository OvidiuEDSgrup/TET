
create procedure wOPSchimbareStareDocument_p (@sesiune varchar(50), @parXML xml)
as

declare
	@tip varchar(2), @numar varchar(20), @data datetime

select
	@tip = @parXML.value('(/row/@tip)[1]','varchar(2)'),
	@numar = @parXML.value('(/row/@numar)[1]','varchar(20)'),
	@data = @parXML.value('(/row/@data)[1]','datetime')


select top 1
	rtrim(j.explicatii) as explicatii_stare_jurnal,
	j.stare as stare_jurnal,
	rtrim(s.denumire) as den_stare_jurnal
from jurnaldocumente j
	inner join staridocumente s on j.stare=s.stare and j.tip=s.tipDocument
where j.tip=@tip and j.numar=@numar and j.data=@data
order by j.data_operatii desc, j.idJurnal desc
for xml raw
