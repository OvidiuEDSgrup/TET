
create procedure wmIaGestiuni @sesiune varchar(50), @parXML xml as  
set transaction isolation level READ UNCOMMITTED  

if exists(select * from sysobjects where name='wmIaGestiuniSP' and type='P')  
begin
	exec wmIaGestiuniSP @sesiune, @parXML   
	return 0
end

	declare 
		@subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2),@userASiS varchar(10),@utilizator varchar(20),
		@faradetalii int, @cGest varchar(20), @procDetalii varchar(100),@lista_gestiuni bit, @numeAtr varchar(100), @titlumacheta varchar(50)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  
	select	
		@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@searchText=REPLACE(@searchText, ' ', '%'),
		@faradetalii=ISNULL(@parXML.value('(/row/@faradetalii)[1]', 'int'), 0),
		-- am nevoie de numeAtr configurabil -> de ex. gestiune + gestiune_primitoare
		@numeAtr = ISNULL(@parXML.value('(/row/@wmIaGestiuni.numeatr)[1]', 'varchar(80)'), '@gestiune'), 
		@titlumacheta = ISNULL(@parXML.value('(/row/@wmIaGestiuni.titlumacheta)[1]', 'varchar(80)'), 'Gestiuni'),
		
		/* e bine sa pastram prefixul wmIaTerti, pt. ca sa nu apara 
		probleme cand se apeleaza mai multe proceduri de acest fel*/
		@procDetalii= @parXML.value('(/row/@wmIaGestiuni.procdetalii)[1]', 'varchar(100)')


	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator output
	if @utilizator is null 
		return -1

	-- gestiuni atasate userului.
	create table #gestiuni(gestiune varchar(50) primary key clustered)
	insert #gestiuni(gestiune)
	select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>''

	set @lista_gestiuni=(case when exists (select 1 from #gestiuni) then 1 else 0 end)

	select top 25 rtrim(g.Cod_gestiune) as cod, rtrim(g.Cod_gestiune)+'-'+rtrim(g.Denumire_gestiune) as denumire,  
		'000000' culoare
		from gestiuni g  
	where (g.Denumire_gestiune like '%'+@searchText+'%' or g.Cod_gestiune like @searchText+'%')
		and (@lista_gestiuni=0 or exists (select 1 from #gestiuni gu where gu.gestiune=g.Cod_gestiune))
	order by patindex('%'+@searchText+'%',g.Denumire_gestiune), g.Denumire_gestiune	 
	for xml raw

	if @faradetalii=0   
		select 1 as areSearch, 0 toateAtr, @titlumacheta as titlu, @procDetalii _procdetalii, @numeAtr _numeAtr
		for xml raw,Root('Mesaje')  
