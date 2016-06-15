--***
create procedure wACPuncteLivrare @sesiune varchar(50),@parXML XML  
as
declare @searchText varchar(80),@tert varchar(20), @subunitate char(9),@n_tert varchar(20),@subtip varchar(2)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),   
  @tert=COALESCE(
	@parXML.value('(/row/@tert)[1]', 'varchar(20)'),@parXML.value('(/row/@ctert)[1]', 'varchar(20)'),
	@parXML.value('(/row/@cTert)[1]', 'varchar(20)'), @parXML.value('(/row/@Tert)[1]', 'varchar(20)') , ''),
  @n_tert=ISNULL(@parXML.value('(/row/@n_tert)[1]', 'varchar(20)'), '') ,
  @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '')  

--select @tert,@new_tert,@subtip
select top 100 rtrim(identificator) as cod, rtrim(max(descriere)) as denumire
from infotert 
where subunitate=@subunitate 
  and identificator<>'' 
  and tert in (@tert, @n_tert)
  and (descriere like '%'+@searchText+'%' or identificator like @searchText+'%')  
group by rtrim(identificator) for xml raw
