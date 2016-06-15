--***

create procedure wStergMasina @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20)
Set @cod = @parXML.value('(/row/@codMasina)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

if exists (select 1 from activitati a where a.Masina=@cod)
	raiserror('Masina are fise operate! Nu este permisa stergerea!',16,1)

if @mesajeroare=''
	delete from masini where cod_masina=@cod

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
