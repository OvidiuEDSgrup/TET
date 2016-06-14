IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_wIaAvizeBon_p')
	DROP PROCEDURE yso_wIaAvizeBon_p
GO
CREATE PROCEDURE yso_wIaAvizeBon_p @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @idContract int, @tipContract varchar(2) ,@nrContract varchar(20), @dataDoc datetime

SELECT @idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), '')
	,@tipContract = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), '')
	,@nrContract = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), '')
	,@nrContract = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), '')

set @parXML = (select f_contract=LTRIM(@nrContract) for xml raw)

select @parXML
