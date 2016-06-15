
CREATE PROCEDURE wIaComenziLivrareTransport @sesiune VARCHAR(50), @parXML XML
AS

	declare
		@idContract int

	set @idContract=@parXML.value('(/*/@idContract)[1]','int')


	IF OBJECT_ID('tempdb..#filtrate') IS NOT NULL
		drop table #filtrate

	select 
		pLiv.idContract, pd.Numar, pd.data
	into #filtrate	
	from PozContracte pTran
	JOIN LegaturiContracte lc on pTran.idPozContract=lc.idPozContract and pTran.idContract=@idContract 
	JOIN PozContracte pLiv on pLiv.idPozContract=lc.idPozContractCorespondent
	LEFT JOIN LegaturiContracte lc2 on lc2.idPozContract=pLiv.idPozContract
	LEFT JOIN pozdoc pd on pd.idPozDoc=lc2.idPozDoc and pd.tip in ('AS','AP')

	select
		c.numar comanda, convert(varchar(10), c.data, 101) datacomanda, convert(varchar(10), f.data, 101) datafactura, rtrim(f.Numar) factura, rtrim(t.denumire) tertcomanda
	from #filtrate f
	JOIN Contracte c on c.idContract=f.idContract
	JOIN Terti t on t.tert=c.tert
	group by c.numar, convert(varchar(10), c.data, 101) , convert(varchar(10), f.data, 101), rtrim(f.Numar), rtrim(t.denumire) 
	for xml raw, root('Date')
