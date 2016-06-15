create procedure wACCoduriResursa @sesiune varchar(50), @parXML XML  
as
	declare 
		@searchText varchar(50), @tip varchar(160)
	
	set @searchText='%'+replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ' ,'%')+'%'	
	set @tip =ISNULL(@parXML.value('(/row/@tipR)[1]', 'varchar(16)'),'')
	
	
	if @tip='A'
	begin
		select 
			RTRIM(marca) as cod, RTRIM(nume) as denumire, 'Loc munca '+RTRIM(loc_de_munca) as info 
		from personal 
		where marca like @searchText or nume like @searchText
		for xml raw, root('Date')
		return
	end
	else if @tip='U'
	begin
		select 
			RTRIM(cod_masina) as cod, RTRIM(denumire) as denumire, 'Tip utilaj'+RTRIM(tip_masina) as info 
		from masini 
		where cod_masina like @searchText or denumire like @searchText
		for xml raw, root('Date')
		return
	end	
	else if @tip='L'
	begin
		select 
			RTRIM(cod) as cod, RTRIM(denumire) as denumire
		from lm
		where cod like @searchText or denumire like @searchText
		for xml raw, root('Date')
	end
	else if @tip='E'
	begin
		select 
			RTRIM(tert) as cod, RTRIM(denumire) as denumire,'CF:'+RTRIM(cod_fiscal) as info
		from terti
		where tert like @searchText or denumire like @searchText
		for xml raw, root('Date')
	end
