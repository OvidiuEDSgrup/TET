--1-cod
--2-cantitate
--3-pret
declare @mod int,@luna int
set @mod=3;
set @luna=4

if(@mod=1)
select r.*,
(select Numar_bon from bp where Cod_produs='AVANS' and (select COUNT(*) from bp b where b.Numar_bon=bp.Numar_bon and b.data=bp.data and tip='21' and b.Casa_de_marcat=bp.Casa_de_marcat)=1
and Numar_bon=r.Numar_bon and DATA=r.data and Casa_de_marcat=r.Casa_de_marcat) as AVANS
 from 
(select Numar_bon,DATA,Casa_de_marcat,cod_produs,
(select max(cod) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as varCHAR(5))))+'%'+'%'+cast(Numar_bon as varCHAR(2)) and cod=bp.Cod_produs) as AC,
(select max(cod) from pozdoc where tip='TE'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as varCHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2))and cod=bp.Cod_produs) as TE from bp

where year(data)=2012 and month(data)=@luna and tip='21' 
group by Numar_bon,DATA,Casa_de_marcat,cod_produs)r
where (r.ac is null or r.te is null) and ltrim(rtrim(isnull(r.Cod_produs,''))) not in ('AVANS')
order by r.Data,r.Numar_bon

if(@mod=2)
select r.*,
(select Numar_bon from bp where Cod_produs='AVANS' and (select COUNT(*) from bp b where b.Numar_bon=bp.Numar_bon and b.data=bp.data and tip='21' and b.Casa_de_marcat=bp.Casa_de_marcat)=1
and Numar_bon=r.Numar_bon and DATA=r.data and Casa_de_marcat=r.Casa_de_marcat) as AVANS
 from 
(select Numar_bon,DATA,Casa_de_marcat,cod_produs,sum(cantitate) as cantitateBP,
(select max(Cod) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2)) and cod=bp.Cod_produs) as CodAC,
(select sum(cantitate) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2)) and cod=bp.Cod_produs) as AC,
(select sum(cantitate) from pozdoc where tip='TE'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2))and cod=bp.Cod_produs) as TE from bp

where year(data)=2012 and month(data)=@luna and tip='21' 
group by Numar_bon,DATA,Casa_de_marcat,cod_produs)r
where (r.ac is null or r.te is null) and ltrim(rtrim(isnull(r.CodAC,''))) not in ('AVANS') OR r.cantitateBP<>r.AC or r.cantitateBP<>r.TE
order by r.Data,r.Numar_bon

if(@mod=3)
select r.*,
(select Numar_bon from bp where Cod_produs='AVANS' and (select COUNT(*) from bp b where b.Numar_bon=bp.Numar_bon and b.data=bp.data and tip='21' and b.Casa_de_marcat=bp.Casa_de_marcat)=1
and Numar_bon=r.Numar_bon and DATA=r.data and Casa_de_marcat=r.Casa_de_marcat) as AVANS
 from 
(select Numar_bon,DATA,Casa_de_marcat,cod_produs,max(pret) as PretBP,
(select max(Cod) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2)) and cod=bp.Cod_produs) as CodAC,
(select max(Pret_amanunt_predator) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2)) and cod=bp.Cod_produs) as AC,
(select sum(Pret_cu_amanuntul) from pozdoc where tip='TE'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2))and cod=bp.Cod_produs) as TE 
from bp

where year(data)=2012 and month(data)=@luna and tip='21'-- and data='2012-05-18'
group by Numar_bon,DATA,Casa_de_marcat,cod_produs)r
where 1=1
--and r.Numar_bon=1 and r.Casa_de_marcat=1 and r.Data='2012-04-05'
and (r.ac is null or r.te is null or r.PretBP!=r.AC or r.PretBP<>r.TE) 
and ltrim(rtrim(isnull(r.ac,''))) not in ('AVANS') 
--or r.PretBP!=r.AC or r.PretBP<>r.TE
--and ltrim(rtrim(isnull(r.CodAC,''))) not in ('AVANS')
order by r.Data,r.Numar_bon,r.Cod_produs


/*
select * from pozdoc where tip='AC' and Numar like '1%3' and DATA='2012-05-18'

select * from bp where DATA='2012-05-18' and Numar_bon='3'
*/