--***
create procedure wScriuCM @parXmlScriereIesiri xml output
as
begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuCMSP')
		exec wScriuCMSP @parXmlScriereIesiri output

	declare @Numar varchar(20), @Data datetime, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), 
		@Cantitate decimal(15,5), @LM char(9), @Comanda char(40), @Barcod char(30), @Factura char(20), @Schimb int, 
		@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @NrPozitie int,@CtCoresp varchar(40),@CtInterm varchar(40), 
		@update bit,@tip varchar(2),@subtip varchar(2),@mesaj varchar(200), @detalii xml, @docDetalii XML, @docInserate XML, @idIntrare int, @idIntrareFirma int

	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri
		
		select @Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod,@Cantitate=cantitate,
			@CodIntrare=cod_intrare,@LM=lm,@Comanda=comanda_bugetari,@Barcod=barcod,
			@Factura=factura,@Serie=isnull(serie,0),	@Utilizator=ISNULL(utilizator,''),@Jurnal=jurnal,
			@Stare=stare,@NrPozitie=ISNULL(numar_pozitie,0),@CtCoresp=cont_corespondent,@CtInterm=cont_intermediar,@update=isnull(ptupdate,0),
			@Schimb=schimb,@tip=tip,@subtip=subtip, @detalii=detalii
		
		from OPENXML(@iDoc, '/row')
		WITH 
		(
			detalii xml 'detalii',
			tip char(2) '@tip', 
			subtip char(2) '@subtip', 
			numar varchar(20) '@numar',
			data datetime '@data',
			factura char(20) '@factura',
			gestiune char(9) '@gestiune',
			cod char(20) '@cod',
			cod_intrare char(20) '@cod_intrare',
			cantitate decimal(15, 5) '@cantitate',	
			lm char(9) '@lm', 
			comanda_bugetari char(40) '@comanda_bugetari', 
			jurnal char(3) '@jurnal', 
			stare int '@stare',
			barcod char(30) '@barcod', 
			utilizator char(20) '@utilizator', 
			serie char(20) '@serie',
			numar_pozitie int '@numar_pozitie',
			cont_corespondent varchar(40) '@cont_corespondent',
			cont_intermediar varchar(40) '@cont_intermediar',
			ptupdate int '@update'	,
			schimb int '@schimb'	
		)
	set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!	
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizator invalid!',11,1)
		return -1
	end
	declare @Sb char(9), 
		@TipNom char(1), @PStocNom float, @PretVanzNom float, @TipGest char(1), 
		@PretStoc float, @CtStoc varchar(40), @TVAnx float, @PretAmPred float, @LocatieStoc char(30), @DataExpStoc datetime, 
		@Discount float, @CtVenit varchar(40), @CtAdaos varchar(40), @CtTVANx varchar(40),
		@StersPozitie int,@serii int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''
	exec iauNrDataDoc 'CM', @Numar output, @Data output, 0
	
	if isnull(@Stare,0)=0  set @Stare=3

	set @TipNom=''
	set @PStocNom=0
	set @PretVanzNom=0
	select @TipNom=tip, @PStocNom=pret_stoc, @PretVanzNom=pret_vanzare
	from nomencl
	where cod=isnull(@Cod,'')

	set @TipGest=''
	set @LocatieStoc=''
	set @DataExpStoc=@Data
	select @TipGest=tip_gestiune
	from gestiuni 
	where subunitate=@Sb and cod_gestiune=isnull(@Gestiune,'')

	select @PretStoc=pret, @CtStoc=cont, @TVAnx=tva_neexigibil, @PretAmPred=pret_cu_amanuntul, @LocatieStoc=locatie, @DataExpStoc=data_expirarii, @idIntrare=idIntrare, @idIntrareFirma=idIntrareFirma
	from stocuri
	where subunitate=@Sb and tip_gestiune=@TipGest and cod_gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') and cod_intrare=isnull(@CodIntrare,'')

	if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
	if @CtStoc is null 
		set @CtStoc=dbo.formezContStoc(isnull(@Gestiune,''), isnull(@Cod,''), isnull(@LM,''))
	if @TVAnx is null
		set @TVAnx=0
	if @PretAmPred is null
		set @PretAmPred=@PretVanzNom
	if @LocatieStoc is null
		set @LocatieStoc=''
	if @DataExpStoc is null
		set @DataExpStoc=@Data
	if isnull(@CodIntrare,'')=''
		set @CodIntrare=dbo.formezCodIntrare('CM', @Numar, @Data, isnull(@Cod,''), isnull(@Gestiune,''), @CtStoc, @PretStoc)

	set @Discount=0
	exec formezConturiCM @Cod, @CtStoc, @Gestiune, '', @LM, @Discount, @CtCoresp output, @CtInterm output, @CtVenit output, @CtAdaos output, @CtTVANx output

	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)

	---start adaugare pozitie noua in pozdoc-----
	if @update=0 and @subtip<>'SE'
	begin		
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
		set @NrPozitie=@NrPozitie+1	
		
		-->>>>>>>>>start cod pentru lucrul cu serii<<<<<<<<<<<<<<--
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>''and @Serii<>0 
		begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			select @cod = (case when @Cod is null then '' else @cod end ),
				@Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
				@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
				@CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
			exec wScriuPDserii 'CM', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
			set @Cantitate =(select SUM(cantitate) from pdserii where tip='CM' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
																  and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie)--calcul cantitate pt pozdoc din pdserii
		end													  														  
		-->>>>>>>>>stop cod pentru lucrul cu serii<<<<<<<<<<<<<<<--
		
		IF OBJECT_ID('tempdb..#CMInserat') IS NOT NULL
			DROP TABLE #CMInserat

		CREATE TABLE #CMInserat (idPozDoc INT)
		
		insert pozdoc
			(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
			Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
			Cod_intrare, Cont_de_stoc, Cont_corespondent,TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
			Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
			Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
			Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
			Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip, idIntrare, idIntrareFirma) 
		OUTPUT inserted.idPozDoc INTO #CMInserat(idPozDoc)
		values
			(@Sb, 'CM', @Numar, isnull(@Cod,''), @Data, isnull(@Gestiune,''), isnull(@Cantitate,0), 0, @PretStoc, 0, 
			0, 0, 0, 0, @Utilizator, convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
			isnull(@CodIntrare,''), @CtStoc, @CtCoresp, @TVAnx, @PretAmPred, 'E', 
			@LocatieStoc, @DataExpStoc, @NrPozitie, isnull(@LM,''), isnull(@Comanda,''), isnull(@Barcod,''), 
			@CtInterm, @CtVenit, @Discount, @CtAdaos, isnull(@Factura,''), '', @CtTVAnx, 
			@Stare, '', '', '', 0, @Data, @Data, isnull(@Schimb,0), 0, 
			0, 0, '', isnull(@Jurnal,''),(case when @subtip=@tip then null else @subtip end), @idIntrare, @idIntrareFirma)
		
		SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #CMInserat
				FOR XML raw, root('Inserate')
				)
		
		SET @docDetalii = (
		SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, @Gestiune gestiune, @cod cod, @CodIntrare 
						codintrare,'pozdoc' as tabel, @detalii
			for xml raw
			)
		exec wScriuDetalii @parXML=@docDetalii
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
	end
	---stop adaugare pozitie noua in pozdoc-----
	
	-----start modificare pozitie existenta in pozdoc----
	if @update=1 or @subtip='SE'--situatia in care se modifica o pozitie din pozdoc sau se adauga pozitie cu subtip SE->serie in cadrul pozitiei din pozdoc
	begin				
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
		begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
			select	@cod = (case when @Cod is null then '' else @cod end ),
				@Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
				@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
				@CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
			exec wScriuPDserii 'CM', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
			set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='CM' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
														  and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
		end
		
		if @subtip='SE'
		begin --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
			update pozdoc set Cantitate=(case when @Cantitate is null then Cantitate else @Cantitate end)
			where subunitate=@Sb and tip='CM' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
		end				
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
		
		update pozdoc set 
			Cod=(case when @Cod is null then Cod else @cod end),
			Gestiune=(case when @Gestiune is null then Gestiune else @Gestiune end),
			Cantitate=(case when @Cantitate is null then Cantitate else @Cantitate end),
			Pret_de_stoc=(case when @PretStoc is null then Pret_de_stoc else @PretStoc end),
			Utilizator=@Utilizator,
			Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
			Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),					
			Cod_intrare=(case when @CodIntrare is null then Cod_intrare else @CodIntrare end),
			Cont_de_stoc=(case when @CtStoc is null then Cont_de_stoc else @CtStoc end),				
			Cont_corespondent=(case when @CtCoresp is null then Cont_corespondent else @CtCoresp end),					
			TVA_neexigibil=(case when @TVAnx is null then convert(decimal(11,5),TVA_neexigibil) else convert(decimal(11,5),@TVAnx) end),
			Pret_amanunt_predator=(case when @PretAmPred is null then Pret_amanunt_predator else convert(decimal(11,5),@PretAmPred) end),
			Locatie=(case when @LocatieStoc is null then Locatie else @LocatieStoc end),
			Data_expirarii=(case when @DataExpStoc is null then Data_expirarii else @DataExpStoc end),				
			Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),				
			Comanda=(case when @Comanda is null then Comanda else @Comanda end),
			Barcod=(case when @Barcod is null then Barcod else @Barcod end),						
			Cont_intermediar=(case when @CtInterm is null then Cont_intermediar else @CtInterm end),
			Cont_venituri=(case when @CtVenit is null then Cont_venituri else @CtVenit end),
			Discount=(case when @Discount is null then Discount else convert(decimal(11,5),@Discount) end),
			Tert=(case when @CtAdaos is null then Tert else @CtAdaos end),
			Factura=(case when @Factura is null then Factura else @Factura end),					
			Numar_DVI=(case when @CtTVAnx is null then Numar_DVI else @CtTVAnx end),									
			Stare=(case when @Stare is null then Stare else @Stare end),					
			Procent_vama=(case when @Schimb is null then Procent_vama else @Schimb end),			
			Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end), 
			idIntrare=(case when @idIntrare is null then idIntrare else @idIntrare end), 
			idIntrareFirma=(case when @idIntrareFirma is null then idIntrareFirma else @idIntrareFirma end)
		where subunitate=@Sb and tip='CM' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
		
		SET @docDetalii = (
		SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, @Gestiune gestiune, @cod cod, @CodIntrare 
			codintrare,'pozdoc' as tabel, @detalii
		for xml raw
		)
		
		exec wScriuDetalii @parXML=@docDetalii
	end
		-----stop modificare pozitie existenta in pozdoc----
		
	---returnare parametri in @parXmlScriereIesiri ---
	-->numar_pozitie	
	if @parXmlScriereIesiri.value('(/row/@numar_pozitie)[1]','int') is null
		set @parXmlScriereIesiri.modify ('insert attribute numar_pozitie {sql:variable("@NrPozitie")} into (/row)[1]')
	else
		set @parXmlScriereIesiri.modify('replace value of (/row/@numar_pozitie)[1] with sql:variable("@NrPozitie")')
	-->cont_corespondent	
	if @parXmlScriereIesiri.value('(/row/@cont_corespondent)[1]','varchar(40)') is null
		set @parXmlScriereIesiri.modify ('insert attribute cont_corespondent {sql:variable("@CtCoresp")} into (/row)[1]')
	else
		set @parXmlScriereIesiri.modify('replace value of (/row/@cont_corespondent)[1] with sql:variable("@CtCoresp")')			
	---stop returnare parametrii in @parXmlScriereIesiri---	
	
	--returnare idpozdoc
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))
	
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = '(wScriuCM)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
