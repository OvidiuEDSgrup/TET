--***
create procedure rapIntrariIesiri (@cod varchar(20)=null, @gestiune varchar(20)=null, @codintrare varchar(100)=null,
		@ctstoc varchar(100)=null, @datajos datetime, @datasus datetime,
		@Nivel1 varchar(2), @Nivel2 varchar(2), @Nivel3 varchar(2), @Nivel4 varchar(2),@Nivel5 varchar(2),	--> nivelele de centralizare
			/*	CM	= Comanda
				CO	= Cod
				GE	= Gestiune
				LO	= Loc de munca
				LU	= Luna (datei doc)
				GR	= Grupa de nomenclator
				DO	= Document
				TE	= Tert
				TI	= Tip document
			*/	
		@ordonare int=1,		--> -0=cod, 1=alfabetic, 2=valoare
		@tip_doc_str varchar(100),	--> tipurile de documente concatenate
		@locm varchar(20)=null, @tert varchar(20)=null, @contCor varchar(20)=null, @comanda varchar(20)=null,
		@indicator varchar(20)=null, @factura varchar(20)=null, @pret_cu_amanuntul bit=0, @grupa varchar(20)=null,
		@locatie varchar(200)=null,
		@detalii bit=1,
		@top int=null,
		@nrmaximdetalii bigint=0	--> numarul maxim de randuri returnat (pentru a evita timpul indelungat de asteptare); daca este 0 se considera ca este nelimitat
		)
as
declare @eroare varchar(2000)
begin try
	/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @utilizator varchar(20), @eLmUtiliz int,@eGestUtiliz int
	select @utilizator=dbo.fIaUtilizator('')
	create table #LmUtiliz (valoare varchar(200))
	create table #GestUtiliz (valoare varchar(200), cod_proprietate varchar(20))
	insert into #LmUtiliz(valoare)
	select cod from lmfiltrare l where l.utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from #LmUtiliz),0)
	insert into #GestUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz(null) where valoare<>'' and cod_proprietate='GESTIUNE'
	set @eGestUtiliz=isnull((select max(1) from #GestUtiliz),0)
	
	declare @ordonare_valori varchar(20)	--> ordonare crescatoare/descrescatoare pe valori
	set @ordonare_valori='desc'
	if @top is not null
	begin
		set @ordonare_valori=(case when @top<0 then 'asc' else 'desc' end)
		if @nivel1 is null raiserror('Pentru raportul "top" trebuie aleasa gruparea de nivel 1!',16,1)
		select @Nivel2=null, @Nivel3=null, @Nivel4=null,@Nivel5=null, @detalii=0, @ordonare=2
	end

	select @grupa=@grupa+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end)
		--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'

	/**	Pregatire filtre:*/
	declare @flt_locm bit, @flt_tert bit, @flt_contCor bit, @flt_comanda bit, @flt_indicator bit, @flt_factura bit
	select	@flt_locm=(case when @locm is null then 0 else 1 end),
			@flt_tert=(case when @tert is null then 0 else 1 end),
			@flt_contCor=(case when @contCor is null then 0 else 1 end),
			@flt_comanda=(case when @comanda is null then 0 else 1 end),
			@flt_indicator=(case when @indicator is null then 0 else 1 end),
			@flt_factura=(case when @factura is null then 0 else 1 end),
		@locm=@locm+'%', @contCor=@contCor+'%', @indicator=@indicator+'%'
	
	declare @identificare_grupari nvarchar(2000),
			@grComanda varchar(1),
			@grCod varchar(1),
			@grGestiune varchar(1),
			@grLocm varchar(1),
			@grLuna varchar(1),
			@grGrupaNomenclator varchar(1),
			@grDocument varchar(1),
			@grTert varchar(1),
			@grTip varchar(1)

--> se identifica ce grupari se cer:
	select @identificare_grupari='
select @tipgr=(case @cod when '''+isnull(@nivel1,'')+''' then ''1''
					when '''+isnull(@nivel2,'')+''' then ''2''
					when '''+isnull(@nivel3,'')+''' then ''3''
					when '''+isnull(@nivel4,'')+''' then ''4''
					when '''+isnull(@nivel4,'')+''' then ''5'' else null end)'
					
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CM', @tipgr=@grComanda output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CO', @tipgr=@grCod output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GE', @tipgr=@grGestiune output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LO', @tipgr=@grLocm output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LU', @tipgr=@grLuna output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GR', @tipgr=@grGrupaNomenclator output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DO', @tipgr=@grDocument output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='TE', @tipgr=@grTert output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='TI', @tipgr=@grTip output

declare @comanda_str nvarchar(max), @expresieCoduri varchar(max), @expresieDenumiri varchar(max),
			@gniv1 varchar(max), @gniv2 varchar(max),@gniv3 varchar(max), @gniv4 varchar(max), @gniv5 varchar(max),		--> gniv = cod de grupare nivel in group by
			@cniv1 varchar(max), @cniv2 varchar(max),@cniv3 varchar(max), @cniv4 varchar(max), @cniv5 varchar(max),		--> cniv = camp cod de grupare nivel
			@nniv1 varchar(max), @nniv2 varchar(max),@nniv3 varchar(max), @nniv4 varchar(max), @nniv5 varchar(max)		--> nniv = nume nivel
--> identificari grupari/totalizari astfel incat case-urile sa nu se proceseze in cadrul select-ului:
--> mai incolo expresia "n.grupa" devine prin inlocuirea lui '.' cu '_' 'n_grupa' pentru a se evita conflictul intre pozdoc.grupa si nomencl.grupa;
-->		aceeasi transformare e suferita de orice camp care e referit cu alias (p.cod), deci se are grija ca alias-urile campurilor in cauza din select-ul de pe pozdoc sa corespunda:
select @comanda_str='set @gniv=(case @Nivel	when ''CM'' then ''comanda'' when ''CO'' then ''p.cod'' when ''GE'' then ''p.gestiune''
							when ''LU'' then ''convert(varchar(20),year(p.data))+'''' ''''+(case when month(p.data)<10 then '''' '''' else '''''''' end)+convert(varchar(20),isnull(month(p.data),0))'' when ''LO'' then ''p.loc_de_munca''
							when ''GR'' then ''n.grupa'' when ''TE'' then ''tert'' when ''TI'' then ''p.tip''
							when ''DO'' then ''p.tip+'''' ''''+rtrim(numar)+'''' ''''+convert(varchar(10),p.data,103)'' else ''null'' end)
					set @cniv=''rtrim(''+@gniv+'')''
					set @gniv=(case when @gniv=''null'' then '''' else '',''+@gniv end)'
	exec sp_executesql @comanda_str,N'@cniv nvarchar(200) output, @nivel nvarchar(200), @nrniv nvarchar(200), @gniv nvarchar(200) output', @nivel=@nivel1, @nrniv='1', @cniv=@cniv1 output, @gniv=@gniv1 output
	exec sp_executesql @comanda_str,N'@cniv nvarchar(200) output, @nivel nvarchar(200), @nrniv nvarchar(200), @gniv nvarchar(200) output', @nivel=@nivel2, @nrniv='2', @cniv=@cniv2 output, @gniv=@gniv2 output
	exec sp_executesql @comanda_str,N'@cniv nvarchar(200) output, @nivel nvarchar(200), @nrniv nvarchar(200), @gniv nvarchar(200) output', @nivel=@nivel3, @nrniv='3', @cniv=@cniv3 output, @gniv=@gniv3 output
	exec sp_executesql @comanda_str,N'@cniv nvarchar(200) output, @nivel nvarchar(200), @nrniv nvarchar(200), @gniv nvarchar(200) output', @nivel=@nivel4, @nrniv='4', @cniv=@cniv4 output, @gniv=@gniv4 output
	exec sp_executesql @comanda_str,N'@cniv nvarchar(200) output, @nivel nvarchar(200), @nrniv nvarchar(200), @gniv nvarchar(200) output', @nivel=@nivel5, @nrniv='5', @cniv=@cniv5 output, @gniv=@gniv5 output

--> conform celor comentate mai sus, unde e necesar alias-urile campurilor se prefixeaza cu "p_":
select @comanda_str='
	declare @nr_randuri bigint, @max bigint, @nrmaximdetalii bigint
	select @max=100000
	
	/**	Selectare date:	*/
	select 0 as nr_ordine,
		max(convert(varchar(20),year(p.data))+'' ''+(case when month(p.data)<10 then '' '' else '''' end)+convert(varchar(20),isnull(month(p.data),0))) as luna, 
		max(isnull(p.data,''1/1/1901'')) as p_data, 
		max(isnull(p.tip,'''')) as p_tip ,
		max(isnull(p.tert,'''')) as tert,
		max(isnull(p.cod,'''')) as p_cod,
		'+(case when @grCod is not null then 'max(isnull(rtrim(n.denumire),''''))' else '''''' end)+' as denumire,
		max(isnull(p.loc_De_munca ,'''')) as p_loc_de_munca,
		max(isnull(p.gestiune,'''')) as p_gestiune,
		max(isnull(p.numar,'''')) as numar,
		sum(isnull(p.cantitate,0)) as cantitate, 
		max(isnull(p.comanda,'''')) as comanda,
		max(isnull(p.cod_intrare,'''')) as codintrare,
		max(isnull(p.cont_de_stoc,'''')) as cont_stoc,
		max(isnull((case when p.tip in(''RS'',''RM'',''RP'') then p.cont_factura else p.cont_corespondent end),'''')) as cont_factura,
		sum(isnull(p.cantitate*'+(case when @pret_cu_amanuntul=0 then 'p.pret_de_stoc' else 'p.Pret_cu_amanuntul' end)+',0)) as valCost,
		'+(case when @grGrupaNomenclator is not null then 'max(rtrim(n.grupa))' else '''''' end) +' as n_grupa,
		max(convert(varchar(20),idpozdoc)) idpozdoc, ''1'' as subunitate,
		''Total'' niv0,
		convert(varchar(2000),'''') niv1,
		convert(varchar(2000),'''') niv2,
		convert(varchar(2000),'''') niv3,
		convert(varchar(2000),'''') niv4,
		convert(varchar(2000),'''') niv5,
		'+(case when @detalii=1 then 'max(convert(varchar(20),idpozdoc))' else '''''' end)+' niv6,
		convert(varchar(2000),'''') nume1,
		convert(varchar(2000),'''') nume2,
		convert(varchar(2000),'''') nume3,
		convert(varchar(2000),'''') nume4,
		convert(varchar(2000),'''') nume5,
		convert(varchar(2000),'''') ordonare
	into #date_brute
	from 
	--#filtrate 
	pozdoc p
		'+(case when @grGrupaNomenclator is not null or @grCod is not null or @grupa is not null then 'left outer join nomencl n on p.cod=n.cod' else '' end)+'
	where charindex('',''+rtrim(p.tip)+'','','''+@tip_doc_str+''')>0
			and p.data between '''+convert(varchar(20),@datajos,102)+''' and '''+convert(varchar(20),@datasus,102)+''''+
			(case when @codintrare is null then '' when @codintrare='''' then ' and isnull(p.cod_intrare,'''')=''''' else ' and p.Cod_intrare='''+rtrim(ltrim(@codintrare))+'''' end)
			+(case when @ctstoc is null then '' else ' and p.cont_de_stoc='''+rtrim(ltrim(@ctstoc))+'''' end) 
			+(case when @gestiune is null then '' else ' and p.gestiune='''+rtrim(ltrim(@gestiune))+'''' end)
			+(case when @cod is null then '' else ' and p.cod='''+rtrim(ltrim(@cod))+'''' end)
			+(case when @flt_locm=0 then '' else ' and p.loc_de_munca like '''+rtrim(ltrim(@locm))+'''' end)
			+(case when @flt_tert=0 then '' else ' and p.Tert='''+rtrim(ltrim(@tert))+'''' end)
			+(case when @flt_contCor=0 then '' else 'and isnull((case when p.tip in(''RS'',''RM'',''RP'') then p.cont_factura else p.cont_corespondent end),'''') like '''+@contCor+'''' end)
			+(case when @flt_comanda=0 then '' else ' and left(p.Comanda,20)='''+rtrim(ltrim(@comanda))+'''' end)
			+(case when @flt_indicator=0 then '' else ' and substring(p.Comanda,21,20) like '''+rtrim(ltrim(@indicator))+'''' end)
			+(case when @flt_factura=0 then '' else ' and p.Factura='''+rtrim(ltrim(@factura))+'''' end)
			+(case when @eLmUtiliz=0 then '' else ' and exists (select 1 from #LmUtiliz u where u.valoare=p.Loc_de_munca)' end)
			+(case when @eGestUtiliz=0 then '' else ' and (p.tip in (''AS'',''RS'',''PF'') or exists (select 1 from #GestUtiliz u where u.valoare=p.Gestiune))' end)
			+(case when @grupa is null then '' else ' and n.grupa like '''+@grupa+'''' end)
			+(case when @locatie is null then '' else ' and p.locatie='''+@locatie+'''' end)
+'	group by subunitate'+@gniv1+@gniv2+@gniv3+@gniv4+@gniv5+(case when @detalii=1 then ',idpozdoc' else '' end)
+	--> se completeaza codurile de grupare; pentru denumiri se completeaza tot cu coduri, urmand ca mai jos sa se completeze cu denumiri unde este cazul si unde exista:
case when @nrmaximdetalii>0 and @top is null then '
	select @nr_randuri=rowcount_big(), @nrmaximdetalii='+convert(varchar(20),@nrmaximdetalii)+'
	if (@nr_randuri>@nrmaximdetalii)
	begin
		declare @eroare varchar(max)
		select @eroare=
''Numarul de linii returnate de server pentru raport (''+convert(varchar(20),@nr_randuri)+''>''+convert(varchar(20),@nrmaximdetalii)+'') ar conduce la timp de procesare indelungat si, posibil, la eroare.
In aceasta situatie se recomanda urmatoarele: renuntarea la anumite grupari (in special generarea cu detalii), adaugarea de filtre, micsorarea intervalului calendaristic.

(Raportul se poate rula in configuratia curenta efectuand clic pe titlul de mai sus)
''
		raiserror(@eroare,16,1)
	end' else '' end+'

	update #date_brute set	niv1='+replace(@cniv1+',niv2='+@cniv2+',niv3='+@cniv3+',niv4='+@cniv4+',niv5='+@cniv5,'.','_')+',
							nume1=''<''+'+replace(@cniv1+'+''>'',nume2=''<''+'+@cniv2+'+''>'',nume3=''<''+'+@cniv3+'+''>'',nume4=''<''+'+@cniv4+'+''>'',nume5=''<''+'+@cniv5+'+''>''','.','_')

	--> group by-ul anterior mareste mult viteza (prin micsorarea numarului de randuri de procesat in continuare) pentru rulari pe perioade indelungate - ani intregi - si fara detalii sau grupari pe documente

--> completare cu denumiri de prin cataloage, dupa nevoie:
if @grComanda is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grComanda+'=isnull(cm.descriere,'''')
		from #date_brute d inner join comenzi cm on cm.subunitate=''1'' and d.comanda=cm.comanda'
if @grLocm is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grLocm+'=isnull(rtrim(lm.denumire),'''')
		from #date_brute d inner join lm on d.p_loc_de_munca=lm.cod'
if @grGestiune is not null
select @comanda_str=@comanda_str+'
	update d set nume'+@grGestiune+'=isnull(rtrim(ge.denumire_gestiune),'''')
		from #date_brute d inner join gestiuni ge on d.p_gestiune=ge.cod_gestiune'
if @grGrupaNomenclator is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grGrupaNomenclator+'=isnull(rtrim(g.denumire),'''')
		from #date_brute d inner join grupe g on d.n_grupa=g.grupa'
if @grTert is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grTert+'=isnull(rtrim(t.denumire),'''')
		from #date_brute d inner join terti t on t.subunitate=''1'' and d.tert=t.tert'
if @grCod is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grCod+'=isnull(rtrim(d.denumire),'''')
		from #date_brute d'
if @grDocument is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grDocument+'=isnull(rtrim(d.niv'+@grdocument+'),'''')
		from #date_brute d'
--> ordonarea pe cod/denumire are loc in acest punct, inainte de acele grupari care vor fi ordonate invariabil pe cod (cum ar fi gruparea pe luna)
select @comanda_str=@comanda_str+'
	update s set ordonare='+(case @ordonare when 2 then ''''''
													when 1	then 'isnull(nume1,'''')+''|''+isnull(nume2,'''')+''|''+isnull(nume3,'''')+''|''+isnull(nume4,'''')+''|''+isnull(nume5,'''')+''|''+idpozdoc'
													else 'isnull(niv1,'''')+''|''+isnull(niv2,'''')+''|''+isnull(niv3,'''')+''|''+isnull(niv4,'''')+''|''+isnull(niv5,'''')+''|''+idpozdoc' end)
+' from #date_brute s'
if @grLuna is not null
select @comanda_str=@comanda_str+'
	update d set d.nume'+@grLuna+'=isnull(rtrim(c.lunaalfa),'''')+'' ''+convert(varchar(20), year(d.p_data))
		from #date_brute d cross apply
			(select max(c.lunaalfa) lunaalfa from calstd c where month(d.p_data)= c.luna) c'
--> daca se genereaza top va trebui ca gruparea de nivel 1 care contine <rest> sa fie intotdeauna ultima;
--> daca se doreste raport @top se cumuleaza orice inregistrari care depasesc numarul dorit pe o singura grupare de nivel 1:
if @top is not null
	select @comanda_str=@comanda_str+'
	update s set nr_ordine=d.nr_ordine from #date_brute s inner join (select d.niv1, row_number() over (order by max(ordonare),sum(valcost) '+
		@ordonare_valori+') nr_ordine from #date_brute d group by d.niv1) d on d.niv1=s.niv1
	update #date_brute set niv1=''<rest top>'', nume1=''<Rest top>'' where nr_ordine>'+convert(varchar(20),abs(@top))+'
	update s set ordonare=''zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'' from #date_brute s where isnull(niv1,'''')=''<Restul>'''

select @comanda_str=@comanda_str+'
	
	/** organizarea datelor pe gruparile care vor aparea in raport:	*/
	select niv0 as cod,'''' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' as cont_stoc, '''' as cont_factura, '''' as codintrare, 0 as nivel, 
			''Total'' as nume, min(ordonare) ordonare,
			'''' niv1, '''' nume1, 0 valgr, 0 topgr	--> ultimele 4 campuri sunt pt grafic
		into #f
		from #date_brute where niv0 is not null group by niv0
	'+case when @gniv1<>'' then 'union all select niv1 as cod,niv0+''|'' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' as cont_stoc, '''' as cont_factura, '''' as codintrare, 1 as nivel,
			max(nume1) as nume, max(ordonare) ordonare,
			niv1 niv1, max(isnull(nume1,'''')) nume1, sum(valcost) valgr, row_number() over (order by sum(valCost) desc) topgr	--> ultimele 4 campuri sunt pt grafic
				from #date_brute where niv1 is not null group by niv1,niv0' else '' end+'
'	--> raport "tip top" are sens doar pentru gruparea de nivel 1, de aceea gruparile urmatoare nu sunt formate pentru acea optiune:
	if @top is null select @comanda_str=@comanda_str+
	  case when @gniv2<>'' then 'union all select niv2, niv1+''|''+niv0+''|'' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' , '''' , '''' , 2, max(nume2),max(ordonare) ordonare,'''','''',0,0 from #date_brute where niv2 is not null group by niv2,niv1,niv0' else '' end+'
	'+case when @gniv3<>'' then 'union all select niv3, niv2+''|''+niv1+''|''+niv0+''|'' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' , '''' , '''' ,3,max(nume3),max(ordonare) ordonare,'''','''',0,0 from #date_brute where niv3 is not null group by niv3,niv2,niv1,niv0' else '' end+'
	'+case when @gniv4<>'' then 'union all select niv4, niv3+''|''+niv2+''|''+niv1+''|''+niv0+''|'' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' , '''' , '''' , 4,MAX(nume4),max(ordonare) ordonare,'''','''',0,0 from #date_brute where niv4 is not null group by niv4,niv3,niv2,niv1,niv0' else '' end+'
	'+case when @gniv5<>'' then 'union all select niv5, niv4+''|''+niv3+''|''+niv2+''|''+niv1+''|''+niv0+''|'' as parinte, sum(cantitate) as cantitate, sum(valCost) as valCost, '''' , '''' , '''' , 5,max(ordonare) ordonare,MAX(nume5),'''','''',0,0 from #date_brute where niv5 is not null group by niv5,niv4,niv3,niv2,niv1,niv0' else '' end+'
	'+case when @detalii=1 then 'union all select niv6, isnull(niv5+''|'','''')+isnull(niv4+''|'','''')+isnull(niv3+''|'','''')+isnull(niv2+''|'','''')+isnull(niv1+''|'','''')+isnull(niv0+''|'','''') as parinte, 
				cantitate, valCost, cont_stoc, cont_factura, codintrare, 6, niv6, ordonare ordonare,'''','''',0,0 from #date_brute' else '' end
select @comanda_str=@comanda_str+'
	select cod, parinte, round(cantitate,5) cantitate, round(valCost,5) valCost, cont_stoc, cont_factura, codintrare, nivel, isnull(nume,'''') as nume,
			niv1, nume1, round(valgr,5) valgr, topgr,
			(case when nivel in ('+isnull(@grComanda+', ','')+isnull(@grCod+', ','')+isnull(@grGestiune+', ','')+isnull(@grLocm+', ','')+isnull(@grGrupaNomenclator+', ','')+isnull(@grTert+', ','')+isnull(@grTip+', ','')+'10) then cod else '''' end) as codAfisat
			,ordonare, 0 eroare
			from #f
		order by nivel, ordonare, valcost '+@ordonare_valori+'	--*/
'
	--test	 select @comanda_str for xml path('')
	exec(@comanda_str)
	--select * from #date_brute
end try
begin catch
	select @eroare=rtrim(error_message())+'( rapIntrariIesiri '+convert(varchar(20),error_line())+' )'
	select '' cod, '' parinte, 0 cantitate, 0 valCost, '' cont_stoc, '' cont_factura, '' codintrare, 1 nivel, @eroare nume, '' niv1, '' nume1, 0 valgr, 0 topgr, '' codAfisat, '' ordonare, 1 eroare
	select @comanda_str for xml path('')	--> daca apare eroare sa se verifice usor problema
end catch

if object_id('tempdb..#f') is not null drop table #f
if object_id('tempdb..#1') is not null drop table #1
if object_id('tempdb..#date_brute') is not null drop table #date_brute
if len(@eroare)>0 raiserror(@eroare,16,1)
