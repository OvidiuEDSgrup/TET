--***
create procedure ReportToExcelProvider @idRulare int
as
declare @procedura varchar(100), @utilizatorWindows varchar(100), @bd varchar(50), @comanda nvarchar(4000), @impersonat bit, @eroare nvarchar(max), 
		@parXML xml, @emailErori varchar(500), @subiect varchar(8000)

set transaction isolation level read uncommitted
select @emailErori = valoare
from parametriRIA p
where p.cod='emailResp'

begin try
	select top 1 @procedura=procedura, @utilizatorWindows = utilizatorWindows, @impersonat=0, @bd=BD, @parXML = parXML, @eroare = mesajEroare
	from proceduriDeRulat p 
	where idRulare = @idRulare
	
	if LEN(@eroare)>0 -- resetez mesajul de eroare...
	begin
		update ProceduriDeRulat set mesajEroare = null where idRulare = @idRulare
		set @eroare=null
	end
	
	if len(@utilizatorWindows)>0 -- nu am reusit sa testez...
	begin 
		exec as login=@utilizatorWindows
		set @impersonat=1
	end
	
	set @comanda = N'exec '+@bd+'.dbo.'+@procedura + ' @idRulare = @idRulare'
	
	exec sp_executesql @statement=@comanda, @params=N'@idRulare as int', @idRulare = @idRulare	
end try
begin catch
	set @eroare = error_message() + ' (ReportToExcelProvider)'
	
	if APP_NAME() like '%Microsoft SQL Server Management Studio%' or APP_NAME() like '%asisria%' 
		raiserror(@eroare, 11, 1)
	else
	begin
		update asisria..proceduriderulat 
			set mesajEroare = @eroare
		where idRulare=@idRulare
		
		set @subiect = 'Eroare ReportToExcelProvider pe serverul '+ @@SERVERNAME + ' - '+
						isnull((select RTRIM(MAX(b.nume)) from bazedeDateRIA b where b.bd=@bd),'')
		exec msdb..sp_send_dbmail @recipients=@emailErori ,@subject=@subiect, @body=@eroare  
	end
end catch

if @impersonat=1
	revert

-- select * from asisria..proceduriderulat
-- exec msdb..sp_send_dbmail @recipients=@emailErori ,@subject='rulat procedura...', @body='merge...'












