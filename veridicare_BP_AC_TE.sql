--Verificare BP AC
declare @luna int
set @luna=3
select r.*,
(select Numar_bon from bp where Cod_produs='AVANS' and (select COUNT(*) from bp b where b.Numar_bon=bp.Numar_bon and b.data=bp.data and tip='21' and b.Casa_de_marcat=bp.Casa_de_marcat)=1
and Numar_bon=r.Numar_bon and DATA=r.data and Casa_de_marcat=r.Casa_de_marcat) as AVANS
 from 
(select Numar_bon,DATA,Casa_de_marcat,
(select max(Numar) from pozdoc where tip='AC'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2))) as AC,
(select max(Numar) from pozdoc where tip='TE'and DATA=bp.Data and Numar like ltrim(rtrim(cast(Casa_de_marcat as CHAR(5))))+'%'+'%'+cast(Numar_bon as CHAR(2))) as TE from bp

where year(data)=2012 and month(data)=@luna
group by Numar_bon,DATA,Casa_de_marcat)r
where (r.ac is null or r.te is null) and
(select Numar_bon from bp where Cod_produs='AVANS' and (select COUNT(*) from bp b where b.Numar_bon=bp.Numar_bon and b.data=bp.data and tip='21' and b.Casa_de_marcat=bp.Casa_de_marcat)=1
and Numar_bon=r.Numar_bon and DATA=r.data and Casa_de_marcat=r.Casa_de_marcat) is null
order by r.Data,r.Numar_bon


