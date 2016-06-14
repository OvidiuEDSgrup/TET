select * 
--update n set n.Tip=s.Tip
from syssn s inner join nomencl n on s.Cod=n.Cod
where s.Data_stergerii between '2012-11-01 08:08:00' and '2012-11-01 08:10:00'
and s.Host_id='1720' 
--order by s.Data_stergerii desc

select t.tip,t.grupa,*
--update n set Tip=t.tip,Grupa=t.grupa
from nomencl n inner join testdb..nomencl t on t.cod=n.Cod
where n.Cod='pk00256'