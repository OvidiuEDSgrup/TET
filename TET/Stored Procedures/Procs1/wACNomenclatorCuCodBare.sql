
create procedure wACNomenclatorCuCodBare @sesiune varchar(50), @parXML xml
as

	declare @search varchar(100), @exact varchar(100)


	set @search='%'+isnull(replace(@parXML.value('(/*/@searchText)[1]','varchar(1000)'),' ','%'),'%')+'%'


	select 
		rtrim(n.cod) cod, RTRIM(n.denumire) denumire, 'Cod bare: '+rtrim(cb.cod_de_bare) as info
	from nomencl n join codbare cb on cb.Cod_produs=n.cod
	where n.cod like @search or n.denumire like @search
	for xml RAW, ROOT('Date')
