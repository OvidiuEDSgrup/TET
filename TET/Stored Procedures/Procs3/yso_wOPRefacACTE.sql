-- reface bonurile in in tabela pozdoc, din tabela bp.
CREATE PROCEDURE yso_wOPRefacACTE @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @datajos DATETIME, @datasus DATETIME, @listaGestiuni VARCHAR(max), @Subunitate VARCHAR(1), @Tip VARCHAR(2), @Numar VARCHAR(
		10), @Cod VARCHAR(10), @Data DATETIME, @Gestiune VARCHAR(10), @Cantitate FLOAT, @Pret_valuta FLOAT, @Pret_de_stoc FLOAT, 
	@utilizator VARCHAR(50), @stergere BIT, @generare BIT, @databon DATETIME, @casabon VARCHAR(10), @numarbon INT, @UID VARCHAR(50), 
	@userASiS VARCHAR(50), @msgEroare VARCHAR(max), @codMeniu VARCHAR(2), @vanzator VARCHAR(20), @casamarcat VARCHAR(20), 
	@DetBon INT, @NrDoc VARCHAR(20), @NuTEAC INT

BEGIN TRY
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

/*sp*/begin transaction yso_refacte/*sp*/
--	RAISERROR('Aceasta operatie sterge toate transferurile inspre gestiunea primitoare!!! Asteptati rescrierea ei',16,1)
--	return
EXEC luare_date_par 'PO', 'DETBON', @DetBon OUTPUT, 0, ''
EXEC luare_date_par 'PO', 'NUTEAC', @NuTEAC OUTPUT, 0, ''

SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), '01/01/1901')
SET @numarbon = isnull(@parXML.value('(/*/@numar)[1]', 'int'), '-1')
/*-------- tratat pentru cele doua tipuri de codMeniu RF- Meniu; BC-Document*/
SET @datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), isnull(@data, '01/01/1901'))
SET @datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), isnull(@data, '01/01/1901'))
/*--------------------------*/
SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(10)'), '')

SET @vanzator = isnull(@parXML.value('(/*/@vanzator)[1]', 'varchar(10)'), '')
SET @casamarcat = isnull(@parXML.value('(/*/@casam)[1]', 'varchar(10)'), '')
SET @stergere = isnull(@parXML.value('(/*/@stergere)[1]', 'bit'), 0)
SET @generare = isnull(@parXML.value('(/*/@generare)[1]', 'bit'), 0)

/* Se citea din greseala variabila CODMENIU
	In aplicatie ea daca este RF inseamna refacere toate bonurile pe o zi
	In cazul curent acest CODMENIU =RF va fi setat automat in cazul in care numarul de bon este -1
*/
SET @codMeniu = @parXML.value('(/*/@codMeniu)[1]', 'varchar(10)')
if @codMeniu is null
begin
	if @numarbon=-1
		set @codMeniu='RF'
	else
		set @codMeniu=''
end
--/*sp
IF isnull(@codMeniu,'') <> ''
begin
	set @codMeniu=''
	if @numarbon=-1 or @casamarcat=''
		RAISERROR ('Aceasta operatie se ruleaza doar pe un bon. Alegeti bonul dorit.', 11, 1)
	if @datajos<>@datasus
		RAISERROR ('Aceasta operatie se ruleaza doar pe un bon. Alegeti bonul dorit.', 11, 1)
end
--sp*/

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

IF @Gestiune = ''
	RAISERROR ('Aceasta operatie se ruleaza pe o gestiune. Alegeti gestiunea dorita.', 11, 1)

IF EXISTS (
		SELECT 1
		FROM proprietati
		WHERE Tip = 'UTILIZATOR'
			AND cod_proprietate IN /*sp ('GESTIUNE') sp*/ ('GESTPV')
			AND cod = @userASiS
			AND Valoare <> ''
		)
	AND @Gestiune NOT IN (
		SELECT valoare
		FROM proprietati
		WHERE Tip = 'UTILIZATOR'
			AND cod_proprietate IN /*sp ('GESTIUNE') sp*/ ('GESTPV')
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

IF @stergere = 1
BEGIN
/*sp exec setare_par 'GE','FARAVSTN','Fara validare stoc negativ',1,0,'' sp*/

	IF (@codMeniu = 'BC' or /*sp*/(@numarbon<>-1 and @casamarcat<>''))/*sp*/ AND @DetBon = 0
		RAISERROR ('Bonul nu poate fi sters deoarece nu are detaliere(bonurile se cumuleaza in tabela pozdoc)!', 16, 1)
	
	/* la bonuri, numarul de document se genereaza dupa urmatoarea formula: */
	SET @NrDoc = left(RTrim(CONVERT(VARCHAR(4), @casamarcat)) + right(replace(str(@numarbon), ' ', '0'), 4), 8)
	SET @listaGestiuni = /*sp*/isnull(/*sp*/
		';' + (SELECT TOP 1 rtrim(val_alfanumerica) FROM par WHERE Tip_parametru = 'PG' AND Parametru = @Gestiune) + ';','')
--/*sp
	set @listaGestiuni = isnull(@listaGestiuni,'')
		+isnull(';' + (SELECT TOP 1 rtrim(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru='REZSTOCBK' 
			and Val_logica = 1) + ';','')
--*sp/

	DELETE
	FROM pozdoc
	WHERE subunitate = '1'
		AND tip = 'AC'
--/*sp	AND stare = 5 sp*/
		AND data BETWEEN @datajos
			AND @datasus
		AND /*sp*/(
			gestiune = @gestiune or charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0 )/*sp*/
		AND (@codMeniu='RF' or Numar = @NrDoc)

	DELETE
	FROM pozdoc
	WHERE Subunitate='1'
		and tip = 'AP'
		AND Stare = 5
		AND data BETWEEN @datajos
			AND @datasus
		AND (@codMeniu='RF' or Numar = convert(varchar(20),@numarbon)) /* nr factura = nr bon pentru AP-uri*/
		/*and gestiune=@gestiune gestiunea e in antetbonuri*/
		AND EXISTS (
			SELECT 1
			FROM antetBonuri a
			WHERE a.Chitanta = 0
				AND a.Factura = pozdoc.Numar
				AND a.Gestiune = @Gestiune
				AND a.Data_facturii = pozdoc.Data
				AND a.Tert = pozdoc.Tert
				AND NOT EXISTS (
					SELECT 1
					FROM antetBonuri a2
					WHERE a.factura = a2.factura
						AND a.data_facturii = a2.data_facturii
						AND a.tert = a2.tert
						AND a2.chitanta = 1
					)
			)

	DELETE
	FROM doc
	WHERE tip = 'AP'
		AND Stare = 5
		AND data BETWEEN @datajos
			AND @datasus
		AND (@codMeniu='RF' or Numar = convert(varchar(20),@numarbon))

	if @NuTEAC=0 -- tratare setarea de negenerare TE automat ('PO', 'NUTEAC')
		DELETE
		FROM pozdoc
		WHERE subunitate = '1'
			AND tip = 'TE'
--/*sp		AND stare = 5 -- reactivare conditie de TE cu stare=5 (TE automat) sp*/
			AND data BETWEEN @datajos AND @datasus 
			AND (Gestiune_primitoare = @gestiune or Gestiune=@gestiune )
			--and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )
			--AND charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0
			AND (@codMeniu='RF' or Numar = @NrDoc)
			
/*sp exec setare_par 'GE','FARAVSTN','Fara validare stoc negativ',0,0,'' sp*/
END

IF @generare = 1
BEGIN
	INSERT INTO BT (
		Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura
		, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, 
		Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract
		)
	SELECT BP.Casa_de_marcat, Factura_chitanta, BP.Numar_bon, Numar_linie, Data, Ora, (CASE Tip WHEN '20' THEN '21' ELSE Tip END
			), BP.Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, 
		Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, BP.Loc_de_munca, 
		Discount, BP.idAntetBon, lm_real, Comanda_asis, BP.Contract
	FROM BP
	LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
	WHERE /*BP.factura_chitanta=1 and*/ 
		BP.data BETWEEN @datajos  AND @datasus
		AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
		AND BP.vinzator = (CASE @codMeniu WHEN 'RF' THEN BP.Vinzator ELSE @vanzator END)
		AND BP.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN BP.Casa_de_marcat ELSE @casamarcat END)
		AND BP.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN BP.numar_bon ELSE @numarbon END)

	DELETE BP
	FROM bp
	LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
	WHERE /*BP.factura_chitanta=1 and*/ BP.data BETWEEN @datajos
			AND @datasus
		AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
		AND BP.vinzator = (CASE @codMeniu WHEN 'RF' THEN BP.Vinzator ELSE @vanzator END)
		AND BP.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN BP.Casa_de_marcat ELSE @casamarcat END)
		AND BP.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN BP.numar_bon ELSE @numarbon END)
	
	--select * from pozdoc where data=@datajos and Gestiune=@Gestiune and tip='ac'
	DECLARE @crsBonuri CURSOR, @status INT, @idBon INT
		-- apelez descarcarea pentru fiecare bon
		SET @crsBonuri = CURSOR
	FOR
	SELECT DISTINCT bp.idAntetBon
	FROM bt bp 
	LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
	WHERE data BETWEEN @datajos AND @datasus
		AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
		AND bp.vinzator = (CASE @codMeniu WHEN 'RF' THEN bp.Vinzator ELSE @vanzator END)
		AND bp.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN bp.Casa_de_marcat ELSE @casamarcat END)
		AND bp.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN bp.numar_bon ELSE @numarbon END)

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
/*sp*/commit transaction yso_refacte/*sp*/
END TRY

BEGIN CATCH 
--/*sp
	if @@TRANCOUNT>0
		rollback transaction yso_refacte --sp*/
	DECLARE @eroare VARCHAR(200)

	SET @eroare = ERROR_MESSAGE() + '(yso_wOPRefacACTE)'

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
