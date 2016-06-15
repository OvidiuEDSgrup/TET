--***
create procedure yso_wStergNomenclator @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

select @mesajeroare=
  (case	when exists (select 1 from stocuri s where s.cod=@cod and stoc > 0) then 'Articolul are stoc!'
		when exists (select 1 from pozdoc p where p.cod=@cod) then 'Articolul este operat in documente!'
		when exists (select 1 from stocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
		when exists (select 1 from istoricstocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
		when exists (select 1 from pozcon p where p.cod=@cod) then 'Articolul este operat in contracte/comenzi!'
		when @cod is null then 'Nu a fost trimis codul'
		else '' end)

if @mesajeroare=''
	delete from nomencl where cod=@cod
else 
	raiserror(@mesajeroare, 11, 1)
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
