create procedure wSalvareDateSinc @sesiune varchar(50), @parXML xml
as    
 declare @utilizator varchar(100) 
     
 --Iau utilizator    
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output    
 
 begin try
	insert into logSincronizare(utilizator, data, date) values ( @utilizator, GETDATE(), @parXML)
	select 'ok' as rasp for xml raw, root('Date')
 end try
 begin catch
	select 'err' as rasp for xml raw, root('Date')
 end catch
