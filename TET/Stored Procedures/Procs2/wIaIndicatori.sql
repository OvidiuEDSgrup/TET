--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

CREATE procedure  wIaIndicatori  @sesiune varchar(50), @parXML XML 
as

declare @flt_cod varchar(20), @flt_denumire varchar(60), @flt_expresie varchar(500), @codCat varchar(20), @flt_categorie varchar(20)

select @flt_cod = rtrim(isnull(@parXML.value('(/row/@f_cod)[1]', 'varchar(20)'), '')),
	@flt_denumire = rtrim(isnull(@parXML.value('(/row/@f_denumire)[1]', 'varchar(60)'), '')),
	@flt_expresie = rtrim(isnull(@parXML.value('(/row/@f_expresie)[1]', 'varchar(500)'), '')),
	@flt_categorie = rtrim(isnull(@parXML.value('(/row/@f_categorie)[1]', 'varchar(20)'), ''))

if @parXML.value('(/row/@_cautare)[1]', 'varchar(25)') is not null
	set @flt_denumire=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(25)'),'')

set @flt_cod='%'+REPLACE(@flt_cod,' ','%')+'%'
set @flt_denumire= '%'+REPLACE(@flt_denumire,' ','%')+'%'
set @flt_expresie='%'+REPLACE(@flt_expresie,' ','%')+'%'
IF @flt_categorie<>''
	set @flt_categorie=REPLACE(@flt_categorie,' ','%')+'%'

select rtrim(Cod_Indicator) as cod, rtrim(Denumire_Indicator) as denumire , rtrim(expresia) as expresie,
	(case when Ordine_in_raport=1 then 'Da' else 'Nu' end ) as detalieredata,
	Ordine_in_raport as cudata,
	Total gaugeinvers,
	rtrim(i.Descriere_expresie) as descriere
from indicatori i
where
	Cod_Indicator like @flt_cod 
	and Denumire_indicator like @flt_denumire 
	and expresia like @flt_expresie and
	(@flt_categorie='' OR exists (select 1 from compcategorii c where c.Cod_Ind=i.Cod_Indicator and c.Cod_Categ like @flt_categorie) )
order by cod_indicator	
for xml raw
