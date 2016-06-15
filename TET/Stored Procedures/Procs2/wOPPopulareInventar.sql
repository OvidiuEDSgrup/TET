
CREATE PROCEDURE wOPPopulareInventar (@sesiune VARCHAR(50), @parXML XML)
AS

DECLARE 
	@data DATETIME, @utilizator VARCHAR(10), @err INT, @folosinta INT, @gestiune VARCHAR(9), @idInventar INT, @tip VARCHAR(2), @grupa varchar(13),
	@locatie varchar(20), @fara_mesaje int

SET @data = isnull(@parXML.value('(*/@data)[1]', 'datetime'), '2999-01-01')
SET @utilizator = ISNULL(dbo.fIaUtilizator(@sesiune), 'POPULARE')
SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(9)'), '')
SET @grupa = @parXML.value('(/*/@grupa)[1]', 'varchar(13)')
SET @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int')
SET @tip = isnull(@parXML.value('(/*/@tipinventar)[1]', 'varchar(2)'),'G')
SET @fara_mesaje = ISNULL(@parXML.value('(/*/@fara_mesaje)[1]', 'int'), 0)

DECLARE @subunitate CHAR(9)

EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

BEGIN TRY
	IF @gestiune = ''
		RAISERROR ('Alegeti un antet de inventar din tabel!', 16, 1)

	DELETE
	FROM PozInventar
	WHERE idInventar = @idInventar

	select @locatie=locatie from AntetInventar where idInventar=@idInventar

		declare @p xml, @TipStoc varchar(1)
		select @TipStoc=(CASE @tip WHEN 'L' THEN 'F' WHEN 'M' THEN 'F' ELSE '' END)
		select @p=(select @data dDataSus, @gestiune cGestiune, @TipStoc TipStoc, @grupa cGrupa, @locatie Locatie, 1 GrCod, 1 GrGest, 0 GrCodi

		for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p
		
	INSERT INTO PozInventar (idInventar, cod, stoc_faptic, utilizator, data_operarii)
	SELECT @idInventar, cod, stoc, @utilizator, GETDATE()
	from #docstoc
	where stoc>0.0009
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPopulareInventarSP1')    
		exec wOPPopulareInventarSP1 @sesiune,@parXML  
	
	IF @fara_mesaje = 0
	BEGIN
		SELECT 'S-a realizat popularea cu stoc scriptic la ' + convert(CHAR(10), @data, 103) AS textMesaj
		FOR XML raw, root('Mesaje')
	END

END TRY
BEGIN CATCH
	DECLARE @eroare VARCHAR(200)
	SET @eroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR (@eroare, 16, 1)
END CATCH
