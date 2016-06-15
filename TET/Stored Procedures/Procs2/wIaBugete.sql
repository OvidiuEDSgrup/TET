--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

CREATE procedure wIaBugete @sesiune varchar(50), @parXML XML 
as

declare  @flt_denumire varchar(25),@can varchar(20),@an int

select 
	@flt_denumire = isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(25)'), '')	
set @flt_denumire= '%'+REPLACE(@flt_denumire,' ','%')+'%'

set @can= isnull(@parXML.value('(/row/@an)[1]', 'int'), 1)	
if ISNUMERIC(@can)=1 and CONVERT(int,@can)>1920
	set @an=CONVERT(int,@can)
else
	set @an=YEAR(getdate())

select rtrim(cod_categ) as codCat, rtrim(denumire_categ) as denumire , '' as lm,'<Unitate>' as denlm,@an as an
from categorii
where
denumire_categ like @flt_denumire
and cod_categ like 'BUG%'
union all
select rtrim(cod_categ) as codCat, rtrim(denumire_categ) as denumire , lm.cod as lm,lm.Denumire as denlm,@an as an
from categorii,lm,proprietati p
where
denumire_categ like @flt_denumire
and cod_categ like 'BUG%'
and p.tip='LM' and p.Cod_proprietate='BUGET' and p.cod=lm.cod
for xml raw
