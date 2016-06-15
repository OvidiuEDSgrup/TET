--***
create procedure wIaTipuriMasini @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaTipuriMasiniSP' and type='P')
	exec wIaTipuriMasiniSP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @denumire varchar(100)

-- grupa, denumire, tip_masina
Select	@denumire = '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%'
		 
select top 100
rtrim(t.Cod) as cod,
RTRIM(t.Denumire) as denumire,
rtrim(t.tip_activitate) tip_activitate,
rtrim(t.Tip_activitate)+'-'+
(case when rtrim(t.Tip_activitate)='P' then 'Parcurs' else 'Lucru' end) as denTipActivitate
from tipmasini t

where t.denumire like @denumire

for xml raw

end
