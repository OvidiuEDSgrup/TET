select round(convert(decimal(12,2),p.Cantitate)*round(round(convert(decimal(12,2),p.Pret)*(1.00+convert(decimal(12,2),p.Cota_TVA)/100.00),2)*(1.00-convert(decimal(12,2),p.Discount)/100),2),2)
,round(convert(decimal(12,2),p.Cantitate)*round(round(convert(decimal(12,2),p.Pret)*(1.00-convert(decimal(12,2),p.Discount)/100),2)*(1.00+convert(decimal(12,2),p.Cota_TVA)/100.00),2),2)
,100*round(2.98-2.98*0.25,2)
,200*round(4.49-4.49*0.25,2)
,*
from pozcon p where p.Contract='9831796'