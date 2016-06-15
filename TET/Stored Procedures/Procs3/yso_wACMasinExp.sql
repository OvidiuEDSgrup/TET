--***
create procedure yso_wACMasinExp @sesiune varchar(50),@parXML XML  
as
declare @searchText varchar(80),@tert varchar(20), @subunitate char(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(replace(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'),' ', '%'), ''),   
	   @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')  

select top 100 rtrim(p.Numarul_mijlocului) as cod
	, denumire=p.Numarul_mijlocului+SPACE(50)+p.Descriere
	, rtrim(p.Descriere) as info
from masinexp p , terti t 
where t.subunitate=@subunitate and p.Numarul_mijlocului<>'' and p.Furnizor=t.tert and t.Tert=@tert 
	and (descriere like '%'+@searchText+'%' or p.Numarul_mijlocului like @searchText+'%')  
--group by rtrim(p.Numarul_mijlocului),RTRIM(t.Denumire) 
for xml raw


	