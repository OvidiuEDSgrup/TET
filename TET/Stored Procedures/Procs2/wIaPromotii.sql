
create procedure  wIaPromotii @sesiune varchar(30), @parXML XML
as

	declare
		@f_articol varchar(100), @f_denumire varchar(400), @f_status varchar(100)
	
	select
		@f_articol = '%' + NULLIF(REPLACE(@parXML.value('(/*/@f_articol)[1]','varchar(100)'),' ','%'),'') + '%',
		@f_denumire = '%' + NULLIF(REPLACE(@parXML.value('(/*/@f_denumire)[1]','varchar(100)'),' ','%'),'') + '%',
		@f_status = '%' + NULLIF(REPLACE(@parXML.value('(/*/@f_status)[1]','varchar(100)'),' ','%'),'') + '%'

	select
		p.denumire denumire, p.cod cod, rtrim(n.denumire) dencod, p.idPromotie idPromotie,
		convert(varchar(10), p.dela, 101) dela, convert(varchar(10), p.panala, 101) panala,
		convert(decimal(15,2), p.cantitate) cantitate, convert(decimal(15,2), p.cantitate_promo) cantitate_promo,
		(case when convert(datetime, GETDATE()) between p.dela and p.panala then '#008000' else '#808080' end ) culoare
	from Promotii p
	JOIN nomencl n on n.cod=p.cod
	where 
		(@f_articol IS NULL or n.cod like @f_articol or n.denumire like @f_articol) and
		(@f_denumire IS NULL or p.denumire like @f_denumire) and
		(@f_status IS NULL OR 
			('activa' like @f_status and convert(datetime,GETDATE()) between p.dela and p.panala) OR
			('expirata' like @f_status and convert(datetime,GETDATE()) not between p.dela and p.panala)
		)
	for xml raw, root('Date')
