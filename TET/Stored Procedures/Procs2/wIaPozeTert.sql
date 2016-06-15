
CREATE PROCEDURE wIaPozeTert @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @calePoze varchar(300)

SET @cod = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
select @calePoze=rtrim(ltrim(val_alfanumerica))+'/formulare/uploads/'
from par where Tip_parametru='AR' and Parametru='URL'
select @cod
if @calePoze not like'http%'
	set @calePoze='http://'+@calePoze

SELECT row_number() OVER (
		ORDER BY Fisier
		) AS nr,(case  when (fisier like '%www%') or (fisier like 'http%') then '<a href="' + rtrim(Fisier) + '" target="_blank" /><u> Click aici </u></a>'
		else '<a href="' + @calePoze +rtrim(Fisier) + '" target="_blank" /><u> Click aici </u></a>' end )
		 AS link, RTRIM(fisier) AS poza
FROM pozeria
WHERE tip = 'T'
	AND cod = @cod
FOR XML raw, root('Date')
