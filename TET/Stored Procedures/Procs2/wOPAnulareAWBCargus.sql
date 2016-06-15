	
create procedure wOPAnulareAWBCargus @sesiune varchar(50), @parXML xml 
as
begin try
	
	declare
		@idContract int, @awb varchar(300), @url varchar(2000), @utilizatorCargus varchar(200), @parolaCargus varchar(300), @contentType varchar(400),
		@raspuns varchar(max), @raspunsXML xml, @err varchar(1000)

	exec luare_date_par 'AR','USRCARGUS',0,0,@utilizatorCargus OUTPUT
	exec luare_date_par 'AR','PASCARGUS',0,0,@parolaCargus OUTPUT	

	select 
		@idContract=@parXML.value('(/*/@idContract)[1]','int')


	select 
		@awb=awb from Contracte where idContract=@idContract 
	select 
		@url='http://webexpress.cargus.ro/custom_print/shipment_import/cancel_awb.php?user='+RTRIM(@utilizatorCargus)+'&parola='+RTRIM(@parolaCargus)+'&awb='+RTRIM(@awb),
		@contentType= 'application/x-www-form-urlencoded'
	
	begin try
		exec httpXMLSOAPRequest
			@uri = @url, 
			@method = 'POST',	
			@requestBody = '',
			@contentType=@contentType,
			@responsetext = @raspuns OUTPUT
			
		select @raspunsXML=CONVERT(XML, @raspuns)		
	end try
	begin catch		
		set @err='Eroare la comunicare cu serverul Cargus ('+ERROR_MESSAGE()+')' 
		RAISERROR(@err, 15, 1)
	end catch

	IF ISNULL(@raspunsXML.value('(/root/is_error/text())[1]','int'),0)=1
	begin
		set @err='Eroare validare Cargus: '+@raspunsXML.value('(/root/err_message/text())[1]','varchar(500)')
		RAISERROR(@err, 15, 1)
	end
	
	declare 
		@docJurnal xml

	update Contracte set AWB=NULL where idContract=@idContract

	set @docJurnal=(select 'Anulat AWB Cargus '+@AWB as explicatii, @idContract idContract,  GETDATE() AS data for xml raw, type)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
		
	select 'S-a anulat cu succes in sistemul Cargus AWB-ul cu numarul: '+@AWB textMesaj, 'Notificare succes' titluMesaj for xml raw, root('Mesaje')

end try
BEGIN CATCH
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
