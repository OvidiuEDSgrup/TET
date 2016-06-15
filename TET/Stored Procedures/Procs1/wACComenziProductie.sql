
--Se foloseste pe macheta de raportare tehnologie din cadrul unei comenzi
CREATE procedure wACComenziProductie @sesiune varchar(50), @parXML xml
as
	if exists(select * from sysobjects where name='wACComenziProductieSP' and type='P')
	BEGIN
		exec wACComenziProductieSP @sesiune=@sesiune, @parXML=@parXML
		RETURN
	END
	
	declare @searchText varchar(80)
	set @searchText='%'+replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ' ,'%')+'%' 
	
	
	select 
		RTRIM(p.cod) as cod, 'Com. ' + rtrim(p.cod) +' Cod '+RTRIM(n.cod) as denumire, 'Comanda '+RTRIM(p.cod) as info
	from pozLansari p
	join comenzi c on p.tip='L' and p.cod=c.Comanda and c.Starea_comenzii='L'
	join pozTehnologii coduri on p.idp=coduri.id
	JOIN tehnologii t on  coduri.cod=t.cod
	join nomencl n on n.Cod=t.codNomencl
	where n.Denumire like @searchText or n.Cod like @searchText or c.Comanda like @searchText	
	for xml raw,root('Date')
	
	
