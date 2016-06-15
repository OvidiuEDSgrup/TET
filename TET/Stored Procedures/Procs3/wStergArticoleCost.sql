create procedure wStergArticoleCost @sesiune varchar(50), @parXML xml 
as
declare @mesajeroare varchar(100), @art_cost varchar(9)
begin try		
	select
		@art_cost=isnull(@parXML.value('(/row/@art_cost)[1]','varchar(9)'),'')

	if exists (select 1 from conturi where articol_de_calculatie=@art_cost)
		raiserror ('Exista conturi cu acest articol de calculatie!',11,1)

	if exists (select 1 from costsql where art_sup=@art_cost or art_inf=@art_cost)
		raiserror ('Exista costuri calculate pe acest articol de calculatie!',11,1)
	
		delete from artcalc	where articol_de_calculatie=@art_cost
end try
begin catch
	set @mesajeroare='(wStergArticoleCost:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch	

/*
select * from costsql
*/	  
