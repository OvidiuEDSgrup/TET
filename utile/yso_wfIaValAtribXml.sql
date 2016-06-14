--***
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'yso_wfIaValAtribXml') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION yso_wfIaValAtribXml
GO
--***
/* extrage filtrele din XML, returnand un tabel cu nume filtru si valoare */
create function yso_wfIaValAtribXml (@parXML xml, @attr varchar(max))
returns nvarchar(200)
with schemabinding
as 
begin
	return @parXML.value('(//@*[local-name()=sql:variable("@attr")])[1]','nvarchar(max)')
end