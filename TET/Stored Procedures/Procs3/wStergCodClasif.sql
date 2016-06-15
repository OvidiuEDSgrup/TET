--***
create procedure wStergCodClasif @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

declare @mesajeroare varchar(500)
set @mesajeroare=''

select @mesajeroare=
  (case	when exists (select 1 from mfix where left(Subunitate,4)<>'DENS' and left(Cod_de_clasificare,LEN(@cod))=@cod) then 'Codul ales este asociat la cel putin un mijloc fix sau este parinte al unui cod asociat la cel putin un mijloc fix!'
		when @cod is null then 'Nu a fost ales articolul pt. stergere!'
		else '' end)

if @mesajeroare=''
	delete from CodClasif where Cod_de_clasificare=@cod
else 
	raiserror(@mesajeroare, 11, 1)
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
