
CREATE PROCEDURE wScriuDetalii @parXML XML
AS
DECLARE @tabel VARCHAR(20), @detalii XML, @comanda NVARCHAR(max), @eroare VARCHAR(500), @subunitate VARCHAR(10)

SET @tabel = @parXML.value('(/*/@tabel)[1]', 'varchar(20)')
if @parXML.exist('(/*/detalii)[1]')=1
	SET @detalii = @parXML.query('(/*/detalii/row)[1]')

BEGIN TRY
	IF ISNULL(@tabel, '') = ''
		RETURN
	ELSE
		IF @tabel = 'pozdoc'
		BEGIN
			/** Daca exista coloana detalii*/
			IF EXISTS (
					SELECT 1
					FROM syscolumns sc, sysobjects so
					WHERE so.id = sc.id
						AND so.NAME = 'pozdoc'
						AND sc.NAME = 'detalii'
					)
			BEGIN
				DECLARE @tip VARCHAR(2), @data DATETIME, @numar VARCHAR(20), @numarpozitie INT

				SET @subunitate = @parXML.value('(/*/@subunitate)[1]', 'varchar(10)')
				SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
				SET @numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)')
				SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
				SET @numarpozitie = @parXML.value('(/*/@numarpozitie)[1]', 'int')
			
				SET @comanda = '
					UPDATE pozdoc
					SET detalii = @detalii
					WHERE Subunitate = @subunitate AND tip = @tip AND Numar = @numar AND data = @data AND Numar_pozitie = @numarpozitie'

				exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @subunitate VARCHAR(10), @tip VARCHAR(2), 
					@data DATETIME, @numar VARCHAR(20), @numarpozitie INT',
					@detalii = @detalii, @subunitate = @subunitate, @tip = @tip, @data = @data, @numar = @numar, @numarpozitie = @numarpozitie 
			
				RETURN
			END
		END

		IF @tabel = 'pozplin'
		BEGIN
			/** Daca exista coloana detalii*/
			IF EXISTS (
					SELECT 1
					FROM syscolumns sc, sysobjects so
					WHERE so.id = sc.id
						AND so.NAME = 'pozplin'
						AND sc.NAME = 'detalii'
					)
			BEGIN
				DECLARE @datap DATETIME, @contp VARCHAR(20), @numarpozitiep INT

				SET @subunitate = @parXML.value('(/*/@subunitate)[1]', 'varchar(10)')
				SET @contp = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
				SET @datap = @parXML.value('(/*/@data)[1]', 'datetime')
				SET @numarpozitiep = @parXML.value('(/*/@numarpozitie)[1]', 'int')
			
				SET @comanda = '
					UPDATE pozplin
					SET detalii = @detalii
					WHERE Subunitate = @subunitate AND Cont = @numar AND data = @data AND Numar_pozitie = @numarpozitie'

				exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @subunitate VARCHAR(10), @data DATETIME, @numar VARCHAR(20), @numarpozitie INT',
					@detalii = @detalii, @subunitate = @subunitate, @data = @datap, @numar = @contp, @numarpozitie = @numarpozitiep 
			
				RETURN
			END
		END

	IF @tabel = 'terti'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'terti'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @tert VARCHAR(20)

		SET @subunitate = isnull(@parXML.value('(/*/@subunitate)[1]', 'varchar(10)'),'1')
		SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
		SET @comanda = 'update terti SET detalii = @detalii
					WHERE tert = @tert and subunitate=@subunitate'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @tert VARCHAR(20), @subunitate varchar(10)',
			@detalii = @detalii, @tert = @tert, @subunitate = @subunitate
		RETURN
	END

	IF @tabel = 'conturi'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'conturi'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @cont VARCHAR(20)

		SET @subunitate = isnull(@parXML.value('(/*/@subunitate)[1]', 'varchar(10)'),'1')
		SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
		SET @comanda = 'update conturi SET detalii = @detalii
					WHERE cont = @cont and subunitate=@subunitate'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @cont VARCHAR(20), @subunitate varchar(10)',
			@detalii = @detalii, @cont = @cont, @subunitate = @subunitate
		RETURN
	END

	IF @tabel = 'nomencl'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'nomencl'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @codN VARCHAR(20)

		SET @codN = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
		SET @comanda = 'update nomencl SET detalii = @detalii
					WHERE cod = @codN'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @codN VARCHAR(20)',
			@detalii = @detalii, @codN = @codN
		RETURN
	END

	IF @tabel = 'gestiuni'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'gestiuni'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @codG VARCHAR(20)

		SET @codG = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
		SET @subunitate = isnull(@parXML.value('(/*/@subunitate)[1]', 'varchar(10)'),'1')
		
		SET @comanda = 'update gestiuni SET detalii = @detalii
					WHERE Cod_gestiune = @codG and subunitate=@subunitate'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @codG VARCHAR(20), @subunitate varchar(10)',
			@detalii = @detalii, @codG = @codG, @subunitate = @subunitate
		RETURN
	END

	IF @tabel = 'grupe'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'grupe'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @grupa VARCHAR(20)

		SET @grupa = @parXML.value('(/*/@grupa)[1]', 'varchar(20)')
		SET @comanda = 'update grupe SET detalii = @detalii
					WHERE grupa=@grupa'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @grupa VARCHAR(20)',
			@detalii = @detalii, @grupa = @grupa
		RETURN
	END

	IF @tabel = 'comenzi'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'comenzi'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @com VARCHAR(20)

		SET @subunitate = isnull(@parXML.value('(/*/@subunitate)[1]', 'varchar(10)'),'1')
		SET @com = @parXML.value('(/*/@comanda)[1]', 'varchar(20)')
		
		SET @comanda = 'update comenzi SET detalii = @detalii where comanda=@com and subunitate=@subunitate'
		
		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @com VARCHAR(20), @subunitate varchar(10)',
			@detalii = @detalii, @com = @com, @subunitate = @subunitate

		RETURN
	END

	IF @tabel = 'lm'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'lm'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @lm VARCHAR(20)

		SET @lm = @parXML.value('(/*/@lm)[1]', 'varchar(20)')
		
		SET @comanda = 'update lm SET detalii = @detalii where Cod=@lm'
		
		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @lm varchar(20)',
			@detalii = @detalii, @lm = @lm

		RETURN
	END

	IF @tabel = 'con'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'con'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @sbCon VARCHAR(10), @con VARCHAR(20), @tertCon VARCHAR(20), @tipCon VARCHAR(10), @dataCon DATETIME

		SET @sbCon = @parXML.value('(/*/@subunitate)[1]', 'varchar(10)')
		SET @con = @parXML.value('(/*/@contract)[1]', 'varchar(20)')
		SET @tertCon = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
		SET @tipCon = @parXML.value('(/*/@tip)[1]', 'varchar(10)')
		SET @dataCon = @parXML.value('(/*/@data)[1]', 'datetime')
		SET @comanda = 'update con SET detalii = @detalii 
				where subunitate=@sbCon and tip=@tipCon and contract=@con and data=@dataCon and tert=@tertCon'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @sbCon varchar(10), @tipCon varchar(10), @con VARCHAR(20), @dataCon datetime, @tertCon varchar(20)',
			@detalii = @detalii, @sbCon = @sbCon, @tipCon = @tipCon, @con = @con, @dataCon = @dataCon, @tertCon = @tertCon
		RETURN
	END

	IF @tabel = 'mfix'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'mfix'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @nrinv VARCHAR(20), @subDENS VARCHAR(9)

		SET @subDENS = 'DENS'--@parXML.value('(/*/@subunitate)[1]', 'varchar(9)')
		SET @nrinv = @parXML.value('(/*/@nrinv)[1]', 'varchar(20)')
		SET @comanda = 'update mfix SET detalii = @detalii where left(subunitate,4)<>@subDENS and numar_de_inventar=@nrinv'

		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @subDENS varchar(10), @nrinv varchar(20)',
			@detalii = @detalii, @subDENS = @subDENS, @nrinv = @nrinv
		RETURN
	END

	IF @tabel = 'uacon'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'uacon'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @id_contract int

		SET @id_contract = @parXML.value('(/*/@id_contract)[1]', 'int')
		SET @comanda = 'update uacon SET detalii = @detalii where id_contract=@id_contract'
		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @id_contract int',
			@detalii = @detalii, @id_contract = @id_contract
		RETURN
	END

	IF @tabel = 'functii'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'functii'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @codfunctie VARCHAR(20)

		SET @codfunctie = @parXML.value('(/*/@codfunctie)[1]', 'varchar(20)')
		
		SET @comanda = 'update functii SET detalii = @detalii where Cod_functie=@codfunctie'
		
		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @codfunctie varchar(20)',
			@detalii = @detalii, @codfunctie = @codfunctie
		RETURN
	END

END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE() + '(wScriuDetalii)'

	RAISERROR (@eroare, 11, 1)
END CATCH
