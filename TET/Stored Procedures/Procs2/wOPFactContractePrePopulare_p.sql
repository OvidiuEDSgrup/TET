-- procedura folosita initalizarea operatiei folosita pentru generare facturi.
-- practic resetam atributele care ar fi completate cand se deschide operatia cand e completat un contract.
CREATE PROCEDURE wOPFactContractePrePopulare_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @dataJos DATETIME, @dataSus DATETIME, @tipContract VARCHAR(2), @mesaj varchar(50)

	SET @tipContract = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	
	SET @dataJos = dbo.BOM(getdate())
	SET @dataSus = dbo.EOM(getdate())
	
	select @tipContract as tip, convert(char(10), @dataJos, 101) as datajos, convert(char(10), @dataSus, 101) as datasus, 
		'' tert, '' as lm, '' as gestiune
	for xml raw,root('Date')
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPFactContractePrePopulare_p)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
