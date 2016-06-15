CREATE procedure wOPGenerareComandaAprovizionareCentralizator @sesiune varchar(50), @parXML xml
as
BEGIN TRY
	declare 
		@mesaj VARCHAR(500), @tert varchar(20), @data datetime, @lm varchar(20), @gestiune varchar(20), @explicatii varchar(500), @curs float, @valuta varchar(20),
		@numar varchar(20), @idContract int,@docComanda xml, @detalii XML, @utilizator varchar(300), @formular varchar(100)

	/** Antet **/
	SELECT
		@tert=NULLIF(@parXML.value('(/*/@cod_furnizor)[1]','varchar(20)'),''),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@valuta=@parXML.value('(/*/@valuta)[1]','varchar(20)'),
		@curs=@parXML.value('(/*/@curs)[1]','float'),	
		@gestiune=NULLIF(@parXML.value('(/*/@gestiune)[1]','varchar(20)'),''),
		@lm=@parXML.value('(/*/@lm)[1]','varchar(20)'),
		@explicatii=@parXML.value('(/*/@explicatii)[1]','varchar(500)'),
		@formular=@parXML.value('(/*/@formular)[1]','varchar(100)')
	
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF @tert is null
		raiserror ('Alegeti furnizorul pentru comanda de aprovizionare!',16,1)
	IF @gestiune is null
		raiserror ('Alegeti gestiunea pentru comanda de aprovizionare!',16,1)
	/**Pozitii **/
	SELECT	
		A.cod.value('(@idPozLansare)[1]', 'int') idPozLansare, 
		A.cod.value('(@idPozContractCoresp)[1]', 'int') idPozContractCoresp, 
		A.cod.value('(@cod)[1]', 'varchar(20)') cod, 
		A.cod.value('(@cantitate)[1]', 'float') cantitate, 
		A.cod.value('(@pret)[1]', 'float') pret,
		A.cod.value('@cod_specific','varchar(20)') cod_specific,
		A.cod.value('@termen','datetime') termen
	INTO #pozitiiAprovizionare
	FROM @parXML.nodes('parametri/DateGrid/row') A(cod)
	where A.cod.value('(@cantitate)[1]', 'float')  >0.0

	/** Incercam scrierea doar daca sunt pozitii cu cantitati valide  ( > 0.0 ) **/
	IF EXISTS (select 1 from #pozitiiAprovizionare)
	BEGIN
		set @docComanda=
		(
			select 
					@tert tert, @data data, 'CA' as tip, @gestiune gestiune, @lm lm, @curs curs, @valuta valuta,
					ISNULL(@explicatii,'Comanda generata din centralizator') explicatii, @detalii detalii,
					(
						select
							idPozLansare idPozLansare, cod cod, convert(decimal(15,2),cantitate) cantitate, convert(decimal(15,2),pret) pret,
							cod_specific codspecific, idPozContractCoresp, termen
						FROM #pozitiiAprovizionare
						for xml raw, type
					) 

			for xml raw, type
		)
		/** Scriu date BULK */
		exec wScriuPozContracte @sesiune=@sesiune, @parXML=@docComanda OUTPUT

		select top 1 
			@idContract= @docComanda.value('(/*/@idContract)[1]','int')

		IF isnull(@formular,'')!=''
		begin
			declare @xmlFormular xml
			set @xmlFormular= 
				(select 
					@formular as nrform, 'Comanda aprovizionare '+@sesiune as numefisier, @idContract idContract
				for XML RAW)

			EXEC wTipFormular @sesiune = @sesiune, @parXML = @xmlFormular
		end

		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

		/* Actualizam pentru a nu recalcula tot doar pentru ce s-a realizat comanda*/
		update t
			set cant_aprovizionare=isnull(cant_aprovizionare,0)+p.cantitate, decomandat=decomandat-p.cantitate
		from tmpArticoleCentralizator t
		INNER JOIN 
			(select cod, sum(ISNULL(cantitate,0)) cantitate from #pozitiiAprovizionare group by cod
			)p on t.cod=p.cod 
		where t.utilizator=@utilizator

		update t
			set cant_aprovizionare =  ISNULL(cant_aprovizionare,0)+ISNULL(p.cantitate,0)
		from tmpPozArticoleCentralizator t
		INNER JOIN #pozitiiAprovizionare p on t.cod=p.cod  and t.idPozLansare=p.idPozLansare
		where t.utilizator=@utilizator

	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareComandaAprovizionareCentralizator)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
