CREATE PROCEDURE wIaComenziLivrareContract_p @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @idContract int

SET @idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), 0)

set @parXML = 
	(select 
		idContract idContractCorespondent, numar+'-'+convert(char(10), data, 103) as denidContractCorespondent
	from contracte where idContract=@idContract
	for xml raw
	)

select @parXML 
