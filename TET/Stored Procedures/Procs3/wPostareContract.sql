
CREATE PROCEDURE wPostareContract @sesiune VARCHAR(50), @parXML XML
AS
	declare @idContract int, @tip_contract varchar(2), @stare_act int

	select 
		@idContract=@parXML.value('(/*/@idContract)[1]','int'),
		@tip_contract=@parXML.value('(/*/@tip)[1]','varchar(2)')


	select top 1 @stare_act=stare from StariContracte where tipContract=@tip_contract and ISNULL(actaditional,0)=1

	IF (select top 1 stare from JurnalContracte where idContract=@idContract order by idJurnal desc) = @stare_act and ISNULL(@stare_act,0)<>0
		select
			'Atentie! Contractul se afla in stare tranzitorie de act aditional: pentru a definitiva actul permitand contractului sa dea efect, utilizati operatia de definitivare contract!' textMesaj, 'Atentionare' titluMesaj
		for xml raw, root('Mesaje')
