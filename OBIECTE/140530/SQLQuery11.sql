select s.Pret_cu_amanuntul,* from stocuri s where s.Cod=
'01350320'
and s.Cod_intrare like 
            	'7146010a%'            
       
 select p.Pret_amanunt_predator,p.Pret_cu_amanuntul,p.Discount,p.Cod_intrare
 ,* from pozdoc p where p.Cod='01350320' and '7146010a' in (p.Cod_intrare,p.Grupa) and '210.IS' in (p.Gestiune,p.Gestiune_primitoare)
 
 select p.Gestiune_primitoare,p.Grupa,* from pozdoc p left join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune_primitoare and p.Cod=s.cod
 and s.Cod_intrare=p.Grupa
 where p.Tip='TE' and p.Gestiune like '211.%' and p.Pret_amanunt_predator<>p.Pret_cu_amanuntul
 and s.Data=p.Data
 and not exists (select top 1 * from pozdoc t where t.Tip='te' and s.Subunitate=t.Subunitate and s.Cod_gestiune=t.Gestiune_primitoare and s.Cod=t.cod
 and s.Cod_intrare=t.Grupa and not(t.Numar=p.Numar and t.Data=p.Data))
 order by p.idPozDoc desc
 
 select p.Pret_amanunt_predator,p.Pret_cu_amanuntul,p.Discount,p.Cod_intrare
 ,* from pozdoc p where p.Cod='PKKPKP300/1000' and 'TE809742' in (p.Cod_intrare,p.Grupa) and '400' in (p.Gestiune,p.Gestiune_primitoare)