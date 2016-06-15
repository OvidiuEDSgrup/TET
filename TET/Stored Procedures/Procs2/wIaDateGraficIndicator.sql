--***
/* procedura aduce datele afisate in grafice sau in filtrele graficelor TBria.
*/
CREATE procedure  wIaDateGraficIndicator  @sesiune varchar(50), @parXML XML 
as
set transaction isolation level read uncommitted
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaDateGraficIndicatorSP')
begin
	exec wIaDateGraficIndicatorSP @sesiune, @parXML output
	return
end

begin try
declare @indicator varchar(20),@nivel int, @dataSus datetime, @dataJos datetime, 
		@filtru0 bit, @filtru1 bit, @filtru2 bit, @filtru3 bit, @filtru4 bit, @filtru5 bit, 
		@dinFiltre bit, @searchText varchar(100), @elementCurent varchar(100), @element varchar(100), 
		@col1 varchar(2000), @col2 varchar(2000), @sql nvarchar(max), @filtreString varchar(4000), @conditieWhere varchar(4000),
		@conditieGroupBy varchar(4000), @dataDebug datetime, @debug bit, @esteFiltruPeElementulCerut bit, @indicatorCuData bit,
		@tipSortare smallint, @elementCaSerie varchar(100), @coloanaCaSerie varchar(100)
set @dataDebug=GETDATE()

select	@dataSus=convert(datetime,isnull(@parXML.value('(/row/@dataSus)[1]','varchar(50)'),'01/01/2999'),103),
		@dataJos=convert(datetime,isnull(@parXML.value('(/row/@dataJos)[1]','varchar(50)'),'01/01/1901'),103),
		@indicator=isnull(@parXML.value('(/row/@indicator)[1]','varchar(50)'),''),
		@nivel=isnull(@parXML.value('(/row/@nivel)[1]','int'),0),
		@searchText=replace(rtrim(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'')), ' ','%'),
		@dinFiltre=isnull(@parXML.value('(/row/@dinFiltre)[1]','bit'),0),
		@debug=isnull(@parXML.value('(/row/@debug)[1]','bit'),0),
		-- elementul pt. care iau date
		@element=@parXML.value('(/row/@element)[1]','varchar(100)'), 
		-- element curent = elementul afisat pe grafic; (@element!=@elementCurent cand se iau date pentru filtre.
		@elementCurent=isnull(@parXML.value('(/row/@elementGrafic)[1]','varchar(100)'),@parXML.value('(/row/@elementCurent)[1]','varchar(100)')),
		-- elementul pe care se fac seriile
		@elementCaSerie= @parXML.value('(/row/@elementCaSerie)[1]','varchar(100)')

declare @coloanaDinEXPVALptElement varchar(20)

		
declare @tipG varchar(1)
select @tipG=tip_Grafic
from colind c 
where c.Cod_indicator=@indicator and numar=0

-- date pentru gauge daca este tip grafic 3 (vin si datele de colChart aici)	
if @tipG='3' --Este Gauge
begin
	-- iau ultima data valida pentru gauge
	declare @dataGauge datetime
	set @dataGauge = (select max(data) from expval e where e.cod_indicator=@indicator and e.Data <= @dataSus)
	-- trimit datele de gauge
	select (
		select top 1 isnull(convert(decimal(12,2),sum(e.valoare)), 0) as '@valoare',
			(select rtrim(s.Semnificatie) as '@semnificatie',
					max(convert(decimal(12,2),s.Val_max)) as '@limita',
					max((case when s.Culoare = 0 then null else s.Culoare end)) as '@culoare'
				from semnific s 
				where s.Indicator = e.Cod_indicator
				group by s.semnificatie
				for xml path, root('semnificatii'), type )
		from expval e
		where e.cod_indicator=@indicator and e.data = @dataGauge
		group by e.Cod_indicator
		for xml path, root('dateGauge'), type
	) Mesaje
	for xml path('')
end

if @element is not null
begin 
	/** Coloana tip sortare poate fi 0 pt filtrare normala(valoare), 1 filtrare data, 2 filtrare text,3 ordonare dupa numar (convert decimal(12,2)
	(nu este filtrare valorica in functie de numele filtrului)*/
	select @nivel=c.Numar,@tipSortare=c.tipSortare
	from colind c 
	where c.Cod_indicator=@indicator and c.Denumire=@element

	select @coloanaDinEXPVALptElement = 'Element_'+CONVERT(varchar(50), Numar)
	from colind c
	where c.Cod_indicator=@indicator and c.Denumire=@element
	
	if @coloanaDinEXPVALptElement ='Element_0'
		set @coloanaDinEXPVALptElement  = 'Data'

end

if @elementCaSerie is not null
begin 
	declare @tipOrdonareColoanaCaSerie int
	select @coloanaCaSerie = 'Element_'+CONVERT(varchar(50), Numar),@tipOrdonareColoanaCaSerie=tipSortare
	from colind c
	where c.Cod_indicator=@indicator and c.Denumire=@elementCaSerie
	
	if @coloanaCaSerie='Element_0'
		set @coloanaCaSerie = 'Data'
end
select @indicatorCuData = i.Ordine_in_raport
	from indicatori i 
	where i.Cod_Indicator=@indicator

if OBJECT_ID('tempdb..#filtre') is not null
	drop table #filtre

-- tabela cu filtre decodificate din XML;
create table #filtre (denElement varchar(50), filtru varchar(200), nivel int, primary key(nivel, filtru, denElement) )

insert #filtre(denElement, filtru, nivel)
select x.element, x.valoare, c.Numar
from
	dbo.wfIaFiltreDinXml(@parXML) x
	inner join colind c on c.Cod_indicator=@indicator and c.Denumire= x.element

set @esteFiltruPeElementulCerut=isnull((select top 1 1 from #filtre f where f.nivel=@nivel),0)

/* nu aplic filtre in select pe elementul la care trimit date. altfel, as trimite doar elementele filtrate deja.
In schimb, adaug separat aceste elemente in grafic daca nu exista.*/
if @dinFiltre=1
begin
	-- la filtre nu pivotam pe serie
	set @coloanaCaSerie = null 
	
	-- tabela cu valorile filtrate pe elementul pt. care se iau date
	create table #filtreElement (filtru varchar(200), primary key(filtru) )

	insert #filtreElement
	select filtru 
	from #filtre f
	where f.nivel=@nivel
	
	delete from #filtre
	where nivel=@nivel
end

		
-- initializare variabile care stabilesc daca un nivel se va filtra
select	@filtru0=0,@filtru1=0,@filtru2=0,@filtru3=0,@filtru4=0,@filtru5=0
select	@filtru0=(case when f.nivel=0 then 1 else @filtru0 end),
		@filtru1=(case when f.nivel=1 then 1 else @filtru1 end),
		@filtru2=(case when f.nivel=2 then 1 else @filtru2 end),
		@filtru3=(case when f.nivel=3 then 1 else @filtru3 end),
		@filtru4=(case when f.nivel=4 then 1 else @filtru4 end),
		@filtru5=(case when f.nivel=5 then 1 else @filtru5 end)
	from #filtre f

--select DATEDIFF(millisecond, @datadebug, getdate()), 'pre-insert'

-- formez parti care nu se schimba in selectul dinamic.
select	
	-- joinuri pe tabela cu filtre - se face join doar daca exista valori filtrate
	@filtreString=
		(case when @filtru0=1 then 'inner join #filtre f0 on f0.nivel=0 and convert(datetime,f0.filtru,103)=expval.Data'+char(13) else '' end)+
		(case when @filtru1=1 then 'inner join #filtre f1 on f1.nivel=1 and f1.filtru=expval.Element_1'+char(13) else '' end)+
		(case when @filtru2=1 then 'inner join #filtre f2 on f2.nivel=2 and f2.filtru=expval.Element_2'+char(13) else '' end)+
		(case when @filtru3=1 then 'inner join #filtre f3 on f3.nivel=3 and f3.filtru=expval.Element_3'+char(13) else '' end)+
		(case when @filtru4=1 then 'inner join #filtre f4 on f4.nivel=4 and f4.filtru=expval.Element_4'+char(13) else '' end)+
		(case when @filtru5=1 then 'inner join #filtre f5 on f5.nivel=5 and f5.filtru=expval.Element_5'+char(13) else '' end),
	
	-- la join-ul pe elementul filtrat, fac left join si afisez elem. filtrate in top.
	-- nu merge asa - la luare date grafic trebuie inner join.
	--@filtreString=REPLACE(@filtreString, 'inner join #filtre f'+str(@nivel,1) , 'left join #filtre f'+str(@nivel,1)),
	
	-- clauza where generala - filtrare indicator, perioada si, daca e completat, @searchText
	@conditieWhere='where expval.tip=''E'' and expval.Cod_indicator=@indicator '+ 
		(case when @indicatorCuData=1 then 'and Expval.Data between @dataJos and @dataSus' else '' end)+
		(case when len(@searchText)>0 then 
			char(13)+' and '+ (case when @nivel=0 then 'convert(char(10),expval.Data,103)'
						else 'expval.Element_'+str(@nivel,1) end)++ ' like ''%''+@searchText+''%''' else '' end)+CHAR(13),
	
	-- group by in functie de nivel.
	@conditieGroupBy = 'group by '+(case when @nivel=0 then 'expval.Data' else 'expval.Element_'+str(@nivel,1) end)+
							isnull(', '+@coloanaCaSerie, '')+CHAR(13)

if @dinFiltre=1
begin
	set @sql=
		'select top 35 '+
			(case when @nivel=0 then 'convert(char(10),expval.Data,103)' else 'rtrim(expval.Element_'+str(@nivel,1)+')' end)+' as data'+CHAR(13)+
		'from Expval '+CHAR(13)+
		'left join #filtreElement fE on '+
			(case when @nivel=0 then 'convert(datetime,fE.filtru,103)=expval.data' else 'fE.filtru=expval.Element_'+str(@nivel,1) end)+CHAR(13)+
		@filtreString+
		@conditieWhere+
		@conditieGroupBy+', fe.filtru'+CHAR(13)+
		'order by '+ (case when @nivel>0 then '(case when fe.filtru is null then 0 else 1 end) desc, '+(case when isnull(@tipSortare,0)=0 then +'sum(valoare) desc' when @tipSortare=1 then  'convert(datetime,expval.Element_'+str(@nivel,1)+',103)' when @tipSortare=2 then 'expval.Element_'+str(@nivel,1)+'' end) else 'expval.Data asc' end)+CHAR(13)+
		'for xml raw(''row''), root(''Date''), type'

		exec sp_executesql @statement=@sql, @params=N'@indicator as varchar(50), @searchText as varchar(100), @dataSus datetime, @dataJos datetime', 
		@indicator=@indicator, @searchText=@searchText, @dataSus=@dataSus, @dataJos=@dataJos
end
/* explicatii select pt. date grafic
toate valorile se calculeaza pentru elementul primit in parXML.
in functie de @dinFiltre se caluleaza date pentru afisare in filtre sau in chart.
1) in cel mai 'adanc' select, in alias T1, se calculeaza pt toate elementele, sum(valoare). => n perechi (element, valoare)
2) in alias T2 se caluleaza cu left join, top 19 elemente ordonate descrescator dupa valoare. => 19 perechi(element, valoare)
3) daca un element e in top19, se pastreaza denumirea, altfel se scrie 'Restul' in dreptul lui.

- la nivelul de baza, se trimite atributul @valoare si linia cu 'Restul' doar daca nu se cer date pt. filtre. Acolo nu se folosesc.
- ordonarea se face descrescator dupa valoare, daca nivel>0 si crescator dupa data, pentru @nivel=0 (la nivel=0, axa x e timpul).
*/

if @dinFiltre=0
--Pentru neserii
	if @elementCaSerie is null
	begin
		set @sql=
		'select '+(case when @nivel=0 then 'convert(char(10),col1,103)' else 'rtrim(col1)' end)+' as data'+(case when @coloanaCaSerie is not null then ', serie' else '' end)+', '+CHAR(13)+ 
		'	convert(decimal(20, 2),sum(col2)) valoare'+CHAR(13)+
		'from (select '+(case when @nivel=0/* nu fac join pt. nivel 0 */ then 'T1.col1' else 'coalesce(T2.col1, ''Restul'') ' end) + ' col1, T1.col2'+
			(case when @coloanaCaSerie is not null then ', T1.serie' else '' end)+'
			from 
				-- select cu toate elementele
				(select '+(case when @nivel=0 then 'expval.Data' else 'expval.Element_'+str(@nivel,1)+'' end)+' as col1, 
					'+(case when @coloanaCaSerie is not null then 'rtrim('+(case when @coloanaCaSerie='Data' then 'CONVERT(char(10), '+@coloanaCaSerie+', 103)' else @coloanaCaSerie end)+') serie, ' else '' end)+
					'SUM(Valoare) as col2 
				from Expval '+CHAR(13)+
				@filtreString+ 
				@conditieWhere+
				@conditieGroupBy +' ) T1'+CHAR(13)+
			(case when @nivel=0 then ''/*la dimensiunea data_lunii nu facem join*/ else 
				 'left join 
					-- select cu top 20 elemente, ordonate descrescator dupa valoare
					(select top 20 '+(case when @nivel=0 then 'expval.Data' else 'expval.Element_'+str(@nivel,1)+'' end)+
						' as col1, sum(valoare) as col2'+CHAR(13)+
					'from Expval '+CHAR(13) + 
					@filtreString+
					@conditieWhere+
					@conditieGroupBy+CHAR(13)+
					'order by 2 desc ) T2 on t1.col1=t2.col1'+CHAR(13)
			end)+' ) T	
		group by col1'+(case when @coloanaCaSerie is not null then ', serie' else '' end)+'
		order by '+ (case when @nivel>0 then (case when isnull(@tipSortare,0)=0 then 'sum(col2) desc' when @tipSortare=1 then '(case when col1=''Restul'' then ''2099-01-01'' else convert(datetime,col1,103) end )' when @tipSortare=2 then '( case when col1=''Restul'' then ''zzzzzzzzzzz'' else col1 end)' end ) else 'convert(datetime,col1,103) asc' end)+CHAR(13)+
		'for xml raw(''row''), root(''Date''), type'

		exec sp_executesql @statement=@sql, @params=N'@indicator as varchar(50), @searchText as varchar(100), @dataSus datetime, @dataJos datetime', 
		@indicator=@indicator, @searchText=@searchText, @dataSus=@dataSus, @dataJos=@dataJos

	end
	else --Comparativa adica cu serii una langa alta
	begin
		create table #dateBrute(data varchar(100),serie varchar(100),valoare decimal(12,2),ranc int)

		set @sql='select rtrim('+ (case when @coloanaDinEXPVALptElement='Data' then 'convert(char(10), Data, 103) ' else @coloanaDinEXPVALptElement end) +') as data,
				rtrim('+@coloanaCaSerie+') as serie,sum(valoare) as valoare,rank() over (partition by rtrim('+@coloanaDinEXPVALptElement+') order by sum(valoare) desc) as ranc
			from expval '+char(13)+
			@filtreString+
			@conditieWhere+
			'group by '+@coloanaDinEXPVALptElement+',rtrim('+@coloanaCaSerie+')'
		
		insert into #dateBrute
		exec sp_executesql @statement=@sql, @params=N'@indicator as varchar(50), @searchText as varchar(100), @dataSus datetime, @dataJos datetime', 
		@indicator=@indicator, @searchText=@searchText, @dataSus=@dataSus, @dataJos=@dataJos
			
		select data,(case when ranc<=4 then serie else 'Restul' end) as serie,sum(valoare) as valoare
		into #dPrel
		from #dateBrute
		group by data,(case when ranc<=4 then serie else 'Restul' end)
		order by 1,3 desc
		
		select serie 
		into #serii
		from #dPrel
		group by serie

		select 'x' as axa,
			(select data/*(case when @coloanaDinEXPVALptElement<>'Data' then data 
						else convert(char(10), convert(datetime, data, 126), 103) end)*/  as data
			from #dPrel
			group by data
			order by (case when @coloanaDinEXPVALptElement='Data' then data else null end)
			for xml raw,type) 
		for xml raw('Axe'),root('Mesaje')

		select rtrim(serie) as serie,
			(select rtrim(data) as data,convert(decimal(12,2),valoare) as valoare 
				from #dPrel db where db.serie=s.serie 

				order by case when @tipOrdonareColoanaCaSerie =1 then convert(char(10), convert(datetime,data,103),126) else data end for xml raw,type)
		from #serii s 
		order by serie
		for xml raw,root('Date')
		
	end

end try
begin catch
	if len(@sql)>0 and @debug=0
		print @sql
	
	declare @msgeroare varchar(500)
	set @msgeroare=ERROR_MESSAGE()
	raiserror(@msgeroare,11,1)
end catch
