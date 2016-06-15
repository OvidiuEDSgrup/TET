
--Pe macheta de realizari tip raportare operatie
Create PROCEDURE wACComenziProductie2 @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(50), @codResursa varchar(20)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), ' ', '%') + '%'
set @codResursa=@parXML.value('(/row/@resursa)[1]', 'varchar(20)')


select 'Comanda '+RTRIM(pl.comanda) as denumire, rtrim(pl.comanda) as cod, '' as info

from planificare pl
join pozLansari p on p.tip='L' and p.cod=pl.comanda and pl.resursa=@codResursa
for xml raw, root('Date')
