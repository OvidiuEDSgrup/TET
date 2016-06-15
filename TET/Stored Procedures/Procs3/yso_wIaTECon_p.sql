CREATE PROCEDURE yso_wIaTECon_p @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @idContract int, @tipContract varchar(2) ,@nrContract varchar(20)

SELECT @idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), '')
	,@tipContract = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), '')
	,@nrContract = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), '')

set @parXML = (select f_factura=LTRIM(@nrContract) for xml raw)

select @parXML
