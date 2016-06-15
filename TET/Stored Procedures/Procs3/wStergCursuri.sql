create procedure wStergCursuri @sesiune varchar(50), @parXML xml 
as

declare @valuta varchar(8),@data datetime, @mesajeroare varchar(100),@curs float,@tip varchar(1)
begin try		
	select
		@valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),''),
		@tip=isnull(@parXML.value('(/row/row/@tip_valuta)[1]','varchar(1)'),''),
		@data=isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'')

	delete from curs 
	where tip=@tip
		and valuta=@valuta
		and data=@data		 
end try
begin catch
	set @mesajeroare='(wStergCursuri:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch		  
