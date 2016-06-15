

CREATE PROCEDURE wIaComenziTransportComanda @sesiune VARCHAR(50), @parXML XML
AS

/**
	Procedura este aferenta tabului de transport din comenzi de livrare si arata transporturile cu detaliere pe cod din CL respectiv

**/
	declare 
		@id_cl int, @f_transportator varchar(200), @f_articol varchar(200)

	set @id_cl=@parXML.value('(/*/@idContract)[1]','int')
	set @f_articol='%'+ISNULL(@parXML.value('(/*/@f_articol)[1]','varchar(20)'),'%')+'%'
	set @f_transportator='%'+ISNULL(@parXML.value('(/*/@f_transportator)[1]','varchar(20)'),'%')+'%'

	select idPozContract 
	into #pozCL
	from PozContracte where idContract=@id_cl
	
	select 
		c.numar as transport, CONVERT(varchar(10), c.data,103) data, rtrim(t.denumire) dentransportator, rtrim(t.tert) transportator,
		rtrim(n.cod) cod, RTRIM(n.denumire) dencod,convert(decimal(15,2), pc.cantitate) cantitate
	from LegaturiContracte lc
	JOIN PozContracte pc ON lc.idPozContract=pc.idPozContract
	JOIN #pozCL pcl on pcl.idPozContract=lc.idPozContractCorespondent
	JOIN nomencl n on n.cod=pc.cod
	JOIN Contracte c on c.idContract=pc.idContract
	LEFT JOIN terti t on t.tert=c.tert
	where (ISNULL(t.tert,'') LIKE @f_transportator OR ISNULL(t.Denumire,'') LIKE @f_transportator) and (n.cod like @f_articol or n.Denumire like @f_articol)
	for xml raw, root('Date')
