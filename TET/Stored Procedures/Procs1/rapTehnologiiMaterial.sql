create procedure rapTehnologiiMaterial  @cod varchar(20)    
as    
	set transaction isolation level read uncommitted
select    
  RTRIM(t.cod) as cod, RTRIM(n.Denumire) as denumire, RTRIM(g.Denumire) as grupa, RTRIM(n.um) as um, ptt.cantitate     
  , RTRIM(n2.Denumire) AS denumireCod  
from tehnologii t      
inner join poztehnologii pt on pt.cod=t.cod    
left join nomencl n on n.Cod=t.cod    
left join grupe g on n.Grupa=g.Grupa    
inner join poztehnologii ptt on ptt.parintetop=pt.id and ptt.cod=@cod    
LEFT JOIN nomencl n2 ON n2.cod=@cod  
order by 3
