IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_wIaAvizeContracte_p')
	DROP PROCEDURE yso_wIaAvizeContracte_p
GO
CREATE PROCEDURE yso_wIaAvizeContracte_p @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @idContract int, @tipContract varchar(2) ,@nrContract varchar(20)

SELECT @idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), '')
	,@tipContract = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), '')
	,@nrContract = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), '')

set @parXML = 
	(select f_contract=rtrim(@tipContract)+'-'+LTRIM(@nrContract)
		from contracte where idContract=@idContract
	for xml raw)

select @parXML
