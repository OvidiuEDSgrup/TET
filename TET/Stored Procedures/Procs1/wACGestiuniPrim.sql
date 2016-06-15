
create procedure wACGestiuniPrim @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACGestiuniPrimSP' and type='P')      
	exec wACGestiuniPrimSP @sesiune,@parXML
else    
begin
	declare @utilizator varchar(100), @search_text varchar(200), @primall bit

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	set @search_text='%'+replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ','')+'%'

	exec luare_date_par 'GE','PRIMALL',@primall output, 0, ''
	IF OBJECT_ID('tempdb..#gestiuni') IS NOT NULL
		drop table #gestiuni

	create table #gestiuni(cod varchar(20))

	declare @nrGestFiltru int
	
	insert into #gestiuni (cod)
	select valoare
	from proprietati where tip='UTILIZATOR' and cod_proprietate in ('GESTIUNE','GESTPRIM') and cod=@utilizator and valoare<>''

	--set @nrGestFiltru=@@ROWCOUNT --Daca am zero gestiuni la filtru inseamna ca le pot vedea pe toate
	select @nrGestFiltru=count(1) from #gestiuni


	select 
		top 100 rtrim(g.Cod_gestiune) as cod, rtrim(g.Denumire_gestiune) as denumire, 
		rtrim(case when g.Cont_contabil_specific='' then (case g.Tip_gestiune when 'M' then 'Materiale' when 'P' then 'Produse' when 'C' then 'Cantitativa' when 'A' then 'Amanuntul' when 'V' then 'Valorica' when 'O' then 'Obiecte' when 'F' then 'Folosinta' when 'I' then 'Imobilizari' else g.Tip_gestiune end)
		else 'Tip ' + g.Tip_gestiune + ' (Ct. ' + RTrim(g.Cont_contabil_specific) + ')' end) as info
	from gestiuni g
	left JOIN #gestiuni gt on g.cod_gestiune=gt.cod
	where (g.cod_gestiune like @search_text or g.denumire_gestiune like @search_text)
		and (@nrGestFiltru=0 or gt.cod is not null OR @primall=1)
	for xml raw, root('Date')
end
