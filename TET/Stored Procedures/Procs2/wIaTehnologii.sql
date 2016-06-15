
CREATE PROCEDURE wIaTehnologii @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE
		 @fltcod VARCHAR(20), @fltdenumire VARCHAR(20), @flttip VARCHAR(20), @fltcodN VARCHAR(20), @id VARCHAR(20)


	select
		@fltdenumire = '%' + replace(isnull(@parXML.value('(/row/@f_denumire)[1]', 'varchar(20)'), '%'),' ','%')+ '%',
		@flttip ='%' +  replace(isnull(@parXML.value('(/row/@f_tip)[1]', 'varchar(20)'), '%'),' ','%')+ '%',
		@fltcod = '%' + replace(isnull(@parXML.value('(/row/@f_cod)[1]', 'varchar(20)'), '%'),' ','%')+ '%',
		@fltcodN = '%' + replace(isnull(@parXML.value('(/row/@f_codN)[1]', 'varchar(20)'), '%'),' ','%')+ '%',
		@id = @parXML.value('(/row/@id)[1]', 'varchar(20)')

	SELECT TOP 100 
		RTRIM(t.Cod) AS cod_tehn, RTRIM(t.denumire) AS denumire,RTRIM(t.codNomencl) AS codNomencl, rtrim(n.denumire) as denNomenclator,t.tip AS tip,convert(VARCHAR(30), getdate(), 101) AS data, 
		(CASE t.tip WHEN 'P' THEN 'Produs' WHEN 'R' THEN 'Reper' WHEN 'S' THEN 'Serviciu' WHEN 'I' THEN 'Inteventie' WHEN 'F' then 'Faza' END) AS dentip_tehn,
		rtrim(t.cod) AS numar, pt.id AS id, pt.id AS idTehn,rtrim(n.denumire) dencodNomencl,t.detalii, t.tip AS tip_tehn,
		'<a href="' + 'formulare/uploads/' + rtrim(fis.fisier) + '" target="_blank" /><u> Descarca </u></a>' AS fisier
	FROM tehnologii t
	INNER JOIN pozTehnologii pt ON pt.cod = t.cod AND pt.tip = 'T' AND idp IS NULL
	LEFT JOIN nomencl n ON n.Cod = t.codNomencl
	OUTER APPLY (select top 1 fisier from FisiereProductie where idPozTehnologie=pt.id) fis
	WHERE 
		t.Cod LIKE @fltcod AND 
		t.denumire LIKE @fltdenumire AND 
		t.tip LIKE @flttip AND 
		isnull(n.Denumire, '%') LIKE @fltcodN AND 
		t.cod LIKE isnull(convert(VARCHAR(20), pt.cod), '%') AND 
		(@id IS NULL or pt.id=@id)
	FOR XML raw, root('Date')
	
	
	SELECT 1 areDetaliiXml
	FOR XML raw, root('Mesaje')
