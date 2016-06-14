
/*
--select * from comenzi c where c.Descriere like '%lovas%'
select n.Denumire,n.Cod
,p.Gestiune,p.Cod_intrare,p.Gestiune_primitoare,p.Grupa
,p.* from pozdoc p inner join nomencl n on n.cod=p.Cod 
where p.Comanda like '2840121245037'
and n.Denumire like '%aliaj%'
order by p.Data desc

select * from stocuri s where s.Cod_gestiune='700'
--s.Comanda like '2840121245037' 
and s.Cod=
--'45255'
--'5090 022000000'
'5270 018000000'
--'1807CU3             '
--*/

declare @cod varchar(20)='',@comanda varchar(20)=''

--if OBJECT_ID('tempdb..#poztecodintrsuprapuse') is not null
--	drop table #poztecodintrsuprapuse
--/*
select * 
--into #poztecodintrsuprapuse
from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.Gestiune_primitoare='700' 
and p.Comanda<>''
and exists 
(select 1 from stocuri s where s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune_primitoare and s.Cod=p.Cod and s.Cod_intrare=p.Grupa
and s.Comanda<>p.Comanda)
and (isnull(@comanda,'')='' or p.Comanda=@comanda)
and (isnull(@cod,'')='' or p.cod=@cod)

select * from stocuri s where s.Cod_gestiune='700'
and exists
	(select 1 from pozdoc d where d.Subunitate=s.Subunitate and d.Gestiune_primitoare=s.Cod_gestiune and d.Cod=s.Cod 
	and d.Grupa=s.Cod_intrare and d.Comanda<>s.Comanda
	and (isnull(@comanda,'')='' or d.Comanda=@comanda)
	and (isnull(@cod,'')='' or d.cod=@cod))

select p.Comanda,p.* from pozdoc p where p.Subunitate='1' and p.Gestiune='700'  
and p.Comanda<>''
and exists 
(select * from stocuri s where s.Cod_gestiune=p.Gestiune
and exists
	(select 1 from pozdoc d where d.Subunitate=s.Subunitate and d.Gestiune_primitoare=s.Cod_gestiune and d.Cod=s.Cod 
	and d.Grupa=s.Cod_intrare and d.Comanda<>s.Comanda
	and (isnull(@comanda,'')='' or d.Comanda=@comanda)
	and (isnull(@cod,'')='' or d.cod=@cod))
and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Grupa)

select p.Comanda,p.* from pozdoc p where p.Subunitate='1' and p.gestiune_primitoare='700'  
and p.Comanda<>''
and exists 
(select * from stocuri s where s.Cod_gestiune=p.Gestiune_primitoare and s.Cod=p.Cod and s.Cod_intrare=p.Grupa
and exists
	(select 1 from pozdoc d where d.Subunitate=s.Subunitate and d.Gestiune_primitoare=s.Cod_gestiune and d.Cod=s.Cod 
	and d.Grupa=s.Cod_intrare and d.Comanda<>s.Comanda
	and (isnull(@comanda,'')='' or d.Comanda=@comanda)
	and (isnull(@cod,'')='' or d.cod=@cod))
)
--*/

/*
select SUM(p.Cantitate*p.Pret_cu_amanuntul)
--,* 
from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.Gestiune_primitoare='700'
and (isnull(@comanda,'')='' or p.Comanda=@comanda)

select SUM(p.Cantitate*p.Pret_cu_amanuntul)
--,* 
from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.Gestiune='700'
and (isnull(@comanda,'')='' or p.Comanda=@comanda)


select SUM(p.Valoare)
--,* 
from doc p where p.Subunitate='1' and p.Tip='TE' and p.Gestiune_primitoare='700'
and (isnull(@comanda,'')='' or p.Comanda=@comanda)

select SUM(p.Valoare)
--,* 
from doc p where p.Subunitate='1' and p.Tip='TE' and p.Cod_gestiune='700'
and (isnull(@comanda,'')='' or p.Comanda=@comanda)
--*/