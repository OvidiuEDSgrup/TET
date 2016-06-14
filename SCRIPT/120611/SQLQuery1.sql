select s.tert,s.Stare,s.Utilizator,* from sysspd s where '118480' in (s.Factura,s.Numar)
order by s.Data_stergerii

select s.tert,s.Stare,s.Utilizator,s.Data_operarii,* from pozdoc s where 1=0
or '118480' in (s.Factura,s.Numar) 
or '118558' in (s.Factura,s.Numar)  
--or '9420120' in (s.Factura,s.Numar)  
--or s.Tert in ('RO12046745')
order by s.Data_operarii, s.Ora_operarii
/*
select * from yso_syssd s where '118480' in (s.Factura,s.Numar)
order by s.Data_stergerii
select * from doc s where '118480' in (s.Factura,s.Numar)
*/
select * from syssp s where s.Parametru IN ('ULTNRF','AVIZE')
and s.Data_stergerii between '2012-06-06 14:00:00.000' and '2012-06-06 15:00:00.000'
order by s.Data_stergerii 
select * from syssp s where s.Parametru IN ('ULTNRF','AVIZE') and s.Val_numerica between 118475 and 118485
order by s.Data_stergerii 

select * from syssp s where s.Tip_parametru ='ID'
and s.Data_stergerii between '2012-06-06 14:00:00.000' and '2012-06-06 15:00:00.000'
order by s.Data_stergerii 

select * from incfact i 
where 1=1
--and '118183' in (i.Numar_factura)
and i.Numar_pozitie>1
order by i.Data_operarii desc, i.Ora_operarii desc


select distinct 
PP.Factura,pp.Numar,pp.tert
,pp.Subunitate,pp.Tip,pp.Data
--,* 
from pozdoc pp where pp.Tip='AP'
and (pp.Factura in
(select p.Factura from pozdoc p
group by p.Factura
having COUNT(distinct p.Numar+p.factura)>1
--order by p.Factura--,p.Numar,p.Data_operarii,p.Ora_operarii
)
or pp.Factura in
(select i.Numar_factura from incfact i 
where 1=1
--and '118183' in (i.Numar_factura)
and i.Numar_pozitie>1
--order by i.Data_operarii desc, i.Ora_operarii desc
)  )
order by PP.Factura,pp.Numar,pp.tert
,pp.Data_operarii,pp.Ora_operarii