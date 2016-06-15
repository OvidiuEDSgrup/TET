--***
--functie care returneaza conturile care au ca parinte contul trimis sau copiii acestora
create function  arbconturi (@cont varchar(40)) 
returns @arbcnt table 
	(cont varchar(40)) 
as 
begin 
	insert into @arbcnt 
	select cont from conturi 
	where cont like RTrim(@Cont) + (case when Len(RTrim(@cont))<3 then '%' else '' end) 
 
	while @@rowcount > 0 
	begin 
		insert into @arbcnt 
		select c.cont 
		from conturi c, @arbcnt a 
		where a.cont=c.cont_parinte and not exists (select 1 from @arbcnt b where b.cont=c.cont) 
	end 
	return 
end 
