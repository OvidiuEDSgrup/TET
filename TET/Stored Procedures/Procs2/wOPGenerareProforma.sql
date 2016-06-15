CREATE PROCEDURE  wOPGenerareProforma @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	declare
		@codAvans varchar(20), @idContract int, @valoare_proforma float, @xml_jurnal xml, @xml_doc xml, @idJurnal int, @idPozDoc int,
		@tert varchar(20), @gestiune varchar(20), @data varchar(10), @lm varchar(20), @tipDoc varchar(2), @numarDoc varchar(20),
		@valuta varchar(10), @curs decimal(15,4), @procent_proforma float, @contr xml, @data_proforma datetime, @valoare float,
		@idContract_Proforma int, @numar_proforma varchar(20), @STPRINC  int, @tert_extern int, @detalii xml

	--citesc codul de nomenclator pentru avans
	exec luare_date_par 'PV','CODAVBEN',0,0,@codAvans OUTPUT

	--stare in care proforma se poate incasa
	exec luare_date_par 'GE','STPRINC',0,0,@STPRINC OUTPUT
		
	select
		@idContract = @parXML.value('(/*/@idContract)[1]','int'),
		@valoare_proforma = @parXML.value('(/*/@valoare_proforma)[1]','float'),
		@procent_proforma = @parXML.value('(/*/@procent_proforma)[1]','float'),
		@data_proforma = isnull(@parXML.value('(/*/@data_proforma)[1]','datetime'),getdate()),
		@curs = isnull(@parXML.value('(/*/@curs)[1]','float'),0)

		IF @parXML.exist('(/*/detalii)[1]') = 1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')
	
	--daca nu s-a introdus valoare sau procent pentru proforma returnez mesaj de eroare		
	IF @valoare_proforma<0.001 and @procent_proforma<0.001 
		raiserror('Introduceti valoarea proformei!',16,1)

	--verific existenta paramatru pentru starea in care poate fi incasata o proforma
	if isnull(@STPRINC,'')=''
		raiserror('Pentru generarea profermei este nevoie sa fie setat parametrul pentru starea de incasare a unei proforme (GE,STPRINC)!',11,1)

	--verific existenta paramatru pentru codul de nomenclator avans
	if isnull(@codAvans,'')=''
		raiserror('Pentru generarea profermei este nevoie sa fie setat parametrul pentru codul de avans (PV,CODAVBEN)!',11,1)

	--preluare date de pe comanda de livrare mama
	select	
		@tert=tert, @gestiune=gestiune, @data=convert(varchar(10), @data_proforma, 101), @lm = loc_de_munca, @valuta=NULLIF(valuta,'')--@curs=NULLIF(curs,0.0)
	from Contracte where idContract=@idContract
	
	select @tert_extern=isnull((select tert_extern from terti where tert=@tert),0)
	
	--formez xml-ul pentru apel wScriuPozContracte	
	set @contr=
	(
		select
			'PR' tip, @tert tert, @data data, @lm lm, @idContract idContractCorespondent, 
				case when @tert_extern=0 and isnull(@valuta,'')<>'' then '' else @valuta end as valuta,--in cazul in care comanda e in valuta si tertul este intern, se va genera proforma in RON 
				convert(decimal(14,4),@curs) curs, @detalii as detalii,
			(
				select
					rtrim(@codAvans) cod, 1 cantitate, 
					convert (decimal(17,2),
						(case when isnull(@valoare_proforma,0)<>0 then @valoare_proforma else sum(cantitate * pret)*@procent_proforma/100 end)
						* case when @tert_extern=0 and isnull(@valuta,'')<>'' then @curs else 1 end) --in cazul in care comanda e in valuta si tertul este intern, se va genera proforma in RON 
						as pret
				from pozcontracte 
				where idcontract=@idContract
				for XML raw, type
			)
		for XML RAW
	)
	--select @contr
	exec wScriuPozContracte @sesiune=@sesiune, @parXML=@contr output
	
	--idContract al proformei generate
	select @idContract_Proforma=@contr.value('(/*/@idContract)[1]','int')

	--numarul proformei generate
	select @numar_proforma=numar
	from contracte
	where idContract=@idContract_Proforma

	--trec proforma in stare in care poate fi incasata
	SELECT @xml_jurnal = (SELECT @idContract_Proforma idContract, @STPRINC as stare, GETDATE() data, 'Trecere proforma in stare de incasare' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT

	--jurnalizare generare proforma pe comanda initiala
	SELECT @xml_jurnal = (SELECT @idContract idContract, GETDATE() data, 'Generare proforma' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT

	/* Permitem un SP1 pt. anumite verificari, trimiteri email, schimbari de stari, listare, samd specifice*/
	IF EXISTS (SELECT *	FROM sysobjects WHERE NAME = 'wOPGenerareProformaSP1')
		exec wOPGenerareProformaSP1 @sesiune=@sesiune, @parXML=@parXML

	select 'S-a generat cu succes proforma cu numarul '+ @numar_proforma+' !' textMesaj, 'Notificare' as titluMesaj for xml raw, root('Mesaje')
END TRY
BEGIN CATCH	
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
