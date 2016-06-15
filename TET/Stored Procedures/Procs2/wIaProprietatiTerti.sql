--***
create procedure wIaProprietatiTerti @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@tert varchar(20)

	set @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')

	select
		rtrim(p.Cod) as codtert,
		rtrim(p.Cod_proprietate) as codproprietate,
		rtrim(cp.Descriere) as denproprietate,
		rtrim(p.Valoare) as valoare,
		convert(varchar(200), '') as denumire,
		rtrim(p.Valoare_tupla) as valoare_tupla,
		cp.validare validare, cp.catalog catalog
	into #proprietatiTerti
	from proprietati p
	inner join catproprietati cp on p.cod_proprietate = cp.cod_proprietate and p.cod = @tert
	where p.Tip = 'TERT'
		and p.Cod = @tert

	update p
		set denumire = rtrim(vp.descriere)
	from #proprietatiTerti p
	inner join valproprietati vp on p.codproprietate = vp.cod_proprietate and p.validare = 1 and vp.valoare = p.valoare

	update p
		set denumire = rtrim(t.denumire)
	from #proprietatiTerti p
	JOIN terti t on p.validare = 2 and p.catalog = 'T' and p.valoare = t.tert

	update p
		set denumire = rtrim(t.denumire_gestiune)
	from #proprietatiTerti p
	JOIN gestiuni t on p.validare = 2 and p.catalog = 'G' and p.valoare = t.cod_gestiune

	update p
		set denumire = rtrim(lm.denumire)
	from #proprietatiTerti p
	inner join lm on p.validare = 2 and p.catalog = 'L' and p.valoare = lm.cod


	update #proprietatiTerti
	set denumire = valoare
	where denumire = ''

	select * from #proprietatiTerti
	for xml raw, root('Date')

	if object_id('tempdb..#proprietatiTerti') is not null
		drop table #proprietatiTerti

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
