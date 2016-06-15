--***
create procedure [dbo].[wIaCategopSA] @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaCategopSASP' and type='P')
	exec wIaCategopSASP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @filtruCod varchar(100), @filtruDenumire varchar(100), @filtruTip varchar(100), @filtruTarifJ float, @filtruTarifS float,
@filtruUM varchar(100), @filtruCategorie varchar(100)

select	@filtruCod = '%'+isnull(@parXML.value('(/row/@cod)[1]','varchar(100)'),'')+'%',
		@filtruDenumire= '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%',
		@filtruTip= '%'+isnull(@parXML.value('(/row/@tip)[1]','varchar(100)'),'')+'%',
		@filtruTarifJ= isnull(@parXML.value('(/row/@tarifj)[1]','float'),-99999999),
		@filtruTarifS= isnull(@parXML.value('(/row/@tarifs)[1]','float'),999999999),
		@filtruUM= '%'+isnull(@parXML.value('(/row/@UM)[1]','varchar(100)'),'')+'%',
		@filtruCategorie= '%'+isnull(@parXML.value('(/row/@categorie)[1]','varchar(100)'),'')+'%'


select top 100
rtrim(c.Cod) as cod,
RTRIM(c.Denumire) as denumire,
rtrim(c.Tip_operatie) as tip,
convert(decimal(12,2),c.Tarif) as tarif,
RTRIM(c.UM) as UM,
RTRIM(c.Categorie) as Categorie
 
from catop c 
--left outer join terti proprietari on c.Cod=proprietari.Tert
--left outer join catop on c.Cod=catop.Cod
where c.Cod like @filtruCod
and c.Denumire like @filtruDenumire
and c.Tip_operatie like @filtruTip
and c.Tarif between @filtruTarifJ and @filtruTarifS
and c.UM like @filtruUM
and c.Categorie like @filtruCategorie


for xml raw

end
