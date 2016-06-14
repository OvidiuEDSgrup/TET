--select distinct p.Tip_miscare,p.Tip from pozdoc p where exists 
--(select * from stocuri s where data='12/31/2999' and s.cod=p.cod and s.cod_intrare=p.cod_intrare and s.cod_gestiune=p.gestiune)
--and p.Data>='2014-01-01'
--1        	AP	SV940103	702000026           	2014-03-20 00:00:00.000	211.SV   	6248003A            	1
--exec RefacereStocuri null,null,null,null,null,null


select s.* -- update s set data=p.data
from istoricstocuri s 
outer apply (select top 1 * from pozdoc p where p.Data<=s.Data_lunii and s.cod=p.cod 
	and (s.cod_intrare=p.cod_intrare and s.cod_gestiune=p.gestiune and p.Tip_miscare='E' 
		OR s.cod_intrare=p.Grupa and s.cod_gestiune=p.Gestiune_primitoare and p.Tip='TE')
		order by p.Data) p
where s.Data='12/31/2999' 
	--and p.Tip='TE'
	and p.Tip is null
	
	--select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* from pozdoc p where 
	--'211.GL              ' in (p.gestiune,p.Gestiune_primitoare) and 'VB-060504-R         '=p.Cod and '6644010AA           ' in (p.Cod_intrare,p.Grupa)
	--select p.Cod_intrare,* from istoricstocuri p where 
	--'210.GL              ' in (p.cod_gestiune) and 'VB-060504-R         '=p.Cod and '6644010AA           ' in (p.Cod_intrare) order by p.Data_lunii