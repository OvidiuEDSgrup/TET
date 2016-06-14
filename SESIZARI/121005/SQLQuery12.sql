select * from bp order by data desc
select top 100 * from pozdoc p order by p.Data_operarii desc, p.Ora_operarii desc
select * from par where par.Parametru like 'FARAVSTN'

select * from syssp s where s.Parametru like  'FARAVSTN' 
order by s.Data_stergerii desc