--***
create procedure wACPersoaneContactSP @sesiune varchar(50),@parXML XML  
as
declare @searchText varchar(80),@tert varchar(20), @subunitate char(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(replace(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'),' ', '%'), ''),   
	   @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')  

select top 100 rtrim(Identificator) as cod
	, denumire=p.Pers_contact+SPACE(50)+p.Nume_delegat+convert(char(3),dbo.fStrToken(p.buletin, 1, ','))+convert(char(9),dbo.fStrToken(p.buletin, 2, ','))
		+p.Eliberat,
	rtrim(t.denumire) as info
from infotert p , terti t 
where p.subunitate='C'+@subunitate and identificator<>'' and p.tert=t.tert and p.Tert=@tert 
	and (descriere like '%'+@searchText+'%' or identificator like @searchText+'%')  
--group by rtrim(p.Identificator),RTRIM(t.Denumire) 
for xml raw, root('Date')


--exec wOPGenerareUnAPdinBK_pSP @sesiune,@parxml