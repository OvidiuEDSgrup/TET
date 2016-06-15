
CREATE PROCEDURE ExecutaJobOra2
AS

	/*----------PAS 1 = generarea inregistrarilor contabile----------*/
	exec faInregistrariContabile @dinTabela=1

	/*---------PAS 2 = stergere fisiere temporare (formulare)----------*/
	declare @director varchar(1000),@cmdDinamic varchar(8000)
	select top 1 @director=val_alfanumerica from par where parametru='CALEFORM'	
	set @cmdDinamic='del '+rtrim(@director)+'*.* /Q'	
	/*	Daca cumva nu este formulare (ASiSplus sau alte situatii) sa nu stearga	*/
	IF @director LIKE '%formulare%'
		exec xp_cmdshell @cmdDinamic

	/*----------PAS 3- preluat cursuri valutare----------*/
	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'wOPCursBNR')
	begin
		--Nu trimitem data, pentru ca sa mearga implicit pe GETDATE()
		declare @xmlCurs xml
		set @xmlCurs=(select '<toate>' valuta for xml raw)
		exec wOPCursBNR @sesiune='', @parXML=@xmlCurs
	end

	/*----------PAS 4- epurare tabel parSesiuniRIA----------*/
	IF EXISTS (select 1 from sys.objects where name='parSesiuniRIA')
		truncate table parSesiuniRIA
	
	/*----------PAS 5- stergea rezervarilor expirate pe comenzi----------*/
	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'wStergRezervariComenzi')
		exec wStergRezervariComenzi '',''

	/*PAS suplimentar: daca exista alte lucruri specifice ce trebuie executate de JOB se pot prevedea in SP */
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'ExecutaJobOra2SP1')
		exec ExecutaJobOra2SP1
