CREATE procedure wStergActivitatiCRM @sesiune varchar(50), @parXML xml  
as 

	declare @idActivitate int
	set @idActivitate = @parXML.value('(/*/@idActivitate)[1]','int')


	delete from ActivitatiCRM where idActivitate=@idActivitate
