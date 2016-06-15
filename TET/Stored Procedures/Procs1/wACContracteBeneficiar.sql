-- apeleaza wACContracteNoi cu filtrare pe contracte beneficiar
CREATE PROCEDURE wACContracteBeneficiar @sesiune VARCHAR(50), @parXML XML
AS

if @parXML.exist('(/row/@tip)')=0 
	set @parXML.modify('insert attribute tip {"CB"} into /row[1]')
else
	set @parXML.modify('replace value of /row[1]/@tip with "CB"')

exec wACContracteNoi @sesiune=@sesiune, @parXML=@parXML
