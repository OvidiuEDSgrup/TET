
create proc wIaProprietatiNomencl @sesiune varchar(250), @parXML xml
as
	
	declare @cod varchar(20)

	select @cod=@parXML.value('(/*/@cod)[1]','varchar(20)')
	
	select 
		rtrim(p.cod_proprietate) codproprietate, rtrim(cp.descriere) denproprietate, p.valoare valoare, convert(varchar(200), '') denumire, cp.validare validare, cp.catalog catalog
	into #propr
	from proprietati p
	JOIN catproprietati cp on p.cod_proprietate=cp.cod_proprietate and p.cod=@cod

	update p
		set denumire=rtrim(vp.descriere)
	from #propr p
	JOIN valproprietati vp on p.codproprietate=vp.cod_proprietate and p.validare=1 and vp.valoare=p.valoare

	update p
		set denumire=rtrim(t.denumire)
	from #propr p
	JOIN terti t on p.validare=2 and p.catalog='T' and p.valoare=t.tert

	update p
		set denumire=rtrim(t.denumire_gestiune)
	from #propr p
	JOIN gestiuni t on p.validare=2 and p.catalog='G' and p.valoare=t.cod_gestiune

	update p
		set denumire=rtrim(t.denumire)
	from #propr p
	JOIN lm t on p.validare=2 and p.catalog='L' and p.valoare=t.cod


	update #propr set denumire=valoare where denumire=''


	select * from #propr for xml raw, root('Date')
