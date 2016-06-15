--***
Create
procedure  wIaBenret  @sesiune varchar(50), @parXML xml
as

Declare @sub varchar(9), @filtruCod varchar(13), @filtruDenumire varchar(30), @filtruTipRetinere varchar(30), 
@filtruBanca varchar(30), @Subtipret int
 
set @sub=dbo.iauParA('GE','SUBPRO')
set @Subtipret=dbo.iauParL('PS','SUBTIPRET')
set @filtruCod = isnull(@parXML.value('(/row/@cod)[1]','varchar(13)'),'')
set @filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')
set @filtruTipRetinere = isnull(@parXML.value('(/row/@TipRetinere)[1]','varchar(30)'),'')
set @filtruBanca = isnull(@parXML.value('(/row/@banca)[1]','varchar(30)'),'')

set @filtrudenumire=Replace(@filtrudenumire,' ','%')    
set @filtruTipRetinere=Replace(@filtruTipRetinere,' ','%')    
  
select top 100 rtrim(b.cod_beneficiar) as cod, rtrim(b.Denumire_beneficiar) as denumire, rtrim(b.Tip_retinere) as tipret, 
rtrim((case when @Subtipret=0 then r.Denumire_tip else r.Denumire_subtip end)) as dentipret,
rtrim(b.Obiect_retinere) as obiectret, rtrim(left(b.Cod_fiscal,9)) as codfiscal, rtrim(b.Banca) as banca, rtrim(b.Cont_banca) as contbanca, 
substring(cod_fiscal,10,1) as bazaprocent, 
rtrim(b.Cont_debitor) as contdebitor, rtrim(cd.Denumire_cont) as dencontdeb, 
rtrim(b.Cont_creditor) as contcreditor, rtrim(cc.Denumire_cont) as dencontcred,
b.Analitic_marca as analiticmarca
from benret b   
left join tipret t on b.tip_retinere=t.Subtip
left join fTip_retineri(0) r on @Subtipret=0 and b.tip_retinere=r.Tip_retinere or @Subtipret=1 and b.tip_retinere=r.subtip
left outer join conturi cd on cd.Subunitate=@sub and cd.Cont=b.Cont_debitor
left outer join conturi cc on cc.Subunitate=@sub and cc.Cont=b.Cont_creditor
where b.Cod_beneficiar like @filtruCod+'%' and b.Denumire_beneficiar like '%'+@filtruDenumire+'%' and b.Banca like '%'+@filtruBanca+'%' 
and ((@Subtipret=0 and r.Denumire_tip like '%'+@filtruTipRetinere+'%' or @Subtipret=1 and t.Denumire like '%'+@filtruTipRetinere+'%') or b.Tip_retinere like @filtruTipRetinere+'%')
order by b.cod_beneficiar
for xml raw
