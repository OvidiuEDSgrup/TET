select 
--p.subunitate, p.tip, p.data, p.numar, p.gestiune, max(isnull(g.tip_gestiune, '')) 
--as tip_gestiune, max(isnull(g.cont_contabil_specific, '')) as cont_specific, 
p.cont_de_stoc, p.cont_corespondent, p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, 
--p.loc_de_munca, p.comanda, n.grupa, p.jurnal, 
--sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) as val_pret_stoc, 
--sum(round(convert(decimal(17,5), p.cantitate*p.pret_cu_amanuntul), 2)) as val_pret_amanunt, 
--sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
--p.pret_cu_amanuntul*p.cota_tva/(100.00+p.cota_tva)),2)), 2)) as val_tva_nx_pret_amanunt, 
--sum(round(convert(decimal(17,5), p.cantitate*p.pret_amanunt_predator), 2)) as val_pret_amanunt_predator,
--sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
--p.pret_amanunt_predator*p.tva_neexigibil/(100+p.tva_neexigibil)),2)), 2)) 
--as val_tva_nx_pred, 
--sum(round(convert(decimal(17,5), p.cantitate*p.suprataxe_vama), 2)) as val_supratx_vama, 
--sum(round(convert(decimal(30,5), p.cantitate*p.accize_cumparare), 2)) as val_accize_cumparare, 
max(p.valuta), max(p.curs)
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join conturi c on p.subunitate = c.subunitate and p.cont_de_stoc = c.cont 
WHERE p.subunitate='1' and p.tip='AC' and p.data between '2012-09-01' and '2012-09-30' 
--and (@nrdoc='' or p.numar=@nrdoc) 
GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, p.loc_de_munca, p.comanda, n.grupa, 
p.jurnal 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune 