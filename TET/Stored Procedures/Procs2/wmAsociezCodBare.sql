/*
	procedura folosita pentru asociere cod de bare la un produs
*/
create procedure [dbo].[wmAsociezCodBare] @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wmAsociezCodBareSP' and type='P')
begin
	exec wmAsociezCodBareSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

declare @searchText varchar(80), @utilizator varchar(10), @cod varchar(50), @codbare varchar(50), @msgEroare varchar(2000)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
	
	-- citesc cod produs si cod de bare
	select	@cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(50)'), ''),
			@codbare=ISNULL(@parXML.value('(/row/@codbare)[1]', 'varchar(50)'), '')
	
	-- verific daca mai exista codul de bare in baza de date
	if exists (select * from codbare where Cod_de_bare = @codbare)
	begin
		set @msgEroare = 'Codul de bare ('+rtrim(@codbare)+') este asociat deja produsului: '+ 
			isnull((select max(denumire) from nomencl n inner join codbare c on n.Cod=c.Cod_produs and c.Cod_de_bare=@codbare),'<null>')+'.'
		raiserror(@msgeroare,11,1)
	end
	
	-- insert-ul efectiv
	insert codbare(Cod_de_bare, Cod_produs, UM)
	select @codbare, @cod, 1
	
	-- revin la view-ul din care s-a cerut asocierea codului de bara.
	select 'back(2)' as actiune 
	for xml raw,Root('Mesaje')
end try
begin catch
		set @msgEroare=ERROR_MESSAGE()+'(wmAsociezCodBare)'
end catch

begin try 
	if OBJECT_ID('#coduri') is not null
		drop table #coduri
	if OBJECT_ID('#gestiuni') is not null
		drop table #gestiuni
end try
begin catch end catch

if @msgEroare is not null
	raiserror(@msgEroare,11,1)
	
