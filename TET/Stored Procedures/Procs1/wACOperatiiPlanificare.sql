create procedure [dbo].[wACOperatiiPlanificare] @sesiune varchar(50), @parXML XML  
as
	declare
		 @cod varchar(20), @searchText varchar(100),@data datetime
	
	set @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '')
	set @cod=ISNULL(ltrim(rtrim(@parXML.value('(/row/@cod)[1]', 'varchar(20)'))), '')
    set @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
	
	set @searchText= '%'+REPLACE(@searchtext,' ','%')+'%'
	
	select
		RTRIM(n.Denumire) as denumire , 
		'Comanda: '+ RTRIM(r.comanda) as info,r.id as cod
	from planificare r
	inner join pozTehnologii pt on pt.id=r.idOp
	inner join pozTehnologii ptt on ptt.id=pt.idp AND ptt.tip='L'
	inner join poztehnologii pttt on pttt.id=ptt.idp
	
	inner join tehnologii t on pttt.cod= t.cod
	
	inner join nomencl n on n.cod=pttt.cod
	inner join catop ct on ct.Cod=pt.cod
	left outer join pozRealizari pr on r.id=pr.idPlanificare and pr.CM is null
	where  r.resursa=@cod  and r.comanda like @searchText and 
	   convert(date,@data,101)  >= convert(date,r.dataStart,101)-- and convert(date,@data,101)  <= convert(date,r.dataStop,101)  
	  
	for xml raw, root('Date')
