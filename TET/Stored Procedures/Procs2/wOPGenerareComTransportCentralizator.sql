
CREATE PROCEDURE wOPGenerareComTransportCentralizator @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare 
		@transport int, @contr xml,  @docJurnal xml , @mesaj varchar(max), @stareCT varchar(10), @nrPozCantitateNepermisa int

	set @transport=@parXML.value('(/*/@comanda_transport)[1]','int')

	if isnull(@transport, 0)<>0
	begin
	/* Transport existent, scriu comanda in dreptul lui*/
		
		set @stareCT = (select top 1 stare from JurnalContracte where idContract = @transport order by data desc, idJurnal desc)

		if OBject_id('tempdb..#pct') IS NOT NULL
			drop TABLE #pct

		select
			D.cod.value('@cod','varchar(20)') cod,
			D.cod.value('@cantitate_transport','float') cantitate,
			D.cod.value('@idPozContract','int') idPozContractCoresp,
			D.cod.value('@idComanda','int') idComanda,
			D.cod.value('@idlinie','int') idlinie,
			D.cod.value('@gestiune','varchar(20)') gestiune,
			D.cod.value('@pret','float') pret,
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
					@transport idContract, 'CT' tip,gestiune, punct_livrare,loc_de_munca lm,data,tert,numar, @stareCT as stare,
					(
						select
							@transport idContract, cod, cantitate, idPozContractCoresp,(select gestiune gestiune for xml RAW,type) detalii,
							pret as pret
						from #pct
						for XML raw, type
					)
				from Contracte where idContract=@transport
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
	end

	else
	begin
		/** Deschid macheta completare date transport - retin pozitiile care le voi trimite in noul CT*/
	
		SELECT 'Detalii transport' nume, 'DT' codmeniu, 'O' tipmacheta,
				 (select dbo.fInlocuireDenumireElementXML(@parXML,'row')) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	end
END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesaj, 16, 1)
END CATCH
