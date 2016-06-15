create procedure  [dbo].[wStergAngajamenteBugetareP] @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @indbug varchar(20),@numar varchar(9),@data datetime        
        
     select
         @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)'),
         @numar = @parXML.value('(/row/@numar)[1]','varchar(9)'),
         @data = @parXML.value('(/row/@data)[1]','datetime')         

	declare @mesajeroare varchar(100)
	if exists (select 1 from registrucfp r where r.indicator=@indbug and r.numar=@numar and r.data=@data) 
        raiserror('Angajamentul bugetar are vize cfp si nu poate fi sters!!',11,1) 
   
	delete from angbug where indicator=@indbug and numar=@numar and data=@data

end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
