Create procedure [dbo].[wOPSalvarePret] @sesiune varchar(50), @parXML XML 
as
	declare @cod varchar(20), @pret float
	
	set @cod=@parXML.value('(/row/@i_tehnologie)[1]','varchar(20)')
	set @pret=@parXML.value('(/row/@pret)[1]','float')


	update nomencl set Pret_stoc=@pret where cod=@cod
