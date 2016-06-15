--***
Create procedure Declaratia390
	(@datajos datetime, @datasus datetime
	,@d_rec int=0	--> tip:	0=Initiala, 1,R=Rectificativa
	,@nume_declar varchar(200)='', @prenume_declar varchar(200)='', @functie_declar varchar(100)=''
	,@cui varchar(100)=null, @den varchar(100)=null, @adresa varchar(100)=null, @telefon varchar(100)=null
	,@fax varchar(100)=null, @mail varchar(100)=null
	,@caleFisier varchar(300)=''	--> calea completa, incluzand fisierul; daca fisierul nu este dat se creeaza unul in functie de data, tip si cod fiscal firma
	,@nrPagini int=null
	,@dinRia int=1		-->	par care determina modul de scriere pe harddisk
	,@RP int=0
	,@FF int=0
	,@listaFF varchar(200)=''
	,@FB int=0
	,@listaFB varchar(200)=''
	,@AS int=0
	,@siTXT bit=1	--> 1=se va genera si fisier txt
	,@genRaport int=0	-- daca procedura este apelata pentru generare raport
	,@tert varchar(100)=''	--> filtru pe tert pentru rapDeclaratia390
	)
as
/*Testare
exec Declaratia390	@datajos ='2013-12-01' , @datasus='2013-12-31'
	,@d_rec=0	--> tip:	0=Initiala, 1,R=Rectificativa
	,@nume_declar='', @prenume_declar='', @functie_declar='', @cui ='', @den ='', @adresa ='', @telefon ='', @fax ='', @mail =''
	,@caleFisier =''	--> calea completa, incluzand fisierul; daca fisierul nu este dat se creeaza unul in functie de data, tip si cod fiscal firma
	,@nrPagini =null, @dinRia =1		-->	par care determina modul de scriere pe harddisk
	,@RP =1, @FF =1, @listaFF ='', @FB =1, @listaFB ='', @AS =1, @siTXT =0	--> 1=se va genera si fisier txt
	,@genRaport=1
*/
declare @eroare varchar(2000)
set @eroare=''
begin try
	select @tert=isnull(@tert,'')
--> var. temporara:
	declare @data datetime
	set @data=@datajos--'2011-2-1'
	select @datajos=dbo.bom(@data), @datasus=dbo.eom(@data)
--???:	e interval sau e doar pe o luna povestea? daca e cu interval, ce luna si an trebuie trecute in Declaratia390?

	declare @fisier varchar(100), @pozSeparator int, @caleCompletaFisier varchar(300)
			,@nrLiniiPagina int--> se folosesc la numararea paginilor din anexa
			,@tariNomenclatorLegislatie varchar(300), @ValidareTara int, @Fara44 int	-- pt. Rematinvest
	--???: cate linii pe pagina are anexa?
	select @nrLiniiPagina=30
	select @pozSeparator=len(@caleFisier)-charindex('\',reverse(@caleFisier))
			,@caleCompletaFisier=@caleFisier
	select	@fisier=substring(@caleFisier,@pozSeparator+2,len(@caleFisier)-@pozseparator+1)
			,@caleFisier=substring(@caleFisier,1,@pozseparator)
			,@tariNomenclatorLegislatie='AT,BE,BG,CZ,CY,DK,EE,DE,EL,FI,FR,IE,IT,LV,LU,LT,MT,GB,NL,PL,PT,SI,SK,ES,SE,HU'

	select	@ValidareTara=isnull(max(case when parametru='TARATERTI' then cast(val_logica as int) else @ValidareTara end),0)
			,@Fara44=isnull(max(case when parametru='FARA44' then cast(val_logica as int) else @Fara44 end),0)
	from par 
	where Parametru in ('TARATERTI','FARA44')

	if object_id('tempdb..#D390') is not null drop table #D390
	if object_id('tempdb..##tmpdecl') is not null drop table ##tmpdecl
--	if object_ID('tempdb..#tvarecap') is not null drop table #tvarecap
	if object_id('tempdb..#tvacump') is not null drop table #tvacump
	if object_id('tempdb..#tvavanz') is not null drop table #tvavanz

	declare @parXML xml
	select @parXML=
		(select @datajos as DataJ, @datasus as DataS, @RP as IncludRP, @FF as IncludFF
			,@listaFF as CtCorespFF, @FB as IncludFB, @listaFB as CtCorespFB, @AS as IncludAS
		for xml raw)

--	Lucian: transformat functia rapTVARecap in procedura, apoi am mutat continutul procedurii rapTVARecap in procedura curenta
	create table #D390 (codtert varchar(13), tara varchar(20), codfisc varchar(20), dentert varchar(80), tipop varchar(1), baza decimal(20), ordine int)
/*	insert into #D390 
	exec rapTVARecap @parXML
*/
	declare @ctcor table (tip char(2), cont varchar(40))
	insert @ctcor
	select 'FF', [Item]
	from dbo.Split(@listaFF, ',')
	where @FF=1 and @listaFF<>''
	union all
	select 'FB', [Item]
	from dbo.Split(@listaFB, ',')
	where @FB=1 and @listaFB<>''

	create table #tvacump (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvacump'
	exec TVACumparari @DataJ=@datajos, @DataS=@datasus, @ContF='', @Gest='', @LM='', @LMExcep=0, @Jurnal='', @ContCor='', @TVAnx=0, @RecalcBaza=0
			,@nTVAex=1, @FFFBTVA0='2', @SFTVA0='2', @IAFTVA0=0, @TipCump=9, @TVAAlteCont=0, @DVITertExt=0
			,@OrdDataDoc=0, @Tert=@tert, @Factura='', @UnifFact=0, @FaraVanz=1, @nTVAned=2, @parXML='<row />'

	create table #tvavanz (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvavanz'
	exec TVAVanzari @DataJ=@datajos, @DataS=@datasus, @ContF='', @ContFExcep=0, @Gest='', @LM='', @LMExcep=0, @Jurnal=''
			,@ContCor='', @TVAnx=0, @RecalcBaza=0, @CtVenScDed='', @CtPIScDed='', @nTVAex=0, @FFFBTVA0='2'
			,@SiFactAnul=0, @TipCump=1, @TVAAlteCont=0, @DVITertExt=0, @OrdDataDoc=0, @OrdDenTert=0
			,@Tert=@tert, @Factura='', @D394=0, @FaraCump=1, @parXML='<row />'
	
	if object_id('tempdb..#tvarecap') is null
	begin
		create table #tvarecap (subunitate varchar(20))
		exec Declaratia39x_tabela
	end

--	pun datele in tabela temporara pentru a putea fi prelucrate daca este cazul prin procedura specifica (Declaratia390SP / rapTVARecapSP)
	insert into #tvarecap(subunitate, tert, tara, codfisc, dentert, tipop, baza,
		numar, numarD, tipD, data, factura, valoare_factura,
		baza_22, tva_22, explicatii, tip, cota_tva, discFaraTVA,
		discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp,
		exonerat, vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, cont_de_stoc, idpozitie)
	select d.subunitate, d.tert, isnull(t.judet, '') as tara, 
		isnull(rtrim(ltrim((case when left(t.cod_fiscal,2)=(case when @ValidareTara=1 then isnull(t.Judet,'') else isnull(tn.cod_tara,'') end) then SUBSTRING(t.cod_fiscal,3,14) else t.cod_fiscal end))), '') as codfisc, 
		isnull(t.denumire, '') as dentert,
		(case when isnull(i.tip_miscare,'')='T' then 'T' when isnull(n.tip, '') in ('R', 'S', '') /*and left(d.cont_coresp,3)!='701'*/ and left(d.cont_coresp,3)!='419' 
			and not (d.tipD='IF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '')<>0) or left(d.cont_coresp, 3) in ('704') or d.tipD='FB' and @FB=0 
				then 'P' else 'L' end) as tipop, 
		round(convert(decimal(15,3), d.valoare_factura*(case when @datajos<'01/01/2010' and d.tipD='IF' and d.factadoc<>'' 
			then dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') / dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 0, '') else 1 end)), 2) as baza, 
		d.numar, d.numarD, d.tipD, d.data, d.factura, d.valoare_factura, d.baza_22, d.tva_22, d.explicatii, d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, 
		d.drept_ded, d.cont_TVA, d.cont_coresp, d.exonerat, d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf, d.cont_de_stoc, d.idpozitie
	from #tvavanz d
		left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.TipD<>'FA'
		left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
		left outer join nomencl n on n.cod=d.cod
		left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
		left outer join tari on cod_tara=i.cont_intermediar
		left outer join tari tn on tn.denumire=t.judet
	where isnull(it.zile_inc, 0)=1 and d.vanzcump='V' and (d.exonerat in (1, 2) or @Fara44=1 and d.exonerat=0)
		and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.Tert and tt.tipf='F' and tt.dela<=@datasus and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' --and isnull(it.grupa13, '')<>'1'
		and (isnull(n.tip, '') not in ('R', 'S', '') and left(d.cont_coresp, 3) not in ('704')
			or @AS=1 and d.tipD='AS'
			or d.tipD in ('ME') 
			or d.tipD='IF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') <> 0
			or @FB=1 and d.tipD='FB' 
				--and charindex(RTrim(d.cont_coresp), @CtCorespFB)>0
				and exists (select 1 from @ctcor cc where cc.tip=d.tipD and d.cont_coresp like RTrim(cc.cont)+'%')
			or @datajos>='01/01/2010' and (d.tipD<>'CB' or d.cont_coresp like '419%')
			)
	union all
	select d.subunitate, d.tert, isnull(t.judet, '') as tara, 
		isnull(rtrim(ltrim((case when left(t.cod_fiscal,2)=(case when @ValidareTara=1 then isnull(t.Judet,'') else isnull(tn.cod_tara,'') end) then SUBSTRING(t.cod_fiscal,3,14) else t.cod_fiscal end))), '') as codfisc, 
		isnull(t.denumire, '') as dentert,
		(case when isnull(n.tip, '') in ('R', 'S', '') and left(d.cont_coresp,3)!='409' and not (d.tipD='SF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '')<>0 
			or d.tipDoc='RP' and @RP=1 or d.tipD='FF' and @FF=1) or d.tipDoc='RP' and @RP=0 or d.tipD='FF' and @FF=0 then 'S' else 'A' end) as tipop, 
		round(convert(decimal(15,3), d.valoare_factura*(case when @datajos<'01/01/2010' and d.tipD='SF' and d.factadoc<>'' 
			then dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') / dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 0, '') else 1 end)), 2) as baza, 
		d.numar, d.numarD, d.tipD, d.data, d.factura, d.valoare_factura, d.baza_22, d.tva_22, d.explicatii, d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, 
		d.drept_ded, d.cont_TVA, d.cont_coresp, d.exonerat, d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf, d.cont_de_stoc, d.idpozitie
	from #tvacump d
		left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
		left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
		left outer join nomencl n on n.cod=d.cod
		left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
		-- left outer join tari on cod_tara=i.cont_intermediar	--> acest join nu pare a avea vreun rost
		left outer join tari tn on tn.denumire=t.judet
	where isnull(it.zile_inc, 0)=1 and d.vanzcump='C' and d.exonerat in (0, 1)
		and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.Tert and tt.tipf='F' and tt.dela<=@datasus and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' --and isnull(it.grupa13, '')<>'1'
		and (isnull(n.tip, '') not in ('R', 'S', '') or d.tipD in ('MI', 'MM') or (@RP = 1 and d.tipDoc='RP')
			or d.tipD='SF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') <> 0
			or @FF=1 and d.tipD='FF' 
				--and charindex(RTrim(d.cont_coresp), @CtCorespFF)>0
				and exists (select 1 from @ctcor cc where cc.tip=d.tipD and d.cont_coresp like RTrim(cc.cont)+'%')
			or @datajos>='01/01/2010')

	update #tvarecap set tara='EL' where tara='GR'

--	Tratam aici ca discountul existent pe o factura cu bunuri sa fie incadrat ca A(chizitie)/L(ivrare) (in loc de P sau S).
	update t set t.tipop=(case 
		when t.tipop='P' and exists (select 1 from #tvarecap t1 where t1.subunitate=t.subunitate and t1.tipD=t.tipD and t1.numar=t.numar and t1.data=t.data and t1.factura=t.factura 
			and t1.tert=t.tert and t1.tipop='L') then 'L' 
		when t.tipop='S' and exists (select 1 from #tvarecap t1 where t1.subunitate=t.subunitate and t1.tipD=t.tipD and t1.numar=t.numar and t1.data=t.data and t1.factura=t.factura 
			and t1.tert=t.tert and t1.tipop='A') then 'A' 
		else tipop end)
	from #tvarecap t
	where t.tipop in ('P','S') and left(t.cont_de_stoc,3) in ('667','709','767','609')

--	apelare procedura specifica Declaratia390SP / rapTVARecapSP (am apelat rapTVARecapSP daca exista, pentru compatibilitate in urma) */
	if exists (select * from sysobjects where name ='Declaratia390SP' and xtype='P')
		exec Declaratia390SP @parXML
	else 
		if exists (select * from sysobjects where name ='rapTVARecapSP' and xtype='P')
			exec rapTVARecapSP @parXML

--	grupare date din tabela temporara dupa tert si tip operatie
--test	select * from #tvarecap
	insert into #D390
	select d.tert, max(rtrim(case when len(d.tara)>2 then isnull(t.cod_tara,'') else d.tara end)) as tara, 
		max(d.codfisc) as codfisc, max(d.dentert) as dentert, d.tipop, convert(decimal(20),sum(d.baza)) as baza, row_number() over (order by d.tipop, max(d.dentert)) as ordine
	from #tvarecap d
		left join tari t on rtrim(t.denumire)=rtrim(d.tara)
	group by d.tert, d.tipop
	having abs(sum(d.baza))>=0.01

	if @genRaport=0
	begin
		insert into #D390 
		select '','AT','','','',0,''	--> pt a fi valid fisierul si daca nu exista inregistrari

		if (@cui is null)
		select 
			@cui=replace(replace(
				max(case when parametru='CODFISC' then rtrim(val_alfanumerica) else '' end),'RO',''),'R','')
		from par 
		where tip_parametru='GE' and parametru='CODFISC'
	
		if (@den is null)
		select 
			@den=max(case when parametru='NUME' then rtrim(val_alfanumerica) else '' end),
			@telefon=isnull(max(case when parametru='TELFAX' then rtrim(val_alfanumerica) else '' end),''),	--?
			@fax=isnull(max(case when parametru='FAX' then rtrim(val_alfanumerica) else '' end),''),	--?
			@mail=isnull(max(case when parametru='EMAIL' then rtrim(val_alfanumerica) else '' end),'')	--?
		from par 
		where tip_parametru='GE' and parametru in ('NUME','TELFAX','FAX','EMAIL')
	
		if @fax=''  -- compatibilitate in urma
			set @fax=@telefon
		
		if len(@fisier)=0		--<<	Aici se compune numele fisierului, daca a fost omis
			select @fisier='390_'+(case when month(@data)<10 then '0' else '' end)+
					rtrim(convert(varchar(2),month(@data)))+right(convert(varchar(4),year(@data)),2)+
					'_J'+rtrim(@cui)
			--> se elimina o eventuala extensie adaugata din greseala din macheta:
		if left(right(@fisier,4),1)='.' set @fisier=substring(@fisier, 1, len(@fisier)-charindex('.',reverse(@fisier)))
		declare @fisierXML varchar(100), @fisierTXT varchar(100)
		select @fisierXML=@fisier+'.xml', @fisierTXT=@fisier+'.txt'
	
		select @telefon=(case when @telefon='' then null else @telefon end),
			@fax=(case when @fax='' then null else @fax end),
			@mail=(case when @mail='' then null else @mail end)
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
	
		if (@nrPagini is null)
			select @nrPagini=1+((select count(1) from #D390))/@nrLiniiPagina	-->	formula de calcul numar linii pe pagina
							--> ar trebui adaugata in expresie si situatia primei pagini (spatiul ocupat de antet)

		declare @continutXml xml, @continutXmlChar varchar(max)
	--> compunere continut XML
		select @continutXml=(
			select 'mfp:anaf:dgti:d390:declaratie:v1' as [@nu_am_alte_idei_decat_replace_pe_string]
				,month(@data) as [@luna], year(@data) as [@an]
				,@d_rec [@d_rec], rtrim(@nume_declar) [@nume_declar], rtrim(@prenume_declar) [@prenume_declar]
				,rtrim(@functie_declar) [@functie_declar], rtrim(@cui) [@cui], rtrim(@den) [@den], rtrim(@adresa) [@adresa], rtrim(@telefon) [@telefon]
				,rtrim(@fax) [@fax], rtrim(@mail) [@mail], (select sum(baza)+count(distinct codfisc+'|'+tipop)-1 from #D390) as [@totalPlata_A],
				(select 
					@nrPagini as [@nr_pag], count(1)-1 as [@nrOPI],
					sum(case when tipop='L' then baza else 0 end) as [@bazaL],
					sum(case when tipop='T' then baza else 0 end) as [@bazaT],
					sum(case when tipop='A' then baza else 0 end) as [@bazaA],
					sum(case when tipop='P' then baza else 0 end) as [@bazaP],
					sum(case when tipop='S' then baza else 0 end) as [@bazaS],
					sum(baza) as [@total_baza]
				from #D390 for xml path('rezumat'), type
				) --as rezumat
			,
				(select --codtert, tara, codfisc, dentert, tipop, baza 
					tipop [@tip], tara [@tara], rtrim(codfisc) as [@codO]
					,rtrim(dentert) [@denO], baza as [@baza]
				from #D390 where tipop<>'' for xml path('operatie'),type
				)-- as operatie
			for xml path('declaratie390'), type)

	if OBJECT_ID('tempdb..##D390outputTXT') is not null
		drop table ##D390outputTXT
	create table ##D390outputTXT(valoare varchar(max), id int identity)
	
	--> compunere continut txt:
		if (@siTXT=1)
		begin
			insert into ##D390outputTXT (valoare)
			select '390,'+convert(varchar(2),month(@data))+','+convert(varchar(4),year(@data))+','+rtrim(@cui)+',#'+rtrim(@den)+'#,#'
						+rtrim(@adresa)+'#,#'+rtrim(@telefon)+'#,#'+rtrim(@mail)+'#'

			insert into ##D390outputTXT (valoare)
			select '#'+tipop+'#,'+						--> tip
						'#'+tara+'#,'+					--> tara
						'#'+rtrim(codfisc)+'#,'+		--> cod operator
						'#'+rtrim(dentert)+'#,'+		--> denumire operator
						convert(varchar(20),baza)		--> baza impozabila
			from #D390 where tipop<>''
			order by ordine desc
		end

	--> urmeaza scrierea fizica a fisierului (versiunea xml si eventual si txt):
		select @continutXmlChar='<?xml version="1.0"?>'+char(13)+replace(convert(varchar(max),@continutXml),'nu_am_alte_idei_decat_replace_pe_string','xmlns')

		if (@dinRia=1)
		begin
			if (@siTXT=1) 
				exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierTXT, @numeTabelDate='##D390outputTXT'
			exec salvareFisier @codXML=@continutXmlChar, @caleFisier=@caleFisier, @numeFisier=@fisierXML
		end
		else
		begin
			if OBJECT_ID('tempdb..##D390outputXML') is not null
				drop table ##D390outputXML
			create table ##D390outputXML (valoare varchar(max), id int identity)
			insert into ##D390outputXML
			select @continutXmlChar as valoare
			exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierXML, @numeTabelDate='##D390outputXML'
			if (@siTXT=1)
				exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisierTXT, @numeTabelDate='##D390outputTXT'
		end

		declare @parXMLVies xml, @detalii xml
		/*	Apelare procedura de validare terti in Vies. */
		if @dinRia=1 and @genRaport=0 and exists (select * from sysobjects where name ='ValidareDateDinVies') and exists (select 1 from #D390)
		begin
			set @parXMLVies=(select @dinRia as dinRia for xml raw)
			IF OBJECT_ID('tempdb..#tertiVies') IS NOT NULL
				drop table #tertiVies

			create table #tertiVies (tert varchar(20))
			exec CreazaDiezTerti @numeTabela='#tertiVies'
			insert into #tertiVies (tert, tara, cod_fiscal)
			select distinct codtert, tara, codfisc
			from #D390 where tipop<>''
			exec ValidareDateDinVies @sesiune=null, @parXML=@parXMLVies
			set @detalii=(select rtrim(tert) as tert, rtrim(requestIdentifier) as requestIdentifier from #tertiVies for xml raw)
		end

	-->	salvez declaratia ca si continut in tabela declaratii
		if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
			exec scriuDeclaratii @cod='390', @tip=@d_rec, @data=@datasus, @detalii=@detalii, @continut=@continutXmlChar
	end
	else if @genRaport<2
--	pentru generare raport
	begin
--	la apel procedura dinspre CGplus, tabela #D390 exista si se populeaza.	
		if object_id('tempdb..#D390plus') is not null
			insert into #D390plus (codtert, tara, codfisc, dentert, tipop, baza, ordine)
			select codtert, tara, codfisc, dentert, tipop, baza, ordine
			from #D390
		else
			select codtert, tara, codfisc, dentert, tipop, baza, ordine
			from #D390
	end

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (Declaratia390 '+convert(varchar(20),error_line())+')'
end catch

if object_id('tempdb..#D390') is not null drop table #D390
if object_id('tempdb..##tmpdecl') is not null drop table ##tmpdecl
--if object_ID('tempdb..#tvarecap') is not null drop table #tvarecap
if object_id('tempdb..#tvacump') is not null drop table #tvacump
if object_id('tempdb..#tvavanz') is not null drop table #tvavanz
if OBJECT_ID('tempdb..##D390outputTXT') is not null drop table ##D390outputTXT
if OBJECT_ID('tempdb..##D390outputXML') is not null drop table ##D390outputXML


if len(@eroare)>0 raiserror(@eroare,16,1)
