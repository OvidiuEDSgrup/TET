
CREATE PROCEDURE wACLocmPrefiltrare @sesiune VARCHAR(30), @parXML XML
AS
SET NOCOUNT ON
	DECLARE 
		@utilizator VARCHAR(100), @searchText varchar(200)

	SET @searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT


	IF OBJECT_ID('tempdb..#lmprop') is not null
		drop TABLE #lmprop
	create table #lmprop (lm varchar(20))

	/** Daca are proprietati ii sugeram in AC acele locuri de munca **/
	insert into #lmprop (lm)
	select 
		RTRIM(valoare) lm
	from proprietati where tip='UTILIZATOR' and Cod=@utilizator and Cod_proprietate='LOCMUNCA'

	/** Daca nu are nici o proprietate LOCMUNCA, ii aratam locurile de munca de nivel 1 **/
	IF NOT EXISTS (select 1 from #lmprop)
	insert into #lmProp (lm)
	SELECT 
		RTRIM(cod)
	from lm where Nivel=1

	select
		RTRIM(lm.cod) as cod, RTRIM(lm.denumire) as denumire
	from lm
	JOIN #lmprop lp on lm.Cod= lp.lm
	where lm.Denumire like @searchText or lm.cod like @searchText
	for xml raw, ROOT('Date')
