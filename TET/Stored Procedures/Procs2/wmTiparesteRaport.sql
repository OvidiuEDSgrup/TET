---
CREATE PROCEDURE wmTiparesteRaport @sesiune VARCHAR(50), @parXML XML
AS
if exists (select 1 from sysobjects where [type]='P' and [name]='wmTiparesteRaportSP')
begin 
	declare @returnValue int 
	exec @returnValue = wmTiparesteRaportSP @sesiune=@sesiune, @parXML=@parXML
	return @returnValue
end

EXEC wExportaRaport @sesiune = @sesiune, @parXML = @parXML
