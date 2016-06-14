select 
d.Cod_produs,(d.val),(p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata),p.Pret*(1.00-p.Discount/100),(p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata)-(d.val)
--sum((d.val)-(p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata))
--sum(d.val),sum(p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata)
--,* 
from pozcon p inner join
--(select d.Cod,val=sum(d.Pret_vanzare*d.Cantitate)
--from pozdoc d where d.Subunitate='1' and d.Tip='AC' and d.Numar='40001' and d.Data='2013-03-28'
--group by d.Cod) d on d.Cod=p.Cod inner join
(select d.Cod_produs,val=sum(d.Pret/1.24*(1-d.Discount/100)*d.Cantitate)
from bp d where d.Casa_de_marcat='4' and d.Numar_bon='1' and d.Data='2013-03-28'
group by d.Cod_produs) d on d.Cod_produs=p.Cod
where p.Contract='9840110 '
and d.val<>(p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata) 
order by (p.Pret*(1.00-p.Discount/100)*p.Cant_aprobata)-(d.val) desc

select SUM(d.total)--d.*,a.*--d.Cod_produs,val=sum(d.Pret/1.24*(1-d.Discount/100)*d.Cantitate)
from bp d inner join antetBonuri a on a.IdAntetBon=d.IdAntetBon
where d.Casa_de_marcat='4' and d.Numar_bon='1' and d.Data='2013-03-28' and d.Tip=21
and d.Cod_produs='200-PRT1620         '

--select *
--from pozdoc d where d.Subunitate='1' and d.Tip='AC' and d.Numar='40001' and d.Data='2013-03-28'

select *--d.Cod_produs,val=sum(d.Pret/1.24*(1-d.Discount/100)*d.Cantitate)
from testov..bp d where d.Casa_de_marcat='9' and d.Numar_bon='2' and d.Data='2013-03-28'
and d.Cod_produs='200-PRT1620         '

select * from bp t inner join testov..bp o on o.Cod_produs=t.Cod_produs
where  t.Casa_de_marcat='4' and t.Numar_bon='1' and t.Data='2013-03-28' and t.Tip=21
and o.Casa_de_marcat='9' and o.Numar_bon='2' and o.Data='2013-03-28'
and t.Total<>o.Total

select sum(round(round(convert(decimal(12,2),p.Pret*(1+convert(decimal(12,2),p.Cota_TVA)/100.00))
	*(1-convert(decimal(12,2),p.Discount)/100),2)*convert(decimal(15,3),p.Cant_aprobata),2)),sum(d.Total)
--convert(decimal(15,2),p.Pret*(1+p.Cota_TVA/100)),d.Pret
--,* 
from yso.pozconexp p inner join bp d on d.Cod_produs=p.Cod
where p.Contract='9840110 '
and d.Casa_de_marcat='4' and d.Numar_bon='1' and d.Data='2013-03-28' and d.Tip=21
--and convert(decimal(15,2),p.Pret*(1+p.Cota_TVA/100))<>d.Pret
and round(round(convert(decimal(12,2),p.Pret*(1+convert(decimal(12,2),p.Cota_TVA)/100.00))
	*(1-convert(decimal(12,2),p.Discount)/100),2)*convert(decimal(15,3),p.Cant_aprobata),2)<>d.Total

SELECT d.Pret
,d.Total
,round(round(convert(decimal(15,2),d.Pret)*(1-d.Discount/100),2)*d.Cantitate,2)
,dif=round(round(convert(decimal(15,2),d.Pret)*(1-d.Discount/100),2)*d.Cantitate,2)
-d.Total
,*
FROM bp d
where d.Casa_de_marcat='4' and d.Numar_bon='1' and d.Data='2013-03-28' and d.Tip=21
order by dif desc

select p.Pret,p.Discount
,p.Pret*(1-p.Discount/100.00),p.Pret*(1-convert(decimal(12,2),p.Discount)/100.00)
,p.Pret*(1+p.Cota_TVA/100.00)*(1-p.Discount/100.00)
,p.Pret*(1+convert(decimal(12,2),p.Cota_TVA)/100.00)*(1-p.Discount/100.00)
,*
from pozcon p where p.Contract='9840110'