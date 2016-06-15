
CREATE PROCEDURE wOPGenConsumComandaProd_p @sesiune VARCHAR(50), @parXML XML
as
BEGIN TRY

	IF EXISTS (select 1 from sysobjects where name='wOPGenConsumComandaProd_pSP')
	begin
		exec wOPGenConsumComandaProd_pSP @sesiune=@sesiune, @parXML=@parXML
		return
	end

	declare 
		@comanda varchar(20),  @sub varchar(9), @idLansare int
		
	select 'Generare consum' explicatii for xml raw, root('Date')

	select 
		@comanda = @parXML.value('(/*/@comanda)[1]','varchar(20)'),
		@idLansare = @parXML.value('(/*/@idLansare)[1]','int')
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub OUTPUT

	IF OBJECT_ID('tempdb.dbo.#temp_cm') IS NOT NULL
		drop table #temp_cm

	select cod, sum(cantitate) cant_elib
	into #temp_cm
	from PozDoc where subunitate=@sub and tip='CM' and comanda=@comanda
	group by cod

	select top 1
		rtrim(c.gestiune) as gestiune, rtrim(g.Denumire_gestiune) as dengestiune
	from contracte c
		inner join gestiuni g on g.Cod_gestiune=c.gestiune
	where c.tip='CL' and c.numar=@comanda
	for xml raw

	select
	(
		select 
			rtrim(n.cod) cod, rtrim(n.denumire) dencod, convert(decimal(15,2), ISNULL(tc.cant_elib,0)) cant_elib,
			convert(decimal(15,2), ISNULL(pl.cantitate,0)) cant_lim, convert(decimal(15,2), ISNULL(pl.cantitate,0)- ISNULL(tc.cant_elib,0)) cant
		from PozLansari pl
		INNER JOIN nomencl n on n.cod=pl.cod and pl.tip='M' and pl.parinteTop=@idLansare 
		LEFT JOIN #temp_cm tc on pl.cod=tc.cod
		for xml raw, type
	)
	for xml path('DateGrid'),root('Mesaje')
	
end try
begin catch
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
