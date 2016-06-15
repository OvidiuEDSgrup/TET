
create procedure wOPListaCoduriBareUM @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @utilizator varchar(100), @um varchar(20), @categPret varchar(20), @parXMLPreturi xml

begin try
	select 
		@um = @parXML.value('(/*/@um)[1]','varchar(20)'),
		@categPret = @parXML.value('(/*/@categpret)[1]','varchar(20)')

	select @parXMLPreturi = (select @categpret as categoriePret for xml raw)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	if object_id('tempdb..#preturi') is not null
		drop table #preturi
	
	create table #preturi(cod varchar(20),umprodus varchar(3),nestlevel int)
	insert into #preturi(cod,umprodus,nestlevel)
	select cod,rtrim(@um),@@NESTLEVEL
	from temp_ListareCodBare
	where utilizator=@utilizator

	exec CreazaDiezPreturi
	exec wIaPreturi @sesiune=@sesiune, @parXML=@parXMLPreturi

	update t
	set pret = p.pret_vanzare
	from temp_ListareCodBare t
	inner join #preturi p on t.cod=p.cod
	where utilizator=@utilizator

end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch

