create procedure [dbo].[wStergSesiuneUtilizator] @sesiune varchar(50), @parXML XML 
as
	declare
		@token varchar(50), @doc xml
		
	set @token=@parXML.value('(/*/@sesiune)[1]','varchar(50)')
	

	exec wLogout @sesiune=@token, @parXML=@parXML
