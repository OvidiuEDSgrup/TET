--***
create procedure wStergCarduriFidelizare(@sesiune varchar(50), @parXML xml)
as

declare @eroare varchar(1000)
set @eroare=''
begin try
	--> extragere date xml
	declare @uid varchar(36)
	select @uid=@parXML.value('(/row/@uid)[1]','varchar(36)')
	--> stergerea
	if not exists (select 1 from CarduriFidelizare c where c.UID=@uid)
		raiserror('Cardul nu exista!',16,1)
	delete CarduriFidelizare where uid=@uid
end try
begin catch
	set @eroare='wStergCarduriFidelizare (linia '+convert(varchar(20),ERROR_LINE())+'):'+char(13)+
		ERROR_MESSAGE()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
