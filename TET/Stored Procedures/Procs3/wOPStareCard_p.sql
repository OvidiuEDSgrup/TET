
CREATE PROCEDURE wOPStareCard_p @sesiune varchar(50), @parXML xml
AS
DECLARE @uid varchar(36)

	SELECT @uid = @parXML.value('(/row/@uid)[1]','varchar(36)')

	SELECT c.blocat AS blocat
		FROM CarduriFidelizare c
		WHERE uid = @uid
	FOR XML RAW
