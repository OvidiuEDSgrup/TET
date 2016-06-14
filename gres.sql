select * from pozcon p where p.Subunitate='1' and p.Cod='02607401'
select * from con c where c.Contract='1012'
select * from sysscon s where s.Contract='1012' order by s.Data_stergerii desc
select * from sysspcon s where s.Cod='02607401' and s.Contract='1012' order by s.Data_stergerii desc