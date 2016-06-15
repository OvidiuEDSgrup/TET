
CREATE PROCEDURE wIaGrupe @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@mesajeroare VARCHAR(500), @f_cont VARCHAR(50), @f_grupa varchar(100), @f_tip varchar(20)

	SELECT 
		@f_grupa =	ISNULL(@parXML.value('(/row/@fltGrupa)[1]', 'varchar(100)'), ''), 
		@f_cont =	ISNULL(@parXML.value('(/row/@fltCont)[1]', 'varchar(100)'), ''),
		@f_tip =	ISNULL(@parXML.value('(/row/@f_tip)[1]', 'varchar(20)'), '')

	if object_id('tempdb..#grFiltrate') is not null
		drop table #grFiltrate
	if object_id('tempdb..#grupe') is not null
		drop table #grupe
	if object_id('tempdb..#tipuri_gr') is not null
		drop table #tipuri_gr

	create table #tipuri_gr(tip varchar(2), denumire varchar(200))
	insert into #tipuri_gr(tip, denumire)
	select 'M', 'Material' union
	select'P', 'Produs' union
	select'A', 'Marfa' union
	select'R', 'Servicii furnizate' union
	select 'S', 'Servicii prestate' union
	select 'O', 'Obiecte de inventar' union
	select 'F', 'Mijloace fixe' union
	select 'U', 'Nefolosit' union
	select '', ''

	select top 100 
		gr.grupa, gr.denumire, gr.grupa_parinte, 'da' expandat
	into #grFiltrate
	from grupe gr
	INNER JOIN #tipuri_gr tg on tg.tip=gr.Tip_de_nomenclator
	where 
		(tg.tip like '%'+@f_tip+'%' or tg.denumire like '%'+@f_tip+'%') and 
		(gr.denumire like '%'+@f_grupa+'%' OR gr.grupa like @f_grupa+'%') and
		(isnull(gr.detalii.value('(/row/@cont)[1]','varchar(20)'), '') like '%'+@f_cont+'%')

	-- daca este referit de alta grupa il stergem de aici
	delete g
	from #grFiltrate g
	where exists (select * from #grFiltrate g2 where g2.grupa_parinte=g.grupa)

	;with grCopii as
	(select g.grupa, g.denumire, g.grupa_parinte
		from #grFiltrate g
		union all
	 select g.grupa, g.denumire, g.grupa_parinte
	 from grupe g, grCopii gc
	 where gc.grupa=g.grupa_parinte
	)
	insert into #grFiltrate
	select g.grupa, g.denumire, g.grupa_parinte, ''
	from grCopii g
	where not exists (select * from #grFiltrate gf where gf.grupa=g.grupa)


	;with gr as
	(	
		select grupa, denumire, grupa_parinte, 1 nivel, expandat
		from #grFiltrate g
		union all
		select g.grupa, g.denumire, g.grupa_parinte, gr.nivel+1, gr.expandat
		from grupe g, gr
		where g.grupa=gr.grupa_parinte
	)
	select grupa, grupa_parinte, max(nivel) nivel, max(expandat) expandat
	into #grupe
	from gr
	group by grupa, grupa_parinte

	alter table #grupe add xmlData xml

	declare @nivel int
	set @nivel=1
	while exists(select * from #grupe where nivel>=@nivel) -- formam randul XML de la cel mai de jos nivel si apoi spre parinti
	begin
		update g
			set xmlData=(select nullif(expandat, '') as _expandat,
								rtrim(g.grupa) grupa, 
								rtrim(gr.denumire) denumire, 
								rtrim(gr.Tip_de_nomenclator) as tip, 
								rtrim(gr.Tip_de_nomenclator) + '-' + tg.denumire as denTip, 
								isnull(gr.detalii.value('(/row/@cont)[1]','varchar(20)'), '') as cont,
								rtrim(gr.grupa_parinte) grupa_parinte,
								rtrim(gpar.denumire) dengrupa_parinte,
								g.nivel,
								gr.detalii,		
								(select xmlData.query('.') 
									from #grupe g2 
									where g2.grupa_parinte=g.grupa for xml path(''),type) 
								order by gr.denumire
								for xml raw,type)
		from #grupe g, grupe gr
		INNER JOIN #tipuri_gr tg on gr.Tip_de_nomenclator=tg.tip
		left join grupe gPar on gPar.grupa=gr.grupa_parinte
		where nivel=@nivel
		and g.grupa=gr.grupa

		set @nivel=@nivel+1
	end

	select
		(select xmlData.query('.') 
		from #grupe 
		where nullif(grupa_parinte,'') is null
		for xml path(''), type)
	for xml raw('Ierarhie'), root('Date')

	
	select 1 as areDetaliiXml
	for xml raw, root('Mesaje')

END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
