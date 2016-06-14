select valstoci=(case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)
--max(case when  4 =5 or  4 =6 then isnull(p.loc_de_munca,'') when  4 =2 then n.grupa else a.gestiune end) as gest, 
--max(case when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda when  4 =6 or  4 =2 then a.gestiune when  4 =7 then n.grupa else a.cont end) as cont_marca,  max(n.grupa), 
--max(case when  4  in (1,2,6,7) then '' when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda else a.cont end) as cont_ordonare, 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)) 
from tempdb..balst1128_1 a 
left outer join nomencl n on a.cod=n.cod 
left outer join stocuri b on a.subunitate=b.subunitate and a.tip_gestiune=b.tip_gestiune and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
left outer join personal p on p.marca=a.gestiune 
where isnull(n.grupa,'') like rtrim('             ')+'%' and isnull(n.UM,'') like rtrim('   ')+'%' and (0=0 or isnull(right(n.tip_echipament,20),'')='                    ') 
and (' '='' or ' '='M' and left(a.cont,3) not in ('345','354','371','357') or ' '='P' and left(a.cont,3) in ('345','354') or ' '='A' and left(a.cont,3) in ('371','357'))
--group by (case when  4  in (1,2,6,7) then '' when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda else a.cont end), (case when  4 =5 or  4 =6 then isnull(p.loc_de_munca,'') when  4 =2 then n.grupa else a.gestiune end), (case when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda when  4 =6 or  4 =2 then a.gestiune when  4 =7 then n.grupa else a.cont end)
--order by cont_ordonare, gest, cont_marca


select stoci*pretraport,*
--max(case when  4 =5 or  4 =6 then isnull(p.loc_de_munca,'') when  4 =2 then n.grupa else a.gestiune end) as gest, 
--max(case when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda when  4 =6 or  4 =2 then a.gestiune when  4 =7 then n.grupa else a.cont end) as cont_marca,  max(n.grupa), 
--max(case when  4  in (1,2,6,7) then '' when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda else a.cont end) as cont_ordonare, 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)) 
from tempdb..stocuria_2 a 
left outer join nomencl n on a.cod=n.cod 
left outer join stocuri b on a.subunitate=b.subunitate and a.tip_gestiune=b.tip_gestiune and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
left outer join personal p on p.marca=a.gestiune 
where isnull(n.grupa,'') like rtrim('             ')+'%' and isnull(n.UM,'') like rtrim('   ')+'%' and (0=0 or isnull(right(n.tip_echipament,20),'')='                    ') 
and (' '='' or ' '='M' and left(a.cont,3) not in ('345','354','371','357') or ' '='P' and left(a.cont,3) in ('345','354') or ' '='A' and left(a.cont,3) in ('371','357'))
--group by (case when  4  in (1,2,6,7) then '' when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda else a.cont end), (case when  4 =5 or  4 =6 then isnull(p.loc_de_munca,'') when  4 =2 then n.grupa else a.gestiune end), (case when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda when  4 =6 or  4 =2 then a.gestiune when  4 =7 then n.grupa else a.cont end)
--order by cont_ordonare, gest, cont_marca

select stoci*pretraport,*
--max(case when  4 =5 or  4 =6 then isnull(p.loc_de_munca,'') when  4 =2 then n.grupa else a.gestiune end) as gest, 
--max(case when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda when  4 =6 or  4 =2 then a.gestiune when  4 =7 then n.grupa else a.cont end) as cont_marca,  max(n.grupa), 
--max(case when  4  in (1,2,6,7) then '' when  4 =10 then substring(a.locatie,15,16) when  4 =9 then /*left(a.locatie,13)*/a.comanda else a.cont end) as cont_ordonare, 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when 0=1 or (not (0=1 or 0=1 and a.tip_gestiune='A') and (isnull(n.tip, '')='A' and 1=0 or isnull(n.tip,'')<>'A' and 1=0)) then 0 when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)*(case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' then (case when a.tip_miscare='I' then a.cantitate else -a.cantitate end) else 0 end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='E' then 0 else a.cantitate end)), 
--sum((case when a.tip_document='SI' or a.data<'12/01/2013' or a.tip_miscare='I' then 0 else a.cantitate end)) 
from tempdb..stocuria_5 a 
left outer join nomencl n on a.cod=n.cod 
left outer join stocuri b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
left outer join personal p on p.marca=a.gestiune 
where isnull(n.grupa,'') like rtrim('             ')+'%' and isnull(n.UM,'') like rtrim('   ')+'%' and (0=0 or isnull(right(n.tip_echipament,20),'')='                    ') 
and (' '='' or ' '='M' and left(a.cont,3) not in ('345','354','371','357') or ' '='P' and left(a.cont,3) in ('345','354') or ' '='A' and left(a.cont,3) in ('371','357'))