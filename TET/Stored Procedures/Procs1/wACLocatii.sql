
CREATE PROCEDURE wACLocatii @sesiune VARCHAR(50), @parXML XML
AS
	if exists(select * from sysobjects where name='wACLocatiiSP' and type='P')      
	begin
		exec wACLocatiiSP @sesiune=@sesiune,@parXML=@parXML
		return 0
	end

	DECLARE 
		@searchText VARCHAR(200), @gestiune varchar(200)

	SET @searchText = '%' + ISNULL(replace(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'),' ','%'), '%') + '%'
	select 
		@gestiune=COALESCE(
			nullif(@parxml.value('(/row/@gestprim)[1]', 'varchar(100)'),''),nullif(@parxml.value('(/row/@cGestiune)[1]', 'varchar(100)'),''),
			nullif(@parxml.value('(/row/@gestiune)[1]', 'varchar(100)'),''),nullif(@parxml.value('(/row/@cGestiune)[1]', 'varchar(100)'),''),
			nullif(@parxml.value('(/row/@Gestiune)[1]', 'varchar(100)'),''), 
			nullif(@parxml.value('(/row/@gest)[1]', 'varchar(100)'),''),''
				)

	IF OBJECT_ID ('tempdb..#locatii') IS NOT NULL
		drop TABLE #locatii
	create table #locatii (cod varchar(20), denumire varchar(max), info varchar(max))

	IF (select top 1 ISNULL(detalii.value('(/*/@custodie)[1]','bit'),0) from gestiuni where Cod_gestiune=@gestiune)=1
	BEGIN 
		INSERT INTO #locatii (cod, denumire, info)
		select 
			rtrim(terti.tert)+REPLICATE(' ',13-LEN(rtrim(terti.tert)))+ISNULL(rtrim(it.identificator),'') as cod, 
			(rtrim(terti.denumire)+ ISNULL('/'+RTRIM(it.Descriere),'') ) denumire,'Gest. ' + RTRIM(g.denumire_gestiune) as info
		from terti   
		JOIN gestiuni g on g.Cod_gestiune=@gestiune
		left join infotert it 
			on it.subunitate=terti.Subunitate and it.tert=terti.tert 
			/*In infotert identificator='' se salveaza un fel de extensie a tertului */ 
			--and it.identificator<>''  -- trebuie sa aduca si tertul propriu-zis
		
		where terti.denumire like @searchText or terti.tert like @searchText
	END

	ELSE
		BEGIN
			INSERT INTO #locatii (cod, denumire, info)
			SELECT 
				RTRIM(l.cod_locatie) AS cod, RTRIM(l.descriere) AS denumire, 'Gest. ' + RTRIM(l.cod_gestiune) AS info
			FROM locatii l
			WHERE l.cod_locatie LIKE @searchText
				OR l.Descriere LIKE @searchText
		END


	select * from #locatii FOR XML raw, root('Date')
