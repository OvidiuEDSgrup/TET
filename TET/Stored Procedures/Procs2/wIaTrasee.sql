--***
create procedure wIaTrasee @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaTraseeSP' and type='P')
	exec wIaTraseeSP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @cod varchar(100)

        -- cod , plecare, sosire, via 
Select	 @cod = '%'+isnull(@parXML.value('(/row/@cod)[1]','varchar(100)'),'')+'%'
		 

select top 100
rtrim(t.Cod) as cod,
RTRIM(t.Plecare) as plecare,
rtrim(t.Sosire) as sosire,
RTRIM(t.Via) as via
from trasee t 


where t.Cod like @cod


for xml raw

end
