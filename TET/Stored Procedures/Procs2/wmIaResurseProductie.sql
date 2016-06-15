CREATE PROCEDURE wmIaResurseProductie @sesiune varchar(50), @parXML xml
AS
set transaction isolation level read uncommitted
if exists(select * from sysobjects where name='wmIaResurseProductieSP' and type='P')
begin
	exec wmIaResurseProductieSP @sesiune=@sesiune, @parXML=@parXML output
	return 0
end

begin try
	declare 
		@search varchar(500), @cod_exact varchar(500)
	select
		@search='%'+ISNULL(@parXML.value('(/*/@searchText)[1]','varchar(200)'),'%')+'%',
		@cod_exact = @parXML.value('(/*/@searchText)[1]','varchar(200)')

	select
		id as id, '1' as _toateAtr, rtrim(ltrim(descriere)) as denumire, 'Tip: '+(case tip when 'L' then 'Loc munca' when 'U' then 'Utilaj' when 'E' then 'Extern' end) as info, cod as cod,
		'wmIaPlanificariResursa' procdetalii
	from Resurse
	where (cod like @search or descriere like @search) OR cod=@cod_exact
	for xml raw, root('Date')

	select '1' as areSearch for xml raw, root('Mesaje')
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
