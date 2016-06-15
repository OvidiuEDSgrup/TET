
CREATE procedure wacLot @sesiune varchar(50),@parXML XML
as
begin
	declare 
		@searchtext varchar(max), @cod varchar(20), @gestiune varchar(20)
	
	if object_id('tempdb..#nomencl') is not null drop table #nomencl
	
	select		--> filtrele pe cod si gestiune sunt pentru raportul Fisa stocuri
		@searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%',
		@cod = @parXML.value('(/*/@cCod)[1]','varchar(20)'),
		@gestiune = @parXML.value('(/*/@cGestiune)[1]','varchar(20)')
	
	select	--> pentru a se putea folosi si in alte machete am tratat si filtre standard de cod si gestiune
		@cod = isnull(@cod, @parXML.value('(/*/@cod)[1]','varchar(20)')),
		@gestiune = isnull(@gestiune, @parXML.value('(/*/@gestiune)[1]','varchar(20)'))
/*
--> filtrare in nomenclator:
	select rtrim(n.cod) cod, rtrim(n.denumire) denumire into #nomencl
	from nomencl n where n.Denumire like @searchtext
*/	
	declare @comanda varchar(max)
	select @comanda='SET QUOTED_IDENTIFIER OFF
	select top 100
		rtrim(lot) cod, rtrim(lot)+" - "+max(rtrim(n.denumire)) as denumire, "(Prod "+rtrim(s.cod)+")" as info
	from stocuri s left join nomencl n on n.cod=s.cod
	where (s.lot like "'+@searchText+'" or n.Denumire like "'+@searchtext+'")
	'
--> filtre suplimentare (sql dinamic tocmai pentru a nu folosi conditie cu "or" si "is null" la fiecare din aceste filtre, ar consuma mai multe resurse)
	if @cod is not null
		select @comanda=@comanda+'and s.cod="'+@cod+'"
		'
	if @gestiune is not null
		select @comanda=@comanda+'and s.cod_gestiune="'+@gestiune+'"
		'

	select @comanda=@comanda+'group by s.lot, s.cod
		'
	
	select @comanda=@comanda+'for xml raw'
	exec(@comanda)
	if object_id('tempdb..#nomencl') is not null drop table #nomencl
end
