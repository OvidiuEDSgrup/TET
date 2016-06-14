--select distinct data_lunii from istoricstocuri i
select cod,Gestiune_primitoare,Grupa,dbo.group_concat(distinct gestiune+Cod_intrare)
from pozdoc p
where p.Tip='TE' and p.Cantitate>0
group by cod,Gestiune_primitoare,Grupa 
having count(distinct Cod_intrare)>1
--select * from par p where p.Parametru like 'teaccodi'
select * -- delete i
from istoricstocuri i right join pozdoc p on p.Cod=i.Cod and p.Cod_intrare=i.Cod_intrare and p.Gestiune=i.Cod_gestiune
--p.idPozDoc=i.idIntrareFirma
where p.data='2011-12-31' and i.Cod is null

select * -- UPDATE i set idintrarefirma=p.idpozdoc,idintrare=p.idpozdoc
from istoricstocuri i join pozdoc p on p.Cod=i.Cod and p.Cod_intrare=i.Cod_intrare and p.Gestiune=i.Cod_gestiune and p.Tip='SI'
--p.idPozDoc=i.idIntrareFirma
where i.Data_lunii='2011-12-31' 

alter table pozdoc disable trigger all
select * -- delete p
from pozdoc p where p.Tip='SI' and p.Numar like 'stocinit%'
alter table pozdoc enable trigger all

select * -- update i set data='2011-12-31'
from istoricstocuri i where i.Data_lunii='2011-12-31' and i.Data>='2012-01-01'

alter table pozdoc disable trigger all
/*
select *, 
--*/update p set 
idIntrare=null,idIntrareFirma=null,idIntrareTI=null
from pozdoc p 
--where p.tip='SI'

alter table pozdoc enable trigger all

exec RefacereStocuri null,null,null,null,null,null

SELECT p.idPozDoc,* from pozdoc p where p.idPozDoc in (1639,4139)
           	               
select p.Gestiune,p.Cod_intrare,p.Gestiune_primitoare,p.Grupa,* from pozdoc p where p.Cod like '72280MS2A' and '86357' in (p.Cod_intrare,p.grupa)
order by p.Tip_miscare desc, p.Data, tip desc, p.idPozDoc
exec RefacereStocuri null,'72280MS2A',null,null,null,null
select * from stocuri s where s.Cod like '72280MS2A' and s.Cod_intrare like '86357'

select p.Gestiune,p.Cod_intrare,p.Gestiune_primitoare,p.Grupa,* from pozdoc p where p.Cod like '00360357' and 'IMPL1' in (p.Cod_intrare,p.grupa)
	and '101' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Tip_miscare desc, p.Data, tip desc, p.idPozDoc
     
select * from istoricstocuri s where s.Cod like '00360357' and s.Cod_intrare like 'IMPL1'  and s.Cod_gestiune='101'           	            	        

SELECT p.idPozDoc,* from pozdoc p where p.idPozDoc in (1639,4139)

alter table pozdoc disable trigger all
/*
select p.idIntrareFirma,s.idIntrareFirma,p.idpozdoc,*,
--*/update p set 
idIntrareFirma=nullif(s.idIntrareFirma,p.idpozdoc)
from pozdoc p join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
where p.Tip_miscare<>'V' and p.Tip NOT IN ('SI','FI') and NOT(p.Tip_miscare='I' and p.Cantitate>0 or p.Tip_miscare='E' and p.Cantitate<0)
	and nullif(s.idIntrareFirma,p.idpozdoc) is not null 
	and p.idIntrareFirma is null--isnull(p.idIntrareFirma,0)<>s.idIntrareFirma
	
/*
select p.idIntrare,s.idIntrare,p.idpozdoc,*, 
--*/update p set 
idintrare=nullif(s.idintrare,p.idpozdoc)
from pozdoc p join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
where p.Tip_miscare<>'V' and p.Tip NOT IN ('SI','FI') and NOT(p.Tip_miscare='I' and p.Cantitate>0 or p.Tip_miscare='E' and p.Cantitate<0)
	and nullif(s.idIntrare,p.idpozdoc) is not null
	and p.idIntrare is null --isnull(p.idIntrare,0)<>s.idIntrare
	and p.Data>='2015-12-01'
	
	
/*
select *, 
--*/update p set 
lot=p.Cod_intrare
from pozdoc p 
where (p.Tip_miscare='I' or p.Tip_miscare='E' and p.Tip<>'TE' and p.Cantitate<0)
	and p.Cod_intrare<>'' and p.lot='' 
	and p.Data>='2015-12-01'

/*
select *, 
--*/update p set 
cont_corespondent=(case when tip='RM' then p.lot else p.cont_corespondent end)
,grupa=(case when tip in ('PP','AI') then p.lot else grupa end)
from pozdoc p 
where (p.Tip_miscare='I' or p.Tip_miscare='E' and p.Tip<>'TE' and p.Cantitate<0)
	and p.tip in ('RM','PP','AI') and (case when tip='RM' then cont_corespondent when tip in ('PP','AI') then grupa end)=''
	and isnull(p.lot,'')<>''
	and p.Data>='2015-12-01'

alter table pozdoc enable trigger all

--select p.idIntrareFirma,p.idPozDoc,p.idIntrare,* from pozdoc p where p.Numar like '1017775' and p.Tip='te'

--select MAX(data_lunii) from tet..istoricstocuri

select i.* -- update i set idintrarefirma=s.idintrarefirma, idintrare=s.idintrare, lot=s.lot
from tet..istoricstocuri i 
left join stocuri s on s.Subunitate=i.Subunitate and s.Cod_gestiune=i.Cod_gestiune and s.Cod=i.Cod and s.Cod_intrare=i.Cod_intrare
where i.Data_lunii='2015-07-31' 
and s.Subunitate is null

select p.idPozDoc,p.idIntrareFirma,p.Gestiune_primitoare,p.Grupa,*
from pozdoc p where p.Cod='0066001' and '1142827005' IN (p.Cod_intrare,p.Grupa)
order by p.Data,p.Tip_miscare desc,p.Numar_pozitie    
             	       

alter table tet..pozdoc disable trigger all

/*
select *, 
--*/ update t set 
idintrarefirma=p.idintrarefirma, idintrare=p.idintrare, lot=p.lot
from tet..pozdoc t join pozdoc p on p.idPozDoc=t.idPozDoc
--where t.idintrarefirma<>p.idintrarefirma or t.idintrare<>p.idintrare

alter table tet..pozdoc enable trigger all

select * from stocuri s where s.Cod='0008023' and '1141338013AA' IN (s.Cod_intrare)

 exec RefacereStocuri null,'S6065A1003',null,null,null,null


select p.idPozDoc,p.idIntrareFirma,p.idIntrare,p.idPozDoc,p.Gestiune_primitoare,p.Grupa,p.Gestiune,p.Cod_intrare,*
from pozdoc p where p.Cod='S6065A1003' and '1142857001' IN (left(p.Cod_intrare,10),left(p.Grupa,10))
order by p.Data,p.Tip_miscare desc,p.Numar_pozitie  

select * from stocuri s where --s.idIntrareFirma is null 
Cod='S6065A1003' and s.Cod_intrare='1142857001A' 
select * from stocuri s where --s.idIntrareFirma is null 
Cod='S6065A1003' and s.Cod_intrare='1142857001' 
          	                  

select * from istoricstocuri s where s.Data_lunii='2015-08-31'
	and Cod='S6065A1003' and s.Cod_intrare='1142857001A' 
          	  

select * from pozdoc p where p.idPozDoc=535703

select i.* -- update i set idintrarefirma=s.idintrarefirma, idintrare=s.idintrare
from tet..stocuri i 
left join testov..stocuri s on s.Subunitate=i.Subunitate and s.Cod_gestiune=i.Cod_gestiune and s.Cod=i.Cod and s.Cod_intrare=i.Cod_intrare
left join istoricstocuri t on t.Subunitate=i.Subunitate and t.Tip_gestiune=i.Tip_gestiune and t.Cod_gestiune=i.Cod_gestiune and t.Cod=i.Cod 
	and t.Cod_intrare=i.Cod_intrare and t.Data_lunii='2015-08-31'
where s.Subunitate is null 

select * from stocuri s where s.idIntrareFirma is null
select * from stocuri s where s.idIntrare is null

select distinct I.TIP from pozdoc p join pozdoc i on i.idPozDoc=isnull(p.idIntrareFirma,p.idPozDoc)


alter table pozdoc disable trigger all

/*
select *, 
--*/update p set 
lot=null
from pozdoc p 

/*
select *, 
--*/update p set 
lot=p.Cod_intrare
from pozdoc p 
	JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
where p.Tip_miscare='I' or p.Tip_miscare='E' and p.Tip<>'TE' and p.Cantitate<0

/*
select *, 
--*/update p set 
cont_corespondent=(case when p.tip='RM' then '' else p.cont_corespondent end)
,grupa=(case when p.tip in ('PP','AI') then '' else grupa end)
from pozdoc p 
	--LEFT JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
where p.tip in ('RM','PP','AI') OR p.Tip_miscare='E' and p.Tip<>'TE' and p.Cantitate<0


/*
select *, 
--*/update p set 
cont_corespondent=(case when p.tip='RM' then p.lot else p.cont_corespondent end)
,grupa=(case when p.tip in ('PP','AI') then p.lot else grupa end)
from pozdoc p 
	JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
where p.tip in ('RM','PP','AI') OR p.Tip_miscare='E' and p.Tip<>'TE' and p.Cantitate<0

alter table pozdoc enable trigger all


exec RefacereStocuri null,null,null,null,null,null

select P.lot,* from pozdoc  p where isnull(p.lot,'')<>''

select i.* -- update i set lot=s.lot
from tet..istoricstocuri i 
left join stocuri s on s.Subunitate=i.Subunitate and s.Cod_gestiune=i.Cod_gestiune and s.Cod=i.Cod and s.Cod_intrare=i.Cod_intrare
where i.Data_lunii='2015-08-31' 
	and s.Subunitate is null
	
alter table tet..pozdoc disable trigger all

/*
select *, 
--*/ update t set 
lot=p.lot
from tet..pozdoc t join pozdoc p on p.idPozDoc=t.idPozDoc
--where t.idintrarefirma<>p.idintrarefirma or t.idintrare<>p.idintrare

alter table tet..pozdoc enable trigger all

select s.Lot,* 
from stocuri s join nomencl n on n.Cod=s.Cod join proprietati p on p.Cod_proprietate='ARESERII' and p.Tip='NOMENCL' and p.Cod=n.Cod and p.Valoare='da'


select data_lunii, SUM(1)
from istoricstocuri i 
group by i.Data_lunii
order by 1 desc