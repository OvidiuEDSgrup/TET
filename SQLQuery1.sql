select * from pozdoc p where p.cod='557A1056            ' 
--and (p.Cod_intrare like 'IMPL1A' or p.Grupa like 'IMPL1A'
and 'IMPL1A' in (p.Cod_intrare,p.Grupa) 
and '300' in (p.Gestiune,p.Gestiune_primitoare)
order by data

--ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(CONVERT(varchar,SUM(p.cantitate)))+'_'+rtrim(isnull(max(n.UM),'')) +'_cu_'+RTRIM(p.Tip)+'_'+rtrim(p.numar)+'_din_'+rtrim(convert(varchar,p.data,102)),' ','_') from pozdoc p where p.Subunitate=s.Subunitate and p.Tip='TE' and p.Factura=s.Contract and p.Gestiune_primitoare=s.Cod_gestiune and p.Cod=s.cod and p.Grupa=s.Cod_intrare and p.stare not in ('4', '6') and p.cantitate>0 GROUP BY p.Tip,p.Numar,p.Data FOR XML PATH('')),' ','_'),'_',' '),'')
select * from stocuri s where s.Cod_gestiune='300'
 --s.Cod like '10800044' 
select p.Cod,p.Grupa,COUNT(distinct p.Factura) 
from pozdoc p where p.Tip='TE' and p.Gestiune_primitoare='300'
and exists 
(select 1 from stocuri s where s.Cod=p.Cod and s.Cod_intrare=p.Grupa and s.Cod_gestiune=p.Gestiune_primitoare and s.Stoc>0) 
group by p.Cod,p.Grupa
having COUNT(distinct p.Factura)>1

SELECT Grupa=rtrim(te.Grupa)+ltrim(te.Factura) 
,*
-- update te set Grupa=rtrim(te.Grupa)+ltrim(te.Factura) 
from pozdoc te where te.Tip='TE' and te.Gestiune_primitoare='300' and exists 
(select p.Cod,p.Grupa,MAX(p.data) as data 
from pozdoc p where p.Tip='TE' and p.Gestiune_primitoare='300'
and exists 
(select 1 from stocuri s where s.Cod=p.Cod and s.Cod_intrare=p.Grupa and s.Cod_gestiune=p.Gestiune_primitoare and s.Stoc>0) 
group by p.Cod,p.Grupa
having COUNT(distinct p.Factura)>1
and p.Cod=te.cod and p.Grupa=te.grupa and MAX(p.Data)=te.data)
and exists 
(select 1 from pozdoc ie where ie.Tip_miscare='E' and ie.Gestiune=te.Gestiune_primitoare and ie.Cod=te.Cod and ie.Cod_intrare=te.Grupa
and ie.Contract=te.Factura)

select * from sysspd s order by s.Data_stergerii desc

select * 
-- update p set grupa=s.grupa
from pozdoc p inner join sysspd s 
on s.Subunitate=p.Subunitate and s.Tip=p.Tip and s.Numar=p.Numar and s.Data=p.Data and s.Numar_pozitie=p.Numar_pozitie
where s.Data_stergerii='2012-06-01 16:23:11.130'
