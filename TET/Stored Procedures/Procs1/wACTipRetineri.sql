--***
Create procedure  wACTipRetineri  @sesiune varchar(50), @parXML XML
as
/*Comentariu de la Lucian*/
declare @Subtipret int
set @Subtipret=dbo.iauParL('PS','SUBTIPRET')

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(a.tip_retinere) as cod, '' as info, rtrim(a.denumire_tip) as denumire
from dbo.fTip_retineri(0) a
where @Subtipret=0 and (tip_retinere like @searchText+'%' or denumire_tip like '%'+@searchText+'%')
union all
select top 100 rtrim(a.subtip) as cod, rtrim(a.Denumire_tip) as info, rtrim(a.denumire_subtip) as denumire
from dbo.fTip_retineri(0) a
where @Subtipret=1 and (subtip like @searchText+'%' or a.denumire_subtip like '%'+@searchText+'%')
order by cod
for xml raw
