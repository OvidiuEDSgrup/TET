select substring(dbo.fStrToken(RTRIM(i.Pret),2,'.'),6,10),* from istoricstocuri i
where substring(dbo.fStrToken(RTRIM(i.Pret),2,'.'),6,10)<>''

select substring(dbo.fStrToken(RTRIM(i.Pret_de_stoc),2,'.'),6,10),* from pozdoc i
where i.Subunitate='1' and i.Tip_miscare='I' 
and substring(dbo.fStrToken(RTRIM(i.Pret_de_stoc),2,'.'),6,10)>5
--and Cod='3135162321203'

select * from stocuri s where s.Cod='3135162321205'
select * from istoricstocuri i where i.Cod='3135162321205' and i.Cod_gestiune='500' and i.Cod_intrare='1140116028' order by i.Data_lunii
select * from pozdoc p where p.Cod='3135162321205' and '500' in (p.Gestiune,p.Gestiune_primitoare) and '1140116028' in (p.Cod_intrare,p.Grupa) order by p.Data

--select * from istoricstocuri i where i.Data_lunii='2014-04-30'
select s.Contract,* from istoricstocuri s 
--join dbo.fStocuriCen('2014-06-30',null,null,null,1,1,1,null,null,null,null,null,null,null,null,null,null) f on f.cod=s.Cod and f.cod_intrare=s.Cod_intrare
--and f.gestiune=s.Cod_gestiune
where s.Cod='510842' and s.Cod_gestiune in ('101','211.SB') and s.Cod_intrare like '7344005%'

select s.Contract,* from stocuri s 
--join dbo.fStocuriCen('2014-06-30',null,null,null,1,1,1,null,null,null,null,null,null,null,null,null,null) f on f.cod=s.Cod and f.cod_intrare=s.Cod_intrare
--and f.gestiune=s.Cod_gestiune
where s.Cod='510842' and s.Cod_gestiune in ('101','211.SB') and s.Cod_intrare like '7344005%'
--s.Stoc<>isnull(f.Stoc,0)
--and isnull(f.Stoc,0)>0

select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* 
from pozdoc p where '7344005' in (LEFT(p.Cod_intrare,7),LEFT(p.Grupa,7)) and p.Cod='510842' and '101' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data

select * from dbo.fStocuriCen('2014-06-30','200-160212','101','6465023',1,1,1,null,null,null,null,null,null,null,null,null,null) f


select * -- update i set pret=CONVERT(decimal(17,5),i.Pret)
from istoricstocuri i 
where i.Data_lunii>='2013-12-31' and CONVERT(decimal(17,5),i.Pret)<>i.Pret

alter table pozdoc disable trigger all
--select * 
update i set Pret_de_stoc=CONVERT(decimal(17,5),i.Pret_de_stoc)
from pozdoc i 
where i.data>='2014-01-01' and CONVERT(decimal(17,5),i.Pret_de_stoc)<>i.Pret_de_stoc
alter table pozdoc enable trigger all