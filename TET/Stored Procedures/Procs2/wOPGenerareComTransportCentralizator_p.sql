
CREATE PROCEDURE wOPGenerareComTransportCentralizator_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@utilizator varchar(100), @grupare varchar(20)

	select
		@grupare = ISNULL(@parXML.value('(/*/@grupare)[1]','varchar(100)'),'')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF @grupare not like @utilizator +'%'
		RAISERROR('Alegeti un transport virtual din cele existente in dreptul utilizatorului curent',16,1)

	select 
	(
		select
			c.numar comanda, f.idContract idComanda, CONVERT(varchar(10),c.data,101) data, c.tert tert, RTRIM(t.denumire) dentert,
			f.cod, RTRIM(n.denumire) dencod,f.idPozContract idPozContract,
			CONVERT(decimal(15,2),f.cantitate_comanda) cantitate_comanda,
			CONVERT(decimal(15,2),f.cantitate) cantitate_sugerata,
			f.gestiune gestiune, 
			pc.pret pret, 
			'1' as selectat, 
			f.idlinie idlinie,
			CONVERT(decimal(15,2), f.cantitate - f.cantitate_transport) as cantitate_transport,
			CONVERT(decimal(15,2), pc.cantitate - ISNULL(pcc.cantitate, 0)) as cantitate_maxima
		from tmpArticoleCentralizatorTransport f
		JOIN PozContracte pc ON pc.idpozcontract=f.idpozcontract
		JOIN Contracte c on c.idContract=f.idContract
		OUTER APPLY (
			SELECT SUM(ISNULL(p.cantitate, 0)) AS cantitate FROM PozContracte p
			LEFT JOIN LegaturiContracte lc on lc.idPozContract = p.idPozContract
			WHERE pc.idPozContract = lc.idPozContractCorespondent
		) AS pcc
		JOIN terti t ON c.tert=t.tert	
		JOIN nomencl n on f.cod=n.cod	
		where f.grupare=@grupare 
		order by c.numar
		for XML RAW,TYPE
	)
	FOR XML path('DateGrid'), root('Mesaje')

END TRY
BEGIN CATCH
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
