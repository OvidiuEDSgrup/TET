--***
create procedure wACConturiBanca @sesiune varchar(50), @parXML XML  
as  
begin  
	declare @searchText varchar(100),@tert varchar(13)

	select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
		@tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),'')
		  
	select distinct top 100	rtrim(p.Cont_in_banca)+'-'+rtrim(p.Banca) as denumire,rtrim(p.Cont_in_banca) as cod
	from ContBanci p
	where p.Tert=@tert or isnull(@tert,'')='' 
		and (p.Cont_in_banca like @searchText+'%' or p.Banca like '%'+@searchText+'%')
	for xml raw
end
