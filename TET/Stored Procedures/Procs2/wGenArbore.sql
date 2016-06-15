
CREATE procedure [dbo].[wGenArbore] @id int,@tip varchar(1),@return xml out,@cantitate float = 1    
as    
--@tip A- Antec, L- Lansare, T-Tehnologie    
with arbore(id,ordine, cod,idParinte,idReal,cant_i, lm, tip, cantitate,nivel)    
as    
( select    
  p.id as id,     
  isnull(convert(decimal(10,6),p.ordine_o),0) as ordine, p.cod,p.idp,p.id as idReal,ISNULL(convert(decimal(16,6),p.cantitate_i),0) as cant_i,    
  rtrim(p.resursa) as lm,p.tip as tip, convert(decimal(16,6),@cantitate) as cantitate, 0 as nivel   
  from poztehnologii as p     
  where  p.id=@id and p.idp is null and p.tip='T'    
      
  union all    
      
  select     
 (case when p.tip in ('M','R') and @tip='T' then isnull((select id from poztehnologii where tip='T' and cod=p.cod),p.id) else p.id end ) as id,     
  isnull(convert(decimal(10,6),p.ordine_o),0) as ordine, p.cod,p.idp,p.id as idReal,ISNULL(convert(decimal(16,6),p.cantitate_i),0) as cant_i,    
  rtrim(p.resursa) as lm,p.tip as tip,    
  (case when @tip='T' then convert(decimal(16,6),p.cantitate*a.cantitate) else convert(decimal(16,6),p.cantitate)end) as cantitate ,  
  a.nivel+1 as nivel   
  from poztehnologii as p    
  join arbore as a on a.id=p.idp and     
  p.tip != (case when @tip='T' then ('A') when @tip='A' then 'E' else ''end) and p.tip != (case when @tip='T' then ('L') else '' end)    
  
  )    
    
    
 select     
  @return=     
  (select     
   rtrim(a.cod) as cod, a.id as id, a.idParinte as idp, a.idReal as idReal, a.tip as tip,    
   (case when a.tip in ('M','Z') then  rtrim(n.denumire) when a.tip='O' then  rtrim(c.Denumire) when a.tip in ('R','T') then RTRIM(t.denumire) end ) as denumire,    
   convert(decimal(15,6),  a.cantitate) as cantitate,convert(decimal(15,6),  a.cant_i) as cant_i,a.ordine as ordine,     
   (case when a.tip='O' then 'Operatie' when a.tip='R' then 'Reper'  when (a.tip='M' and n.tip ='P' )then 'Semifabricat' when a.tip='Z' then 'Rezultat' else 'Material' end )as _grupare,     
   (case when a.tip in ('M','Z') then rtrim(n.um) when a.tip='O' then  rtrim(c.um)  end ) as um,    
   ((case when a.tip in ('M','Z') then rtrim(n.denumire) when a.tip='O' then  rtrim(c.Denumire)else '' end) +' ('+rtrim(a.cod)+')') as denumireCod    
   from arbore a    
   left join nomencl n on a.tip='M' and n.cod=a.cod    
   left join catop c on a.tip='O' and c.Cod=a.cod    
   left join tehnologii t on a.tip='T' and a.cod=t.cod    
   where a.id <> @id    
   order by a.nivel   
   for xml raw    
  )