CREATE PROCEDURE  wOPPrefiltrareCentralizator_p @sesiune VARCHAR(50), @parXML XML
AS
	declare @refresh bit

	SET @refresh = isnull(@parXML.value('(/row/@_refresh)[1]', 'varchar(5)'), '1')

	/** Daca cumva s-a trimis refresh "1" si s-a ajuns la deschiderea machetei de operatie o inchid automat-> deoarece am deja date in tabel
		Trebuie sa se ajunge in macheta de prefiltrare doar 1 singura data, la deschiderea machetei de centralizator
	**/
	if @refresh='1'
	begin
		select 
			'1' as inchideFereastra
		for xml raw, root('Mesaje')
	end
