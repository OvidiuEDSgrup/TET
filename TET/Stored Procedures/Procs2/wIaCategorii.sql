--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

CREATE procedure wIaCategorii  @sesiune varchar(50), @parXML XML 
as

declare  @flt_denumire varchar(25)

select 
	@flt_denumire = isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(25)'), '')	
set @flt_denumire= '%'+REPLACE(@flt_denumire,' ','%')+'%'

select rtrim(cod_categ) as codCat, rtrim(denumire_categ) as denumire , (case when rtrim(categ_tb)> 0 then '1' else '0' end) as aparetb, rtrim(categ_tb) as nrordine,
	rtrim(categ_tb) as categtb,
	isnull((select COUNT(*) from compcategorii  where cod_categ=categorii.cod_categ),0) as ind,
	(case when categ_tb>0 then '#0000FF' else '#000000'end) as culoare
from categorii
where
denumire_categ like @flt_denumire
order by (case when categ_tb=0 then 99 else categ_tb end)
for xml raw
