
CREATE PROCEDURE wIaResurse @sesiune VARCHAR(50), @parXML XML
AS

	DECLARE 
		@fltDescriere VARCHAR(80), @fltCod VARCHAR(20), @fltTip VARCHAR(20)

	SELECT
		@fltCod = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_cod)[1]', 'varchar(20)'), ''), ' ', '%') + '%',
		@fltDescriere = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_descriere)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@fltTip = '%' + REPLACE(ISNULL(@parXML.value('(/row/@f_tip)[1]', 'varchar(20)'), ''), ' ', '%') + '%'

	SELECT 
		RTRIM(descriere) AS descriere, id AS id, RTRIM(tip) AS tipR, RTRIM(cod) AS cod, 
		(CASE WHEN tip = 'A' THEN 'Angajat' WHEN tip = 'E' THEN 'Extern' WHEN tip = 'U' THEN 'Utilaj' WHEN tip = 'L' THEN 'Loc munca' END) AS descriereTip, 
		ISNULL(o.nr,0) AS nrOp, detalii
	FROM Resurse
	OUTER APPLY (SELECT COUNT(*) nr FROM OpResurse WHERE idRes = Resurse.id) o
	WHERE 
		cod LIKE @fltCod AND 
		descriere LIKE @fltDescriere AND 
		(CASE WHEN tip = 'A' THEN 'Angajat' WHEN tip = 'E' THEN 'Extern' WHEN tip = 'U' THEN 'Utilaj' WHEN tip = 'L' THEN 'Loc munca' END) LIKE @fltTip
	FOR XML raw, root('Date')

	select '1' as areDetaliiXml for xml raw, root('Mesaje')
