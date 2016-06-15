--***
create procedure wScriuAE @parXmlScriereIesiri xml output
as
begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuAESP')
		exec wScriuAESP @parXmlScriereIesiri output

	declare @Numar varchar(20), @Data datetime, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), @Cantitate float, @CtCoresp varchar(40), 
		@LM char(9), @Comanda char(40), @ComLivr char(20),@Explicatii char(16), @Serie char(20), @Utilizator char(10), @Schimb int, @Jurnal char(3), 
		@Stare int, @NrPozitie int, @PozitieNoua int, @PretStoc float,@update bit,@subtip varchar(2),@mesaj varchar(200),@tip varchar(2),
		@detalii xml, @docDetalii XML, @CotaTVA FLOAT, @SumaTVA FLOAT,@docInserate XML, @idIntrare int, @idIntrareFirma int
	
	set @PozitieNoua =0	

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri
		
	select @Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod,@Cantitate=cantitate,
		@CodIntrare=cod_intrare,@CtCoresp=cont_corespondent,@LM=lm,@Comanda=comanda_bugetari,
		@ComLivr=contract,@Explicatii=explicatii,	@Serie=isnull(serie,0),	@Utilizator=ISNULL(utilizator,''),
		@Jurnal=jurnal,@Stare=stare,@NrPozitie=ISNULL(numar_pozitie,0),@update=ptupdate,
		@Schimb=schimb,@tip=tip,@subtip=subtip,@detalii = detalii,@PretStoc=pret_stoc, @CotaTVA=cota_TVA, @SumaTVA=suma_TVA
		
		from OPENXML(@iDoc, '/row')
		WITH 
		(
			detalii xml 'detalii',
			tip varchar(2) '@tip', 
			subtip varchar(2) '@subtip', 
			numar varchar(20) '@numar',
			data datetime '@data',
			gestiune varchar(9) '@gestiune',
			cod varchar(20) '@cod',
			cod_intrare varchar(20) '@cod_intrare',
			cantitate decimal(10, 3) '@cantitate',	
			pret_stoc float '@pstoc',
			cota_TVA float '@cota_TVA',
			suma_TVA float '@suma_tva',
			lm varchar(9) '@lm', 
			comanda_bugetari varchar(40) '@comanda_bugetari', 
			jurnal varchar(3) '@jurnal', 
			stare int '@stare',
			utilizator varchar(20) '@utilizator', 
			serie varchar(20) '@serie',
			numar_pozitie int '@numar_pozitie',
			cont_corespondent varchar(40) '@cont_corespondent',
			ptupdate int '@update'	,
			contract varchar(20) '@contract',
			explicatii varchar(50) '@explicatii',
			schimb int '@schimb'	
		)
	set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizator invalid!',11,1)
		return -1
	end
	declare @Sb char(9), @Ct378 varchar(40), @AnGest378 int, @AnGr378 int, @Ct4428 varchar(40), @AnGest4428 int, 
		@CtCorespAE varchar(40), @CuCtFactAE int, @CtFactAE varchar(40), 
		@TipNom char(1), @PStocNom float, @PretVanzNom float, @GrNom char(13), @TipGest char(1), 
		@CtStoc varchar(40), @TVAnx float, @PretAmPred float, @LocatieStoc char(30), @DataExpStoc datetime, 
		@CtFact varchar(40), @CtAdaos varchar(40), @CtTVANx varchar(40), @StersPozitie int,@serii int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'CADAOS', @AnGest378 output, @AnGr378 output, @Ct378 output
	exec luare_date_par 'GE', 'CNTVA', @AnGest4428 output, 0, @Ct4428 output
	exec luare_date_par 'GE', 'CCORAE', 0, 0, @CtCorespAE output
	exec luare_date_par 'GE', 'CONT_AE?', @CuCtFactAE output, 0, ''
	exec luare_date_par 'GE', 'CONT_AE', 0, 0, @CtFactAE output
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''
	
	exec iauNrDataDoc 'AE', @Numar output, @Data output, 0
	if isnull(@Stare,0)=0 
		set @Stare=3

	set @TipNom=''
	set @PStocNom=0
	set @PretVanzNom=0
	set @GrNom=''
	select @TipNom=tip, @PStocNom=pret_stoc, @PretVanzNom=pret_vanzare, @GrNom=grupa
	from nomencl
	where cod=isnull(@Cod,'')

	set @TipGest=''
	set @LocatieStoc=''
	set @DataExpStoc=@Data
	select @TipGest=tip_gestiune
	from gestiuni 
	where subunitate=@Sb and cod_gestiune=isnull(@Gestiune,'')

	select @PretStoc=(case when @PretStoc is null then pret else @PretStoc end), @CtStoc=cont, @TVAnx=tva_neexigibil, @PretAmPred=pret_cu_amanuntul, @LocatieStoc=locatie, @DataExpStoc=data_expirarii, @idIntrare=idIntrare, @idIntrareFirma=idIntrareFirma
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
	-- tratare TVA neinregistrat cu cota <>0:
	IF isnull(@SumaTVA, 0) = 0
		SET @SumaTVA = round(convert(DECIMAL(17, 4), ISNULL(@Cantitate, 0) * @PretStoc * isnull(@CotaTVA, 0) / 100), 2)
	IF isnull(@SumaTVA, 0) <> 0 and isnull(@CotaTVA,0)=0
		SET @SumaTVA = 0

	if isnull(@CtCoresp, '')='' and LEFT(@CtStoc,1) not in ('8','9')
		set @CtCoresp=(case when @CtCorespAE<>'' then @CtCorespAE else '6588' end)
	set @CtTVAnx=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end)
	set @CtAdaos=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)
	set @CtFact=(case when @CuCtFactAE=1 then @CtFactAE else @CtCoresp end)

	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)

	---start adaugare pozitie noua in pozdoc-----
	if @update=0 and @subtip<>'SE'
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
		set @NrPozitie=@NrPozitie+1
			
		-->>>>>>>>>start cod pentru lucrul cu serii<<<<<<<<<<<<<<--
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>''
			begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
				select @cod = (case when @Cod is null then '' else @cod end ),
						@Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
						@CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
				exec wScriuPDserii 'AE',@Numar,@Data,@Gestiune,@Cod,@CodIntrare,@NrPozitie,@Serie,@Cantitate,''
				set @Cantitate =(select SUM(cantitate) from pdserii where tip='AE' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
																and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie)--calcul cantitate pt pozdoc din pdserii
			end														  														  
		-->>>>>>>>>	stop cod pentru lucrul cu serii<<<<<<<<<<<<<<<--
	
		IF OBJECT_ID('tempdb..#AEInserat') IS NOT NULL
		DROP TABLE #AEInserat

		CREATE TABLE #AEInserat (idPozDoc INT)
			
		insert pozdoc
			(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
			Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
			Cod_intrare, Cont_de_stoc, Cont_corespondent, 
			TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
			Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
			Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
			Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
			Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip, idIntrare, idIntrareFirma) 
		OUTPUT inserted.idPozDoc INTO #AEInserat(idPozDoc)	
		values
			(@Sb, 'AE', @Numar, isnull(@Cod,''), @Data, isnull(@Gestiune,''), isnull(@Cantitate,0), 0, @PretStoc, 0, 
			0, 0, @sumaTVA, @cotaTVA, isnull(@Utilizator,''), convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
			isnull(@CodIntrare,''), @CtStoc, isnull(@CtCoresp,''), @TVAnx, @PretAmPred, 
			(case when isnull(@TipNom,'') in ('F','S','R') then 'V' else 'E' end),
			@LocatieStoc, @DataExpStoc, @NrPozitie, isnull(@LM,''), isnull(@Comanda,''), '', 
			'', '', 0, @CtTVAnx, left(isnull(@Explicatii,''), 8), @CtAdaos, '', 
			@Stare, isnull(@ComLivr,''), @CtFact, '', 0, @Data, @Data, isnull(@Schimb,0), 0, 
			0, 0, substring(isnull(@Explicatii,''), 9, 8), isnull(@Jurnal,''),(case when @subtip=@tip then null else @subtip end), @idIntrare, @idIntrareFirma)
			
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
			
		SET @docInserate = (
			SELECT idPozDoc idPozDoc
			FROM #AEInserat
			FOR XML raw, root('Inserate')
			)	
			
		SET @docDetalii = (
			SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, 'pozdoc' as tabel, @detalii
			for xml raw
			)
		exec wScriuDetalii @parXML=@docDetalii
	end
	---stop adaugare pozitie noua in pozdoc-----
	
	-----start modificare pozitie existenta in pozdoc----
	if @update=1 or @subtip='SE'--situatia in care se modifica o pozitie din pozdoc sau se adauga pozitie cu subtip SE->serie in cadrul pozitiei din pozdoc
	begin				
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
			begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
				select @cod = (case when @Cod is null then '' else @cod end ),
						@Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						@Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
						@CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
				exec wScriuPDserii 'AE', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
				set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='AE' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
																and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
			end
			
		if @subtip='SE'
			begin --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
				update pozdoc set Cantitate=(case when isnull(@Cantitate,0)<>0 then isnull(@Cantitate,0) else Cantitate end)
				where subunitate=@Sb and tip='AE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
			end				
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
			
		update pozdoc set 
				Cod=(case when @Cod is null then Cod else @cod end),
				Gestiune=(case when @Gestiune is null then Gestiune else @Gestiune end),
				Cantitate=(case when @Cantitate is null then Cantitate else convert(decimal(11,3),@Cantitate) end),
				Pret_de_stoc=(case when @PretStoc is null then convert(decimal(11,5),Pret_de_stoc) else convert(decimal(11,5),@PretStoc) end),
				Utilizator=@Utilizator,
				Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
				Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),					
				Cod_intrare=(case when @CodIntrare is null then Cod_intrare else @CodIntrare end),
				Cont_de_stoc=(case when @CtStoc is null then Cont_de_stoc else @CtStoc end),				
				Cont_corespondent=(case when @CtCoresp is null then Cont_corespondent else @CtCoresp end),					
				Cota_TVA=(case when @CotaTVA is null then Cota_TVA else convert(decimal(11,5),@CotaTVA) end),
				TVA_deductibil=(case when @SumaTVA is null then TVA_deductibil else convert(decimal(11,5),@SumaTVA) end),
				TVA_neexigibil=(case when @TVAnx is null then TVA_neexigibil else convert(decimal(11,5),@TVAnx) end),
				Pret_amanunt_predator=(case when @PretAmPred is null then Pret_amanunt_predator else convert(decimal(11,5),@PretAmPred) end),
				Locatie=(case when @LocatieStoc is null then Locatie else @LocatieStoc end),
				Data_expirarii=(case when @DataExpStoc is null then Data_expirarii else @DataExpStoc end),				
				Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),				
				Comanda=(case when @Comanda is null then Comanda else @Comanda end),
				Tert=(case when @CtTVAnx is null then Tert else @CtTVAnx end),
				Factura=(case when @Explicatii is null then Factura else left(@Explicatii, 8) end),					
				Gestiune_primitoare=(case when @CtAdaos is null then Gestiune_primitoare else @CtAdaos end),
				Stare=(case when @Stare is null then Stare else @Stare end),					
				Grupa=(case when @ComLivr is null then Grupa else @ComLivr end),
				Cont_factura=(case when @CtFact is null then Cont_factura else @CtFact end),
				Procent_vama=(case when @Schimb is null then Procent_vama else @Schimb end),
				Contract=(case when @Explicatii is null then Contract else substring(@Explicatii, 9, 8) end),
				Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end), 
				idIntrare=(case when @idIntrare is null then idIntrare else @idIntrare end), 
				idIntrareFirma=(case when @idIntrareFirma is null then idIntrareFirma else @idIntrareFirma end) 
		where subunitate=@Sb and tip='AE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
			
		SET @docDetalii = (
			SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, @Gestiune gestiune, @cod cod, @CodIntrare 
				codintrare,'pozdoc' as tabel, @detalii
			for xml raw
			)
		exec wScriuDetalii @parXML=@docDetalii
	end
	-----stop modificare pozitie existenta in pozdoc----
		
	--returnare idpozdoc
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = '(wScriuAE)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
