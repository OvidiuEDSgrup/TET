
CREATE PROCEDURE wOPTransportNou @sesiune VARCHAR(50), @parXML XML
AS
begin try
/**

	Procedura creaza o comanda noua de tip transport cu pozitiile din CL, si in dreptul comenzilor de livrare se jurnalizeaza faptul ca s-a alocat
	(ceva) transport

*/
	declare
		@tert varchar(20), @data datetime, @lm varchar(20), @explicatii varchar(100), @contr xml, @detalii xml, @docJurnal xml , @mesaj varchar(max),
		@nrPozCantitateNepermisa int

	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @data=@parXML.value('(/*/@data)[1]','datetime')
	set @lm=@parXML.value('(/*/@lm)[1]','varchar(20)')
	set @explicatii=@parXML.value('(/*/@explicatii)[1]','varchar(100)')
	SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	if OBject_id('tempdb..#pct') IS NOT NULL
		drop TABLE #pct


	select
		D.cod.value('@cod','varchar(20)') cod,
		D.cod.value('@cantitate_transport','float') cantitate,
		D.cod.value('@idPozContract','int') idPozContractCoresp,
		D.cod.value('@idComanda','int') idComanda,
		D.cod.value('@gestiune','varchar(20)') gestiune,
		D.cod.value('@pret','float') pret,
		D.cod.value('@idlinie','int') idlinie,
		D.cod.value('@cantitate_maxima', 'float') cantitate_maxima --> cantitate maxima permisa pentru generare
	into #pct
	FROM @parXML.nodes('*/DateGrid/row') D(cod)
	where ISNULL(D.cod.value('@cantitate_transport','float') ,0)>0.0
		AND ISNULL(D.cod.value('@selectat', 'bit'), 0) = 1
	
	set @nrPozCantitateNepermisa = (select count(*) from #pct where cantitate > cantitate_maxima)
	if @nrPozCantitateNepermisa > 0
	begin
		select @mesaj = 'Cantitatea selectata pentru ' + (case when @nrPozCantitateNepermisa = 1 then 'codul: ' else 'codurile: ' end)
			+ STUFF((select distinct rtrim(cod) + ', ' from #pct where cantitate > cantitate_maxima for xml path(''),
				type).value('.', 'varchar(max)'), 1, 0, '')
			+ 'ar depasi cantitatea maxima permisa!'

		raiserror(@mesaj, 16, 1)
	end

	set @contr=
		(
			select
				'CT' tip, @tert tert, @data data, @lm lm, @explicatii explicatii, @detalii detalii,
				(
					select
						cod, cantitate, idPozContractCoresp, pret, (select gestiune gestiune for xml raw, type) detalii
					from #pct
					for XML raw, type
				)
			for XML RAW
		)

	exec wScriuPozContracte @sesiune=@sesiune, @parXML=@contr

	set @docJurnal=
	(
		select 
			distinct idComanda idContract,GETDATE() data, 'Alocare transport' explicatii
		from #pct
		for XML raw, root('Date')
	)

	exec wScriuJurnalContracte @sesiune=@sesiune, @parXML=@docJurnal

	delete t
	from tmpArticoleCentralizatorTransport t	
	JOIN #pct p on p.idlinie=t.idlinie
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ '(wOPTransportNou)'
	raiserror(@mesaj, 16,1)
end catch
