
Create PROCEDURE wOPInlocuireCodLM_p @sesiune VARCHAR(50), @parXML XML
AS

	select 
		@parXML.value('(/*/@lm)[1]','varchar(20)') cod_vechi,
		@parXML.value('(/*/@denlm)[1]','varchar(20)') dencod_vechi
	for xml raw, root('Date')
