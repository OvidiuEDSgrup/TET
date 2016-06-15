CREATE procedure [dbo].[wOPGenComandaProductie_p] @sesiune varchar(50), @parXML XML  
as
	declare
		@cantitate float,@poz bit	
	
	set @poz= @parXML.exist('/row/row/@comanda')	
	if @poz=0
			--Antet
			set @cantitate= ISNULL(@parXML.value('(/row/@diferenta)[1]','float'),0)
	else
		if @poz=1
			--Pozitie
			set @cantitate= ISNULL(@parXML.value('(/row/row/@cantitate)[1]','float'),0)	

	select convert(decimal(10,2),@cantitate) as cantitate
	for xml raw, root('Date')
