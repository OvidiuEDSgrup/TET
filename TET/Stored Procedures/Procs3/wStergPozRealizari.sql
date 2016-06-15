
CREATE procedure wStergPozRealizari @sesiune varchar(50), @parXML XML    
as  
 declare  
  @nrCM varchar(20),@idPozRealizari int,@idRealizare int,@eroare varchar(256)  
    
 set @nrCM=@parXML.value('(/row/row/@nrCM)[1]', 'varchar(20)')  
 
 set @idPozRealizari=@parXML.value('(/row/row/@idPozRealizare)[1]', 'int')  
 set @idRealizare=@parXML.value('(/row/@idRealizare)[1]','int')  
   
 begin try  
	  delete from pozdoc where Subunitate='1' and tip='CM' and Numar=@nrCM and detalii.value('(/row/@idRealizare)[1]','int') = @idPozRealizari   
	  delete from pozRealizari where id=@idPozRealizari    
   
	 set @parXML='<row id="'+convert(varchar(20),@idRealizare)+'"/>'  
	 exec wIaPozRealizari @sesiune=@sesiune, @parXML=@parXML
 end try
 begin catch  
  set @eroare=ERROR_MESSAGE()+ ' (wStergPozRealizari)'
  raiserror(@eroare, 11, 1)	
 end catch  
