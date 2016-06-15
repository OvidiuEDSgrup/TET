--***
create procedure wOPDescarcaBon @sesiune varchar(50), @parXML xml
as
begin try
declare @UID varchar(90)
	select @UID = isnull(@parXML.value('(/parametri/@UID)[1]','varchar(50)'),'')
	declare @descarcInput xml
	set @descarcInput = (select @UID as UID for xml raw)
 exec wDescarcBon @sesiune=@sesiune, @parXML=@descarcInput
 
 
 end try
 begin catch
	declare @eroare varchar(500)
	set @eroare='wOPDescarcaBon'+ERROR_MESSAGE()
		raiserror(@eroare,16,1)
 end catch
