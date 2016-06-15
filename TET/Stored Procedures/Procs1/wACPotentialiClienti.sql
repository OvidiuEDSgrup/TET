CREATE procedure wACPotentialiClienti @sesiune varchar(50), @parXML xml  
as 

	declare @searchText varchar(200)

	set @searchText='%'+ISNULL(REPLACE(@parXML.value('(/*/@searchText)[1]','varchar(200)'),' ','%'),'%')+'%'
	select
		idPotential cod, rtrim(denumire) denumire, 'CUI: '+cod_fiscal info
	from Potentiali
	where denumire like @searchText
	for xml raw, root('Date')
