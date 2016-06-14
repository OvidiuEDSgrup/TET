if object_id('tmp_avize_44282') is not null
	drop table tmp_avize_44282
select distinct tert,factura,data_facturii--, nrcrt=identity(int,1,1)
into tmp_avize_44282
from pozdoc p where p.subunitate='1' and p.tip in ('AP','AS') and p.data between '2013-08-01' and '2013-08-31'
and p.Grupa like '4428.2%'
--and p.data<>p.data_facturii

select
--update pozdoc set 
grupa='4427'
from pozdoc p 
where YEAR(DATA)='2013' and MONTH(data)=8 AND Tip in ('ap','as')
AND p.Grupa='4428.2'

update tva
set tip_tva='P', dela=data_facturii
from TVApeTerti tva inner join tmp_avize_44282 t on t.tert=tva.tert and t.factura=tva.factura 
where tipf='B' and tva.tip_tva<>'P'

insert TVApeTerti (tipf,tert,dela,tip_tva,factura)
select 'B',t.tert,t.data_facturii,'P',t.factura
from tmp_avize_44282 t left join TVApeTerti tva on t.tert=tva.tert and t.factura=tva.factura and tva.tipf='F'
where tva.tip_tva is null



