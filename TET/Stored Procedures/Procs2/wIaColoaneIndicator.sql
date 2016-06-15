--***
/* Procedura pentru configurare TB (categorii, indicatori ) - aduce configurari legate de coloanele unui indicator. */
CREATE procedure  wIaColoaneIndicator  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(15)

select @cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), ''))

select numar as nivel, rtrim(denumire) as denumire, Tip_grafic tipgrafic, procedura procedura, tip_filtru tipfiltru,
	(case Tip_grafic 
		when 0 then 'Linie' 
		when 1 then 'Placinta'
		when 2 then 'Coloane'
		when 3 then 'Ceas' 
		else Tip_grafic end) dengrafic, 
	(case numar
		when 0 then 'Data' 
		else 'Element_'+convert(varchar(10),numar) end) dencoloana,
		(case when isnull(tipSortare,0) =0 then 'Valoare' when tipSortare='1' then 'Data' else 'Text' end) as dentipsortare,
		ISNULL(tipSortare,0) as tipsortare
from colind where Cod_indicator=@cod
order by numar
for xml raw

