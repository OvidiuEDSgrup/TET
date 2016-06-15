create procedure [dbo].[wOPModificaCantFundamentare] @sesiune varchar(50), @parXML XML  
as
	declare @cod varchar(20), @cantitate float, @utilizator varchar(40),@doc xml,@tip varchar(20)
	
	
	set @cod= @parXML.value('(/parametri/@cod)[1]', 'varchar(20)')
	set @utilizator= @parXML.value('(/parametri/@utilizator)[1]', 'varchar(40)')
	set @cantitate= @parXML.value('(/parametri/@diferenta)[1]', 'float')
	set @tip= @parXML.value('(/parametri/@Tip)[1]', 'varchar(20)')
	
	
	if @tip='Produs'
	begin
		raiserror('Cantitatea de lansat pentru produs este rezultatul unui calcul direct asupra comenzilor de livrare si nu poate fi modificata!', 16, 1) 
		return
	end
	
	update tmpFundamentareLansare set lans=@cantitate, modificat=1 where cod=@cod and utilizator=@utilizator
	
	set @doc=(select 1 as _refresh for xml raw)
	exec wIaFundamentareLans @sesiune=@sesiune, @parXML=@doc