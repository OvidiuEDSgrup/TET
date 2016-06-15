--***
create procedure yso_wACFacturiComisionate @sesiune varchar(50), @parXML XML  
as  
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @tert varchar(13), 
	@valuta varchar(3), @furnbenef varchar(1), @inValuta int,@faraRestrictiiProp int,@cont varchar(40),@SoldPozitivNegativ int,@lminfo int,
	@utilizator varchar(20), @facturi_la_data char(1), @data datetime, @nesosite int, @CtDocFaraFact varchar(1000)

declare @raport varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
/*	Citim conturi setate pentru documente fara factura. Utilizam aceste conturi la filtrare facturi cand se apeleazaza procedura dinspre SF/IF.	*/
set @CtDocFaraFact=isnull(nullif((select top 1 val_alfanumerica from par where Tip_parametru='GE' and Parametru='NEEXDOCFF'),''),'408,418')

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
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

if OBJECT_ID('tempdb..#ctdocfarafact') is not null drop table #ctdocfarafact
select c.cont into #ctdocfarafact
	from dbo.fSplit(@CtDocFaraFact,',') ff
	left outer join conturi c on c.subunitate=@subunitate and c.cont like rtrim(ff.string)+'%'
	where c.are_analitice=0
-- Ghita, 24.05.2012: vom merge totdeauna pe tabela facturi
--    daca se va reveni la fTerti se va face o tabela temporara de facturi pe locul de munca la intrare in ASiSria
if 1=1 --(rtrim(@raport)<>'' or dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=0) or @faraRestrictiiProp=1	/**	Daca suntem pe rapoarte sau nu exista proprietatea 'LOCMUNCA' pentru utilizatorul curent se iau pur si simplu facturile*/
begin
	select top 100 convert(char(20),f.Factura)+CONVERT(char(20),f.Tert) as cod, 
		rtrim(f.Factura)+' din ' + CONVERT(varchar(10), f.data, 103) 
		+(case @tert when '' then ' Pt. '+RTRIM(t.Denumire) else 
			+ ' Scad. ' + CONVERT(varchar(10), f.data_scadentei, 103)+' Ct. ' + RTRIM(f.Cont_de_tert) end) as denumire, 
		'Sold ' + CONVERT(varchar(20), convert(money, (case when @inValuta=1 then f.sold_valuta else f.sold end)), 1) + ' ' + (case when @inValuta=1 then @valuta else 'lei' end)
			+(case when @lminfo=1 then ' Lm. '+rtrim(f.Loc_de_munca) else '' end)+(case when substring(f.comanda,21,20)<>'' then ' Indbug. '+rtrim(substring(f.comanda,21,20)) else '' end) as info, 
		f.Data
	from facturi f
	inner join terti t on t.Subunitate=f.Subunitate and t.Tert=f.Tert
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=f.Loc_de_munca 
	left join #ctdocfarafact cdff on f.cont_de_tert like rtrim(cdff.cont)+'%'
	where f.subunitate=@subunitate 
		and (f.Factura like @searchText or RTRIM(f.Cont_de_tert) like @searchText)
		and (@tert='' or f.Tert=@tert)
		and (f.Cont_de_tert=@cont or @cont='' or @tip<>'RK')
		and f.Tip=(case when @furnbenef='B' then 0x46 else 0x54 end)
		and (@nesosite=0 and cdff.cont is null or @nesosite=1 and cdff.cont is not null or @nesosite=2)
		and (@inValuta=0 or f.Valuta=@valuta)
		and (@tip not in ('RE', 'RV', 'DE', 'EF', 'CO', 'C3', 'CB', 'CF', 'SF', 'IF', 'AA') or convert(money, ABS(case when @inValuta=1 then f.sold_valuta else f.sold end))>=0.01)
		/*and (@subtip<>'AA' or f.Factura like 'AV%' or f.Cont_de_tert like '167%' 
			or f.Cont_de_tert like '408%' or f.Cont_de_tert like '409%' or f.Cont_de_tert like '418%' 
			or f.Cont_de_tert like '419%' or f.Cont_de_tert like '461%' or f.Cont_de_tert like '462%')*/
			-- daca este subtip de avans sa aduca numai facturile de avans
		and (@subtip<>'IF' or f.Cont_de_tert like '418%') 
		and ((@lista_lm=0 or lu.cod is not null) or @faraRestrictiiProp=1)
		and (@facturi_la_data=0 or f.data<@data)
	order by 4, f.Factura
	for xml raw
end
else	/**	altfel se iau doar acele facturi pentru care exista date pe locul de munca filtrat*/
Begin
	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select @furnbenef as furnbenef, rtrim(@tert) as tert, @searchText as factura for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact
	
	select top 100 rtrim(f.Factura) as cod, 
		rtrim(f.Factura)+' din ' + CONVERT(varchar(10), max(isnull(fa.data,f.data)), 103) +
					' Scad. ' + CONVERT(varchar(10), max(isnull(fa.data_scadentei,f.data_scadentei)), 103)+' Ct. ' + RTRIM(max(f.Cont_de_tert)) as denumire, 
		'Sold ' + CONVERT(varchar(20), convert(money, sum(case when @inValuta=1 then f.total_valuta-f.achitat_valuta else f.valoare+f.tva-f.achitat end)), 1) +
					' ' + (case when @inValuta=1 then @valuta else 'lei' end) as info, 
		max(isnull(fa.data,f.data)) as data
	from #docfacturi f
	--dbo.fFacturi (@furnbenef, '1901-1-1', '2500-1-1', @tert, @searchText, null, 0, 0, 0, null, @parXMLFact) f
		left join facturi fa on f.factura=fa.factura and f.tert=fa.tert and f.subunitate=fa.subunitate and fa.tip=(case when @furnbenef='B' then 0x46 else 0x54 end)
	where f.Factura like @searchText
		and (@tert<>'')
		and (f.Cont_de_tert=@cont or @cont='' or @tip<>'RK')
		and (@inValuta=0 or f.Valuta=@valuta)
		and (@nesosite=0 or @CtDocFaraFact like rtrim(f.cont_de_tert)+'%')
	group by f.factura, f.tert
	having (@tip not in ('RE', 'RV', 'DE', 'EF','CO','C3','CB','CF','SF','IF') or convert(money, ABS(sum(case when @inValuta=1 then f.total_valuta-f.achitat_valuta else f.valoare+f.tva-f.achitat end)))>=0.01)
		   and (@subtip<>'AA' or f.Factura like 'AV%')--daca este subtip de avans sa aduca numai facturile de avans
	order by 4
	for xml raw
end