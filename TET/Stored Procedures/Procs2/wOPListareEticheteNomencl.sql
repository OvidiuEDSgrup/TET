
CREATE PROCEDURE wOPListareEticheteNomencl @sesiune VARCHAR(50), @parXML XML
AS
	declare 
		@tipcod varchar(20), @listaCoduri varchar(max), @docXML xml, @caleRaport varchar(1000), @utilizator varchar(100), @categorie_pret varchar(20)
	
	set @tipcod=@parXML.value('(/*/@tip_cod)[1]','varchar(20)')
	set @caleRaport = isnull(nullif(@parXML.value('(/*/@cale_raport)[1]', 'varchar(1000)'),''),'/CG/Stocuri/Etichete nomenclator')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	SELECT	cod
	INTO #deGenerat
	FROM temp_ListareCodBare where utilizator=@utilizator

	select @categorie_pret=valoare.value('(/*/@categorie_pret)[1]','varchar(20)') from parSesiuniRIA where username=@utilizator and param='CATLISTARECODURI'
	IF @categorie_pret=''
		select @categorie_pret=null
	select @listaCoduri =STUFF((SELECT rtrim(cod) + ',' from #deGenerat for xml PATH(''),type).value('.','VARCHAR(MAX)'),1,0,'')

	set @docXML = 
		(
			select 
				'Etichete '+@sesiune numeFisier, @caleRaport caleRaport, DB_NAME() BD,@categorie_pret categorie_pret,@listaCoduri listaCoduri, @tipcod tipBarcode, '' denumire
			for xml raw
		)
	exec wExportaRaport @sesiune=@sesiune, @parXML=@docXML
	
	delete from temp_ListareCodBare where utilizator=@utilizator
	delete from parSesiuniRIA where username=@utilizator and param='CATLISTARECODURI'
