
CREATE procedure wmAlegSumaIncasare @sesiune varchar(50), @parXML xml
as
	declare
		@suma decimal(15,2)
	
	set @suma= ISNULL(@parXML.value('(/*/@suma)[1]','decimal(15,2)'),0.0)


	/** Daca se alege suma, trimite "1" pentru populare a tabelului de facturi in limita sumei introduse */
	select 
		@suma suma,  '1' as populare ,'' as tabel
	for xml RAW('atribute'), ROOT('Mesaje')
	
	select 'back(1)' as _actiune
	for xml raw,root('Mesaje')
