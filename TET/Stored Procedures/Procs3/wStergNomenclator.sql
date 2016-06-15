
create procedure wStergNomenclator @sesiune varchar(50), @parXML xml
as
begin try

	declare @cod varchar(20), @mesajeroare varchar(100)
	select @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

	select @mesajeroare=
	  (case	when exists (select 1 from stocuri s where s.cod=@cod and stoc > 0) then 'Articolul are stoc!'
			when exists (select 1 from pozdoc p where p.cod=@cod) then 'Articolul este operat in documente!'
			when exists (select 1 from stocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
			when exists (select 1 from istoricstocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
			when @cod is null then 'Nu a fost trimis codul'
			else '' end)

	if exists(select * from sysobjects where name='LegaturiAtributeNomenclator')
		delete from LegaturiAtributeNomenclator where cod=@cod

	if exists (select * from sysobjects where name='UMProdus')
		delete from UMProdus where cod=@cod
		
	if @mesajeroare=''
		delete from nomencl where cod=@cod
	else 
		raiserror(@mesajeroare, 11, 1)

	/** Daca produsul a fost sters se sterg si preturile existente, ca ulterior, daca se adauga
		un produs cu acelasi cod (dar alta semnificatie), sa nu aiba preturile respective. */
	if exists (select * from preturi where cod_produs = @cod) and not exists (select * from nomencl where cod = @cod)
	begin
		delete from preturi where cod_produs = @cod
	end
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
