--***
CREATE procedure [dbo].[wIaLocalitati] @sesiune varchar(50), @parXML xml
as

declare @f_localitate varchar(30), @f_judet varchar(30), @f_codpostal varchar(10), @f_extern bit

set @f_localitate = @parXML.value('(/*/@f_localitate)[1]','varchar(30)')
set @f_judet = @parXML.value('(/*/@f_judet)[1]','varchar(30)')
set @f_codpostal = @parXML.value('(/*/@f_codpostal)[1]','varchar(10)')
set @f_extern = @parXML.value('(/*/@f_extern)[1]','bit')

select rtrim(l.cod_oras) as cod_localitate,rtrim(l.oras) as localitate, rtrim(j.denumire) as judet, rtrim(l.cod_postal) as cod_postal, rtrim(l.extern) as extern,
		rtrim(l.cod_oras) as local, rtrim(l.oras) as den_local, rtrim(l.cod_judet) as jud, rtrim(j.denumire) as den_jud
from Localitati l
	inner join Judete j on j.cod_judet = l.cod_judet
where ((@f_localitate is null) or (l.cod_oras like '%' + @f_localitate + '%') or (l.oras like '%' + @f_localitate + '%'))
	and (@f_judet is null or j.denumire like '%' + @f_judet + '%')
	and (@f_codpostal is null or l.cod_postal like '%' + @f_codpostal + '%')
	and (@f_extern is null or l.extern = @f_extern)
order by j.denumire,l.oras
for xml raw
