create procedure wOPModificareAntetNC @sesiune varchar(50),@parXML xml
as
declare @mesaj varchar(500),@numar varchar(10),@data datetime,@o_numar varchar(10),@o_data datetime
begin try
	set @numar=@parXML.value('(/parametri/@numar)[1]','varchar(10)')
	set @data=@parXML.value('(/parametri/@data)[1]','datetime')
	set @o_numar=@parXML.value('(/parametri/@o_numar)[1]','varchar(10)')
	set @o_data=@parXML.value('(/parametri/@o_data)[1]','datetime')
	
	update pozncon set numar=@numar,data=@data
	where subunitate='1' and tip='NC' and numar=@o_numar and data=@o_data

end try
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror (@mesaj,11,1)
end catch
