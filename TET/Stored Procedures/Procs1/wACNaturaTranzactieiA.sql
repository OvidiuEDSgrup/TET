--***

create procedure wACNaturaTranzactieiA @sesiune varchar(50), @parXML XML
as
begin
	declare @searchText varchar(80),@tip varchar(2), @numar varchar(8), @data datetime, @Sb varchar(9), @parXMLNatTranz xml
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@Numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
		@Data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')

	set @parXMLNatTranz=(select 'A' as tip for xml raw)
	
	select cod, denumire
	from fNaturaTranzactiiIntrastat(@parXMLNatTranz)
	order by 1
	for xml raw
end
