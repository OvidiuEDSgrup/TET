--***
create procedure wScriuCI @parXmlScriereIesiri xml output
as
begin try
	declare 
		@Numar varchar(20), @Data datetime, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), @mesaj varchar(200),
		@Cantitate float, @Locatie char(30), @LM char(9), @Comanda char(40), @Jurnal char(3), @CtCoresp varchar(40),
		@CtInterm varchar(40), @Stare int, @Utilizator char(10), @NrPozitie int,@update bit,@subtip varchar(2),@tip varchar(2), @docInserate XML, @iDoc int,
		@Sb char(9), @trecereobinvpecheltlacasare int, @Ct602 varchar(40), @AnLM602 int, @AnCtSt602 int, @CtUzura varchar(40), @AnUzura int, 
		@PStocNom float, @PretStoc float, @CtStoc varchar(40), @LocatieStoc char(30), @DataExpStoc datetime, @StersPozitie int,
		@comandaSql nvarchar(max), @detalii XML,@areDetalii bit,  @dataoperarii datetime, @oraoperarii varchar(50)
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri
				
	select 
		@Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod,@CodIntrare=cod_intrare,
		@Cantitate=cantitate,@Locatie=locatie,@LM=lm,@Comanda=comanda_bugetari,
		@Jurnal=jurnal,@Stare=stare,@Utilizator=ISNULL(utilizator,''),@NrPozitie=ISNULL(numar_pozitie,0),
		@CtInterm=cont_intermediar,@CtCoresp=cont_corespondent,@update=ptupdate,@tip=tip,@subtip=subtip,
		@detalii=detalii
				
		from OPENXML(@iDoc, '/row')
		WITH 
		(
			tip char(2) '@tip', 
			subtip char(2) '@subtip', 
			numar varchar(20) '@numar',
			data datetime '@data',
			gestiune char(9) '@gestiune',
			cod char(20) '@cod',
			cod_intrare char(20) '@cod_intrare',
			cantitate float '@cantitate',	
			locatie char(30) '@locatie', 
			lm char(9) '@lm', 
			comanda_bugetari char(40) '@comanda_bugetari', 
			jurnal char(3) '@jurnal', 
			stare int '@stare',
			utilizator char(20) '@utilizator', 
			serie char(20) '@serie',
			numar_pozitie int '@numar_pozitie',
			cont_intermediar varchar(40) '@cont_intermediar',
			cont_corespondent varchar(40) '@cont_corespondent',
			ptupdate int '@update',
			detalii XML 'detalii/row'
		)

	set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!		
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'TROICHCAS', @trecereobinvpecheltlacasare output, 0, ''
	exec luare_date_par 'GE', 'CONTCINV', @AnLM602 output, @AnCtSt602 output, @Ct602 output
	exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output

	exec iauNrDataDoc 'CI', @Numar output, @Data output, 0
	if isnull(@Stare,0)=0 
		set @Stare=3

	set @PStocNom=0
	select @PStocNom=pret_stoc 
	from nomencl
	where cod=isnull(@Cod,'')

	select @PretStoc=pret, @CtStoc=cont, @LocatieStoc=locatie, @DataExpStoc=data_expirarii 
	from stocuri
	where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') and cod_intrare=isnull(@CodIntrare,'')

	--pret de stoc
	if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
	--cont de stoc
	if @CtStoc is null set @CtStoc=dbo.formezContStocFol(isnull(@Cod,''))

	if isnull(@Locatie, '')='' 
		set @Locatie=isnull(@LocatieStoc, '')
	if isnull(@DataExpStoc, '01/01/1901')<='01/01/1901'
		set @DataExpStoc=@Data

	if isnull(@CtCoresp,'')='' 
		set @CtCoresp=(case when left(@CtStoc, 1)='8' then '' when @trecereobinvpecheltlacasare=1 
		then RTrim(@Ct602)+(case when @AnLM602=1 then '.'+RTrim(isnull(@LM,'')) else '' end)+(case when @AnCtSt602=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) 
		else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
	
	if isnull(@CtInterm,'')='' 
		set @CtInterm=''
	
	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)	

	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
		set @areDetalii = 1

	select 			
		@dataOperarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104),
		@oraOperarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', ''))

	---start adaugare pozitie noua in pozdoc-----
	if @update=0 
	begin	
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
		set @NrPozitie=@NrPozitie+1
		
		IF OBJECT_ID('tempdb..#CIInserat') IS NOT NULL
			DROP TABLE #CIInserat
		CREATE TABLE #CIInserat (idPozDoc INT)

		SET @comandaSql = N'
				INSERT pozdoc (
					Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
					Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
					Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
					Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
					Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
					Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+'
					)
				OUTPUT inserted.idPozDoc INTO #CIInserat(idPozDoc)
				VALUES (
					@Sb, @tip, @Numar, isnull(@Cod,''''), @Data, isnull(@Gestiune,''''), isnull(@Cantitate,0), 0, @PretStoc, 0, 
					0, 0, 0, 0, isnull(@Utilizator,''''), @dataoperarii, @oraoperarii, 
					isnull(@CodIntrare,''''), @CtStoc, isnull(@CtCoresp,''''), 0, 0, ''E'', 
					isnull(@Locatie,''''), @DataExpStoc, @NrPozitie, isnull(@LM,''''), isnull(@Comanda,''''), '''', 
					@CtInterm, '''', 0, '''', '''', '''', '''', 
					@Stare, '''', '''', '''', 0, @Data, @Data, 0, 0, 
					0, 0, '''', isnull(@Jurnal,''''),(case when @subtip=@tip then null else @subtip end)'
					+(case when @areDetalii=1 then ', @detalii' else '' end)+')'	

			exec sp_executesql @statement=@comandaSql, @params=N'
				@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @Gestiune CHAR(9), @Cantitate FLOAT, 
				@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare CHAR(13), 
				@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@Locatie char(30), @DataExpStoc datetime, @NrPozitie int, @LM char(9),
				@comanda char(40),@CtInterm VARCHAR(40), @Stare int,@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
				@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @Gestiune=@Gestiune, @Cantitate=@Cantitate , 
				@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare ,@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@Locatie =@Locatie, 
				@DataExpStoc =@DataExpStoc, @NrPozitie =@NrPozitie,@LM =@LM ,@comanda =@comanda,@CtInterm =@CtInterm ,@Stare =@Stare,@Jurnal =@Jurnal ,
				@subtip =@subtip,@dataoperarii=@dataoperarii,@oraoperarii=@oraoperarii

		SET @docInserate = (
			SELECT idPozDoc idPozDoc
			FROM #CIInserat
			FOR XML raw, root('Inserate')
			)	
		
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
	end
	---stop adaugare pozitie noua in pozdoc-----
		
	-----start modificare pozitie existenta in pozdoc----
	if @update=1
	begin
		SET @comandaSql = N'
			UPDATE pozdoc
			SET '+		
				(case when @Cod is null then '' else 'Cod=@cod' end)+
				(case when @Gestiune is null then '' else ',Gestiune=@Gestiune' end)+
				(case when @Cantitate is null then '' else ',Cantitate=convert(decimal(11,3),@Cantitate)' end)+
				(case when @PretStoc is null then '' else ',Pret_de_stoc=convert(decimal(11,5),@PretStoc)' end)+
				',utilizator=@Utilizator'+
				',data_operarii=@dataoperarii'+
				',ora_operarii=@oraoperarii'+
				(case when @CodIntrare is null then '' else ',Cod_intrare=@CodIntrare' end)+
				(case when @CtStoc is null then '' else ',Cont_de_stoc =@CtStoc' end)+
				(case when @CtCoresp is null then '' else ',Cont_corespondent=@CtCoresp' end)+
				(case when @Locatie is null then ''  else ',Locatie=@Locatie' end)+
				(case when @DataExpStoc is null then '' else ',Data_expirarii=@DataExpStoc' end)+		
				(case when @LM is null then '' else ',Loc_de_munca = @LM 'end)+				
				(case when @Comanda is null then '' else ',Comanda=@Comanda' end)+
				(case when @CtInterm is null then '' else ',Cont_intermediar =@CtInterm' end)+
				(case when @Stare is null then '' else ',Stare=@Stare' end)+
				(case when @Jurnal is null then '' else ',Jurnal =@Jurnal' end)+
				(CASE WHEN @areDetalii=1 THEN ', detalii = @detalii' else '' end)+
								
		 ' WHERE subunitate = @Sb
			AND tip = @tip
			AND numar = @Numar
			AND data = @Data
			AND numar_pozitie = @NrPozitie '
		
		exec sp_executesql @statement=@comandaSql, @params=N'
			@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @Gestiune CHAR(9), @Cantitate FLOAT, 
			@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare CHAR(13), 
			@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@Locatie char(30), @DataExpStoc datetime, @NrPozitie int, @LM char(9),
			@comanda char(40),@CtInterm VARCHAR(40), @Stare int,@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
			@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @Gestiune=@Gestiune, @Cantitate=@Cantitate , 
			@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare ,@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@Locatie =@Locatie, 
			@DataExpStoc =@DataExpStoc, @NrPozitie =@NrPozitie,@LM =@LM ,@comanda =@comanda,@CtInterm =@CtInterm ,@Stare =@Stare,@Jurnal =@Jurnal ,
			@subtip =@subtip,@dataoperarii=@dataoperarii,@oraoperarii=@oraoperarii
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
	
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))	
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

