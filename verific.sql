select round(pc.Pret*(1-pc.Discount/100),5)
,convert(decimal(17,5), pc.Pret*(1-pc.Discount/100))
,round(convert(decimal(17,5), pc.Pret*(1-pc.Discount/100))*pc.Cantitate,2)
,round(convert(decimal(17,5), pd.pret_vanzare*pd.Cantitate),2)
,pd.* 
from pozdoc pd join pozcon pc on pd.Subunitate=pc.Subunitate and pd.Tert=pc.Tert and pd.Contract=pc.Contract and pd.Cod=pc.cod
where pc.contract='1137' and pc.Tert='RO1437292'
--group by pd.cod