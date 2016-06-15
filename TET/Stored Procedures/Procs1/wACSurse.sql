--***
create procedure wACSurse @sesiune varchar(50), @parXML XML
as

if exists(select * from sysobjects where name='wACSurseSP' and type='P')      
	exec wACSurseSP @sesiune, @parXML      
else      
begin
	declare @tip varchar(2), @searchText varchar(80), @tipContr varchar(2),@numar varchar(10),@tert varchar(20),@subunitate varchar(20),
	 @TermPeSurse int,@data datetime,@subtip varchar(2)
	 
	set @TermPeSurse=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)

	select @searchText=replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ','%'),
	       @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(10)'), ''),
	       @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	       @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),	       
	       @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),
	       @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
	       @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1')
	       
   
	select RTRIM(su.Cod) as cod ,
		   RTRIM(su.Denumire) as denumire
	from surse su
		--inner join pozcon p on p.cod=su.cod and p.Subunitate=@subunitate 
	    --inner join terti t on t.Tert=p.Tert and  t.Tert=@tert
		--inner join termene te on te.contract =p.contract and te.Contract=@numar
	where (su.Cod in (select Mod_de_plata from pozcon p where p.Contract=@numar and p.Data=@data and p.Tert=@tert) or @subtip not in ('SP','PR'))
	  and (su.Denumire like '%'+@searchText +'%' or su.Cod like @searchText +'%')
	order by patindex('%'+@searchText+'%',su.Denumire),1 
	for xml raw
end
