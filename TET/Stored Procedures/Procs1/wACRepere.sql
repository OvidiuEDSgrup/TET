
CREATE PROCEDURE wACRepere @sesiune VARCHAR(50), @parXML XML
AS
	
	set @parXML.modify('insert attribute tip_tehnologie {"R"} into (/row[1])')
	exec wACTehnologii @sesiune=@sesiune, @parXML=@parXML
