delete pozcomlivrtmp
delete comlivrtmp

select * 
--into #pozcomlivrtmp
from pozcomlivrtmp

select * 
--into #comlivrtmp
from comlivrtmp

insert pozcomlivrtmp
select * from #pozcomlivrtmp

insert comlivrtmp
select * from #comlivrtmp

select*
	from proprietati p 
		where p.tip='UTILIZATOR' and p.cod_proprietate='CONTPLIN' and p.cod=dbo.fIaUtilizator(null) 
		SELECT dbo.fIaUtilizator(null) 
		SELECT * FROM utilizatori