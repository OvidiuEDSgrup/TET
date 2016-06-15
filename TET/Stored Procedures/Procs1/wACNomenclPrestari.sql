--***

create procedure wACNomenclPrestari @sesiune varchar(50), @parXML XML
as
begin
	declare @searchText varchar(80),@tip varchar(2), @numar varchar(20), @data datetime, @Sb varchar(9)
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@Numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@Data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output

	select top 100 rtrim(p.cod) as cod, rtrim(n.Denumire) as denumire
	from pozdoc p
		inner join nomencl n on p.subunitate=@Sb and p.tip='RM' and p.numar=@numar and p.data=@data and p.cod=n.Cod
	where (n.denumire like '%'+@searchText+'%' or n.cod like @searchText+'%')	
	order by 1
	for xml raw
end
