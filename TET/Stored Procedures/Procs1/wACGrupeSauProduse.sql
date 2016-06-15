create procedure wACGrupeSauProduse @sesiune varchar(50), @parXML XML  
as
	declare @tip varchar(10), @docXML xml
	
	set @tip=@parXML.value('(/row/@tip_antec)[1]','varchar(10)')
	
	if @tip ='C' 
		exec wACResursa @sesiune=@sesiune, @parXML=@parXML
	else
		if @tip='G'
			exec wACGrupe @sesiune=@sesiune, @parXML=@parXML
