create procedure wStergProdNeterminata @sesiune varchar(50), @parXML xml 
as
declare @mesajeroare varchar(100), @data datetime, @comanda varchar(20), @lm varchar(13)
begin try		
	select
		@data=isnull(@parXML.value('(/*/@data)[1]','datetime'),''),
		@comanda=isnull(@parXML.value('(/*/@comanda)[1]','varchar(20)'),''),
		@lm=isnull(@parXML.value('(/*/@lm)[1]','varchar(20)'),'')
	
	delete from nete where data=@data and loc_de_munca=@lm and comanda=@comanda
end try
begin catch
	set @mesajeroare='(wStergProdNeterminata:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch	

/*
select * from costsql
*/	  
