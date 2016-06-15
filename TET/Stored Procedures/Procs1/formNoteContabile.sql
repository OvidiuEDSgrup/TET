--***
CREATE PROCEDURE formNoteContabile @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @subunitate varchar(20), @debug bit, @cTextSelect nvarchar(max), @mesaj varchar(1000), @tip varchar(2), @numar varchar(20), @data datetime
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
-- declaratii variabile
-- citire filtre
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data=@parXML.value('(/*/@data)[1]', 'datetime')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

-- select-ul propriu-zis si optimizari
	select 
		rtrim(pn.numar) as NC,
		rtrim(convert(char(10),pn.data,103)) as DATA,
		rtrim(pn.cont_debitor) as CONTDB,
		rtrim(pn.cont_creditor) as CONTCR,
		convert(char(15), convert(money, pn.suma)) as SUMA,
		rtrim(pn.explicatii) as EXPLICATII,
		rtrim(pn.loc_munca) as LM,
		rtrim(pn.comanda) AS COMANDA,
		(case when rtrim(isnull(pn.valuta,''))='' then '' else rtrim(pn.valuta) end) as VALUTA,
		(case when rtrim(isnull(pn.valuta,''))='' then '' else rtrim(pn.curs) end) as CURS,
		(case when rtrim(isnull(pn.valuta,''))='' then '' else rtrim(pn.suma_valuta) end) AS SUMAVALUTA

	into #selectMare
	from pozncon pn
	where pn.subunitate = @subunitate and pn.tip = @tip and pn.numar = @numar

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY data
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formNoteContabileSP1')
	begin
		exec formNoteContabileSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formNoteContabile)'
	raiserror(@mesaj, 11, 1)
end catch
