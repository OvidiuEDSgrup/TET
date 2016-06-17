--***
create procedure RuleazaProceduri
as
declare @idRulare int, @procedura varchar(100), @utilizatorWindows varchar(100), @emailErori varchar(500), @bd varchar(50),
		@comanda nvarchar(4000), @impersonat bit, @eroare nvarchar(max), @subiect varchar(8000), @parXML xml, @sesiune varchar(50),
		@areSesiune bit, @areParXml bit

set transaction isolation level read uncommitted

select @emailErori = valoare
from parametriRIA p
where p.cod='emailResp'

if ISNULL(@emailErori,'')=''
	raiserror('Aceasta operatie notifica erorile prin email. Completati parametrul ''EmailResp'' in tabela ASiSria..parametriRIA', 11, 1)

while exists (select * from proceduriderulat where dataStop is null)
begin
	set @eroare = null
	
	begin try
		select top 1 @idRulare = idRulare, @procedura=procedura, @utilizatorWindows = utilizatorWindows, @impersonat=0,
				@bd=BD, @parXML = p.parXML, @sesiune = p.sesiune
		from proceduriDeRulat p 
		where dataStop is null
	
	if len(@utilizatorWindows)>0 -- nu am reusit sa testez...
	begin 
		exec as login=@utilizatorWindows
		set @impersonat=1
	end
	
	update proceduriDeRulat
		set dataStart=getdate()
	where idRulare=@idRulare
	
	set @comanda=N'
	SELECT 
		@areSesiune = case when p.name=''@sesiune'' then 1 else @areSesiune end,
		@areParXml = case when p.name=''@parXML'' then 1 else @areParXml end
	FROM ['+@bd+'].sys.procedures sp
	JOIN ['+@bd+'].sys.parameters p ON sp.object_id = p.object_id
	WHERE sp.name = @procedura'
	
	exec sp_executesql @statement=@comanda, 
		@params=N'@areSesiune as bit output, @areParXml bit output, @procedura varchar(500)',
		@procedura=@procedura, @areSesiune=@areSesiune output, @areParXml=@areParXml output
	
	set @comanda = N'exec ['+@bd+N'].dbo.'+@procedura + N' @idRulare = @idRulare' +
			case when @areSesiune=1 then N', @sesiune = @sesiune' else '' end + 
			case when @areParXml=1 then N', @parXML = @parXML' else '' end

	exec sp_executesql @statement=@comanda, 
		@params=N'@idRulare as int, @sesiune varchar(50), @parXML xml', 
		@idRulare = @idRulare, @sesiune = @sesiune, @parXML = @parXML
		
	end try
	begin catch
		set @eroare = error_message() + ' (RuleazaProceduri)'
		
		if APP_NAME() like '%Microsoft SQL Server Management Studio%'
			raiserror(@eroare, 11, 1)
		else
		begin
			set @subiect = 'Eroare RuleazaProceduri pe serverul '+ @@SERVERNAME + ' - '+ isnull((select RTRIM(MAX(b.nume)) from bazedeDateRIA b where b.bd=@bd),'')
			exec msdb..sp_send_dbmail @recipients=@emailErori ,@subject=@subiect, @body=@eroare  
		end
	end catch
	
	update proceduriDeRulat
		set dataStop = getdate(), mesajEroare = isnull(mesajEroare + ', ', '') + @eroare
	where idRulare=@idRulare
	
	if @impersonat=1
		revert
end

-- select * from asisria..proceduriderulat
-- select * from asisria..parametriria
-- exec msdb..sp_send_dbmail @recipients=@emailErori ,@subject='rulat procedura...', @body='merge...'












