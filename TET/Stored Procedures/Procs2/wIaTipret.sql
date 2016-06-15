--***
Create
procedure  wIaTipret  @sesiune varchar(50), @parXML xml
as

Declare @filtruDenumire varchar(30), @filtruTipret varchar(30)
 
set @filtruDenumire = isnull(@parXML.value('(/row/@DenTipret)[1]','varchar(30)'),'')
set @filtruTipret = isnull(@parXML.value('(/row/@Tipret)[1]','varchar(30)'),'')

set @filtruDenumire=Replace(@filtruDenumire,' ','%')    
set @filtruTipret=Replace(@filtruTipret,' ','%')    
  
select top 100 rtrim(a.subtip) as subtip, rtrim(a.Denumire) as densubtip, rtrim(r.Denumire_tip) as dentipret, rtrim(a.tip_retinere) as tipret
from tipret a
left join fTip_retineri(1) r on a.tip_retinere=r.Tip_retinere 
where  a.Denumire like '%'+@filtruDenumire+'%' and (r.Denumire_tip like '%'+@filtruTipret+'%'  or a.Tip_retinere like @filtruTipret+'%')
order by a.subtip
for xml raw
