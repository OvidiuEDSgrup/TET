select *
--a.subunitate, a.gestiune, a.cont, a.cod, a.data, a.data_stoc, a.cod_intrare, a.pret, 
--(case when 0=1 and 0=1 /*pare ca nu trebuie - cursorul din pozincon ia PI/FI pe parte de credit*/ then (case a.tip_document when 'FI' then 'DF' when 'PI' then 'PF' else a.tip_document end) else a.tip_document end) as tip_document, 
--a.numar_document, (case when 0=0 then a.cantitate else a.cantitate_UM2 end) as cantitate, a.tip_miscare, a.in_out, a.predator, a.jurnal, a.tert, a.serie, 
--a.pret_cu_amanuntul-(case when 0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent then a.pret else 0 end) as pret_cu_amanuntul,
--a.tip_gestiune, a.locatie, a.data_expirarii, a.TVA_neexigibil, a.pret_vanzare, a.accize_cump,
--a.comanda, a.furnizor, a.contract, a.loc_de_munca
into tempdb..balst1128_1                                 
from dbo.fStocuri('12/01/2013', '12/31/2013', null, '211.NT', null, '', 'D', '', 0, '', '', '', '', '', '                    ', null) a
where (''='' or a.gestiune like RTrim(''))
and (0=0 or a.tip_gestiune='A')
and (0=0 or left(a.locatie, 30 )='')
and (''='' or a.comanda='') 
and (''='' or a.furnizor='') 
and (''='' or a.contract='') 
and (''='' or a.loc_de_munca='') 
and ('                    '='' or a.lot='                    ')
and not (0=1 and a.tip_document in ('TE', 'TI') and a.cont=a.cont_corespondent and a.tip_gestiune not in ('A', 'V'))
and (0=0 or a.tip_gestiune in ('F', 'T') or exists (select 1 from gesttmpid gt where gt.gestiune=a.gestiune and gt.HostId='1128'))
and (0=0 or exists (select 1 from personal where personal.marca=a.gestiune and personal.loc_de_munca like RTrim('211.NT')+'%'))
and (0=0 or abs(a.cantitate_UM2)>=0.001)
