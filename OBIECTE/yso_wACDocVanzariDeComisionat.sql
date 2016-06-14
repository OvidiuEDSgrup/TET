--/***
if exists (select * from sysobjects where name ='yso_wACDocVanzariDeComisionat')
	drop procedure yso_wACDocVanzariDeComisionat
go
create procedure yso_wACDocVanzariDeComisionat --*/ DECLARE
	@sesiune varchar(50), @parXML XML 
/* 
declare @p2 xml
set @p2=convert(xml,N'<row codMeniu="DO" subunitate="1" tip="RS" numar="3/040" numarf="3/040" data="03/03/2016" dataf="03/03/2016" dengestiune="" gestiune="" dentert="COBAR COM SRL" tert="RO6380669" factura="2254" contract="" denlm="NEAMT1" lm="1VZ_NT_01" dencomanda="" comanda="" indbug="" gestprim="" dengestprim="" punctlivrare="" denpunctlivrare="" valuta="" curs="0.0000" tcantitate="0.000" valoare="2500.00" tva11="0.00" tva22="500.00" tvatotala="500.00" valtotala="3000.00" valoarevaluta="0.00" totalvaloare="3000.00" valvalutacutva="3000.00" valvaluta="0.00" valoare_valuta_tert="0.00" valinpamanunt="0.00" categpret="0" facturanesosita="0" aviznefacturat="0" cotatva="20.00" discount="0.00" sumadiscount="0.00" tiptva="0" denTiptva="0-TVA Deductibil" explicatii="COBAR COM SRL" 
numardvi="COBAR COM SRL" proforma="1" tipmiscare="" contfactura="401.3" dencontfactura="401.3 - Furnizori servicii Ron" contcorespondent="" contvenituri="4426" dencontvenituri="TVA deductibila" datafacturii="03/03/2016" datascadentei="03/15/2016" zilescadenta="12" jurnal="" numarpozitii="1" numedelegat="" seriabuletin="" numarbuletin="" eliberat="" mijloctp="" nrmijloctp="" dataexpedierii="01/01/1900" oraexpedierii="      " observatii="" punctlivareexped="" contractcor="" stare="3" denStare="Operat" culoare="tempdb.dbo.#000000" _nemodificabil="0" tipdocument="RS" nrdocument="3/040" furnizor="RO6380669" denfurnizor="COBAR COM SRL" numarpozitie="560912" sumaTVA="500.00" cod="COMIS" dencod="COMISIOANE" codintrare="3/040001" pamanunt="0.00" pvaluta="2500.00000" contstoc="622" dencontstoc="622 - Chelt privind comis si onorar" contintermediar="4428.1" dencontintermediar="4428.1 - TVA neex. comert" idpozdoc="570378" o_numar="3/040" o_data="03/03/2016" o_denfurnizor="COBAR COM SRL" o_cod="COMIS" o_dencod="COMISIOANE" o_contstoc="622" update="0" tipMacheta="D" TipDetaliere="RS" subtip="CV" searchText="NT941"><row idpozdoc="570378"/><detalii><row docVanzareComisionat=""/></detalii></row>')
SELECT @sesiune='20B3329472541',@parXML=@p2
USE TET
--*/as  
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @tert varchar(13), 
	@valuta varchar(3), @furnbenef varchar(1), @inValuta int,@faraRestrictiiProp int,@cont varchar(40),@SoldPozitivNegativ int,@lminfo int,
	@utilizator varchar(20), @facturi_la_data char(1), @data datetime, @nesosite int, @CtDocFaraFact varchar(1000)

declare @raport varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
/*	Citim conturi setate pentru documente fara factura. Utilizam aceste conturi la filtrare facturi cand se apeleazaza procedura dinspre SF/IF.	*/
set @CtDocFaraFact=isnull(nullif((select top 1 val_alfanumerica from par where Tip_parametru='GE' and Parametru='NEEXDOCFF'),''),'408,418')

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

select 
	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@tert=ISNULL(@parXML.value('(/row/@beneficiar)[1]', 'varchar(20)'),''),
		--ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'),	ISNULL(@parXML.value('(/row/@cTert)[1]', 'varchar(13)'), '')), 
	@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), ''),
	@cont=ISNULL(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''),
	@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(100)'), ''),
	@furnbenef=isnull(@parXML.value('(/row/@furnbenef)[1]', 'varchar(1)'),
		ISNULL(@parXML.value('(/row/@cFurnBenef)[1]', 'varchar(1)'), 'B')),
	@faraRestrictiiProp=ISNULL(@parXML.value('(/row/@faraRestrictiiProp)[1]', 'int'), 0),
	@lminfo=ISNULL(@parXML.value('(/row/@lminfo)[1]', 'int'), 0),
	@facturi_la_data=isnull(@parXML.value('(/row/@facturi_la_data)[1]', 'char(1)'),0),
	@data = isnull(convert(datetime, @parXML.value('/row[1]/@data', 'char(10)'), 101),'01/01/2999'),
	@nesosite=ISNULL(@parXML.value('(/row/@nesosite)[1]', 'int'), 0)
--FROM @parXML.nodes('/row') p(xcol)
	

set @searchText=REPLACE(@searchText, ' ', '%')+'%'

declare @lista_lm bit
select @lista_lm=dbo.f_arelmfiltru(@utilizator)

if ISNULL(@furnbenef,'')=''
	set @furnbenef=(case when @tip in ('AP', 'AS','CB','IF','RK') or @tip in ('RE', 'DE', 'EF') and (left(@subtip, 1)='I' and @subtip<>'IS' or @subtip='PS') then 'B' else 'F' end)

set @inValuta=(case when (@tip in ('RM', 'RS', 'AP', 'AS', 'CF', 'CB', 'CO', 'C3') or @tip in ('RE', 'RV', 'DE', 'EF') and @subtip in ('PV', 'IV')) and @valuta<>'' then 1 else 0 end)
declare @parXMLFact xml
select @parXMLFact=(select @sesiune as sesiune for xml raw)
if @subtip='IF'
	set @tip='IF'

if OBJECT_ID('tempdb.dbo.#ctdocfarafact') is not null drop table tempdb.dbo.#ctdocfarafact
select c.cont into tempdb.dbo.#ctdocfarafact
	from dbo.fSplit(@CtDocFaraFact,',') ff
	left outer join conturi c on c.subunitate=@subunitate and c.cont like rtrim(ff.string)+'%'
	where c.are_analitice=0
-- Ghita, 24.05.2012: vom merge totdeauna pe tabela facturi
--    daca se va reveni la fTerti se va face o tabela temporara de facturi pe locul de munca la intrare in ASiSria
if 1=1 --(rtrim(@raport)<>'' or dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=0) or @faraRestrictiiProp=1	/**	Daca suntem pe rapoarte sau nu exista proprietatea 'LOCMUNCA' pentru utilizatorul curent se iau pur si simplu facturile*/
begin
	IF OBJECT_ID('tempdb.dbo.#antetbonuri') IS NOT NULL
		DROP TABLE tempdb.dbo.#antetbonuri
	
	select top (case replace(@searchText,'%','') when '' then 10 else 100 end) PERCENT * 
	into tempdb.dbo.#antetbonuri
	from antetBonuri a where a.Chitanta=1 and a.Data_bon<=@data
		and a.Factura like @searchText
	
	CREATE NONCLUSTERED INDEX yso_pozdocbon
	ON tempdb.dbo.#antetbonuri (Data_bon, yso_numar_in_pozdoc)--, Chitanta, Factura, Data_facturii)
	
	IF OBJECT_ID('tempdb.dbo.#doc') IS NOT NULL
		DROP TABLE tempdb.dbo.#doc
	
	select rtrim(coalesce((case f.Tip when 'AP' then pa.Factura_stinga when 'AC' then b.Factura end),nullif(f.Factura,''),f.Numar))
			+ CONVERT(varchar(10), 
			isnull(nullif(nullif(isnull((case f.Tip when 'AP' then pa.Data_fact when 'AC' then b.Data_facturii end),f.Data_facturii),'1900-01-01'),'1900-01-01'),f.data),103) 
			+RTRIM(t.Denumire) AS denumire,
		rtrim(coalesce((case f.Tip when 'AP' then pa.Factura_stinga when 'AC' then b.Factura end),nullif(f.Factura,''),f.Numar)) as factura,
		f.Tip, pa.Factura_stinga, b.Factura AS b_factura, f.Factura AS f_factura, f.Numar,
		pa.Data_fact, b.Data_facturii AS b_data_facturii, f.Data_facturii AS f_data_facturii, f.Data,
		t.Denumire AS den_tert, f.Valoare_valuta, f.Valoare, f.Tva_22, f.Loc_munca, f.Comanda
	into tempdb.dbo.#doc
	from doc f
	left join yso_LegComisionVanzari l on l.subDoc=f.Subunitate and l.tipDoc=f.Tip and l.dataDoc=f.Data and l.nrDoc=f.Numar
	inner join terti t on t.Subunitate=f.Subunitate and t.Tert=f.Cod_tert
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=f.Loc_munca 
	left outer join 
		(select b.Data_bon, b.yso_numar_in_pozdoc, b.Factura, b.Data_facturii
		from tempdb.dbo.#antetbonuri b 
			join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
		--where b.Chitanta=1 and b.Data_bon<=@data and b.Factura like @searchText
		group by b.Data_bon, b.yso_numar_in_pozdoc, b.Factura, b.Data_facturii
		) AS B
	ON b.Data_bon=f.Data and b.yso_numar_in_pozdoc=f.Numar 
		--isnull(nullif(b.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
			--,left(rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4),8))=f.numar) b
	left outer join pozadoc pa ON pa.Tip='IF' and pa.Factura_stinga<>'' AND pa.Subunitate=f.Subunitate and pa.Factura_dreapta=f.Factura
	--left outer join par on par.Tip_parametru='GE' and par.Parametru='CTCLAVRT' 
	--left join tempdb.dbo.#ctdocfarafact cdff on f.cont_de_tert like rtrim(cdff.cont)+'%'
	where f.subunitate=@subunitate and f.tip in ('AC','AP','AS') and f.Data<=@data and l.idLegDoc is null
		and ((@lista_lm=0 or lu.cod is not null) or @faraRestrictiiProp=1)
		--and (rtrim(coalesce((case f.Tip when 'AP' then pa.Factura_stinga when 'AC' then b.Factura end),nullif(f.Factura,''),f.Numar))
		--		+ CONVERT(varchar(10), 
		--		isnull(nullif(nullif(isnull((case f.Tip when 'AP' then pa.Data_fact when 'AC' then b.Data_facturii end),f.Data_facturii),'1900-01-01'),'1900-01-01'),f.data),103) 
		--		+RTRIM(t.Denumire) like @searchText
		--	or RTRIM(f.Numar) like @searchText)
		and (@tert='' or f.Cod_tert=@tert)
	order by 1
		
	CREATE NONCLUSTERED INDEX yso_denumire ON tempdb.dbo.#doc (denumire)
	--CREATE NONCLUSTERED INDEX yso_numar ON tempdb.dbo.#doc (denumire)
	--CREATE NONCLUSTERED INDEX yso_factura ON tempdb.dbo.#doc (Data DESC,factura DESC)
	--INCLUDE (denumire,Tip,Factura_stinga,b_factura,f_factura,Numar,Data_fact,b_data_facturii,f_data_facturii,Valoare_valuta,Valoare,Tva_22,Loc_munca,Comanda) 
		
	select top (100) convert(char(2),f.Tip)+CONVERT(char(8),f.Numar)+CONVERT(char(10),f.data,101) as cod, 
		rtrim(coalesce((case f.Tip when 'AP' then f.Factura_stinga when 'AC' then b_Factura end),nullif(f_Factura,''),f.Numar))
		+' din ' + CONVERT(varchar(10), 
		isnull(nullif(nullif(isnull((case f.Tip when 'AP' then Data_fact when 'AC' then b_Data_facturii end),f_Data_facturii),'1900-01-01'),'1900-01-01'),f.data),103) 
		+' pt. '+RTRIM(f.Denumire)
		--+(case @tert when '' then ' Pt. '+RTRIM(t.Denumire) else 
		--	+ ' Scad. ' + CONVERT(varchar(10), f.data_scadentei, 103)+' Ct. ' + RTRIM(f.Cont_factura) end) 
		as denumire, 
		'Val. ' + CONVERT(varchar(20), convert(money, (case when @inValuta=1 then f.Valoare_valuta else f.Valoare+f.TVA_22 end)), 1) + ' ' + (case when @inValuta=1 then @valuta else 'lei' end)
			+(case when @lminfo=1 then ' Lm. '+rtrim(f.Loc_munca) else '' end)+(case when substring(f.comanda,21,20)<>'' then ' Indbug. '+rtrim(substring(f.comanda,21,20)) else '' end) as info
	FROM tempdb.dbo.#doc f
	WHERE f.denumire like @searchText
			or f.Numar like @searchText
	order by f.Data desc, f.factura desc 
	for xml raw
end
