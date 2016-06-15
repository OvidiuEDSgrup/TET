
CREATE PROCEDURE wACDelegatTransport @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE
		@searchText VARCHAR(200), @tip_delegat varchar(20), @tert varchar(20)

	SET @searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'
	set @tip_delegat=@parXML.value('(/*/@transportator)[1]','varchar(2)')
	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')

	/**
		i= intern (eu?)
		c= client (tert)
		e= extern (tert)
		Daca client: delegat = persoana de contact a clientului 
		Daca intern delegat = persoana de contact a tertului spatiu (tert = nimic)
		Daca extern: delegat = persoana de contact a tertului respectiv

	**/
	
	if @tip_delegat='I'
		set @tert=''

	select 
		rtrim(Identificator) as cod, RTRIM(descriere) as denumire
	from infotert where tert=@tert and Subunitate='C1'
	FOR XML raw, root('Date')
