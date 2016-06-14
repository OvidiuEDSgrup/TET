select p.tip, p.numar, p.data, 
(case  9  when 7 then p.loc_de_munca when 9 then convert(char(10), p.data, 102) else p.comanda end) as ord, 
(case  9  when 7 then p.loc_de_munca when 9 then convert(char(10), p.data, 104) else p.comanda end) as lm_com_data, 
(case  9  when 7 then isnull(lm.denumire, '') when 9 then convert(char(10), p.data, 104) else isnull(c.descriere, '') end) as desc_lm_com_data, 
p.cod, p.cantitate, p.pret_de_stoc, (case when 0=1 then pr.pret_vanzare else p.pret_vanzare end) as pret_vanzare, 
round(convert(decimal(17,5), (case when p.pret_de_stoc<>0 then (((case when 0=1 then pr.pret_vanzare else p.pret_vanzare end)/p.pret_de_stoc) - 1.00)*100.00 else 100 end)), 2) as adaos, 
p.tva_deductibil, p.factura, 
isnull(n.denumire, '') as denumire_nom, isnull(n.UM, '') as UM_nom, n.tip  
from pozdoc p 
left outer join lm on lm.cod=p.loc_de_munca 
left outer join comenzi c on c.subunitate=p.subunitate and c.comanda=p.comanda 
left outer join terti t on t.tert=p.tert 
left outer join nomencl n on n.cod=p.cod 
left outer join gestiuni g on p.subunitate=g.subunitate and p.gestiune=g.cod_gestiune 
left outer join stocuri s on p.subunitate=s.subunitate and s.tip_gestiune=g.tip_gestiune
and s.cod_gestiune=p.gestiune and s.cod=p.cod and s.cod_intrare=p.cod_intrare 
left outer join preturi pr on pr.cod_produs=p.cod and pr.um=0 and pr.tip_pret='1' and pr.data_superioara='2999-01-01' 
where p.subunitate='1        ' and p.tip in ('AC', 'AP', 'AS') and p.data between '07/01/2012' and '07/31/2012' 
and (0=0 or p.loc_de_munca like RTrim('         ')+'%') and (0=0 or p.comanda='             ') and (0=0 or p.tert='             ') 
and (0=0 or p.cod='                    ') and (0=0 or p.cont_de_stoc like RTrim('             ')+'%') and (0=0 or p.cont_factura like RTrim('             ')+'%') 
and (0=0 or p.valuta='   ') and (0=0 or p.cantitate<=-0.001) 
and (0=0 or round(convert(decimal(17,5), (case when p.pret_de_stoc<>0 then (p.pret_vanzare/p.pret_de_stoc - 1.00)*100.00 else 100 end)), 2) between 0 and 0) 
and (0=0 or p.gestiune='         ') and (0=0 or p.gestiune in (select gesttmp.gestiune from gesttmp where gesttmp.terminal=1752    )) 
and (0=0 or RTrim(p.factura) = '') 
and ((0=0 and 0=0) or (0=1 and p.contract='                    ') or (0=1 and p.contract<>'')) 
and (0=0 or p.jurnal='   ') 
and (0=0 or p.tip_miscare='E') 
and ((0=0 and 0=0) or (0=1 and s.furnizor='             ') or (0=1 and p.locatie like RTrim('T')+RTrim('')+'%')) 
and (0=0 or isnull(t.grupa, '')='   ') and (0=0 or isnull(t.tert_extern, 0)=1) 
and (0=0 or isnull(n.grupa, '') like RTrim('             ')+RTrim('%')) and (0=0 or isnull(n.furnizor, '')='             ') 
order by ord, p.cod, p.data, p.numar_pozitie
