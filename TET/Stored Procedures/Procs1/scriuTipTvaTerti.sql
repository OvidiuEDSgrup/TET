--***
create procedure scriuTipTvaTerti (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
--	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @iTvaTert int, @TipTVAUnitate char(1), @dataAzi datetime
	set @dataAzi=convert(datetime,convert(char(10), getdate(),101), 101)
	IF OBJECT_ID('tempdb..#tvatert') IS NOT NULL drop table #tvatert
	IF OBJECT_ID('tempdb..#tvaAnterior') IS NOT NULL drop table #tvaAnterior
	
	EXEC sp_xml_preparedocument @iTvaTert OUTPUT, @parXML
	select rtrim(tiptva) tiptva, rtrim(tert) tert, 0 as cuCfgAnterioara into #tvatert
	from OPENXML(@iTvaTert, '/row')
	WITH
	(
		tiptva varchar(1) '@tiptva',
		tert varchar(100) '@tert'
	)
	exec sp_xml_removedocument @iTvaTert
--	citesc tip tva unitate
	select @TipTVAUnitate=tip_tva from TvaPeTerti where TipF='B' and Tert is null and dela<=@dataAzi
	select @TipTVAUnitate=isnull(@TipTVAUnitate,'P')
		
	select row_number() over (partition by ta.tert order by ta.dela desc) ordine, ta.tert, ta.tip_tva			--> ultimele tva-uri pe tertii in cauza
	into #tvaAnterior
	from TvaPeTerti ta, #tvatert t
	where ta.Tert=t.tert

	--> pentru tertii care au ultimul tva setat la fel nu se va mai scrie in tvapeterti:
	delete t
	from #tvatert t, #tvaAnterior ta where ta.ordine=1 and t.tert=ta.tert and t.tiptva=ta.tip_tva

	update t set cuCfgAnterioara=1		--> determin care terti au deja configurat cel putin un tva
	from #tvatert t where exists (select 1 from tvapeterti ta where ta.tert=t.tert and ta.tipf='F')

	update t set t.tip_tva=x.tiptva
		from tvapeterti t, #tvatert x where t.dela=@dataAzi and tipf='F' and t.tert=x.tert

	insert into tvapeterti(Tert, dela, factura, tip_tva, tipf)
	select tert, (case when x.cuCfgAnterioara=1 then @dataAzi else '1901-1-1' end), null, x.tiptva, 'F'
	from #tvatert x
	where not exists (select 1 from TvaPeTerti t where t.dela=@dataAzi and t.tert=x.tert and t.tipf='F')
--	am tratat sa nu se insereze pozitii cu tip TVA='P'; este tratat in procedurile de jurnal TVA si 394 ca lipsa pozitiei inseamna tip TVA=P - discutat cu Ghita.
--	am pus si null pentru cazul in care campul tip TVA nu este vizibil in macheta.
		and not (@TipTVAUnitate='P' and isnull(x.tiptva,'') in ('P','')) 
--	am tratat sa nu insereze pozitii daca tip tva unitate este Incasare 
--	in acest caz implicit toti tertii sunt asimilati ca fiind cu TVA la incasare (in macheta apar cu TVA la incasare).
		and not (@TipTVAUnitate='I' and isnull(x.tiptva,'')='I')
		
	IF OBJECT_ID('tempdb..#tvatert') IS NOT NULL drop table #tvatert
	IF OBJECT_ID('tempdb..#tvaAnterior') IS NOT NULL drop table #tvaAnterior
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (scriuTipTvaTerti '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
