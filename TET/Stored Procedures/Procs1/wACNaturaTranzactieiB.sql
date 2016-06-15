--***

create procedure wACNaturaTranzactieiB @sesiune varchar(50), @parXML XML
as
begin
	declare @searchText varchar(80), @nattranza varchar(10), @parXMLNatTranz xml
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	set @nattranza=ISNULL(@parXML.value('(/row/detalii/row/@nattranza)[1]', 'varchar(10)'), '')

	set @parXMLNatTranz=(select 'B' as tip, @nattranza as nattranza for xml raw)

	select cod, denumire 
	from fNaturaTranzactiiIntrastat(@parXMLNatTranz)
	where cod like '%'+@searchText+'%'
	order by 1
	for xml raw
end
