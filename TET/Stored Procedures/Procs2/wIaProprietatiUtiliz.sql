
CREATE PROCEDURE wIaProprietatiUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @f_codproprietate VARCHAR(20), @f_descriere VARCHAR(50), @f_denvalidare VARCHAR(50)

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @f_codproprietate = '%' + isnull(@parXML.value('(/row/@f_codproprietate)[1]', 'varchar(20)'), '') + '%'
SET @f_descriere = '%' + isnull(@parXML.value('(/row/@f_descriere)[1]', 'varchar(50)'), '') + '%'
SET @f_denvalidare = '%' + isnull(@parXML.value('(/row/@f_denvalidare)[1]', 'varchar(50)'), '') + '%'

if exists (select 1 from utilizatori u where u.ID=@utilizator and u.Marca='GRUP')
	raiserror('Acesta este un grup! Nu exista proprietati pe grupuri!',16,1)

SELECT @utilizator AS utilizator, RTRIM(pr.cod_proprietate) AS codproprietate, rtrim(cpr.Descriere) AS descriere, rtrim(pr.valoare
	) AS valoare, cpr.Validare AS codvalidare, (
		CASE WHEN cpr.Validare = '0' THEN 'Fara' WHEN cpr.Validare = '2' THEN 'Catalog' WHEN cpr.Validare = '1' THEN 'Lista' ELSE 'Compusa' 
			END
		) AS denvalidare, pr.Valoare_tupla as ordine
FROM proprietati pr
INNER JOIN catproprietati cpr ON pr.Cod_proprietate = cpr.Cod_proprietate
WHERE pr.Tip = 'UTILIZATOR'
	AND pr.Cod = @utilizator
	AND cpr.Cod_proprietate LIKE @f_codproprietate
	AND cpr.Descriere LIKE @f_descriere
	AND (
		CASE WHEN cpr.Validare = '0' THEN 'Fara' WHEN cpr.Validare = '2' THEN 'Catalog' WHEN cpr.Validare = '1' THEN 'Lista' ELSE 'Compusa' 
			END
		) LIKE @f_denvalidare
order by isnull(nullif(pr.Valoare_tupla,''),0),cod
FOR XML raw, root('Date')
