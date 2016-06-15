
/** Aceasta mini-procedura este folosita la operatia de generare receptie
	din comanda de aprovizionare, pentru popularea unui camp invizibil din macheta cu grid. */
CREATE PROCEDURE wOPPopulareGridCursComandaAprovizionare @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @curs decimal(17,4), @lm varchar(20), @tert varchar(20), @gestiune varchar(13), @dengestiune varchar(200),
		@dentert varchar(100), @denlm varchar(100), @idContract int, @valuta varchar(10), @nr_receptie varchar(20),
		@data_receptie datetime, @factura varchar(50), @data_facturii datetime, @codmeniu varchar(20)

	SELECT @curs = @parXML.value('(/parametri/@curs)[1]', 'decimal(17,4)'),
		@denlm = @parXML.value('(/*/@denlm)[1]', 'varchar(100)'),
		@dentert = @parXML.value('(/*/@dentert)[1]','varchar(100)'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@dengestiune = @parXML.value('(/*/@dengestiune)[1]', 'varchar(200)'),
		@tert = @parXML.value('(/*/@tert)[1]', 'varchar(100)'),
		@lm = @parXML.value('(/*/@lm)[1]', 'varchar(100)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@valuta = ISNULL(@parXML.value('(/*/@valuta)[1]', 'varchar(10)'), ''),
		@nr_receptie = ISNULL(@parXML.value('(/*/@nr_receptie)[1]', 'varchar(20)'), ''),
		@data_receptie = @parXML.value('(/*/@data_receptie)[1]', 'datetime')

	/** Inserare curs in tabela de manevrare, ca sa putem pune cursul in macheta principala. */
	INSERT INTO tabelXML (sesiune, date, data_modificare)
	SELECT @sesiune, (SELECT @curs AS curs, @nr_receptie AS nr_receptie,
		@data_receptie AS data_receptie FOR XML RAW), GETDATE()
	
	SELECT @tert = RTRIM(d.Cod_tert), @dentert = RTRIM(t.Denumire),
		@lm = RTRIM(d.Loc_munca), @denlm = RTRIM(lm.Denumire),
		@gestiune = RTRIM(d.Cod_gestiune), @dengestiune = RTRIM(g.Denumire_gestiune),
		@factura = RTRIM(d.Factura), @data_facturii = d.Data_facturii,
		@curs = CONVERT(decimal(17,4), d.Curs), @valuta = RTRIM(d.Valuta)
	FROM doc d
	LEFT JOIN lm ON lm.Cod = d.Loc_munca
	LEFT JOIN terti t ON t.Subunitate = d.Subunitate AND t.Tert = d.Cod_tert
	LEFT JOIN gestiuni g ON g.Cod_gestiune = d.Cod_gestiune
	WHERE d.Tip = 'RM' AND d.Numar = @nr_receptie AND d.Data = @data_receptie
	
	set @codmeniu='CA'
	if exists (select 1 from webconfigmeniu where meniu='D_CA')
		set @codmeniu='D_CA'

	SELECT 'Generare receptie' AS nume, @codmeniu AS codmeniu, 'CA' AS tip,
		'GR' AS subtip, 'O' AS tipmacheta,
		(SELECT @valuta AS valuta, @tert AS tert, @dentert AS dentert, 1 AS prePopulare,
			@gestiune AS gestiune, @dengestiune AS dengestiune, @lm AS lm, @idContract AS idContract,
			@curs AS curs, @denlm AS denlm, @factura AS factura, @nr_receptie AS nr_receptie,
			CONVERT(varchar(10), @data_facturii, 101) AS data_facturii FOR XML RAW, TYPE) AS dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
END
