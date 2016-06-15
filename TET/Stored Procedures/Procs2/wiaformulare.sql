--***
CREATE PROCEDURE wiaformulare @sesiune VARCHAR(40), @parXML XML
AS
DECLARE @utilizator VARCHAR(255), @formimplicit VARCHAR(255), @tip VARCHAR(10), @meniu varchar(20)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
set @meniu = ISNULL(@parXML.value('(/row/@codmeniu)[1]', 'varchar(20)'), '')

/**
	Citesc ultimul formular folosit din proprietati. Folosesc tip ='PROPUTILIZ', nu 'UTILIZATOR' pt. ca 
	vreau sa nu se vada in ED la proprietati pe utilizator 
**/
SELECT @formimplicit = Valoare
FROM proprietati p
WHERE p.Tip = 'PROPUTILIZ'
	AND p.Cod_proprietate = 'FORM' + @tip
	AND p.cod = @utilizator

IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wIaFormulareSP' AND type = 'P')
begin
	EXEC wIaFormulareSP @sesiune, @parXML
	return
end

SELECT rtrim(wcf.cod_formular) AS formular, RTRIM(af.Denumire_formular) AS denumire, 
	(CASE WHEN @formimplicit = wcf.cod_formular THEN 0 ELSE 1 END) AS ordonare
FROM webConfigFormulare wcf
INNER JOIN antform af ON wcf.cod_formular = af.Numar_formular 
where (@meniu='' or wcf.meniu = @meniu)
	and (exists (select 1 from webconfigmeniu m where m.meniu=wcf.meniu and m.tipmacheta='c') or wcf.tip = @tip)
FOR XML raw, root('Date')
