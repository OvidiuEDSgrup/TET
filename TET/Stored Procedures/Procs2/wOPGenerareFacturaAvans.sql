CREATE PROCEDURE  wOPGenerareFacturaAvans @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	declare
		@codAvans varchar(20), @idContract int, @valoare_avans float, @xml_jurnal xml, @xml_doc xml, @idJurnal int, @idPozDoc int,
		@tert varchar(20), @gestiune varchar(20), @data varchar(10), @lm varchar(20), @tipDoc varchar(2), @numarDoc varchar(20),
		@valuta varchar(10), @curs decimal(15,4)

	exec luare_date_par 'PV','CODAVBEN',0,0,@codAvans OUTPUT
		
	select
		@idContract = @parXML.value('(/*/@idContract)[1]','int'),
		@valoare_avans = @parXML.value('(/*/@valoare_avans)[1]','float')
			
	IF @valoare_avans<0.001
		raiserror('Valoare avansului nu este completata!',16,1)

	IF EXISTS(select 1 from JurnalContracte jc JOIN PozDoc pd on pd.idPozDoc=jc.idJurnal and jc.idContract=@idContract and pd.cod=@codAvans)
		RAISERROR('Pentru contractul/comanda selectata s-a generat deja o factura de avans!',15,1)

	select	
		@tert=tert, @gestiune=gestiune, @data=convert(varchar(10), GETDATE(), 101), @lm = loc_de_munca, @valuta=NULLIF(valuta,''), @curs=NULLIF(curs,0.0)
	from Contracte where idContract=@idContract
	select * from Contracte where idContract=@idContract
	select @tipDoc='AS'

	set @xml_doc=
	(
		select
			@tipDoc tip, @tert tert, @gestiune gestiune, @data data, @lm lm,
			'1' fara_luare_date, '1' fara_mesaje, '1' returneaza_inserate, @valuta valuta, @curs curs, 
			(
				select
					@codAvans cod, 1 cantitate, convert(decimal(17,5), @valoare_avans) pvaluta, 1 idlinie, @valuta valuta, @curs curs
				for xml raw, type
			)
		for xml raw, type
	)
	exec wScriuPozDoc @sesiune=@sesiune, @parXML=@xml_doc OUTPUT

	SELECT @xml_jurnal = (SELECT @idContract idContract, GETDATE() data, 'Generare factura avans' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT

	select 
		@idJurnal=@xml_jurnal.value('(/*/@idJurnal)[1]','int'),
		@idPozDoc=@xml_doc.value('(/row/docInserate/row/@idPozDoc)[1]','int')

	--generare inregistrari contabile
	if object_id('tempdb.dbo.#DocDeContat') is not null drop table #DocDeContat
	CREATE TABLE #DocDeContat (subunitate varchar(20),tip varchar(2),numar varchar(20),data datetime) 
	insert into #DocDeContat (subunitate,tip,numar,data)
	select subunitate,tip,numar,data from pozdoc
	where idPozdoc=@idPozDoc
	exec faInregistrariContabile @dinTabela=2

	insert into LegaturiContracte(idJurnal, idPozDoc)
	SELECT @idJurnal, @idPozDoc

	/* Permitem un SP1 pt. anumite verificari, trimiteri email, schimbari de stari, samd specifice*/
	IF EXISTS (SELECT *	FROM sysobjects WHERE NAME = 'wOPGenerareFacturaAvansSP1')
		exec wOPGenerareFacturaAvansSP1 @sesiune=@sesiune, @parXML=@parXML

	select 'S-a generat cu succes factura de avans pentru valoare selectata!' textMesaj, 'Notificare' as titluMesaj for xml raw, root('Mesaje')

END TRY
BEGIN CATCH	
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
