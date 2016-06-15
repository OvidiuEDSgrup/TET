CREATE procedure wOPFinalizareSarcinaCRM @sesiune varchar(50), @parXML xml  
as 
begin try
	declare
		 @idSarcina int

	set @idSarcina= @parXML.value('(/*/@idSarcina)[1]','int')

	update SarciniCRM
		set stare='F'
	where idSarcina=@idSarcina

	
	select
		'S-a finalizat sarcina: ' +convert(varchar(10), @idSarcina) textMesaj, 'Notificare' titluMesaj, 1 as inchideFereastra
	for xml raw, root('Mesaje')

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
