CREATE procedure wOPStergereDocumentPlati @sesiune varchar(50), @parXML xml    
as     
   
 declare @sterginvalid bit ,@stergdoc bit , @datadoc datetime, @nrdoc varchar(20) , @stare int
   
 select @sterginvalid=ISNULL(@parXML.value('(/parametri/@sterginvalid)[1]', 'bit'), 0),  
		@stergdoc=ISNULL(@parXML.value('(/parametri/@stergdoc)[1]', 'bit'), 0),  
		@datadoc=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'1901-01-01'),  
		@nrdoc=isnull(@parXML.value('(/parametri/@numar)[1]', 'varchar(50)'), ''),  
		@stare=isnull(@parXML.value('(/parametri/@stare)[1]', 'int'), '')  
if @stare<>0
	raiserror('Documentul nu este in stare Operabil, operatie de stergere nepermisa!',16,1)
if @sterginvalid=1  
   delete from generareplati where Numar_document=@nrdoc and data=@datadoc and abs(val1)<0.01 and stare=0  
if @stergdoc=1  
   delete from generareplati where Numar_document=@nrdoc and data=@datadoc and stare=0
  
declare @docXMLIaPozGP xml    
set @docXMLIaPozGP = '<row numar="' + rtrim(@nrdoc) + '" data="' + convert(varchar(20), @datadoc, 101)+'"/>'    
select @docXMLIaPozGP  
exec wIaPozGP @sesiune=@sesiune, @parXML=@docXMLIaPozGP     
