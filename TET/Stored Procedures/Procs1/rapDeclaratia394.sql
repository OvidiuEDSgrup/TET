	--***
Create procedure rapDeclaratia394 @sesiune varchar(50)=null	-->	parametrul sesiune nu va avea efect pana ce nu-l vom trimite catre ftert
		,@data datetime=null, @tert varchar(1000)=''
		,@tip_D394 varchar(1)='R'	--> R=Toate
		,@taxainv varchar(1)='1'	--> 1=Toate, 2=fara, 3=doar taxare inversa
		,@iddeclaratie varchar(100)=null
		,@parxml xml='<row/>'
		,@locm varchar(20)=null
as

declare @facturi varchar(1000), @expandare int, @tert_generare varchar(100),
	@raport bit
if @tert is not null and not exists (select 1 from terti t where t.denumire like @tert)
	set @tert_generare=@tert
else set @tert_generare=''

set @locm=isnull(@locm,'')

select	@raport=(case when isnull(@parxml.value('(row/@iddeclaratie)[1]','varchar(100)'),'')='' then 1 else 0 end)
		--> filtre:
		,@iddeclaratie=isnull(@parxml.value('(row/@iddeclaratie)[1]','int'),@iddeclaratie)
		,@data=isnull(@parxml.value('(row/@data)[1]','datetime'),@data)
		,@tip_D394=isnull(@parxml.value('(row/@f_tip)[1]','varchar(10)'),@tip_D394)
		,@tert=isnull(nullif(@parxml.value('(row/@f_tert)[1]','varchar(1000)'),''),isnull(@tert,''))+'%' --> filtrarea pe tert se face fara null, nefiltrare = ''
		,@facturi=isnull(@parxml.value('(row/@facturi)[1]','varchar(1000)'),'1')
		--> specifice machetei:
		,@expandare=(case left(isnull(@parxml.value('(row/@expandare)[1]','varchar(2)'),'2'),1) when 'd' then 10 when 'n' then 1 when '' then 2 else isnull(@parxml.value('(row/@expandare)[1]','varchar(2)'),2) end)

select @facturi=(case when left(@facturi,1)='d' or @raport=1 then '1' else '0' end)
		
		--,@locm=isnull(@locm,'')
if object_id('tempdb..#D394det') is null
begin
	create table #D394det (subunitate varchar(20))
	exec Declaratia39x_tabela
end
--select * from #D394det
	--/*
begin
	--> ma asigur ca identific unic declaratia:
	if @iddeclaratie is null
	select top 1 @iddeclaratie=d.iddeclaratie
	from declaratii d
		cross apply Continut.nodes('(/*/*)') as T(N)
		where d.Cod = '394'
			--and isnull(T.N.value('(@cuiP)[1]','varchar(80)'),'') <> ''
			and dateadd(d,1-day(data),data)<=dateadd(d,1-day(@data),@data)
/*			and (@tert = '' or rtrim(T.N.value('(@cuiP)[1]','varchar(80)'))
				like '%' + @tert + '%' or rtrim(T.N.value('(@denP)[1]','varchar(200)'))
				like '%' + @tert + '%')
			and (@tip_d394 = '' or rtrim(T.N.value('(@tip)[1]','varchar(1)'))
				like '%' + @tip_d394 + '%')
*/	order by data desc
	
	--> daca nu am primit data exacta ca parametru o setez:
	select @data=data from declaratii d where d.iddeclaratie=@iddeclaratie
	
	--> identific facturile care S-AR PUTEA sa faca parte din declaratia 394 ca valori prin apelarea procedurii de generare - nu se genereaza din nou declaratia, doar se interogheaza baza de date ca si cum s-ar genera:
	if @facturi=1
	exec Declaratia394
		@data=@data
		,@nume_declar='Maier', @prenume_declar='Lucian', @functie_declar='program_test'
		,@caleFisier='c:\websites\ria\formulare\D394_luci'
		,@tip_D394='L'
		,@genRaport=2
		,@tert=@tert_generare
		, @locm=@locm

		
	--> iau datele declaratiei generate:
	create table #d394xml(subunitate varchar(100) default '', tert varchar(100) default '', codfisc varchar(100) default '', dentert varchar(1000) default '',
		tipop varchar(100), baza decimal(15),
		numar varchar(100) default '', numarD varchar(100) default '', tipD varchar(100) default '',
		data datetime default '1901-1-1', factura varchar(100) default '', valoare_factura decimal(15) default 0, explicatii varchar(1000) default '', tip varchar(100) default '',
		cota_tva int default 0, discFaraTVA decimal(15) default 0, discTVA decimal(15) default 0,
		data_doc datetime default '1901-1-1', ordonare varchar(100) default '', drept_ded varchar(100) default '',
		cont_TVA varchar(100) default '', cont_coresp varchar(100) default '', exonerat int default 0, vanzcump varchar(100) default 0,
		numar_pozitie int default 0, tipDoc varchar(100) default '', cod varchar(100) default '', factadoc  varchar(100) default '', contf varchar(100) default ''
		, tara varchar(100) default '', baza_22 decimal(15) default 0, tva_22 decimal(15) default 0
		, tva decimal(15) default 0, codNomenclator varchar(100) default '', invers int default 0, nrFact int default 0
		, setdate int default 0	--> setdate: 1 = valori din dreptul tertilor, 2 = totaluri
		, luna int default 0, an int default 0, cod_nomenclatura varchar(500) default '', denumire_nomenclator varchar(500) default '')
	
	insert into #d394xml(subunitate, tert, codfisc, dentert, tipop, baza, numar, numarD, tipD, data, factura, valoare_factura, explicatii, tip, cota_tva, discFaraTVA,
			discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp, exonerat, vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, tara, baza_22, tva_22, tva, codNomenclator, invers, setdate, nrFact
			)
	select '1' subunitate,
		rtrim(T.N.value('(@cuiP)[1]','varchar(80)')) as tert,
		rtrim(T.N.value('(@cuiP)[1]','varchar(80)')) as codfisc,
		rtrim(T.N.value('(@denP)[1]','varchar(200)')) as dentert,
		rtrim(T.N.value('(@tip)[1]','varchar(1)')) as tipop,
		--(case when rtrim(T.N.value('(@tip)[1]','varchar(1)')) = 'A' then 'Achizitie' else 'Livrare' end) as dentip_op,
		convert(decimal(15,3), T.N.value('(@baza)[1]','float')) as baza,
		'' numar, '' numarD, '' tipD, '' data, '' factura, 0 valoare_factura, '' explicatii,
			'' tip, 0 cota_tva, 0 discFaraTVA,
		0 discTVA, '' data_doc, 1 ordonare, '' drept_ded, '' cont_TVA, '' cont_coresp, '' exonerat,
			'' vanzcump, '' numar_pozitie,
		'' tipDoc, '' cod, '' factadoc, '' contf, '' tara, 0 baza_22, 0 tva_22,
		convert(decimal(15), T.N.value('(@tva)[1]','float')) as tva, '' codNomenclator, 0 invers, 1 setdate
		,convert(decimal(15),T.N.value('(@nrFact)[1]','int')) nrFact
	from declaratii d
	cross apply Continut.nodes('(/*/*)') as T(N)
	where Cod = '394'
		and d.iddeclaratie=@iddeclaratie
		and isnull(T.N.value('(@cuiP)[1]','varchar(80)'),'') <> ''
		and (@tip_D394='R' or @tip_d394=rtrim(T.N.value('(@tip)[1]','varchar(1)')))
		and (@tert = '' or rtrim(T.N.value('(@cuiP)[1]','varchar(80)'))
				like '%' + @tert + '%' or rtrim(T.N.value('(@denP)[1]','varchar(200)'))
				like '%' + @tert + '%')
	
	--> filtrez pe tert dupa denumire si/sau cod
	if rtrim(@tert)<>'%'
	delete d
		from #d394xml d left join terti t on d.codfisc=t.cod_fiscal
	where d.tert not like @tert and t.denumire not like '%'+@tert
	--> elimin facturile pentru care nu exista tert in declaratie:
	delete d from #D394det d where not exists (select 1 from #d394xml x where x.tert=d.tert and x.tipop=(case	when d.invers=1 and d.tipop='L' then 'V'
					when d.invers=1 and d.tipop='A' then 'C' else d.tipop end))
	
	--> inserez facturile (daca este cazul)
	insert into #d394xml(subunitate, tert, codfisc, dentert, tipop, baza, numar, numarD, tipD, data, factura, valoare_factura, explicatii, tip, cota_tva, discFaraTVA,
			discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp, exonerat, vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, tara, baza_22, tva_22, tva,
			codNomenclator, invers, setdate, nrFact
			, cod_nomenclatura)
	select subunitate, rtrim(tert), codfisc, max(dentert), 
			(case	when d.invers=1 and d.tipop='L' then 'V'
					when d.invers=1 and d.tipop='A' then 'C' else d.tipop end)
			tipop, 
			sum(baza), max(numar), max(numarD), max(tipD), data, factura, sum(valoare_factura), max(explicatii),
			max(d.tip), max(d.cota_tva), sum(discFaraTVA), sum(discTVA), max(data_doc), max(ordonare), max(drept_ded), max(cont_TVA), max(cont_coresp), max(exonerat),
			max(vanzcump), max(numar_pozitie), max(tipDoc), max(d.cod), max(factadoc), max(contf), max(tara), sum(baza_22), sum(tva_22), sum(tva), max(codNomenclator),
			max(invers), 0 setdate, 0 nrFact, max(p.valoare) cod_nomenclatura
	from #D394det d
	left join proprietati p on p.tip='nomencl' and p.cod_proprietate='codnomenclatura'	and p.cod=d.codnomenclator
	group by subunitate, tert, codfisc, d.invers, tipop, factura, numar, numard, data, p.valoare
	
	--> completez denumiri pentru anexa:
	update d set denumire_nomenclator=rtrim(n.denumire)
	from #d394xml d
		inner join nomencl n on d.codnomenclator=n.cod --and d.tipop in ('C','V')
	
	--> iau totalurile din xml:
	select rtrim(T.N.value('(@bazaL)[1]','decimal(15,0)')) bazaL
		,rtrim(T.N.value('(@tvaL)[1]','decimal(15,0)')) tvaL
		,rtrim(T.N.value('(@bazaA)[1]','decimal(15,0)')) bazaA
		,rtrim(T.N.value('(@tvaA)[1]','decimal(15,0)')) tvaA
		,rtrim(T.N.value('(@bazaV)[1]','decimal(15,0)')) bazaV
		,rtrim(T.N.value('(@tvaV)[1]','decimal(15,0)')) tvaV
		,rtrim(T.N.value('(@bazaVc)[1]','decimal(15,0)')) bazaVc
		,rtrim(T.N.value('(@tvaVc)[1]','decimal(15,0)')) tvaVc
		,rtrim(T.N.value('(@bazaC)[1]','decimal(15,0)')) bazaC
		,rtrim(T.N.value('(@tvaC)[1]','decimal(15,0)')) tvaC
		,rtrim(T.N.value('(@bazaCc)[1]','decimal(15,0)')) bazaCc
		,rtrim(T.N.value('(@tvaCc)[1]','decimal(15,0)')) tvaCc
		,rtrim(T.N.value('(@nrFactL)[1]','decimal(15,0)')) nrFactL
		,rtrim(T.N.value('(@nrFactA)[1]','decimal(15,0)')) nrFactA
		,rtrim(T.N.value('(@nrFactV)[1]','decimal(15,0)')) nrFactV
		,rtrim(T.N.value('(@nrFactC)[1]','decimal(15,0)')) nrFactC
		,d.continut.value('(*/@luna)[1]','int') an
		,d.continut.value('(*/@an)[1]','int') luna
	into #d394totaluri
	from declaratii d 
	cross apply Continut.nodes('(/*/*)') as T(N)
	where cod='394'
		and d.iddeclaratie=@iddeclaratie
		and isnull(T.N.value('(@nrCui)[1]','varchar(80)'),'') <> ''
	
	--> organizez totalurile astfel incat sa poata fi folosite mai departe de catre raport si macheta:
	insert into #d394xml(baza, tva, nrFact, tipop, setdate, luna, an)
	select d.bazaL, d.tvaL, d.nrFactL, 'L' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','L') union all
	select d.bazaA, d.tvaA, d.nrFactA, 'A' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','A') union all
	select d.bazaV, d.tvaV, d.nrFactV, 'V' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','V') union all
	select d.bazaVc, d.tvaVc, 0, 'Vc' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','V') union all
	select d.bazaC, d.tvaC, d.nrFactC, 'C' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','C') union all
	select d.bazaCc, d.tvaCc, 0 , 'Cc' tipop, 2 as setdate, an, luna from #d394totaluri d where @tip_D394 in ('R','C')

--> date pentru raport:
	if @raport=1
	select * from #d394xml t
	order by (case t.tipop when 'L' then 1 when 'A' then 2 when 'V' then 3 when 'C' then 4 else 5 end), t.dentert, t.factura, t.numarD

-->	date pentru macheta - ierarhie:
	else
	begin
		select(
		select (case p.tipop	when 'L' then 'Livrare (L)'
								when 'A' then 'Achizitii (A)'
								when 'V' then 'Livrare cu taxare inversa (V)'
								when 'C' then 'Achizitii cu taxare inversa (C)' else p.tipop end) tert,
				baza baza, tva tva, nrfact nr_facturi,
				(case p.tipop	when 'L' then 'Livrare (L)'
								when 'A' then 'Achizitii (A)'
								when 'V' then 'Livrare cu taxare inversa (V)'
								when 'C' then 'Achizitii cu taxare inversa (C)' else p.tipop end) dentip_op,
			(select rtrim(codfisc) as tert, rtrim(dentert) dentert, nrfact nr_facturi,
				baza, tva,
					(case p.tipop	when 'L' then 'Livrare (L)'
								when 'A' then 'Achizitii (A)'
								when 'V' then 'Livrare cu taxare inversa (V)'
								when 'C' then 'Achizitii cu taxare inversa (C)' else p.tipop end) dentip_op,
				(select rtrim(d.factura) as tert, rtrim(d.numard) as dentert, d.baza, d.tva
					from #d394xml d
					where setdate=0 and d.tert=t.tert and d.tipop=t.tipop
					for xml raw, type
				)
				,(case when @expandare>2 then 'Da' else 'Nu' end) as _expandat
			from #d394xml t
			where t.setdate='1' and t.tipop=p.tipop
			for xml raw, type),
			(case when @expandare>1 then 'Da' else 'Nu' end) as _expandat
		from #d394xml p
			where p.nrfact>0 and p.setdate=2
		order by (case p.tipop when 'L' then 1 when 'A' then 2 when 'V' then 3 when 'C' then 4 else 5 end)
		for xml raw, type
		)
		for xml path('Ierarhie'), root('Date')
	end
end

if object_id('tempdb..#D394det') is not null
	drop table #D394det
if object_id('tempdb..#D394xml') is not null
	drop table #D394xml
if object_id('tempdb..#D394totaluri') is not null
	drop table #D394totaluri
