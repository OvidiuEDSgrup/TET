
CREATE PROCEDURE wOPPlanificaComenziProductie @sesiune VARCHAR(50), @parXML XML
AS

/** 
	Aceasta va fi procedura conform careia se va realizare planificarea productiei in mod specific fiecarei unitati
	Pe baza informatiilor din wOPGenerareComenziProductie2 ( tabelul tmpprodsisemif sau alte forme ) se vor scrie date in 
	tabelul "Planificare"
**/
