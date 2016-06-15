-- procedura apelata din PVria pt. autocomplete-ul cu terti
CREATE procedure wACGestiuniTransferPv @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wACGestiuniTransferPvSP1' and type='P')
begin
	exec wACGestiuniTransferPvSP1 @sesiune, @parXML output
	
	if @parXML is null
		return 0
end
begin try
	set transaction isolation level read uncommitted
	declare @subunitate varchar(9), @searchText varchar(80), @userASiS varchar(10), @msgEroare varchar(500)
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')

	set @searchText=REPLACE(@searchText, ' ', '%')
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	if OBJECT_ID('tempdb..#terti') is not null
		drop table #terti
	
	create table #terti(gestiune varchar(20), tert varchar(13), denumire varchar(300))
	-- aduc toate gestiunile cu tert atasat
	insert into #terti(gestiune, tert, denumire)
		select top 100 RTRIM(g.Cod_gestiune), rtrim(substring(g.Denumire_gestiune,31,13)) as tert,
			rtrim(SUBSTRING(g.Denumire_gestiune,1,30)) denumire
		from gestiuni g
		where substring(Denumire_gestiune,31,13) <>''
	
	-- aduc denumirea tertilor
	update tt
		set tt.denumire=tt.denumire+'('+RTRIM(t.Denumire)+')'
	from terti t, #terti tt
	where t.Tert=tt.tert and t.Subunitate=@subunitate 
	
	-- filtrez dupa cod/denumire tert+gestiune
	delete from #terti
	where (denumire+tert+gestiune not like '%'+@searchText+'%')
	
	select top 100 rtrim(terti.tert) as cod, rtrim(max(terti.denumire)) as denumire, 
		'Sold ben.: ' + ltrim(convert(varchar(20), convert(money, sum(facturi.sold)), 1))+' '+ 'lei' as info
	from (select * from #terti) terti 
	left join facturi on facturi.subunitate=@subunitate and facturi.tert=terti.tert and facturi.tip=0x46
	group by terti.tert
	order by patindex('%'+@searchText+'%',max(terti.Denumire)+terti.Tert), 2
	for xml raw
	
	if OBJECT_ID('tempdb..#terti') is not null
		drop table #terti
	
end try
begin catch
set @msgEroare=ERROR_MESSAGE()+'(wACGestiuniTransferPv)'
raiserror(@msgEroare,11,1)
end catch	


