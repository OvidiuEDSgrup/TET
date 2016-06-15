CREATE PROCEDURE wmSalvarePoza @sesiune varchar(50), @parXML xml
AS
begin try
	declare @idPozRealizare int, @numepoz varchar(200)


	select 
		 @idPozRealizare=@parXML.value('(/*/@idPozRealizare)[1]','int'),
		 @numepoz=@parXML.value('(/*/@numepoz)[1]','varchar(100)')


	delete pozeria where tip='P' and cod=@idPozRealizare
	insert into pozeria (tip, cod,fisier)
	select 'P', @idPozRealizare, @numepoz

	select 'back(1)' as actiune for xml raw, root('Mesaje')
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
