--***
/*
exec Declaratia394
	@sesiune='', @data='2015-03-31'
	,@nume_declar='', @prenume_declar='', @functie_declar=''
	,@cui=null, @den=null, @adresa=null
	,@telefon=null,@fax=null, @mail=null
	,@caleFisier=''
	,@dinRia=1		-->	par care determina modul de scriere pe harddisk
	,@tip_D394='L'	-->	L=lunar, T=trimestrial, S=semestrial, A=anual
	,@cifR=null, @denR=null, @adresaR=null, @telefonR=null,
				@faxR=null, @mailR=null
	, @genRaport=1	-- daca procedura este apelata pentru generare raport
	,@siTXT=0	--> 1=se va genera si fisier txt
	,@tert='5031652'	--> filtrare pe tert pentru rapDeclaratia394
	,@locm=''	--> filtrare pe loc de munca pentru rapDeclaratia394

*/
Create procedure Declaratia394
	(@sesiune varchar(50)='', @data datetime--, @datasus datetime
	,@nume_declar varchar(200), @prenume_declar varchar(200), @functie_declar varchar(100)
	,@cui varchar(100)=null, @den varchar(100)=null, @adresa varchar(100)=null
	,@telefon varchar(100)=null,@fax varchar(100)=null, @mail varchar(100)=null
	,@caleFisier varchar(300)	--> calea completa, incluzand fisierul; daca fisierul nu este dat se creeaza unul in functie de data, tip si cod fiscal firma
	,@dinRia int=1		-->	par care determina modul de scriere pe harddisk
	-->	decl394:
	,@tip_D394 varchar(1)	-->	L=lunar, T=trimestrial, S=semestrial, A=anual
	--/**	--necunoscute (trebe, nu trebe?):
	,@cifR varchar(20)=null, @denR varchar(200)=null, @adresaR varchar(1000)=null, @telefonR varchar(15)=null,
				@faxR varchar(15)=null, @mailR varchar(200)=null,
	@genRaport int=0	-- daca procedura este apelata pentru generare raport; 1=vechi, pt o eventuala compatibilitate, 2=raportul declaratie 394
	,@siTXT bit=1	--> 1=se va genera si fisier txt
	,@tert varchar(100)=''	--> filtrare pe tert pentru rapDeclaratia394
	,@locm varchar(100)=''	--> filtrare pe loc de munca pentru rapDeclaratia394
	)
as

declare @eroare varchar(2000)
set @eroare=''
begin try
	declare @datasus datetime, @datajos datetime
	select @data=dbo.bom(@data)
	select @datajos=(case @tip_D394 when 'L' then @data
									when 'T' then dateadd(M,-(month(@data)-1) % 3,@data)
									when 'S' then dateadd(M,-(month(@data)-1) % 6,@data)
									when 'A' then dateadd(M,-month(@data)+1,@data)
									else @datajos end),
			@datasus=(case @tip_D394 when 'L' then dbo.eom(@data)
									when 'T' then dbo.eom(dateadd(M,-(month(@data)-1) % 3 +2,@data))
									when 'S' then dbo.eom(dateadd(M,-(month(@data)-1) % 6 + 5,@data))
									when 'A' then dbo.eom(dateadd(M,-month(@data)+12,@data))
									else @datajos end)

	declare @fisier varchar(100), @pozSeparator int, @caleCompletaFisier varchar(300)
	select	@pozSeparator=len(@caleFisier)-charindex('\',reverse(rtrim(@caleFisier))),
			@caleCompletaFisier=@caleFisier
	select	@fisier=substring(@caleFisier,@pozSeparator+2,len(@caleFisier)-@pozseparator+1),
			@caleFisier=substring(@caleFisier,1,@pozseparator)

	if object_id('tempdb.dbo.##tmpdecl') is not null drop table ##tmpdecl
	if object_id('tempdb.dbo.#tCoduriCereale') is not null drop table #tCoduriCereale
	if object_id('tempdb.dbo.#detaliereSFIF') is not null drop table #detaliereSFIF
	if object_id('tempdb.dbo.#D394') is not null drop table #D394
	if object_id('tempdb.dbo.#D394cif') is not null drop table #D394cif
	if object_id('tempdb.dbo.#D394tmp') is not null drop table #D394tmp
--	if object_id('tempdb.dbo.#D394det') is not null drop table #D394det
	if object_id('tempdb.dbo.#D394facttmp') is not null drop table #D394facttmp
	if object_id('tempdb.dbo.#D394fact') is not null drop table #D394fact

	declare @proprietateNomenclatorCoduriCereale varchar(100), @coduriCereale varchar(3000),	-->	coduri de nomenclatura combinata pt cereale si plante tehnice
			@parXML xml, @dataFactCumpInPerioada int, @pecoduri int, @siICPCplatitor int, @D394SFIFCereale int, 
			@versiune varchar(1)	--> variabila pt. versiune declaratie
	select	@proprietateNomenclatorCoduriCereale='CODNOMENCLATURA',
			--@coduriCereale='10011000,10019010,10019091,10019099,10020000,100300,1005,120100,1205,120600,121291',
			@parXML=(select @datajos datajos, @datasus datasus, 1 as pecoduri for xml raw),
			@dataFactCumpInPerioada=1, -- ar putea fi setare "Data facturilor de cumparare sa fie in perioada selectata"
			@pecoduri=1	-- (case when year(@datajos)<2012 then 0 else 1 end) ar trebui ca pentru perioade anterioare anului 2012, @pecoduri=0. Momentan nu tratam aici acest caz (Ghita)
	set @siICPCplatitor=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='ICPCPLAT'),0)
	set @D394SFIFCereale=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='394SFIFCE'),0)

--	>versiune=1 pentru perioade anterioare ultimei perioade din 2013, versiune=2 pentru perioadele >= ultima perioada din 2013. Incepand cu versiunea 2 se declara si numarul de facturi.
	set @versiune=(case when @tip_D394='L' and @data>='12/01/2013' or @tip_D394='T' and @data>='10/01/2013' 
		or @tip_D394='S' and @data>='07/01/2013' or @tip_D394='A' and @data>='01/01/2013' then '2' else '1' end)

--	inlocuit apelul functiei fDeclaratia394 cu continutul ei
/*	select codfisc as cuiP, dentert, tipop, convert(decimal(15),baza) baza, convert(decimal(15),tva) tva, cod
		into #D394
	 from dbo.fDeclaratia394(@sesiune, @datajos, @datasus) f*/
				
	create table #tCoduriCereale (cod varchar(20), codNomenclatura varchar(20))
	insert into #tCoduriCereale (cod, codNomenclatura)
	select cod, valoare as codNomenclatura from proprietati 
		where tip='NOMENCL'
			--and charindex(','+rtrim(valoare)+',',','+@coduriCereale+',')>0
			and cod_proprietate=@proprietateNomenclatorCoduriCereale

	create table #D394cif 
		(codtert char(13), codfisc char(20), dentert char(80), tipop char(1), baza float, tva float, 
		codNomenclator varchar(20) default '', invers int default 0)
	create table #D394tmp 
		(codtert char(13), codfisc char(20), dentert char(80), tipop char(1), nrfacturi int, baza float, tva float, 
		codNomenclator varchar(20), invers int default 0)	--> invers:	1=taxare inversa; altceva=nu e taxare inversa
	create table #D394fact
		(codfisc char(20), tipop char(1), invers int default 0, nrfacturi int)
	create table #D394facttmp
		(codfisc char(20), tipop char(1), invers int default 0, nrfacturi int)

	if object_id('tempdb..#D394det') is null
	begin
		create table #D394det (subunitate varchar(20))
		exec Declaratia39x_tabela
	end

	create table #tvavanz (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvavanz'
	exec TVAVanzari @DataJ=@datajos, @DataS=@datasus, @ContF='', @ContFExcep=0, @Gest='', @LM=@locm, @LMExcep=0, @Jurnal=''
		,@ContCor='', @TVAnx=0, @RecalcBaza=0, @CtVenScDed='', @CtPIScDed='', @nTVAex=8, @FFFBTVA0='1'
		,@SiFactAnul=0, @TipCump=1, @TVAAlteCont=0, @DVITertExt=0, @OrdDataDoc=0, @OrdDenTert=0
		,@Tert=@tert, @Factura='', @D394=1, @FaraCump=1, @parXML='<row />'

	create table #tvacump (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvacump'
	exec TVACumparari @DataJ=@datajos, @DataS=@datasus, @ContF='', @Gest='', @LM=@locm, @LMExcep=0, @Jurnal='', @ContCor='', @TVAnx=0, @RecalcBaza=0
			,@nTVAex=0, @FFFBTVA0='0', @SFTVA0='2', @IAFTVA0=0, @TipCump=9, @TVAAlteCont=2, @DVITertExt=0
			,@OrdDataDoc=0, @Tert=@tert, @Factura='', @UnifFact=0, @FaraVanz=1, @nTVAned=2, @parXML='<row />'

	--	apel procedura specifica Declaratia394SP care permite completarea/modificarea tabelelor #tvacump si #tvavanz
	if exists (select 1 from sysobjects o where o.type='P' and o.name='Declaratia394SP') 
		exec Declaratia394SP @parXML 

--	inceput functie frapTVApecoduridet
	insert into #D394det
			(subunitate, numar, numarD, tipD, data, factura, tert, valoare_factura, baza, tva, explicatii,
			tip, cota_tva, discFaraTVA, discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp, exonerat, 
			vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, codfisc, dentert, tipop, codNomenclator, invers)
	select 
		d.subunitate, d.numar, d.numarD, d.tipD, d.data, d.factura, d.tert, d.valoare_factura,
		round(convert(decimal(15,3),d.baza_22),3) baza, round(convert(decimal(15,3),d.tva_22),3) tva, d.explicatii,
		d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, d.drept_ded, d.cont_TVA, d.cont_coresp, d.exonerat,
		d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf, --codfisc, dentert, tipop, codNomenclator, coloana
		replace(replace(replace(isnull(t.cod_fiscal,(case when d.tipD='FA' or d.tipD='BP' and d.tip='F'
				then d.cont_TVA else '' end)), 'RO', ''), 'R', ''), ' ','') as codfisc,
		isnull(t.denumire, d.explicatii) as dentert, 'L' as tipop,
		d.cod as codNomencl, 
		(case when dbo.coloanaTVAVanzari(d.cota_tva, d.drept_ded, d.exonerat, d.vanzcump, d.cont_coresp, '', isnull(it.zile_inc, 0), tari.teritoriu,
										isnull(n.tip, ''), d.tert, d.factura, d.tipD, d.numar, d.data, d.numar_pozitie, d.numarD, d.tipDoc, d.cod)
			= 10 then 1 else 0 end) as invers
	from #tvavanz d
			--> deocamdata @nTVAex a ramas 8 in loc de 18, deoarece nu functiona corect taxarea inversa.
		inner join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.tipD<>'FA' and not (d.tipD='BP' and d.tip='F')
		left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
		left outer join nomencl n on n.cod=d.cod
		left outer join doc on doc.subunitate=d.subunitate and doc.tip=d.tipDoc and doc.numar=d.numar and doc.data=d.data_doc
		left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
		left outer join tari on cod_tara=isnull(doc.detalii.value('/row[1]/@taraexp', 'varchar(20)'),i.cont_intermediar)
	where isnull(it.zile_inc, 0)=0 /*and d.cota_TVA in (9,19,24)*/ and d.vanzcump='V' and (@pecoduri=1 or d.exonerat=0)
		and (d.tipD<>'FA' and not (d.tipD='BP' and d.tip='F') 
		-- verificare ca tertii sunt platitori de TVA
		and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=t.Tert and tt.tipf='F' and tt.dela<=d.data /*@datasus*/ and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' 
		--and left(isnull(it.grupa13,''),1)<>'1' --and t.tert is not null
			or d.tipD='BP' and d.tip='F' and charindex('R', d.cont_TVA)>0)
		and (d.TipDoc<>'IC' or @siICPCplatitor=1 and d.numar not like 'ITVA%') -- Ghita, 21.02.2012: se vor lua, totusi, IC-urile de la terti platitori de TVA
		and not (d.tipD='FA' and d.factura='FACT.UA' and d.tert='ABON.UA')
		and d.tipDoc<>'IB' -- sa nu ia avansurile in D.394
	union all
	
	select d.subunitate, d.numar, d.numarD, d.tipD, d.data, d.factura, d.tert, d.valoare_factura,
		round(convert(decimal(15,3),d.baza_22),3) baza, round(convert(decimal(15,3),d.tva_22),3) tva, d.explicatii,
		d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, d.drept_ded, d.cont_TVA, d.cont_coresp, d.exonerat,
		d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf, --codfisc, dentert, tipop, codNomenclator, coloana
		replace(replace(replace(isnull(t.cod_fiscal, ''), 'RO', ''), 'R', ''), ' ','') as codfisc, 
		isnull(t.denumire, d.explicatii) as dentert, 'A' as tipop, d.cod,
		(case when dbo.coloanaTVACumparari (d.cota_tva, exonerat, vanzcump, cont_coresp, '', isnull(it.zile_inc, 0), Teritoriu, isnull(n.tip, ''), d.tert,
					d.factura, (case when d.tipD='RM' then d.tipDoc else d.tipD end), d.numar, d.data_doc, d.numar_pozitie, d.numarD, d.tipDoc, d.cod)
			= 17 then 1 else 0 end) invers
	from #tvacump d
		inner join terti t on t.subunitate=d.subunitate and t.tert=d.tert
		left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
		left outer join nomencl n on n.cod=d.cod
		left outer join doc on doc.subunitate=d.subunitate and doc.tip=d.tipDoc and doc.numar=d.numar and doc.data=d.data_doc
		left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
		left outer join tari on cod_tara=isnull(doc.detalii.value('/row[1]/@taraexp', 'varchar(20)'),i.cont_intermediar)
	where isnull(it.zile_inc, 0)=0 /*and d.cota_TVA in (9,19,24)*/ and d.vanzcump='C' and (@pecoduri=1 or d.exonerat=0)
		and d.tipD<>'FA' 
		-- verificare ca tertii sunt platitori de TVA
		and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=t.Tert and tt.tipf='F' and tt.dela<=d.data /*@datasus*/ and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' 
		--and left(isnull(it.grupa13,''),1)<>'1' --and t.tert is not null 
		and (@dataFactCumpInPerioada=0 or d.data between @datajos and @datasus) -- campul "data" reprezinta data facturii
		--and (d.TipDoc<>'PC' or (@siICPCplatitor=1 or d.data>='2013-03-14') and d.numar not like 'ITVA%') 
		--and (d.tipDoc<>'RC' or d.data>='2013-03-14') -- PC si RC de la 14.03.2013 sa se ia in D. 394 indiferent de setarea ('GE','ICPCPLAT')
		and (d.TipDoc<>'PC' or (@siICPCplatitor=1 or d.data between '2013-03-14' and '2013-07-31' or (ISNULL(d.detalii.value('(/*/@_fsimplificata)[1]','bit'),0)=0 or d.data>'2016-12-31')) and d.numar not like 'ITVA%') 
		and (d.tipDoc<>'RC' or d.data between '2013-03-14' and '2013-07-31' or d.data>'2016-12-31') -- PC si RC de la 14.03.2013 sa se ia in D. 394 indiferent de setarea ('GE','ICPCPLAT')
		-- mai sus tratare Ordin OPANAF NR. 2986 DIN  9 SEPTEMBRIE 2013
		and d.tipDoc<>'PF' -- sa nu ia avansurile in D.394
		
	update r set tva=r.baza*r.cota_tva/100		--> se calculeaza tva-ul pe loc pt inversat (in bd e 0)
	from #D394det r where r.exonerat=2 and r.tva=0 and r.cota_tva<>0

--	Nu recomandam varianta de a opera pt. cereale documente de tip SF/IF. 
--	In cazul cerealelor documentele de tip SF/IF se vor opera prin RM/AP pe cod de tip serviciu care va avea atasat un cod de Nomenclatura combinata pt. cereale
	if @D394SFIFCereale=1
	begin
	--> se inlocuiesc SF-urile si IF-urile cu date de pe facturile propriu-zise (doc RM, respectiv AP); feliere pe coduri si calcul ponderat al valorilor
		create table #detaliereSFIF (tip varchar(2), factura varchar(20), tert varchar(20), cod varchar(20), baza decimal(15,3), codNomenclatura varchar(20), pondere decimal(15,5))
	
		insert into #detaliereSFIF(tip, factura, tert, cod, baza, codNomenclatura, pondere)
		select (case p.tip when 'RM' then 'SF' when 'AP' then 'IF' end) tip, p.factura, p.tert, p.cod,
				sum(p.Cantitate*p.Pret_valuta) baza, isnull(pr.valoare,'') as codNomenclatura, 0 pondere
		from pozdoc p left join proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate=@proprietateNomenclatorCoduriCereale and pr.Cod=p.Cod
		where exists (select 1 from #D394det r 
				where ((r.tipDoc='SF' and p.Tip='RM') and r.exonerat=1  or (r.tipDoc='IF' and p.Tip='AP') and r.exonerat=2)
					--and r.exonerat=1 
					and r.factadoc<>''
					and p.factura=r.factadoc and p.Tert=r.tert
				)
		group by p.tip, p.factura, p.tert, p.cod, pr.valoare
	
		update d set pondere=(case when t.total=0 then 0 else d.baza/t.total end)
		from #detaliereSFIF d inner join (select sum(t.baza) total, tip, factura, tert from #detaliereSFIF t group by tip, factura, tert) t 
				on t.tip=d.tip and t.factura=d.factura and t.tert=d.tert

		--	am scos conditia de @exonerat=1 din insert/delete-ul de mai jos intrucat la insert in #detaliereSFIF se preiau doar acele documente cu @exonerat corespunzator.
		insert into #D394det(subunitate, numar, numarD, tipD, data, factura, tert, valoare_factura, baza, tva, explicatii,
				tip, cota_tva, discFaraTVA, discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp, exonerat,
				vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, codfisc, dentert, tipop, codNomenclator, invers)
		select max(r.subunitate), max(r.numar), max(r.numarD), max(r.tipD), max(r.data), max(r.factura), max(r.tert), sum(r.valoare_factura)*max(p.pondere),
				sum(r.baza)*max(p.pondere), sum(r.tva)*max(p.pondere), max(r.explicatii), max(r.tip), max(r.cota_tva), max(r.discFaraTVA), max(r.discTVA),
				max(r.data_doc), max(r.ordonare), max(r.drept_ded), max(r.cont_TVA), max(r.cont_coresp), max(r.exonerat), max(r.vanzcump), max(r.numar_pozitie),
				max(r.tipDoc), p.cod, max(r.factadoc), max(r.contf), max(r.codfisc), max(r.dentert), max(r.tipop), p.cod, max(r.invers+10)
		from #D394det r inner join #detaliereSFIF p on p.tip=r.tipDoc and p.factura=r.factadoc and p.tert=r.tert /*and r.exonerat=1*/ and r.factadoc<>''
		group by p.tip, p.factura, p.tert, p.cod

		delete r from #D394det r inner join #detaliereSFIF p on p.tip=r.tipDoc and p.factura=r.factadoc and p.tert=r.tert /*and r.exonerat=1*/ and rtrim(r.factadoc)<>'' and r.invers<10
	end
	update #D394det set invers=invers-10 where invers>=10
	--	sfarsit functie frapTVApecoduridet

	-- sa nu aduc facturi de prestari cu taxare inversa - nu intra la D. 394 (?)
	delete from #D394det
	where tipDoc='RP' and invers=1 and tipOp='A'

	--	apel procedura specifica Declaratia394SP care permite completarea/modificarea tabelei #D394det
	if exists (select 1 from sysobjects o where o.type='P' and o.name='Declaratia394SP1') 
		exec Declaratia394SP1 @parXML 

	--	grupare date pentru stabilire numar de facturi pe tert, tipop
	insert #D394facttmp(codfisc, tipop, invers, nrfacturi)
	select codfisc, tipop, invers, count(distinct factura) as nrfacturi
	from #D394det d
	where abs(round(convert(decimal(15,3),d.baza),2))>=0.01 or @pecoduri=1 and abs(round(convert(decimal(15,3),d.tva),2))>=0.01
	group by d.subunitate, d.codfisc, d.tipop, d.invers
	having abs(sum(round(convert(decimal(15,3),d.baza),2)))>=0.01 or @pecoduri=1 and abs(sum(round(convert(decimal(15,3),d.tva),2)))>=0.01
	order by tipop desc, codfisc
	
	--	grupare date
	insert #D394tmp(codtert, codfisc, dentert, tipop, nrfacturi, baza, tva, codNomenclator, invers)
	select max(d.tert) as tert, max(codfisc) codfisc, max(dentert) dentert, tipop, 0, sum(baza) baza, sum(tva) tva, cod, invers
	from #D394det d
	group by d.subunitate, d.codfisc, d.cod, d.tipop, d.invers
	-- nu mai duc in declaratie documentele cu baza de tva 0 - sper sa fie bine asa
	-- Lucian: Am adaugat conditia @pecoduri=1 si sum(TVA)>0.01 astfel incat sa ia in calcul si pozitiile cu TVA nedeductibil (unde baza=0 si TVA<>0)
	-- probabil ca nu trebuie sa aduca pozitiile unde baza=0 si tva=0 (facturi+storno ale acelor facturi)
	having abs(sum(round(convert(decimal(15,3),d.baza),2)))>=0.01 or @pecoduri=1 and abs(sum(round(convert(decimal(15,3),d.tva),2)))>=0.01
	order by tipop desc, dentert

	-- facturi din UAPlus:
	if exists (select 1 from sysobjects o where o.type='TF' and o.name='docTVAVanzUA') and exists (select 1 from sysobjects o where o.type='U' and o.name='incfactAbon')
	begin
		insert #D394tmp (codtert, codfisc, dentert, tipop, nrfacturi, baza, tva, codNomenclator, invers)
		OUTPUT inserted.codfisc, inserted.tipop, inserted.invers, inserted.nrfacturi
		into #D394facttmp(codfisc, tipop, invers, nrfacturi) 
		select codtert,codfisc,dentert,tipop,nrfacturi,baza,tva,codNomenclator, invers from dbo.rapTVAUAPlus(@datajos,@datasus) 
	end

	-- facturi din UARia:
	if exists (select 1 from sysobjects o where o.type='P' and o.name='TVAVanzariUA') and exists (select 1 from sysobjects o where o.type='U' and o.name='AntetfactAbon')
	begin
		exec Declaratia394UA @DataJos=@datajos,@DataSus=@datasus,@sesiune=@sesiune
	end

	insert #D394cif(codtert, codfisc, dentert, tipop, baza, tva, codNomenclator, invers)
	select max(codtert),codfisc,max(dentert) as dentert,tipop, sum(baza), sum(tva), codNomenclator, invers
	from #D394tmp
	group by codfisc,tipop, codNomenclator, invers
	having abs(sum(round(convert(decimal(15,3),baza),2)))>=0.01 or @pecoduri=1 and abs(sum(round(convert(decimal(15,3),tva),2)))>=0.01
	order by tipop desc, dentert

	insert #D394fact(codfisc, tipop, invers, nrfacturi)
	select codfisc,tipop, invers, sum(nrfacturi)
	from #D394facttmp
	where @versiune='2'
	group by codfisc, tipop, invers

	select max(rtrim(d.codtert)) codtert, rtrim(d.codfisc) cuiP, max(rtrim(d.dentert)) dentert,
			(case	when d.invers=1 and d.tipop='L' then 'V'
					when d.invers=1 and d.tipop='A' then 'C' else d.tipop end) tipop
		,(case when row_number() over (partition by d.codfisc, 
		(case when d.invers=1 and d.tipop='L' then 'V' when d.invers=1 and d.tipop='A' then 'C' else d.tipop end) order by rtrim(isnull(c.codNomenclatura,'')))=1 then max(isnull(f.nrfacturi,0)) else 0 end) as nrfacturi
		,convert(decimal(15),convert(decimal(15,3),sum(d.baza))) baza, convert(decimal(15),convert(decimal(15,3),sum(d.tva))) tva
		,rtrim(isnull(c.codNomenclatura,'')) as cod		--> pentru acest cod de nomenclator s-a separat rapTVAInform in rapTVApecoduri si rapTVAInform
		,max(rtrim(n.Denumire)) as denumirecod
	into #D394
	from #D394cif d /*dbo.frapTVApecoduri(@parXML) d*/
		left join #tCoduriCereale c on d.codNomenclator=c.cod
		left join nomencl n on n.Cod=d.codNomenclator
		left join #D394fact f on d.codfisc=f.codfisc and d.tipop=f.tipop and d.invers=f.invers
	group by d.codfisc, (case	when d.invers=1 and d.tipop='L' then 'V'
						when d.invers=1 and d.tipop='A' then 'C' else d.tipop end),
				rtrim(isnull(c.codNomenclatura,''))
	order by 4,3,8

	delete #D394 where abs(baza)<0.01 and abs(tva)<0.01
	
--	generare declaratie
	if @genRaport=0
	begin
		if (@cui is null)
		select 
			@cui=ltrim(rtrim(replace(replace(
				max(case when parametru='CODFISC' then val_alfanumerica else '' end),'RO',''),'R','')))
			,@den=max(case when parametru='NUME' then rtrim(val_alfanumerica) else '' end)
			,@telefon=max(case when parametru='TELFAX' then rtrim(val_alfanumerica) else '' end)	--?
			,@fax=max(case when parametru='FAX' then rtrim(val_alfanumerica) else '' end)
			,@mail=max(case when parametru='EMAIL' then rtrim(val_alfanumerica) else '' end)	--?
		from par where tip_parametru='GE' and parametru in ('CODFISC','NUME','TELFAX','FAX','EMAIL')

		if @fax=''  -- compatibilitate in urma
			set @fax=@telefon

		if len(rtrim(@fisier))=0	--<<	Aici se compune numele fisierului, daca a fost omis
			select @fisier='394_'+@tip_D394+
					'_D'+rtrim(convert(varchar(2),month(@data)))+right(convert(varchar(4),year(@data)),2)+
					'_J'+rtrim(@cui)
	
			--> se elimina o eventuala extensie adaugata din greseala din macheta:
		if left(right(@fisier,4),1)='.' set @fisier=substring(@fisier, 1, len(@fisier)-charindex('.',reverse(@fisier)))
		
		declare @fisierXML varchar(100), @fisierTXT varchar(100)
		if left(right(@fisier,4),1)<>'.' 
			select @fisierXML=@fisier+'.xml', @fisierTXT=@fisier+'.txt'

		if year(@data)<2012
			select @fisierTXT='394_'+@tip_D394+(case when month(@data)<=6 then '1' else '2' end)+right(convert(varchar(4),year(@data)),2)+'_J'+rtrim(@cui)+'.txt'

		if (@adresa is null)
			select 
			@adresa=max(case when rtrim(val_alfanumerica)<>'' and parametru='LOCALIT' then 'Localitatea '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='STRADA' then 'str '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='NUMAR' then 'nr '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='BLOC' then 'bl '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='SCARA' then 'sc '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='ETAJ' then 'etaj '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='APARTAM' then 'ap '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='JUDET' then 'jud '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='CODPOSTAL' then 'cod postal '+rtrim(val_alfanumerica)+' ' else '' end)
				+max(case when rtrim(val_alfanumerica)<>'' and parametru='SECTOR' then 'sector '+rtrim(val_alfanumerica)+' ' else '' end)
				from par where tip_parametru='PS' and parametru in 
					('LOCALIT','STRADA','NUMAR','BLOC','SCARA','ETAJ','APARTAM','JUDET','CODPOSTAL','SECTOR')
		
		select	@cui=(case when rtrim(@cui)='' then null else @cui end),
				@den=(case when rtrim(@den)='' then null else @den end),
				@telefon=(case when rtrim(@telefon)='' then null else @telefon end),
				@fax=(case when rtrim(@fax)='' then null else @fax end),
				@mail=(case when rtrim(@mail)='' then null else @mail end),
				@adresa=(case when rtrim(@adresa)='' then null else @adresa end)
		
		declare @continutXml xml, @continutXmlChar varchar(max)
		select @continutXml=(
			select 'mfp:anaf:dgti:d394:declaratie:v'+@versiune as [@nu_am_alte_idei_decat_replace_pe_string],
				month(@datasus) as [@luna], year(@data) as [@an]
				,@tip_D394 [@tip_D394], rtrim(@nume_declar) [@nume_declar], rtrim(@prenume_declar) [@prenume_declar]
				,rtrim(@functie_declar) [@functie_declar]
				,(select rtrim(@cui) [@cui], rtrim(@den) [@den], rtrim(@adresa) [@adresa]
					,rtrim(@telefon) [@telefon], rtrim(@fax) [@fax], rtrim(@mail) [@mail]
					,convert(decimal(15),(select count(distinct cuiP)+sum(baza)+sum(tva)+sum(case when cod<>'' and tipop in ('V','C') then baza+tva else 0 end) from #D394)) as [@totalPlata_A]
					for xml path('identificare'),type)
				,(select @cifR [@cifR], @denR [@denR], @adresaR [@adresaR], @telefonR [@telefonR],
					@faxR [@faxR], @mailR [@mailR]
					where @cifR is not null or @denR is not null or @adresaR is not null or @telefonR is not null or @faxR is not null or @mailR is not null
					for xml path('idReprezentant'),type)
				,(select 
					count(distinct cuiP) as [@nrCui],
					convert(decimal(15),sum(case when tipop='L' then convert(decimal(15),baza) else 0 end)) as [@bazaL],
					convert(decimal(15),sum(case when tipop='L' then convert(decimal(15),tva) else 0 end)) as [@tvaL],
					convert(decimal(15),sum(case when tipop='A' then convert(decimal(15),baza) else 0 end)) as [@bazaA],
					convert(decimal(15),sum(case when tipop='A' then convert(decimal(15),tva) else 0 end)) as [@tvaA],
					convert(decimal(15),sum(case when tipop='V' then convert(decimal(15),baza) else 0 end)) as [@bazaV],
					convert(decimal(15),sum(case when tipop='V' then convert(decimal(15),tva) else 0 end)) as [@tvaV],
					convert(decimal(15),sum(case when tipop='V' and cod<>'' then convert(decimal(15),baza) else 0 end)) as [@bazaVc],
					convert(decimal(15),sum(case when tipop='V' and cod<>'' then convert(decimal(15),tva) else 0 end)) as [@tvaVc],
					convert(decimal(15),sum(case when tipop='C' then convert(decimal(15),baza) else 0 end)) as [@bazaC],
					convert(decimal(15),sum(case when tipop='C' then convert(decimal(15),tva) else 0 end)) as [@tvaC],
					convert(decimal(15),sum(case when tipop='C' and cod<>'' then convert(decimal(15),baza) else 0 end)) as [@bazaCc],
					convert(decimal(15),sum(case when tipop='C' and cod<>'' then convert(decimal(15),tva) else 0 end)) as [@tvaCc],
					(case when @versiune='2' then sum(case when tipop='L' then nrfacturi else 0 end) end) as [@nrFactL],
					(case when @versiune='2' then sum(case when tipop='A' then nrfacturi else 0 end) end) as [@nrFactA],
					(case when @versiune='2' then sum(case when tipop='V' then nrfacturi else 0 end) end) as [@nrFactV],
					(case when @versiune='2' then sum(case when tipop='C' then nrfacturi else 0 end) end) as [@nrFactC]
				from #D394 for xml path('rezumat'), type
				) --as rezumat
			,
				(select
					tipop [@tip], cuiP as [@cuiP]
					,max(dentert) [@denP], (case when @versiune='2' then max(nrfacturi) end) as [@nrFact], 
					convert(decimal(15),sum(baza)) as [@baza], convert(decimal(15),sum(tva)) as [@tva],
					(select d.cod [@codPR], convert(decimal(15),sum(baza)) [@bazaPR], convert(decimal(15),sum(tva)) [@tvaPR] from #D394 d
						where d.tipop=d1.tipop and d.cuip=d1.cuip and cod<>'' and d1.tipop in ('V','C')
						group by d.cod order by d.cod for xml path('op11'),type)
					from #D394 d1 group by tipop, cuiP order by max(dentert)
					for xml path('op1'),type
				)
			for xml path('declaratie394'), type)

		--/*--> urmeaza scrierea fizica a fisierului:
		select @continutXmlChar='<?xml version="1.0"?>'+char(10)+replace(convert(varchar(max),@continutXml),'nu_am_alte_idei_decat_replace_pe_string','xmlns')

	if OBJECT_ID('tempdb..##D394outputTXT') is not null
		drop table ##D394outputTXT
	create table ##D394outputTXT (valoare varchar(max), id int identity)

--> compunere continut txt:
		if @siTXT=1
		begin
			--	pentru anii anteriori lui 2012 fisierul TXT are o alta structura
			if year(@data)<2012
			begin
				declare @nrOperatori int, @BazaLivrari decimal(15,2), @TVALivrari decimal(15,2), @BazaAchizitii decimal(15,2), @TVAAchizitii decimal(15,2)
				-- pentru perioade anterioare anului 2012, nu se declara operatiunile cu taxare inversa
				delete from #D394 where tipop in ('V','C')
				select @nrOperatori=count(distinct tipop+cuiP), 
					@BazaLivrari=sum(case when tipop='L' then baza else 0 end), @TVALivrari=sum(case when tipop='L' then tva else 0 end),
					@BazaAchizitii=sum(case when tipop='A' then baza else 0 end), @TVAAchizitii=sum(case when tipop='A' then tva else 0 end)
				from #D394 where codtert<>''

				insert into ##D394outputTXT (valoare)
				select '394,'+rtrim(@cui)+',#S'+(case when month(@data)<=6 then '1' else '2' end)+'#,'+convert(varchar(4),year(@data))
						+',#'+rtrim(@den)+'#,#'+rtrim(@adresa)+'#,#'+rtrim(@telefon)+'#,#'+rtrim(@fax)+'#,#'+rtrim(isnull(@mail,''))+'#'+',,##,##,##,##,##,'+
						convert(varchar(10),@nrOperatori)+','+convert(varchar(20),@BazaLivrari)+','+convert(varchar(20),@TVALivrari)
						+','+convert(varchar(20),@BazaAchizitii)+','+convert(varchar(20),@TVAAchizitii)
			end

			if year(@data)>=2012
				insert into ##D394outputTXT (valoare)
				select '394,'+convert(varchar(2),month(@data))+','+convert(varchar(4),year(@data))+',#'+@tip_D394+'#,#'
						+rtrim(@nume_declar)+'#,#'+rtrim(@prenume_declar)+'#,#'+rtrim(@functie_declar)+'#,'+rtrim(@cui)+',#'+rtrim(@den)+'#,#'
						+rtrim(@adresa)+'#,#'+rtrim(@telefon)+'#,#'+rtrim(@fax)+'#,#'+rtrim(isnull(@mail,''))+'#'

			insert into ##D394outputTXT (valoare)
			select '#'+(case when cod<>'' and tipop='V' then '1' 
						when cod<>'' and tipop='C' then '2' else tipop end)+'#,'+												--> tip
						rtrim(cuiP)+','+																						--> cod operator
						'#'+rtrim((case when cod='' then dentert else cod end))+'#,'+											--> denumire operator
						(case when @versiune='2' 
							then (case when rtrim(cod)='' then convert(varchar(20),nrfacturi) else '' end)+',' else '' end)+	--> numar facturi
						convert(varchar(20),baza)+','+																			--> baza impozabila
						convert(varchar(20),tva)																				--> TVA
			from #D394 where tipop<>''
			order by tipop desc, dentert desc, cod desc
		end

-->	salvez declaratia ca si continut in tabela declaratii
		if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
			exec scriuDeclaratii @cod='394', @tip='0', @data=@datasus, @continut=@continutXmlChar

-->	salvare fisier xml/txt
		if (@dinRia=1)
		begin
			if (@siTXT=1) 
				exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierTXT, @numeTabelDate='##D394outputTXT'
			exec salvareFisier @codXML=@continutXmlChar, @caleFisier=@caleFisier, @numeFisier=@fisierXML
		end
		else
		begin
			if OBJECT_ID('tempdb..##D394outputXML') is not null
				drop table ##D394outputXML
			create table ##D394outputXML (valoare varchar(max), id int identity)
			insert into ##D394outputXML
			select @continutXmlChar as valoare
			exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierXML, @numeTabelDate='##D394outputXML'
			if (@siTXT=1)
				exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierTXT, @numeTabelDate='##D394outputTXT'
		end
	end
	else if @genRaport<2
	begin
		if object_id('tempdb..#D394plus') is not null
			insert into #D394plus (codtert, cuiP, dentert, tipop, nrfacturi, baza, tva, cod, denumirecod)
			select codtert, cuiP, dentert, tipop, nrfacturi, baza, tva, cod, denumirecod
			from #D394
		else
			select codtert, cuiP, dentert, tipop, nrfacturi, baza, tva, cod, denumirecod
			from #D394
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (Declaratia394)'
end catch

if object_id('tempdb.dbo.##tmpdecl') is not null drop table ##tmpdecl
if object_id('tempdb.dbo.#tCoduriCereale') is not null drop table #tCoduriCereale
if object_id('tempdb.dbo.#detaliereSFIF') is not null drop table #detaliereSFIF
if object_id('tempdb.dbo.#D394') is not null drop table #D394
if object_id('tempdb.dbo.#D394cif') is not null drop table #D394cif
if object_id('tempdb.dbo.#D394tmp') is not null drop table #D394tmp
--if object_id('tempdb.dbo.#D394det') is not null drop table #D394det
if object_id('tempdb.dbo.#D394facttmp') is not null drop table #D394facttmp
if object_id('tempdb.dbo.#D394fact') is not null drop table #D394fact
if OBJECT_ID('tempdb..##D394outputTXT') is not null drop table ##D394outputTXT
if OBJECT_ID('tempdb..##D394outputXML') is not null drop table ##D394outputXML


if len(@eroare)>0 raiserror(@eroare,16,1)
