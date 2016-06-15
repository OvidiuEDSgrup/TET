--***
create procedure wIaGrupeMasini @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaGrupeMasiniSP' and type='P')
	exec wIaGrupeMasiniSP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @denumire varchar(100)

-- grupa, denumire, tip_masina
Select	@denumire = '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%'
		 
select top 100
rtrim(g.Grupa) as grupa,
RTRIM(g.Denumire) as denumire,
rtrim(g.Tip_masina) as tip_masina,
rtrim(t.Denumire) as denumiretip
from grupemasini g
left join tipmasini t on g.tip_masina=t.Cod

where g.denumire like @denumire

for xml raw

end
