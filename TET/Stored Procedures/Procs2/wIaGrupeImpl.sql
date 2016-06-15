
/** Procedura aduce toate grupele si pastreaza datele de antet in pozitii la refresh.
	Este folosita la macheta "Date implementare", la subtipul Nomenclator */
CREATE PROCEDURE wIaGrupeImpl @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @grupa varchar(13), @f_grupa varchar(50), @f_tip varchar(20), @f_cont varchar(40)
	
	SELECT @grupa = ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(13)'), ''),
		@f_grupa = ISNULL(@parXML.value('(/row/@f_grupa)[1]', 'varchar(50)'), ''),
		@f_tip = ISNULL(@parXML.value('(/row/@f_tip)[1]', 'varchar(20)'), ''),
		@f_cont = ISNULL(@parXML.value('(/row/@f_cont)[1]', 'varchar(40)'), '')

	IF OBJECT_ID('tempdb.dbo.#tipuri_gr') IS NOT NULL
		DROP TABLE #tipuri_gr

	CREATE TABLE #tipuri_gr (tip varchar(2), denumire varchar(200))
	INSERT INTO #tipuri_gr (tip, denumire)
	SELECT 'M', 'Material' UNION
	SELECT 'P', 'Produs' UNION
	SELECT 'A', 'Marfa' UNION
	SELECT 'R', 'Servicii furnizate' UNION
	SELECT 'S', 'Servicii prestate' UNION
	SELECT 'O', 'Obiecte de inventar' UNION
	SELECT 'F', 'Mijloace fixe' UNION
	SELECT 'U', 'Nefolosit' UNION
	SELECT '', ''

	SELECT TOP 100 
		RTRIM(gr.grupa) AS grupa, RTRIM(gr.denumire) AS denumire,
		RTRIM(gr.Tip_de_nomenclator) AS tip,
		RTRIM(gr.Tip_de_nomenclator) + ' - ' + RTRIM(tg.denumire) as denTip,
		RTRIM(g.Grupa) AS grupa_parinte, RTRIM(g.Denumire) AS dengrupa_parinte,
		RTRIM(gr.detalii.value('(/row/@cont)[1]', 'varchar(40)')) AS detalii_cont
	FROM grupe gr
	INNER JOIN #tipuri_gr tg ON tg.tip = gr.Tip_de_nomenclator
	LEFT JOIN grupe g ON g.grupa_parinte = gr.Grupa
	WHERE (@grupa = '' OR gr.grupa = @grupa) AND
		(tg.tip LIKE '%' + @f_tip + '%' OR tg.denumire LIKE '%' + @f_tip + '%') AND 
		(gr.denumire LIKE '%' + @f_grupa + '%' OR gr.grupa LIKE @f_grupa + '%') AND
		(ISNULL(gr.detalii.value('(/row/@cont)[1]','varchar(20)'), '') LIKE '%' + @f_cont + '%')
	FOR XML RAW, ROOT('Date')
END
