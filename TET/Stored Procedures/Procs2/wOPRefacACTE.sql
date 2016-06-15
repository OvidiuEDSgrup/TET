-- reface bonurile in in tabela pozdoc, din tabela bp.
CREATE PROCEDURE wOPRefacACTE @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @datajos DATETIME, @datasus DATETIME, @Subunitate VARCHAR(1), @Tip VARCHAR(2),
	@Gestiune VARCHAR(10), @Cantitate FLOAT, @Pret_valuta FLOAT, @Pret_de_stoc FLOAT, @dataDoc datetime,
	@utilizator VARCHAR(50), @stergere BIT, @generare BIT, @userASiS VARCHAR(50), @msgEroare VARCHAR(max), 
	@vanzator VARCHAR(20), @DetBon INT, @NrDoc VARCHAR(20), @NuTEAC INT, @idAntetBon int, @tipDoc varchar(2),
	@debug bit, @sub varchar(20)

DECLARE @documente TABLE(idAntetBon int, tipDoc VARCHAR(2), numarDoc varchar(50), dataDoc datetime)

BEGIN TRY

select	@DetBon=(case when parametru='DETBON' then Val_logica else isnull(@DetBon,0) end),
		@NuTEAC=(case when parametru='NUTEAC' then Val_logica else isnull(@NuTEAC,0) end),
		@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end)
from par 
where (Tip_parametru='PO' and Parametru in ('DETBON','NUTEAC')) or (Tip_parametru='GE' and Parametru='SUBPRO')


select	@idAntetBon = isnull(@parXML.value('(/*/@idantetbon)[1]', 'int'), 0),
		@datajos = @parXML.value('(/*/@datajos)[1]', 'datetime'),
		@datasus = @parXML.value('(/*/@datasus)[1]', 'datetime'),
		@gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(10)'), ''),
		@vanzator = isnull(@parXML.value('(/*/@vanzator)[1]', 'varchar(10)'), ''),
		@stergere = isnull(@parXML.value('(/*/@stergere)[1]', 'bit'), 0),
		@generare = isnull(@parXML.value('(/*/@generare)[1]', 'bit'), 0),
		@debug = isnull(@parXML.value('(/*/@debug)[1]', 'bit'), 0)

-- cerem sa completeze explicit intreaga istorie daca doresc; pentru eliminarea erorilor accidentale.
if @idAntetBon=0 and (@datajos is null or @datasus is null)
	raiserror('Data inferioara sau superioara nu e completata',11,1)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

if @idAntetBon > 0 -- daca se trimite idAntetBon, operatia e apelata pentru un singur document. Citesc gestiunea documentului.
BEGIN	
	IF NOT EXISTS (SELECT * FROM bonuri WHERE idAntetBon=@idAntetBon)
		RAISERROR('Acest document nu are pozitii! Refacerea nu ar avea niciun efect. Daca incercati refacerea unei facturi din bon, rulati operatia pentru fiecare bon in parte.', 11, 1)
	
	select 
		@Gestiune=a.Gestiune, @datajos=a.data_bon, @datasus=a.data_bon
	from antetBonuri a where a.IdAntetBon=@idAntetBon
end

-- validare completare gestiune
IF @Gestiune = ''
	RAISERROR ('Aceasta operatie se ruleaza pe o gestiune. Alegeti gestiunea dorita.', 11, 1)

/* nu permitem rularea pe o gestiune pe care nu are drepturi utilizatorul - oricum ar da eroare triggerele de validare. */
IF EXISTS (
		SELECT 1
		FROM proprietati
		WHERE Tip = 'UTILIZATOR'
			AND cod_proprietate IN ('GESTIUNE')
			AND cod = @userASiS
			AND Valoare <> ''
		)
	AND @Gestiune NOT IN (
		SELECT valoare
		FROM proprietati
		WHERE Tip = 'UTILIZATOR'
			AND cod_proprietate IN ('GESTIUNE')
			AND cod = @userASiS
		)
BEGIN
	SET @msgEroare = 'Nu aveti dreptul de a rula operatia pe aceasta gestiune (' + @Gestiune + ').'

	RAISERROR (@msgeroare, 11, 1)
END

IF @stergere = 0
	AND @generare = 1
BEGIN
	SET @msgEroare = 'Nu se poate rula generarea documentelor, daca nu bifati si stergerea documentelor existente.'

	RAISERROR (@msgEroare, 11, 1)
END

/*
	Stergerea se ocupa de identificarea documentelor generate de PVria in pozdoc, si apoi stergerea lor efectiva.
	Identificarea documentelor se face pornind de la tabela antetBonuri de unde se identifca numarul si data 
	fiecarui document afectat de refacere.
*/
IF @stergere = 1
BEGIN
	/* nu permitem stergerea unui singur bon, daca acestea se cumuleaza pe un singur AC/gestiune in pozdoc. */
	IF @idAntetBon > 0 and @tipDoc='AC' AND @DetBon = 0
		RAISERROR ('Bonul nu poate fi sters indivitual deoarece se foloseste setarea prin care bonurile se cumuleaza in tabela pozdoc!', 16, 1)
	
	/* salvam in aceasta tabela toate documentele din pozdoc afectate de refacere. */
	INSERT INTO @documente(idAntetBon, tipDoc, numarDoc, dataDoc)
	SELECT 
		/* identificatorul de document */
		idAntetBon,
		/* identificarea tipului de document. In caz ca nu exista in XML, se identifica prin a.Chitanta */
		ISNULL(a.Bon.value('(/date/document/@tipdoc)[1]','varchar(2)'), (case when a.Chitanta=1 then 'AC' else 'AP' end)),
		/* @numar_in_pozdoc se insereaza la descarcare inca dinaintea posibilitatii de generare TE(real) din PVria. 
			Deci daca nu exista, vorbim de bonuri si facturi. Pe viitor se poate sterge case-ul de mai jos. */
		ISNULL(a.Bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'), 
			(case when a.chitanta=0 then LTrim(a.Factura) 
				when @DetBon=1 then RTrim(CONVERT(varchar(4),a.Casa_de_marcat))+right(replace(str(a.Numar_bon),' ','0'),4) 
				else 'B'+LTrim(str(day(a.Data_bon)))+'G'+rtrim(a.Gestiune) end)) numar_document,
		a.Data_bon
	from
	antetBonuri a 
	WHERE 
		@idAntetBon>0 AND a.idAntetBon=@idAntetBon -- un document
		OR 
		@idAntetBon=0 -- mai multe documente
			AND a.Gestiune = @gestiune -- ne legam de gestiunea din antet tot timpul; in pozitii poate fi diferita...
			AND a.Data_bon BETWEEN @datajos AND @datasus
	
	IF @debug=1
		SELECT 'documente' tabela,* FROM @documente
	/* 
		Stergerea are 2 pasi: stergem documentul principal (AC,AP,TE(din PV, nu automat), iar apoi stergerea TE-urilor automate.
		Nu stergem in aceeasi comanda si TE-ul generat automat, pt. ca sa nu dea eroare triggerele de validare.
		
		Nu ne legam de gestiuni in acest select, deoarece gestiunile difera pentru facturi 
			sau pentru bonuri in care s-au facturat comenzi de pe alte gestiuni.
	*/		
	IF @debug=1
		SELECT 'pozdoc_de_sters' tabela, p.*
			from pozdoc p
			INNER JOIN @documente d ON d.tipDoc=p.Tip and d.numarDoc=p.Numar AND d.dataDoc=p.Data
			where p.subunitate=@sub 
	
	delete p
		from pozdoc p
		INNER JOIN @documente d ON d.tipDoc=p.Tip and d.numarDoc=p.Numar AND d.dataDoc=p.Data
		where p.subunitate=@sub 
		-- Pe viitor, cand vom avea tot timpul detalii XML in pozdoc, mai putem adauga o clauza cu validarea sursei...
		-- and pozdoc.detalii.exist('/row[@sursa="PV"]')=1
	
	-- stergem si antetul facturilor si transferurilor(reale) generate din PVria.
	IF EXISTS (SELECT * FROM @documente WHERE @tipDoc IN ('AP', 'TE'))
	BEGIN 
		IF @debug=1
			SELECT 'doc_de_sters' tabela, doc.*
				FROM doc
				INNER JOIN @documente d ON doc.Tip=d.tipDoc AND doc.Numar=d.numarDoc AND doc.data=d.dataDoc
				WHERE doc.Subunitate=@sub AND d.tipDoc IN ('AP', 'TE')
		
		DELETE doc
			FROM doc
				INNER JOIN @documente d ON doc.Tip=d.tipDoc AND doc.Numar=d.numarDoc AND doc.data=d.dataDoc
				WHERE doc.Subunitate=@sub AND d.tipDoc IN ('AP', 'TE')
	end

	/*
		stergem TE-ul generat automat pentru bonuri.
		TE-urile automante au acelasi numar cu numarul de AC aferent bonurilor.
	*/
	IF @NuTEAC=0 AND EXISTS (SELECT * FROM @documente WHERE tipDoc='AC')
	BEGIN
		IF @debug=1
			SELECT 'TE_automate_de_sters' tabela, p.*
				from pozdoc p
				INNER JOIN @documente d ON p.Tip='TE' and d.numarDoc=p.Numar AND d.dataDoc=p.Data
				where p.subunitate=@sub AND d.tipDoc='AC'
		delete p
			from pozdoc p
			INNER JOIN @documente d ON p.Tip='TE' and d.numarDoc=p.Numar AND d.dataDoc=p.Data
			where p.subunitate=@sub AND d.tipDoc='AC'
	END
END

IF @debug=1
	SELECT 'intre op'  intre_op, * FROM dbo.pozdoc WHERE data BETWEEN @datajos AND @datasus order by numar_pozitie

IF @generare = 1
BEGIN

	-- copiem toate pozitiile documentelor afectate din BP in BT
	INSERT INTO BT (
		Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura
		, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, 
		Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, 
		idPozContract, detalii
		)
	SELECT BP.Casa_de_marcat, Factura_chitanta, BP.Numar_bon, Numar_linie, Data, Ora, (CASE Tip WHEN '20' THEN '21' ELSE Tip END
			), BP.Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, 
		Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, BP.Loc_de_munca, 
		Discount, BP.idAntetBon, lm_real, Comanda_asis, BP.Contract, idPozContract, detalii
	FROM BP
	INNER JOIN @documente d ON d.IdAntetBon = bp.IdAntetBon
		

	-- stergem pozitiile mutate in BT
	DELETE BP
	FROM bp
	INNER JOIN @documente d ON d.IdAntetBon = bp.IdAntetBon
	
	DECLARE @crsBonuri CURSOR, @status INT, @idBon INT
	
	-- apelez descarcarea pentru fiecare bon
	SET @crsBonuri = CURSOR
	FOR
	SELECT DISTINCT idAntetBon
	FROM @documente

	OPEN @crsBonuri

	FETCH NEXT
	FROM @crsBonuri
	INTO @idBon

	SET @status = @@fetch_status

	WHILE @status = 0
	BEGIN
		SET @parXML = (
				SELECT @idBon idAntetBon
				FOR XML raw
				)

		EXEC wDescarcBon @sesiune, @parXML

		FETCH NEXT
		FROM @crsBonuri
		INTO @idBon

		SET @status = @@fetch_status
	END
END

SELECT 'Refacere AC/TE efectuata cu succes!' AS textMesaj
FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	DECLARE @eroare VARCHAR(200)

	SET @eroare = ERROR_MESSAGE() + '(wOPRefacACTE)'

	RAISERROR (@eroare, 16, 1)
END CATCH

BEGIN TRY
	-- incerc sa inchid cursoarele doar daca sunt deschise
	IF CURSOR_STATUS('variable', '@crsBonuri') >= 0
		CLOSE @crsBonuri

	IF CURSOR_STATUS('variable', '@crsBonuri') >= - 1
		DEALLOCATE @crsBonuri
END TRY

BEGIN CATCH
END CATCH
	/*
-- verific corelare BONURI bp si pozdoc pe o perioada

select sum(Total)
 from bp 
where Factura_chitanta=1 and tip='21'
and data between '2012-04-10' and '2012-04-10'
and vinzator='magazin_nt' 

select SUM(cantitate*Pret_cu_amanuntul) 
from pozdoc
where Subunitate='1' and tip='AC' 
and data between '2012-04-10' and '2012-04-10'
and pozdoc.Utilizator='magazin_nt'


*/
