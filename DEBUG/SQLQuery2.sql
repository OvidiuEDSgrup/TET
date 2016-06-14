--factura,data_facturii,den_tert,valuta,cant*pret,tvalei,cant*pret_valuta,categ_pret
select --*, 
p.factura,max(convert(date,p.data_facturii)) as data_facturii,p.tert,max(t.Denumire) as den_tert
,max(p.valuta) as valuta
,sum(round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),2)) as valoare_lei
,SUM(p.TVA_deductibil) as tva
,sum(round(convert(decimal(17,5),p.cantitate*p.Pret_valuta),2)) as valoare_valuta
,MAX(p.Accize_cumparare) as categ_pret
,MAX(cp.Denumire) as den_categ_pret
from pozdoc p 
left join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert
left join categpret cp on cp.Categorie=p.Accize_cumparare
where p.Subunitate='1' and p.Tip='AP' and p.Data between '2012-03-01' and '2012-03-31'
GROUP BY p.Subunitate,p.factura,p.Tert 
ORDER BY MAX(P.data_facturii)