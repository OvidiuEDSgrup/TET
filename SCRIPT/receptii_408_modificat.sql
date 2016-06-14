if object_id('tmp_receptii_408') is not null
	drop table tmp_receptii_408
select distinct tert,factura,data_facturii--, nrcrt=identity(int,1,1)
into tmp_receptii_408
from pozdoc p where p.subunitate='1' and p.tip='RM' and p.data>='2013-01-01'
and p.cont_factura like '408%'
--and p.data<>p.data_facturii


update tva
set tip_tva='P', dela=data_facturii
from TVApeTerti tva inner join tmp_receptii_408 t on t.tert=tva.tert and t.factura=tva.factura 
where tipf='F' and tva.tip_tva<>'P'

insert TVApeTerti (tipf,tert,dela,tip_tva,factura)
select 'F',t.tert,t.data_facturii,'P',t.factura
from tmp_receptii_408 t left join TVApeTerti tva on t.tert=tva.tert and t.factura=tva.factura and tva.tipf='F'
where tva.tip_tva is null


--SELECT * FROM pozdoc
WHERE YEAR(DATA)='2013' AND Tip='rm'
AND Cont_factura='408' AND Cont_venituri='4428'

--update pozdoc
set Cont_venituri='4426'
where YEAR(DATA)='2013' AND Tip='rm'
AND Cont_factura='408' AND Cont_venituri='4428'


