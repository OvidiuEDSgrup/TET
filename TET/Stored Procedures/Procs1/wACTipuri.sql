CREATE procedure [dbo].[wACTipuri] @sesiune varchar(50), @parXML XML  
as
	declare @idp int
	set @idp=ISNULL(@parXML.value('(/row/@i_idp)[1]', 'int'), 0)

		begin
			select 'Produs' as denumire, 'P' as cod
			union 
			select 'Reper' as denumire, 'R' as cod
			union 
			select 'Operatie' as denumire, 'O' as cod
			union 
			select 'Material' as denumire, 'M' as cod
			union 
			select 'Structura' as denumire, 'S' as cod
			
			for xml raw,root('Date')
		end
