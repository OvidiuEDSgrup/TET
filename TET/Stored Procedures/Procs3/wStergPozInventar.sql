
--***
CREATE PROCEDURE [wStergPozInventar] @sesiune VARCHAR(50), @parXML XML
as

declare @idInventar int,@idPozInventar int

	select @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int'),
		@idPozInventar = @parXML.value('(/*/*/@idPozInventar)[1]', 'int')


delete from PozInventar where idInventar=@idInventar and idPozInventar=@idPozInventar
exec wIaPozInventar @sesiune, @parXML

