
create procedure wStergJurnale @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @jurnal varchar(20)

begin try
	select @jurnal = @parXML.value('(/row/@jurnal)[1]','varchar(20)')
	delete from jurnale where jurnal=@jurnal
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
