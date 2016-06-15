
CREATE PROCEDURE wOPTrateazaLegaturiSiStariContracte @sesiune VARCHAR(50), @parXML XML
as
begin try

	declare 
		@docJurnal XML, @explicatii varchar(1000),@stare int

	/* 
		Explicatiile se pot trimite din fiecare procedura care vrea sa fie tratate legaturi si stari la contracte 
		Exemplu: 
			din facturarea de contracte se trimite "generare factura"
			din rezervare pe comanda se poate trimite "comanda rezervata"...etc
	*/
	IF NOT EXISTS (select 1 from #Legaturi)
		return

	IF OBJECT_ID('tempdb.dbo.#con_leg') IS NOT NULL
		drop table #con_leg

	select 
		@explicatii =  @parXML.value('(/*/@explicatii)[1]','varchar(1000)'),
		@stare=@parXML.value('(/*/@stare)[1]','int')
		
	update l
		set idContract=c.idContract
	from #Legaturi l 
	JOIN pozContracte c on l.idPozContract=c.idPozContract

	select distinct idContract, isnull(idjurnal, 0) as idjurnal into #con_leg from #Legaturi
	
	IF OBJECT_ID('tempdb.dbo.#con_leg') IS NULL
		return

	/*  Se jurnalizeaza operatia curenta (fie ea facturare, transfer ori altceva) */
	SELECT @docJurnal = (
		SELECT 
			cl.idContract idContract, GETDATE() data, @explicatii explicatii,nullif(@stare,0) as stare
		from #con_leg cl
		where cl.idJurnal=0 -- daca se trimite idJurnal, nu mai facem linie noua
		FOR XML raw,root('Date'))
	
	if @docJurnal is not null
		EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT

	update l set idJurnal=jc.idJurnal
	from #legaturi l
	cross apply (select top 1 idJurnal from jurnalContracte jc where jc.idContract=l.idContract order by idJurnal desc) jc

	/*  Se scriu legaturile pozContracte <-> pozDoc <-> jurnalContracte
		Jurnalul se ia ultimul de pe jurnalContracte
	*/
	insert into LegaturiContracte(idJurnal, idPozContract, idPozDoc)
	select l.idJurnal, l.idPozContract, l.idPozDoc 
	from #Legaturi l


	/* 
		Aceasta procedura trateaza de ex. schimbarea starii in REALIZAT daca cant. facturata =  cant.comanda. Daca de ex. se facturaza partial o factura 
		apelul acestei proceduri este null-> adica nu va gasi nimic de jurnalizat in plus fata de ceea ce se face mai sus
	 */
	SELECT @docJurnal = (SELECT idContract idContract from #con_leg FOR XML raw,root('Date'))
	EXEC updateStareSetContracte @sesiune = @sesiune, @parXML = @docJurnal 

	/*
		Procedura aceasta va permite operatiie specifice de schimbari de stari in principal
	*/
	IF EXISTS (select 1 from sys.objects where name ='wOPTrateazaLegaturiSiStariContracteSP')
		exec wOPTrateazaLegaturiSiStariContracteSP @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
