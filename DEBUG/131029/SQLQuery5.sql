select * from stocuri s where s.Cod_gestiune like '700.GL' and s.Stoc>0
select * from antetBonuri a join bp on bp.IdAntetBon=a.IdAntetBon
where a.Casa_de_marcat=7 and a.Numar_bon=1 and a.Data_bon='2013-09-09'
select c.Cod_dobanda,p.Factura,* from pozcon p join con c on c.Contract=p.Contract and c.Tert=p.Tert
where p.Contract='9870035'

select c.Cod_dobanda,* from sysscon c where c.Contract='9870035' 

select p.Factura,p.Comanda,p.Gestiune,p.Gestiune_primitoare,* from pozdoc p where --p.Cod='VB-060502-B' and 
p.Comanda like '1861111171694'
and p.Numar='9370028'

select * from par p where p.Parametru like 'REZSTOCBK'
select * from syssp p where p.Parametru like 'REZSTOCBK' order by p.Data_stergerii desc