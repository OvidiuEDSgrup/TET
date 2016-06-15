--***
create procedure [dbo].wOPCardBCRExcel_p @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on
begin try
	declare @utilizator varchar(100), @mesaj varchar(250), @idOP int
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator = @utilizator output

	set @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	select 'cardBCRExcel' as procedura, @idOP as idOP, 'Card_BCR.xlsx' as numefisier 
	for xml raw
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPCardBCRExcel_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
end catch
