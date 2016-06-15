--***
create procedure wScriuDF @parXmlScriereIesiri xml output
as
begin try
	declare @Numar varchar(20), @Data datetime , @GestPred char(9), @GestPrim char(13), 
		@Cod char(20), @CodIntrare char(13), @CodIPrim char(13), @Cantitate float, @ProcSal float, @CotaTVA float, 
		@LocatiePrim char(30), @LM char(9), @Comanda char(40), @Jurnal char(3), @Barcod char(30), @DataExp datetime, 
		@Stare int, @Explicatii char(16), @Serie char(20), @Utilizator char(10), @NrPozitie int, 
		@CtCoresp varchar(40), @CtVen varchar(40), @CtInterm varchar(40), @CtFact varchar(40),@update bit,@subtip varchar(2),@mesaj varchar(200),@tip varchar(2),
		@detalii xml, @areDetalii bit,@iDoc int, @comandaSql nvarchar(max), @docInserate xml, @dataoperarii datetime, @oraoperarii varchar(50),
		@Sb char(9), @trecereobinvpecheltlacasare int, @Ct602 varchar(40), @AnLM602 int, @AnCtSt602 int, @CtUzura varchar(40), @AnUzura int, @Ct4282 varchar(40), @AnGest4282 int, 
		@PStocNom float, @TipGestPred char(1), @PretStoc float, @CtStoc varchar(40), @LocatieStoc char(30),@serii int, @idIntrare int, @idIntrareFirma int 	
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri
				
	select 
		@Numar=isnull(numar,''),@Data=data,@CtFact=cont_factura,@GestPred=gestiune,@GestPrim=gestiune_primitoare,
		@Cod=cod,@CodIntrare=cod_intrare,@Cantitate=cantitate,@CodIPrim=codiPrim,@ProcSal=0,
		@CotaTVA=cota_TVA,@LocatiePrim=locatie,@LM=lm,@Comanda=comanda_bugetari,
		@Jurnal=jurnal,@Stare=stare,@Barcod=barcod,@DataExp=data_expirarii,@Explicatii =explicatii,
		@Serie=isnull(serie,0),@Utilizator=ISNULL(utilizator,''),@NrPozitie=ISNULL(numar_pozitie,0),@CtCoresp=cont_corespondent,
		@CtVen=isnull(cont_venituri,''),@CtInterm=cont_intermediar,@CtFact=cont_factura,		
		@update=ptupdate,@tip=tip,@subtip=subtip, @detalii=detalii
				
		from OPENXML(@iDoc, '/row')
		WITH 
		(
			tip char(2) '@tip', 
			subtip char(2) '@subtip', 
			numar varchar(20) '@numar',
			data datetime '@data',
			tert char(13) '@tert',
			factura char(20) '@factura',
			data_facturii datetime '@data_facturii',
			data_scadentei datetime '@data_scadentei',
			data_expirarii datetime '@data_expirarii',
			cont_factura varchar(40) '@cont_factura',
			gestiune char(9) '@gestiune',
			cod char(20) '@cod',
			cod_intrare char(20) '@cod_intrare',
			codiPrim char(20) '@codiPrim',
			cantitate float '@cantitate',	
			valuta varchar(3) '@valuta' , 
			curs varchar(14) '@curs',
			locatie char(30) '@locatie', 
			pret_valuta float '@pret_valuta', 
			discount float '@discount', 
			pret_amanunt float '@pret_amanunt', 
			lm char(9) '@lm', 
			comanda_bugetari char(40) '@comanda_bugetari', 
			contract char(20) '@contract',
			jurnal char(3) '@jurnal', 
			stare int '@stare',
			barcod char(30) '@barcod', 
			tipTVA int '@tipTVA',
			utilizator char(20) '@utilizator', 
			serie char(20) '@serie',
			suma_tva float '@suma_tva', 
			cota_TVA float '@cota_TVA',
			numar_pozitie int '@numar_pozitie',
			suprataxe float '@suprataxe', 
			ptupdate int '@update',
			explicatii varchar(30) '@explicatii',
			cont_corespondent varchar(40) '@cont_corespondent',
			cont_venituri varchar(40) '@cont_venituri',
			cont_intermediar varchar(40) '@cont_intermediar',
			gestiune_primitoare varchar(30) '@gestiune_primitoare',
			categ_pret varchar(30) '@categ_pret',
			detalii XML 'detalii/row'
		)
	set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!		
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end	
	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
		set @areDetalii = 1

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'TROICHCAS', @trecereobinvpecheltlacasare output, 0, ''
	exec luare_date_par 'GE', 'CONTCINV', @AnLM602 output, @AnCtSt602 output, @Ct602 output
	exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output
	exec luare_date_par 'GE', 'CONTDAS', @AnGest4282 output, 0, @Ct4282 output
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

	exec iauNrDataDoc 'DF', @Numar output, @Data output, 0
	if ISNULL(@Stare,0)=0
		set @Stare=3

	set @PStocNom=0
	select @PStocNom=pret_stoc 
	from nomencl
	where cod=@Cod

	set @TipGestPred=''
	select @TipGestPred=tip_gestiune
	from gestiuni 
	where subunitate=@Sb and cod_gestiune=@GestPred

	select @PretStoc=pret, @CtStoc=cont, @LocatieStoc=locatie, @DataExp=(case when isnull(@DataExp, '01/01/1901')<='01/01/1901' then data_expirarii else @DataExp end), @idIntrare=idIntrare, @idIntrareFirma=idIntrareFirma
	from stocuri
	where subunitate=@Sb and tip_gestiune=@TipGestPred and cod_gestiune=@GestPred and cod=@Cod and cod_intrare=@CodIntrare

	--pret de stoc
	if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
	--cont de stoc
	if @CtStoc is null set @CtStoc=dbo.formezContStoc(isnull(@GestPred,''), isnull(@Cod,''), isnull(@LM,''))

--cod intrare primitor
	if isnull(@CodIPrim, '')=''
	begin
		set @CodIPrim=@CodIntrare
		declare @pas int
		set @pas=0
		while @pas<702 
			and exists (select 1 from stocuri where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim
				and (abs(@PretStoc-pret)>=0.00001 or @CtCoresp is not null and cont<>isnull(@CtCoresp,'')))
		begin
			set @pas=@pas+1
			set @CodIPrim=RTrim(left(isnull(@CodIntrare,''), (case when @pas<=26 then 12 else 11 end)))+RTrim((case when @pas>26 then CHAR(64+(@pas-1)/26) else '' end))+CHAR(64+(@pas-1)%26+1)
		end
	end

--stoc la primitor
	select @CtCoresp=(case when isnull(@CtCoresp,'')='' then cont else @CtCoresp end), 
		@LocatiePrim=(case when isnull(@LocatiePrim, '')='' then locatie else @LocatiePrim end), @DataExp=(case when isnull(@DataExp, '01/01/1901')<='01/01/1901' then data_expirarii else @DataExp end)
	from stocuri
	where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim

	if isnull(@LocatiePrim, '')='' 
		set @LocatiePrim=isnull(@LocatieStoc, '')
	if isnull(@DataExp,'')=''
		set @DataExp=@Data

	if isnull(@CtCoresp,'')='' set @CtCoresp=dbo.formezContStocFol(isnull(@Cod,''))

	if isnull(@CtVen,'')='' set @CtVen=(case when left(@CtStoc, 1)='8' then '' when left(@CtCoresp, 1)<>'8' and @trecereobinvpecheltlacasare=1 then '' 
		else RTrim(@Ct602)+(case when @AnLM602=1 then '.'+RTrim(isnull(@LM,'')) else '' end)+(case when @AnCtSt602=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
	if isnull(@CtInterm,'')='' set @CtInterm=(case when left(@CtCoresp, 1)<>'8' and @trecereobinvpecheltlacasare=1 then '' 
		else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
	if isnull(@CtFact,'')='' set @CtFact=RTrim(@Ct4282)+(case when @AnGest4282=1 then '.'+RTrim(isnull(@GestPrim,'')) else '' end)

	if isnull(@CotaTVA,0)=0 or @ProcSal=0
		set @CotaTVA=0

	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)
	
	select 			
		@dataOperarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104),
		@oraOperarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', ''))
	---start adaugare pozitie noua in pozdoc-----
	if @update=0 
		begin	
		    IF OBJECT_ID('tempdb..#DFInserat') IS NOT NULL
				DROP TABLE #DFInserat
			CREATE TABLE #DFInserat (idPozDoc INT)

			exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
			set @NrPozitie=@NrPozitie+1

		
			SET @comandaSql = N'
				INSERT pozdoc (
					Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
					Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
					Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
					Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
					Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
					Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+', idIntrare, idIntrareFirma
					)
				OUTPUT inserted.idPozDoc INTO #DFInserat(idPozDoc)
				VALUES (
					@Sb, @tip, @Numar, isnull(@Cod,''''), @Data, isnull(@GestPred,''''), isnull(@Cantitate,0), 0, @PretStoc, 0, 
					0, 0, 0, isnull(@CotaTVA,0), isnull(@Utilizator,''''), @dataoperarii,
					@oraoperarii, 
					isnull(@CodIntrare,''''), @CtStoc, isnull(@CtCoresp,''''), 0, 0, ''E'', 
					@LocatiePrim, @DataExp, @NrPozitie, isnull(@LM,''''), isnull(@Comanda,''''), isnull(@Barcod,''''), 
					@CtInterm, @CtVen, 0, '''', left(isnull(@Explicatii,''''), 8), isnull(@GestPrim,''''), '''', 
					@Stare, @CodIPrim, isnull(@CtFact,''''), '''', 0, @Data, @Data, @ProcSal, 0, 
					0, 0, substring(isnull(@Explicatii,''''), 9, 8), isnull(@Jurnal,''''),(case when @subtip=@tip then null else @subtip end)'
					+(case when @areDetalii=1 then ', @detalii' else '' end)+', @idIntrare, @idIntrareFirma)'

				exec sp_executesql @statement=@comandaSql, @params=N'
					@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @GestPred CHAR(9), @Cantitate FLOAT, 
					@PretStoc FLOAT, @CotaTVA FLOAT,@Utilizator VARCHAR(100), @CodIntrare CHAR(13), 
					@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@LocatiePrim char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
					@comanda char(40),@Barcod CHAR(30),@CtInterm VARCHAR(40), @CtVen VARCHAR(40),@Explicatii varchar(100),@GestPrim CHAR(9), @Stare int, 
					@CodIPrim varchar(100),@CtFact VARCHAR(40), @procSal FLOAT,@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100), @idIntrare int, @idIntrareFirma int',
					@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @GestPred=@GestPred , @Cantitate=@Cantitate , 
					@PretStoc=@PretStoc, @CotaTVA=@CotaTVA,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare , 
					@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@LocatiePrim =@LocatiePrim , @DataExp =@DataExp, @NrPozitie =@NrPozitie , 
					@LM =@LM ,@comanda =@comanda ,@Barcod =@Barcod ,@CtInterm =@CtInterm , @CtVen =@CtVen ,@Explicatii=@Explicatii ,@GestPrim =@GestPrim , 
					@Stare =@Stare ,@CodIPrim =@CodIPrim ,@CtFact =@CtFact , @procSal =@procSal ,@Jurnal =@Jurnal ,@subtip =@subtip,@dataoperarii=@dataoperarii,
					@oraoperarii=@oraoperarii, @idIntrare= @idIntrare, @idIntrareFirma = @idIntrareFirma 				
					
			SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #DFInserat
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
					(case when @Cod is null then '' else 'cod = @cod' end)+
					(case when @GestPred is null then '' else ',gestiune=@GestPred' end)+
					(case when @Cantitate is null then '' else ',Cantitate = convert(decimal(11,3),@Cantitate)' end)+
					(case when @PretStoc is null then '' else ',Pret_de_stoc=convert(decimal(11,5),@PretStoc)' end)+
					(case when @CotaTVA is null then '' else ',Cota_TVA=convert(decimal(11,5),@CotaTVA)' end)+
					',utilizator=@Utilizator'+
					',Data_operarii = @dataoperarii '+
					',ORA_operarii=@oraoperarii'+
					(case when @CodIntrare is null then '' else ',Cod_intrare=@CodIntrare' end) + 
					(case when @CtStoc is null then '' else ',Cont_de_stoc =@CtStoc' end)+
					(case when @CtCoresp is null then '' else ',Cont_corespondent=@CtCoresp' end)+
					(case when @LocatiePrim is null then '' else ',Locatie=@LocatiePrim' end)+
					(case when @DataExp is null then '' else ',Data_expirarii=@DataExp' end)+
					(case when @LM is null then '' else ',Loc_de_munca=@LM' end)+
					(case when @Comanda is null then '' else ',Comanda=@Comanda' end)+
					(case when @Barcod is null then '' else ',Barcod=@Barcod' end)+				
					(case when @CtInterm is null then '' else ',Cont_intermediar =@CtInterm' end)+
					(case when @CtVen is null then '' else ',Cont_venituri =@CtVen 'end)+
					(case when @Explicatii is null then '' else ',Factura =left(@Explicatii, 8)' end)+
					(case when @GestPrim is null then ''  else ',Gestiune_primitoare=@GestPrim' end)+
					(case when @Stare is null then '' else ',Stare=@Stare' end)+
					(case when @CodIPrim is null then '' else ',Grupa =@CodIPrim' end)+
					(case when @CtFact is null then '' else ',Cont_factura=@CtFact' end)+				
					(case when @ProcSal is null then  '' else ',Procent_vama=@ProcSal' end)+
					(case when @Explicatii is null then '' else ',Contract=substring(@Explicatii, 9, 8)' end)+
					(case when @Jurnal is null then '' else ',Jurnal =@Jurnal ' end) +					
					(CASE WHEN @areDetalii=1 THEN ', detalii = @detalii ' else '' end)+
					',idIntrare=@idIntrare' + 
					',idIntrareFirma=@idIntrareFirma' + '
				WHERE subunitate = @Sb
					AND tip = @tip
					AND numar = @Numar
					AND data = @Data
					AND numar_pozitie = @NrPozitie
			'
			exec sp_executesql @statement=@comandaSql, @params=N'
					@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @GestPred CHAR(9), @Cantitate FLOAT, 
					@PretStoc FLOAT, @CotaTVA FLOAT,@Utilizator VARCHAR(100), @CodIntrare CHAR(13), 
					@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@LocatiePrim char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
					@comanda char(40),@Barcod CHAR(30),@CtInterm VARCHAR(40), @CtVen VARCHAR(40),@Explicatii varchar(100),@GestPrim CHAR(9), @Stare int, 
					@CodIPrim varchar(100),@CtFact VARCHAR(40), @procSal FLOAT,@Jurnal char(3),@subtip varchar(2), @dataOperarii datetime, @oraoperarii varchar(100), @idIntrare int, @idIntrareFirma int',
					@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @GestPred=@GestPred , @Cantitate=@Cantitate , 
					@PretStoc=@PretStoc, @CotaTVA=@CotaTVA,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare , 
					@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@LocatiePrim =@LocatiePrim , @DataExp =@DataExp, @NrPozitie =@NrPozitie , 
					@LM =@LM ,@comanda =@comanda ,@Barcod =@Barcod ,@CtInterm =@CtInterm , @CtVen =@CtVen ,@Explicatii=@Explicatii ,@GestPrim =@GestPrim , 
					@Stare =@Stare ,@CodIPrim =@CodIPrim ,@CtFact =@CtFact , @procSal =@procSal ,@Jurnal =@Jurnal ,@subtip =@subtip, @dataoperarii=@dataoperarii,
					@oraoperarii=@oraoperarii, @idIntrare= @idIntrare, @idIntrareFirma = @idIntrareFirma
		end
		-----stop modificare pozitie existenta in pozdoc----
	
	---returnare parametri in @parXmlScriereIesiri ---
	-->numar_pozitie	
	if @parXmlScriereIesiri.value('(/row/@numar_pozitie)[1]','int') is null
		set @parXmlScriereIesiri.modify ('insert attribute numar_pozitie {sql:variable("@NrPozitie")} into (/row)[1]')
	else
		set @parXmlScriereIesiri.modify('replace value of (/row/@numar_pozitie)[1] with sql:variable("@NrPozitie")')
		
	-->cont_venituri	
	if @parXmlScriereIesiri.value('(/row/@cont_venituri)[1]','varchar(40)') is null
		set @parXmlScriereIesiri.modify ('insert attribute cont_venituri {sql:variable("@CtVen")} into (/row)[1]')
	else
		set @parXmlScriereIesiri.modify('replace value of (/row/@cont_venituri)[1] with sql:variable("@CtVen")')			
	---stop returnare parametrii in @parXmlScriereIesiri---	

	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))

end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
