
create procedure wIaConfigurariParametri @sesiune varchar(50), @parXML xml
as
	declare
		@utilizator varchar(100), @aplicatie varchar(100), @tab varchar(100), @componenta varchar(100),
		@f_componenta varchar(200), @f_parametru varchar(200), @f_denumire varchar(100), @f_valoare varchar(200), @datajos datetime, @datasus datetime,
		@docXML xml, @tip varchar(2)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	set @tab = isnull(@parXML.value('(/Ierarhie/*/*/*/@tab)[1]','varchar(100)'),@parXML.value('(/*/@tab)[1]','varchar(100)'))
	set @aplicatie = isnull(@parXML.value('(/Ierarhie/*/*/*/@aplicatie)[1]','varchar(100)'),@parXML.value('(/*/@aplicatie)[1]','varchar(100)'))
	set @componenta = isnull(@parXML.value('(/Ierarhie/*/*/*/@componenta)[1]','varchar(100)'),@parXML.value('(/*/@componenta)[1]','varchar(100)'))
	set @datajos = ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'), DATEADD(YEAR,-50,GETDATE()))
	set @datasus = ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'), DATEADD(YEAR,50,GETDATE()))
	set @f_componenta = '%'+ISNULL(@parXML.value('(/*/@f_componenta)[1]','varchar(20)'),'%')+'%'
	set @f_parametru = '%'+ISNULL(@parXML.value('(/*/@f_parametru)[1]','varchar(20)'),'%')+'%'
	set @f_denumire = '%'+ISNULL(@parXML.value('(/*/@f_denpar)[1]','varchar(100)'),'%')+'%'
	set @f_valoare = replace('%'+ISNULL(@parXML.value('(/*/@f_valpar)[1]','varchar(20)'),'%')+'%',' ','%')
	set @tip = ISNULL(@parXML.value('(/*/@tip)[1]','varchar(20)'),'')

	if object_id('tempdb..#cfgpar') is not null drop table #cfgpar
	if object_id('tempdb..#aplicatii') is not null drop table #aplicatii
	select distinct aplicatie into #aplicatii from edlia..par where aplicatie is not null

	select tip_parametru, parametru, denumire_parametru, aplicatie, tab, subtab, descriere, NrOrdine
	into #cfgpar
	from edlia..par 
	where folosit=1 and tab is not null
		and (@aplicatie is null or aplicatie=@aplicatie)
		and (@tab is null or tab=@tab)
		and (@componenta is null or subtab=@componenta)
		and (@f_parametru='%%%' or parametru like @f_parametru)
		and (@f_denumire='%%%' or Denumire_parametru like @f_denumire)
		and (@f_valoare='%%%' or Val_alfanumerica like @f_valoare)

if @componenta is not null and 1=0
	select rtrim(s.Subtab) componenta, rtrim(s.tab) as tab, aplicatie as aplicatie, isnull(s.NrOrdine,0) as nrordine, @tip as tip, '#0000FF' as culoare
	from #cfgpar s
	where s.Aplicatie=@aplicatie and s.Tab=@tab and s.Subtab is not null and (@componenta is null or s.Subtab=@componenta) and folosit=1
	group by s.tab, s.Subtab, s.NrOrdine
	order by s.NrOrdine
	FOR XML raw
else
begin
	set @docXML = (
		SELECT a.aplicatie, RTRIM(apl.nume) as componenta, @tip as tip, '#B43104' as culoare, 
			(case when nexp.aplicatie is not null then 'Da' else null end) as _expandat,
--	nivelul pentru taburi
			(select rtrim(p.tab) componenta, isnull(max(p.NrOrdine),0) as nrordine, '#0000FF' as culoare, 
				(case when max(nexp.aplicatie) is not null then 'Da' else null end) as _expandat,
	--	nivelul pentru subtaburi
				(select rtrim(s.Subtab) componenta, rtrim(s.tab) as tab, rtrim(a.aplicatie) as aplicatie, isnull(max(s.NrOrdine),0) as nrordine, @tip as tip, 
				'#0000FF' as culoare, (case when max(nexp.aplicatie) is not null then 'Da' else null end) as _expandat
				from #cfgpar s
					left join NoduriExpandateConfigurari nexp on nexp.utilizator=@utilizator and nexp.aplicatie=a.aplicatie and nexp.tab=p.tab and nexp.subtab=s.subtab
				where s.aplicatie=a.aplicatie and s.Tab=p.tab and s.Subtab is not null and (@componenta is null or s.Subtab=@componenta)
				group by s.tab, s.Subtab--, s.NrOrdine
				order by max(s.NrOrdine)
				FOR XML raw,type
				)
			from #cfgpar p
				left join NoduriExpandateConfigurari nexp on nexp.utilizator=@utilizator and nexp.aplicatie=a.aplicatie and nexp.tab=p.tab 
			where p.aplicatie=a.aplicatie and p.Tab is not null and (@tab is null or p.Tab=@tab)
			group by p.tab
			order by max(p.NrOrdine)
			FOR XML raw,type
			)
		FROM #aplicatii a
			left join aplicatii apl on apl.cod_aplicatie=a.aplicatie
			left join NoduriExpandateConfigurari nexp on nexp.utilizator=@utilizator and nexp.aplicatie=a.aplicatie
		where (@aplicatie is null or a.aplicatie=@aplicatie) and a.aplicatie is not null and apl.nume is not null
		order by a.aplicatie
		FOR XML raw, root('Ierarhie')
		)	
	
/*	IF @docXML IS NOT NULL
		SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')*/
	
	SELECT @docXML
	FOR XML path('Date')

	SELECT '1' AS areDetaliiXml
	FOR XML raw, root('Mesaje')	
end