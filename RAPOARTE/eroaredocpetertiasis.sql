select *
--p.subunitate, p.tert, p.factura, p.tip, p.numar, p.data, (case when p.data between '01/01/1921' and '05/31/2012' then '2' else '1' end) as in_perioada, 
--p.valoare+p.tva as total, 0 as tva_11, p.tva as tva_22, 
--(case when 'B'='B' and 0=1 and p.fel='3' and p.cont_coresp like '413%' and (p.achitat>isnull(e.decontat, 0) or p.achitat<0 and isnull(e.decontat, 0)=0) then isnull(e.decontat, 0) else p.achitat end) as achitat, 
--p.loc_de_munca, p.comanda, p.cont_de_tert, p.fel, p.cont_coresp, space(3) as valuta, 
--p.explicatii, p.numar_pozitie, 
--(case when 'B'='F' then 
-- (case when p.tip in ('SI', 'PF', 'PR') then 'FC' when p.tip in ('SX', 'CO', 'FX', 'C3', 'RX') then 'D' else 'C' end) else 
-- (case when p.tip in ('SI', 'IB', 'IR') then 'FD' when p.tip in ('IX', 'BX', 'CO', 'C3', 'AX') then 'C' else 'D' end) end) as op,
--p.gestiune, p.data_facturii, p.data_scadentei, 0 as curs, p.nr_dvi as DVI, p.barcod, 
--0 as totLPV, 0 as achLPV, space(10) as Utilizator, contTVA, contract, data_platii 
--into tempdb..doctert7616 
from dbo.fTert ('B', '01/01/1921', '05/31/2012', 'RO566132', '%', '', 0, 0, 0, '') p
--left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
--left outer join infotert i on p.subunitate=i.subunitate and p.tert=i.tert and i.identificator='' 
--left outer join facturi f on p.subunitate=f.subunitate and p.tert=f.tert and p.factura=f.factura and f.tip=(case when 'B'='F' then 0x54 else 0x46 end)
--left outer join efecte e on 'B'='B' and 0=1 and p.fel='3' and p.cont_coresp like '413%' and e.subunitate=p.subunitate and e.tert=p.tert and e.tip='I'
--	and e.nr_efect=(case when charindex('|', p.numar)>0 then RTRim(substring(p.numar, charindex('|', p.numar) + 1, 20)) else p.numar end)
--	and e.data_decontarii<='05/31/2012'
--where (0=0 or p.tip<>'SI') and (0=0 or isnull(t.judet,'')='') and (0=0 or isnull(t.localitate,'')='') 
--and (0=0 or '        ' in (select jz.zona from judzone jz where jz.judet=isnull(t.judet, '') and (0=0 or jz.divizia=left(isnull(f.loc_de_munca, ''), 1)))) 
--and isnull(t.grupa, '') between '' and 'zzz' and isnull(i.descriere,'') between '' and 'zzzzz' and isnull(f.loc_de_munca,'') like rtrim('')+'%' 
--and (0=0 or p.tip not in ('SI', 'AP', 'AS') or rtrim(p.factura) <> '')
--and (0=0 or rtrim(left(isnull(f.comanda, ''),20))=rtrim('                    ')) and (0=0 or rtrim(right(isnull(p.comanda, ''),20))=rtrim('                    '))