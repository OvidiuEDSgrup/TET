--***
Create
procedure  wIaTipcor  @sesiune varchar(50), @parXML xml
as

Declare @filtruDenumire varchar(30), @filtruTipcor varchar(30)
 
set @filtruDenumire = isnull(@parXML.value('(/row/@filtruDenTipcor)[1]','varchar(30)'),'')
set @filtruTipcor = isnull(@parXML.value('(/row/@filtruTipcor)[1]','varchar(30)'),'')

set @filtruDenumire=Replace(@filtruDenumire,' ','%')    
set @filtruTipcor=Replace(@filtruTipcor,' ','%')    
  
select top 100 rtrim(a.subtip) as subtip, rtrim(a.Denumire) as densubtip, rtrim(b.Denumire) as dentipcor,rtrim(a.tip_corectie_venit) as tipcor
from subtipcor a   
left outer join tipcor b on b.tip_corectie_venit=a.tip_corectie_venit
where  a.Denumire like '%'+@filtruDenumire+'%' and (b.Denumire like '%'+@filtruTipcor+'%'  or a.Tip_corectie_venit like @filtruTipcor+'%')
order by a.subtip
for xml raw
