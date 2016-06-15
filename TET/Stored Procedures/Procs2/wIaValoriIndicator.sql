--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- aduce valorile existente calculate pt fiecare indicator */

CREATE procedure  wIaValoriIndicator  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(15), @searchtext varchar(30)

select 
	@cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')),
	@searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'
select convert(char(10),data,101) data, Element_1 as e1, Element_2 as e2, Element_3 as e3, Element_4 as e4 , Element_5 as e5,
 convert (varchar(20),convert(decimal(20,4),valoare ))  as val 
 --valoare 
 from expval
where data is not null and
Cod_indicator=@cod and
(
	Element_1 like @searchtext or
	Element_2 like @searchtext or
	Element_3 like @searchtext or
	Element_4 like @searchtext or
	Element_5 like @searchtext or
	data like @searchtext or
	Valoare like @searchtext 
)
order by data 
for xml raw

