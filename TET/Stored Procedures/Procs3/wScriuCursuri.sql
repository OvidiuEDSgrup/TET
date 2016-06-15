--***
CREATE procedure wScriuCursuri @sesiune varchar(50),@parXML xml
as  
Declare @mesaj varchar(250), @data datetime,@valuta varchar(3), @update int, @curs float, @o_data datetime
select
	@valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),''),
	@update=isnull(@parXML.value('(/row/row/@update)[1]','int'),0),
	@curs=isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
	@data=isnull(@parXML.value('(/row/row/@data)[1]','datetime'),GETDATE()),
	@o_data=isnull(@parXML.value('(/row/row/@o_data)[1]','datetime'),'')

begin try
	if @update=1
	begin  
		update curs set Data=@data, curs= @curs where valuta=@valuta and data=@o_data
	end  
	else   
	begin  
		insert into curs (Valuta, Data, Tip, Curs)  
		values (@valuta, @data, '', @curs)  
   	end  
end try
begin catch
	set @mesaj ='(wScriuCursuri:) '+ ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch   
  
--Select @errCode as errcode  for xml raw
