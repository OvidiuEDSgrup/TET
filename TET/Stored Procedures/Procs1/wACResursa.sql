
--macheta de Tehnologii
create procedure wACResursa @sesiune varchar(50), @parXML XML  
as

declare @tip varchar(10), @searchText varchar(100)

set @tip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(10)'), '')
set @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '')

set @searchText= '%'+REPLACE(@searchtext,' ','%')+'%'

	if @tip='OP'
	begin
		exec wACOperatii @sesiune=@sesiune, @parXML=@parXML
		return
	end
	else 
		if @tip='MT'
			begin
				exec wACNomenclator @sesiune=@sesiune, @parXML=@parXML
				return
			end
		else 
			if @tip='RS'
			begin
				select top 100 RTRIM(cod) as cod, RTRIM(Denumire) AS  denumire,''as info from tehnologii where (denumire like @searchText or cod like @searchText) and Tip='R' for xml raw, root('Date')
			end
			else
				select top 100 RTRIM(cod) as cod, RTRIM(Denumire) AS  denumire,''as info from tehnologii where (denumire like @searchText or cod like @searchText) and Tip in ('R','P','S') for xml raw, root('Date')
				
