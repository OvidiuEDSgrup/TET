select * from pozdoc p where p.Tip in ('AP','TE','AC') and p.Cod='EFC-H34'
and p.Utilizator='MAGAZIN_CJ'
and p.Tert like '25490633'
ORDER BY p.Tip,p.data
--and p.Pret_cu_amanuntul

select * from terti t where t.Denumire like '%isabela%'