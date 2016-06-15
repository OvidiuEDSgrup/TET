	
create procedure wApelWSGenerareAWBCargus @sesiune varchar(50), @parXML xml OUTPUT
as
begin try	
	
	declare  
		@contCargus varchar(100),@url varchar(500), @raspuns varchar(max), @body nvarchar(max), @raspunsXML xml, @contentType varchar(500), @err varchar(3000),
		-- DATE AWB
		@adresa_dest varchar(200), @adresa_exp varchar(200), @asigurare bit, @cash_on_delivery bit, @contact_dest varchar(200), @contact_exp varchar(200), @continut varchar(200),
		@data_exp datetime/*DD/MM/YYYY*/, @destinatar varchar(200), @email_dest varchar(200), @email_exp varchar(200), @expeditor varchar(200), @explicatii_retur varchar(200), @greutate float,
		@judet_dest varchar(200), @judet_exp varchar(200), @livrare_sambata bit, @nr_colete int, @oras_dest varchar(200), @oras_exp varchar(200), @retur_alte_doc bit, @retur_nota_semnata bit,
		@telefon_dest varchar(200), @telefon_exp varchar(200), @tip_plata_ramburs varchar(200), @tip_livrare int, 
		@valoare_asigurata float, @valoare_ramburs float, @zip_dest varchar(200), @zip_exp varchar(200),
		@plic bit, @plata_transport int, @metoda_plata int

	
	exec luare_date_par 'AR','CNTCARGUS',0,0,@contCargus OUTPUT
	
	exec wIaUrlServiciuCargus @url=@url OUTPUT
	select 
		@contentType='application/x-www-form-urlencoded',
		@body='cont='+RTRIM(@contCargus),
		@expeditor=@parXML.value('(/*/@expeditor)[1]','varchar(200)'),
		@contact_exp=@parXML.value('(/*/@contact_exp)[1]','varchar(200)'),
		@telefon_exp=@parXML.value('(/*/@telefon_exp)[1]','varchar(200)'),
		@adresa_exp=@parXML.value('(/*/@adresa_exp)[1]','varchar(200)'),
		@email_exp=@parXML.value('(/*/@email_exp)[1]','varchar(200)'),
		@judet_exp=@parXML.value('(/*/@judet_exp)[1]','varchar(200)'),
		@oras_exp=@parXML.value('(/*/@denoras_exp)[1]','varchar(200)'),
		@zip_exp=@parXML.value('(/*/@zip_exp)[1]','varchar(6)'),
		@destinatar=@parXML.value('(/*/@dendestinatar)[1]','varchar(200)'),
		@contact_dest=@parXML.value('(/*/@contact_dest)[1]','varchar(200)'),
		@telefon_dest=@parXML.value('(/*/@telefon_dest)[1]','varchar(200)'),
		@adresa_dest=@parXML.value('(/*/@adresa_dest)[1]','varchar(200)'),
		@email_dest=@parXML.value('(/*/@email_dest)[1]','varchar(200)'),
		@judet_dest=@parXML.value('(/*/@judet_dest)[1]','varchar(200)'),
		@oras_dest=@parXML.value('(/*/@denoras_dest)[1]','varchar(200)'),
		@zip_dest=@parXML.value('(/*/@zip_dest)[1]','varchar(6)'),
		@plic=ISNULL(@parXML.value('(/*/@plic)[1]','bit'),0),
		@nr_colete=@parXML.value('(/*/@nr_colete)[1]','int'),		
		@tip_livrare=@parXML.value('(/*/@tip_livrare)[1]','int'),	
		@data_exp=@parXML.value('(/*/@data_exp)[1]','datetime'),
		@plata_transport=@parXML.value('(/*/@plata_transport)[1]','int'),
		@greutate=@parXML.value('(/*/@greutate)[1]','DECIMal(15,2)'),
		@asigurare=ISNULL(@parXML.value('(/*/@asigurare)[1]','bit'),0),
		@valoare_asigurata=@parXML.value('(/*/@valoare_asigurata)[1]','decimal(15,2)'),
		@cash_on_delivery=ISNULL(@parXML.value('(/*/@cash_on_delivery)[1]','bit'),0),
		@valoare_ramburs=@parXML.value('(/*/@valoare_ramburs)[1]','decimal(15,2)'),
		@tip_plata_ramburs=@parXML.value('(/*/@tip_plata_ramburs)[1]','int'),
		@retur_nota_semnata=ISNULL(@parXML.value('(/*/@retur_nota_semnata)[1]','bit'),0),
		@livrare_sambata=ISNULL(@parXML.value('(/*/@livrare_sambata)[1]','bit'),0),
		@retur_alte_doc=ISNULL(@parXML.value('(/*/@retur_alte_doc)[1]','bit'),0),
		@explicatii_retur=@parXML.value('(/*/@explicatii_retur)[1]','varchar(200)'),
		@continut=@parXML.value('(/*/@continut)[1]','varchar(200)')

	/*	Conventii Cargus; facem si noi niste validari si mesaje de eroare, ale lor sunt cam criptice */
	IF @asigurare = 1 and ISNULL(@valoare_asigurata,0)=0
		raiserror('Daca s-a bifat optiunea "Asigurare" trebuie completata si suma pentru care se asigura expeditia',15,1)

	IF @cash_on_delivery=1 and ISNULL(@valoare_ramburs,0)=0
		raiserror('Daca s-a bifat optiunea "Cash on delivery" trebuie completata si suma pentru ramburs',15,1)

	IF @cash_on_delivery=1 and ISNULL(@valoare_ramburs,0)>0.01 and ISNULL(@metoda_plata,0)=0
		raiserror('Daca s-a bifat optiunea "Cash on delivery" trebuie completata aleasa metoda de plata pentru ramburs (Numerar, Cec, OP sau BO)',15,1)

	IF @retur_alte_doc=1
		raiserror('Daca s-a bifat optiunea "Retur alte documente" trebuie completata sectiunea de "Explicatii retur". Exemplu: Preluare factura CGS123456 / 12.05.2010',15,1)

	select 
		@body=@body+
			ISNULL('&'+'compania_expeditor='+@expeditor,'')+
			ISNULL('&'+'contact_expeditor='+@contact_exp,'')+
			ISNULL('&'+'telefon_expeditor='+@telefon_exp,'')+
			ISNULL('&'+'adresa_expeditor='+@adresa_exp,'')+
			ISNULL('&'+'mail_expeditor='+@email_exp,'')+
			ISNULL('&'+'judet_expeditor='+@judet_exp,'')+
			ISNULL('&'+'oras_expeditor='+@oras_exp,'')+
			ISNULL('&'+'zip_expeditor='+@zip_exp,'')+
			ISNULL('&'+'compania_destinatar='+@destinatar,'')+
			ISNULL('&'+'contact_destinatar='+@contact_dest,'')+
			ISNULL('&'+'telefon_destinatar='+@telefon_dest,'')+
			ISNULL('&'+'adresa_destinatar='+@adresa_dest,'')+
			ISNULL('&'+'oras_destinatar='+@oras_dest,'')+
			ISNULL('&'+'judet_destinatar='+@judet_dest,'')+
			ISNULL('&'+'zip_destinatar='+@zip_dest,'')+
			ISNULL('&'+'plic='+CONVERT(varchar(1), @plic),'')+
			ISNULL('&'+'nr_colete='+convert(varchar(2), @nr_colete),'')+
			ISNULL('&'+'produs='+convert(varchar(1), @tip_livrare),'')+
			ISNULL('&'+'data='+convert(varchar(10), @data_exp,103),'')+
			ISNULL('&'+'plata_transport='+convert(varchar(1), @plata_transport),'')+
			ISNULL('&'+'greutate='+convert(varchar(10), @greutate),'')+
			ISNULL('&'+'asigurare='+convert(varchar(1), @asigurare),'')+
			ISNULL('&'+'valoare='+convert(varchar(10), @valoare_asigurata),'')+
			ISNULL('&'+'COD='+convert(varchar(1), @cash_on_delivery),'')+
			ISNULL('&'+'valoare_ramburs='+convert(varchar(10), @valoare_ramburs),'')+
			ISNULL('&'+'metoda_plata_cod='+convert(varchar(1), @metoda_plata),'')+
			ISNULL('&'+'RTR='+convert(varchar(1), @retur_nota_semnata),'')+
			ISNULL('&'+'SAT='+convert(varchar(1), @livrare_sambata),'')+
			ISNULL('&'+'RTD='+convert(varchar(1), @retur_alte_doc),'')+
			ISNULL('&'+'comments_rtd='+convert(varchar(1), @explicatii_retur),'')+
			ISNULL('&'+'content1='+convert(varchar(1), @continut),'')
	
	begin try
		exec httpXMLSOAPRequest
			@uri = @url, 
			@method = 'POST',	
			@requestBody = @body,
			@contentType=@contentType,
			@responsetext = @raspuns OUTPUT
			
		select @raspunsXML=CONVERT(XML, @raspuns)		
	end try
	begin catch		
		set @err='Eroare la comunicare cu serverul Cargus ('+ERROR_MESSAGE()+')' 
		RAISERROR(@err, 15, 1)
	end catch

	IF ISNULL(@raspunsXML.value('(/root/is_error/text())[1]','int'),0)=1
	begin
		set @err='Eroare validare Cargus: '+@raspunsXML.value('(/root/err_message/text())[1]','varchar(500)')
		RAISERROR(@err, 15, 1)
	end
	
	declare 
		@AWB varchar(500)

	select @AWB=@raspunsXML.value('(/root/awb/text())[1]','varchar(500)')
	select @parXML=(select @AWB awb for xml raw)

end try
BEGIN CATCH
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
