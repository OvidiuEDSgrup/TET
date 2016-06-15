
create procedure wACPersoaneContactExpeditie @sesiune varchar(50),@parXML XML  
as
	set transaction isolation level read uncommitted
	if exists(select * from sysobjects where name='wACPersoaneContactExpeditieSP' and type='P')      
	begin
		exec wACPersoaneContactExpeditieSP @sesiune,@parXML
		return 0
	end
	declare 
		@searchText varchar(80),@tert varchar(20), @subunitate char(9), @tertGen varchar(20)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select 
		@searchText=ISNULL(replace(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'),' ', '%'), ''),   
		@tert=ISNULL(@parXML.value('(//@tertdelegat)[1]', 'varchar(20)'),@parXML.value('(//@tert)[1]', 'varchar(20)'))

	/* Daca nu am primit tertul=> caut delegatii tertului general */

	if ISNULL(@parXML.value('(//@tertdelegat)[1]', 'varchar(20)'), '') = '' -- daca nu e selectat explicit un tert pt. delegati (cazul general)
	begin
		exec luare_date_par 'UC','TERTGEN',0,0,@tertGen OUTPUT
		if isnull(@tertGen,'')<>'' and ISNULL((select val_logica from par where Tip_parametru='AR' and Parametru='EXPEDITIE'),0)=0
			set @tert=@tertGen -- tertul setat este mai tare decat tertul documentului, in cazul setarii AR,EXPEDITIE = False 
	end

	select 	top 100 
		rtrim(Identificator) as cod, rtrim(max(Descriere)) as denumire,
		rtrim(max(t.denumire))+', ' +isnull(rtrim(max(p.buletin)),'')+', '+ isnull(max(rtrim(p.mijloc_Tp)),'') as info
	from infotert p , terti t 
	where 
		p.subunitate='C'+@subunitate and identificator<>'' and p.tert=t.tert and p.Tert=@tert 
		and (descriere like '%'+@searchText+'%' or identificator like @searchText+'%')  
	group by rtrim(p.Identificator),RTRIM(t.Denumire) 
	for xml raw, root('Date')	
