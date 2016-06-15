
CREATE PROCEDURE wScriuPozTehnologii @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE 
		--Date antet
		@codTehnologie VARCHAR(20), @denumireTehnologie VARCHAR(80), @tipTehnologie VARCHAR(1), @idTehnologie INT, @codNomencl 
		VARCHAR(20), 
		--Date pozitie
		@cod VARCHAR(20), @cantitate FLOAT, @pret FLOAT, @ordineOperatie FLOAT, @id INT, @tip VARCHAR(1), @cant_i FLOAT, @resursa VARCHAR(20), 
		--Altele
		@subtip VARCHAR(2), @update BIT, @eroare VARCHAR(200), @docXMLIaPozTehn xml,
		--Parinte (modificari/adaugari pozitii)
		@codLinie VARCHAR(20), @parinteTopLinie INT, @codTehnologieParinteTopLinie VARCHAR(20), @tipLinie VARCHAR(2), @idLinie INT, 
		@grupareLinie VARCHAR(20), @selectat BIT, @detalii XML, @mesaj varchar(500), @detaliiAntet xml

	IF EXISTS (SELECT 1	FROM sysobjects	WHERE [type] = 'P'AND [name] = 'wScriuPozTehnologiiSP')
		EXEC wScriuPozTehnologiiSP @sesiune = @sesiune, @parXML = @parXML OUTPUT

	--Antet
	SET @codTehnologie = ISNULL(@parXML.value('(/row/@cod_tehn)[1]', 'varchar(20)'), '')
	SET @denumireTehnologie = ISNULL(@parXML.value('(/row/@denumire)[1]', 'varchar(80)'), '')
	SET @tipTehnologie = ISNULL(@parXML.value('(/row/@tip_tehn)[1]', 'varchar(1)'), 'P')
	SET @idTehnologie = ISNULL(@parXML.value('(/row/@id)[1]', 'int'), 0)
	SET @codNomencl = @parXML.value('(/row/@codNomencl)[1]', 'varchar(20)')
	IF @codNomencl=''
		set @codNomencl=NULL
	if @parXML.exist('(/row/row/detalii)[1]')=1
		SET @detalii = @parXML.query('(/row/row/detalii/row)[1]')
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detaliiAntet = @parXML.query('(/*/detalii/row)[1]')
	--Pozitie
	SET @cod = ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), '')
	SET @cantitate = ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0)
	SET @resursa = @parXML.value('(/row/row/@resursa)[1]', 'varchar(20)')
	SET @pret = ISNULL(@parXML.value('(/row/row/@pret)[1]', 'float'), 0)
	SET @cant_i = ISNULL(@parXML.value('(/row/row/@cant_i)[1]', 'float'), 0)
	SET @ordineOperatie = ISNULL(@parXML.value('(/row/row/@ordine)[1]', 'float'), 0)
	--Linie
	SET @codLinie = ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'), '')
	SET @id = ISNULL(@parXML.value('(/row/linie/@idReal)[1]', 'int'), 0)
	SET @parinteTopLinie = ISNULL(@parXML.value('(/row/linie/@parinteTop)[1]', 'int'), 0)
	SET @tipLinie = ISNULL(@parXML.value('(/row/linie/@tip)[1]', 'varchar(2)'), '')
	SET @idLinie = ISNULL(@parXML.value('(/row/linie/@id)[1]', 'int'), 0)
	SET @grupareLinie = ISNULL(@parXML.value('(/row/linie/@_grupare)[1]', 'varchar(20)'), '')
	SET @selectat = @parXML.exist('/row/linie')


	IF @selectat <> '1' 
	BEGIN
		IF @idTehnologie <> 0 and EXISTS (select 1 from pozTehnologii where parinteTop=@idTehnologie)
			RAISERROR ('Selectati un parinte din grid pentru a adauga o componenta tehnologiei!', 11, 1)
		ELSE
			select
				@parinteTopLinie = @idTehnologie, @idLinie=@idTehnologie

	END

	SELECT 
		@codTehnologieParinteTopLinie = cod
	FROM pozTehnologii
	WHERE id = @parinteTopLinie
	
	IF NOT EXISTS(select 1 from tehnologii where codNomencl=@codNomencl) and ISNULL(@codTehnologie,'')=''
		select @codTehnologie=@codNomencl

	--Altele
	SET @update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)
	SET @subtip = ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '')

	--Determinare tip pozitie
	IF OBJECT_ID('tempdb..#tp') IS NOT NULL
		drop table #tp
	create table #tp(subtip varchar(20), tip_poztehnologii varchar(2))
	insert into #tp(subtip, tip_poztehnologii)
	select 'MT','M' UNION
	select 'SA','M' UNION
	select 'OP','O' UNION
	select 'RS','R' 

	select top 1 @tip=tip_poztehnologii from #tp where subtip=@subtip

	IF @denumireTehnologie = ''
		SELECT 
			@denumireTehnologie = denumire
		FROM nomencl
		WHERE cod = @codNomencl

	IF @update = 0
		--Adaugare date (nu modificare)
	BEGIN
		if (@cod=@codTehnologie)
			RAISERROR ('Nu se poate adauga codul de tehnologie ca si fiu!', 11, 1)

		IF @idTehnologie = 0
			--Adaugare tehnologie
		BEGIN
			--Validari date introduse in antet
			IF (SELECT count(*)FROM tehnologii WHERE cod = @codTehnologie) > 0
				RAISERROR ('Codul introdus este asociat deja unei tehnologii!', 11, 1)

			IF @codTehnologie = ''OR @tipTehnologie = ''OR @denumireTehnologie = ''OR (@codNomencl = '' AND @tipTehnologie NOT IN  ('S','R','F'))
				RAISERROR ('Nu sunt permise campuri cu valori necompletate in antet!', 11, 1)

			--Validate date introduse in pozitie
			IF @cod = ''OR (@pret < 0 AND @subtip <> 'RS')OR (@ordineOperatie <= 0 AND @subtip = 'OP')
				RAISERROR (	'Nu sunt permise: valori negative pentru Pret si OrdineOperatie, cod necompletat', 11, 1)

			--Insert
			INSERT INTO tehnologii (cod, Denumire, tip, Data_operarii, detalii, codNomencl)
			VALUES (@codTehnologie, @denumireTehnologie, @tipTehnologie, GETDATE(), @detaliiAntet, @codNomencl)

			CREATE TABLE #id (id INT)

			INSERT INTO pozTehnologii (tip, cod, cantitate, pret)
			OUTPUT inserted.id
			INTO #id
			VALUES ('T', @codTehnologie, 0, 0)

			--Obtinem id-ul tehnologiei tocmai introduse pentru a putea salva pozitia
			SELECT @idTehnologie = id
			FROM #id

			IF @tipTehnologie='F'
				set @cantitate=1
			INSERT INTO pozTehnologii (tip, cod, cantitate, pret, idp, cantitate_i, ordine_o, parinteTop, resursa, detalii)
			VALUES (@tip, @cod, @cantitate, @pret, @idTehnologie, @cant_i, @ordineOperatie, @idTehnologie, @resursa, @detalii)
		END
		ELSE
			--Adaugare pozitie in tehnologie existenta
		BEGIN
			IF @cod = ''OR (@pret < 0 AND @subtip <> 'RS')OR (@ordineOperatie <= 0 AND @subtip = 'OP')
				RAISERROR ('Nu sunt permise: valori negative pentru Pret si OrdineOperatie, cod necompletat', 11, 1)

			BEGIN
				IF EXISTS (SELECT 1 FROM poztehnologii WHERE tip = @tip	AND idp = @idTehnologie AND cod = @cod and (@tip<>'O' or ISNULL(@ordineOperatie,0)=ISNULL(ordine_o,0)))
				BEGIN
					SET @eroare = 'Elementul: ' + isnull(@cod,'.') + ' exista deja pe nivelul selectat al tehnologie'
					--RAISERROR (@eroare, 11, 1)
				END

				IF (@parinteTopLinie <> @idTehnologie AND @grupareLinie NOT IN ('Produs','Serviciu','Interventie','Reper','Faza'))
				BEGIN					
					SET @eroare = 'Pentru a adauga elementul: ' + isnull(@cod,'.') + ' mergeti pe tehnologia: ' + rtrim(isnull(@codTehnologieParinteTopLinie,'.')) + ' !'
					RAISERROR (@eroare, 11, 1)
				END

				IF @tipLinie NOT IN ('M', 'Z')
					INSERT INTO pozTehnologii (tip, cod, cantitate, pret, idp, cantitate_i, ordine_o, parinteTop, resursa, detalii)
					VALUES (@tip, @cod, @cantitate, @pret, @idLinie, @cant_i, @ordineOperatie, @idTehnologie, @resursa, @detalii)
				ELSE
				BEGIN
					SET @eroare = 'Elementului ' + isnull(@codLinie,'.') + ' nu i se pot adauga elemente in structura! Daca este Semifabricat editati tehnologia acestuia!'
					RAISERROR (@eroare, 11, 1)
				END
			END
		END
	END --Gata adaugari
	ELSE
	BEGIN
		IF @idTehnologie = @parinteTopLinie
			UPDATE pozTehnologii
				SET cantitate = @cantitate,detalii = @detalii, pret = @pret,cantitate_i = @cant_i, ordine_o = @ordineOperatie, resursa = @resursa, cod=@cod
			WHERE id = @id			
		ELSE
		BEGIN
			SET @eroare = 'Pentru a modifica ' + isnull(@codLinie,'.') + ' mergeti pe tehnologia ' +isnull(@codTehnologieParinteTopLinie,'.')
			RAISERROR (@eroare, 11, 1)
		END
	END

	SET @docXMLIaPozTehn = (select @codTehnologie as cod_tehn for XML raw)

	/* Inainte de a apela luarea, vom completa o tabela temporara cu nodurile ce vor veni expandate*/
	declare 
		@idp int,@nivel int,@utilizator varchar(200)
	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator OUTPUT

	delete from NoduriExpandateTehnologii where ut=@utilizator

	set @idp=@idLinie
	set @nivel=0
	
	while @idp>0 and @idp is not null and @nivel<50
	begin 
		insert into NoduriExpandateTehnologii(ut,id) values (@utilizator,@idp)
		select @idp=idp from pozTehnologii where id=@idp
		set @nivel=@nivel+1
	end
	if @nivel>=50
		raiserror('Nivel maxim depasit (50)!',16,1)
	/* Gata scrierea in tabela temporara*/
	EXEC wIaPozTehnologii @sesiune = @sesiune, @parXML = @docXMLIaPozTehn

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuPozTehnologii)'
	raiserror(@mesaj, 11, 1)
end catch
