--***
CREATE procedure yso_wScriuUM  @sesiune varchar(50), @parXML xml--, @um varchar(3), @denumire varchar(30)
as  
declare @um varchar(3), @denumire varchar(30)
Set @um = @parXML.value('(/row/@um)[1]','varchar(3)')
Set @denumire = @parXML.value('(/row/@denumire)[1]','varchar(30)')

begin try
if exists (select * from um where UM = @um)  
begin  
 update um set Denumire= @denumire
 where UM  = @um  
end  
else   
begin  
 insert into um (UM, Denumire)  
 values (upper(@um), @denumire)  
end  
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
