--***
create procedure wACValuta @sesiune varchar(50), @parXML XML
as
 
declare @searchText varchar(100),@tip varchar(2)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')


--pentru tip VX= operatie de actualizare curs conform curs BNR, sa fie posibilitate de actualizare toate valutele
if @tip='VX'
	select rtrim(Valuta) as cod, rtrim(Denumire_valuta) as denumire, 
		'Curs: '+ltrim(CONVERT(char(20),convert(decimal(15,4),Curs_curent))) as info	
	from valuta
	where Denumire_valuta like '%'+@searchText+'%' or valuta like @searchText+'%'
	union all
	select case when @tip='VX' then '<Toate>' else null end as cod,case when @tip='VX' then '<Toate valutele>' else null end as denumire,
		null as info
	for xml raw
else	
	select rtrim(Valuta) as cod, rtrim(Denumire_valuta) as denumire, 
		'Curs: '+ltrim(CONVERT(char(20),convert(decimal(15,4),Curs_curent))) as info	
	from valuta
	where Denumire_valuta like '%'+@searchText+'%' or valuta like @searchText+'%'
	for xml raw
