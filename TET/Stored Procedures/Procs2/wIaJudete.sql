--***
create procedure [dbo].[wIaJudete] @sesiune varchar(50), @parXML xml
as

declare @f_cod_judet varchar(3), @f_judet varchar(30), @f_prefix varchar(4)

set @f_cod_judet = @parXML.value('(/*/@f_cod_judet)[1]','varchar(3)')
set @f_judet = @parXML.value('(/*/@f_judet)[1]','varchar(30)')
set @f_prefix = @parXML.value('(/*/@f_prefix)[1]','varchar(4)')

select	rtrim(j.cod_judet) as cod_judet, rtrim(j.denumire) as judet, rtrim(j.prefix_telefonic) as prefix,
		rtrim(j.cod_judet) as judet_, rtrim(j.denumire) as den_judet
from Judete j
where (@f_cod_judet is null or j.cod_judet like '%' + @f_cod_judet + '%')
	and	(@f_judet is null or j.denumire like '%' + @f_judet + '%')
	and (@f_prefix is null or j.prefix_telefonic like '%' + @f_prefix + '%')
order by j.Denumire
for xml raw
