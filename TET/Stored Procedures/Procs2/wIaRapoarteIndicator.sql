--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- aduce valorile existente calculate pt fiecare indicator */

CREATE procedure  wIaRapoarteIndicator  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(15), @searchtext varchar(30)

select 
	@cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')),
	@searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'


select Nume_raport as "numeraport", Path_raport "pathraport", Procedura_populare procpopulare
from rapIndicatori 
where Cod_indicator=@cod
and Nume_raport like @searchtext
for xml raw, root('Date')
		
