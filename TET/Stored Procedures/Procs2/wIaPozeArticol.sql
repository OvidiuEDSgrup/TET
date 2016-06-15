
CREATE PROCEDURE wIaPozeArticol @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @calePoze varchar(300), @tip varchar(2)

select @tip = @parXML.value('(/row/@tip)[1]','varchar(2)')

if @tip = 'PZ'
	SET @cod = @parXML.value('(/row/@cod)[1]', 'varchar(20)')

if @tip='PG'
	SET @cod = @parXML.value('(/row/@grupa)[1]', 'varchar(20)')

select @calePoze=rtrim(ltrim(val_alfanumerica))+'/formulare/uploads/'
from par where Tip_parametru='AR' and Parametru='URL'

if @calePoze not like'http%'
	set @calePoze='http://'+@calePoze

SELECT isnull(pozitie,0) AS nr,(case  when (fisier like '%www%') or (fisier like 'http%') then '<a href="' + rtrim(Fisier) + '" target="_blank" /><u> Click aici </u></a>'
		else '<a href="' + @calePoze +rtrim(Fisier) + '" target="_blank" /><u> Click aici </u></a>' end )
		 AS link, RTRIM(fisier) AS poza
FROM pozeria
WHERE cod = @cod
	and tip = (case when @tip='PZ' then 'N' when @tip='PG' then 'G' end)
FOR XML raw, root('Date')
