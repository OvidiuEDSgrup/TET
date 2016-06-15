
CREATE PROCEDURE wOPPrefiltrareTertiOP @sesiune VARCHAR(50), @parXML XML
AS
	declare @idOP int, @tert varchar(20), @grupa varchar(20), @lm varchar(20)

	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @grupa=@parXML.value('(/*/@grupa)[1]','varchar(20)')
	set @lm=@parXML.value('(/*/@lm)[1]','varchar(20)')
	set @idOp=@parXML.value('(/*/@idOP)[1]','int')

	SELECT 'Actualizare sume facturi' nume, 'MS' codmeniu, 'O' tipmacheta,
			(SELECT @tert tert, @grupa grupa, @idOP idOP, @lm lm for xml raw, type) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
