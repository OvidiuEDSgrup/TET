select a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret, 
(case when 0=1 and 0=1 /*pare ca nu trebuie - cursorul din pozincon ia PI/FI pe parte de credit*/ then (case a.tip_document when 'FI' then 'DF' when 'PI' then 'PF' else a.tip_document end) else a.tip_document end) as tip_document, 
a.numar_document, (case when 0=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
a.pret_cu_amanuntul-(case when 0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent then a.pret else 0 end) as pret_cu_amanuntul,
a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump,
a.comanda, a.furnizor, a.contract, a.loc_de_munca
--into tempdb..balst77801                                 
from dbo.fStocuri('08/01/2012', '08/31/2012', null, '211', null, '', 'D', '', 0, '', '', '', '', '', '                    ') a
where (''='' or a.gestiune like RTrim(''))
and (0=0 or a.tip_gestiune='A')
and (0=0 or left(a.locatie, 30 )='')
and (''='' or a.comanda='') 
and (''='' or a.furnizor='') 
and (''='' or a.contract='') 
and (''='' or a.loc_de_munca='') 
and ('                    '='' or a.lot='                    ')
and not (0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent and a.tip_gestiune not in ('A', 'V'))
and (0=0 or a.tip_gestiune in ('F', 'T') or exists (select 1 from gesttmpid gt where gt.gestiune=a.gestiune and gt.HostId='7780'))
and (0=0 or exists (select 1 from personal where personal.marca=a.gestiune and personal.loc_de_munca like RTrim('211')+'%'))
and (0=0 or abs(a.cantitate_UM2)>=0.001)


select a.gestiune, a.cont, a.cod, a.data, a.data_expirarii, a.cod_intrare
, (case when           1.00000000 =0 then a.pret_cu_amanuntul else a.pret end) as pret
, (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) as stoc_scriptic
, 0 as stoc_faptic, (case when 0=1 then substring(b.denumire,1,13) else a.cod end) as den
, b.grupa, (case when 0=1 then a.serie else '' end) as serie, 
a.locatie
--into ##stocinv77801 
from tempdb..balst77801 a, nomencl b 
where a.cod=b.cod and b.grupa like rtrim('')+'%' and b.cont like rtrim('')+'%' 
union all 
select a.gestiunea, '', a.cod_produs, a.data_inventarului, a.data_inventarului, '', a.pret, 0, a.stoc_faptic, (case when 0=1 then  substring(b.denumire,1,13) else a.cod_produs end), b.grupa, '', ''
from inventar a, nomencl b 
where 0=0 and 1=1 and a.gestiunea  between '211' and '211' and (0=0 or a.cod_de_bara='                              ') and a.cod_produs between '' and 'zzzzzzzzzzzzz' and a.data_inventarului='08/31/2012' and a.cod_produs=b.cod and  b.grupa like rtrim('')+'%' and b.cont like rtrim('')+'%' 
and (0=0 and a.cod_de_bara<>'F' or 0=1 and a.cod_de_bara='F')
and (0=0 or exists (select 1 from personal p where p.marca=a.gestiunea and p.loc_de_munca like RTrim('         ')+'%'))
union all 
select a.gestiunea, '', a.cod_produs, a.data_inventarului, a.data_inventarului, '', 0, 0, a.stoc_faptic, (case when 0=1 then  substring(b.denumire,1,13) else a.cod_produs end), b.grupa, a.serie, ''
from invserii a, nomencl b 
where 0=1 and 1=1 and a.gestiunea  between '211' and '211' and a.cod_produs between '' and 'zzzzzzzzzzzzz' and a.data_inventarului='08/31/2012' and a.cod_produs=b.cod and  b.grupa like rtrim('')+'%' and b.cont like rtrim('')+'%'

if 0=1
 update ##stocinv77801
 set cont=isnull((select max(s1.cont) from ##stocinv7780 s1 where s1.gestiune=s.gestiune and s1.cod=s.cod), '')
 from ##stocinv77801 s
 where s.cont=''

select gestiune, cod, max(grupa), sum(stoc_scriptic), sum(stoc_faptic), max(pret), 
(case when abs(sum(stoc_scriptic))<0.001 then 0 else sum(stoc_scriptic*pret) end), 
(case when abs(sum(stoc_scriptic))<0.001 then 0 else sum(stoc_scriptic*pret)/sum(stoc_scriptic) end), 
(case when 0=1 then cont else '' end) as contord, max(data), (case when 0=1 then serie else '' end), 
(case when 0=1 then grupa else ''  end) as grupaord, max(cod_intrare), max(den) as den1 
from ##stocinv77801 
group by gestiune, (case when 0=1 then cont else '' end), (case when 0=1 then grupa else ''  end), cod, (case when 0=1 then serie else '' end)
having abs(sum(stoc_scriptic))>=0.001 or abs(sum(stoc_faptic))>=0.001 or abs(sum(stoc_scriptic*pret))>=0.01
order by gestiune, contord, grupaord, den1, cod
