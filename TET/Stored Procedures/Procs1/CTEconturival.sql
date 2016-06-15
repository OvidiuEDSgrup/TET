--***
create procedure CTEconturival(@hostid varchar(8)) as  
begin  
	if exists (select name from sysobjects where name='conttmp')   
		 delete from conttmp where hostid=@hostid  
	else 
		create table conttmp(hostid varchar(8),cont varchar(40),valprop varchar(1))  
	;WITH conturicte (cont,  valprop, [Level]) AS  
	(  
		SELECT c.cont, convert(char(1),isnull(p.valoare,'')), 0 as [Level]   
		FROM conturi AS c  
		left outer join proprietati p on c.cont = p.cod and tip = 'CONT' and cod_proprietate = 'INVALUTA'   
		where cont_parinte = ''  
		UNION ALL  
		SELECT  c2.cont, convert(char(1),case when (c.valprop = 'D') or exists (select 1 from proprietati p   
		where c2.cont = p.cod and tip = 'CONT' and cod_proprietate = 'INVALUTA' and valoare = 'D') then 'D' else ''     end),[Level] + 1  
		FROM conturi AS c2  
   
	 --inner join proprietati p on c2.cont = p.cod and tip = 'CONT' and cod_proprietate = 'INVALUTA'   
		INNER JOIN conturicte AS c  
			ON c2.cont_parinte = c.cont   
	)  
	insert into conttmp select @hostid as hostid,cont, left(valprop,1) from conturicte order by cont  
end
