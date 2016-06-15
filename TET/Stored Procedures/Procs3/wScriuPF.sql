--***
create procedure wScriuPF @parXmlScriereIesiri xml output
	
as
begin try
	declare @Numar varchar(20) , @Data datetime , @GestPred char(9), @GestPrim char(13), @GestDest char(20),
		@Cod char(20), @CodIntrare char(13), @CodIPrim char(13) , @Cantitate float, 
		@LocatiePrim char(30), @LM char(9), @Comanda char(40), @Jurnal char(3), @Barcod char(30), @DataExp datetime, 
		@Stare int, @Utilizator char(10), @NrPozitie int ,@update bit,@subtip varchar(2),@mesaj varchar(200),@tip varchar(2),
		@CtCoresp varchar(40), @CtVen varchar(40), @CtInterm varchar(40), @CtStoc varchar(40), @docInserate XML, @comandaSql nvarchar(max), @detalii XML,
		@areDetalii bit,  @dataoperarii datetime, @oraoperarii varchar(50),  @iDoc int,	@Sb char(9), @Ct602 varchar(40), @AnLM602 int, @AnCtSt602 int, 
		@CtUzura varchar(40), @AnUzura int, @PStocNom float, @PretStoc float, @LocatieStoc char(30),@StersPozitie int
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri

	select 
		@Numar=isnull(numar,''),@Data=data,@GestPred=gestiune,@GestPrim=gestiune_primitoare,@GestDest=contract,
		@Cod=cod,@CodIntrare=cod_intrare,@CodIPrim=null,@Cantitate=cantitate,@LocatiePrim=locatie,
		@LM=lm,@Comanda=comanda_bugetari,	@Jurnal=jurnal,@Stare=stare,@Barcod=barcod,
		@Utilizator=ISNULL(utilizator,''),@DataExp=data_expirarii,@CtVen=cont_venituri,@CtInterm=cont_intermediar,
		@NrPozitie=ISNULL(numar_pozitie,0),@CtCoresp=cont_corespondent,@update=ptupdate,@tip=tip,@subtip=subtip,
		@CtStoc=cont_stoc, @detalii=detalii		

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
			cont_stoc varchar(40) '@cont_stoc',
			cont_corespondent varchar(40) '@cont_corespondent',
			cont_venituri varchar(40) '@cont_venituri',
			cont_intermediar varchar(40) '@cont_intermediar',
			gestiune_primitoare varchar(40) '@gestiune_primitoare',
			categ_pret varchar(30) '@categ_pret'	,	
			detalii XML 'detalii/row'
		)	
	set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!	
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'CONTCINV', @AnLM602 output, @AnCtSt602 output, @Ct602 output
	exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output

	exec iauNrDataDoc 'PF', @Numar output, @Data output, 0
	if isnull(@Stare,0)=0
		set @Stare=3

	set @PStocNom=0
	select @PStocNom=pret_stoc 
	from nomencl
	where cod=@Cod

	select @PretStoc=pret, @CtStoc=(case when isnull(@CtStoc,'')='' then cont else @CtStoc end), @LocatieStoc=locatie, @DataExp=(case when isnull(@DataExp, '01/01/1901')<='01/01/1901' then data_expirarii else @DataExp end)
	from stocuri
	where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@GestPred and cod=@Cod and cod_intrare=@CodIntrare

	--pret de stoc
	if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
	--cont de stoc
	if isnull(@CtStoc,'')='' set @CtStoc=dbo.formezContStocFol(isnull(@Cod,''))

	--cod intrare primitor
	--if isnull(@CodIPrim, '')=''
	--begin
	--	set @CodIPrim=@CodIntrare
	--	declare @pas int
	--	set @pas=0
	--	while @pas<702 
	--		and exists (select 1 from stocuri where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim
	--			and (abs(@PretStoc-pret)>=0.00001 or @CtCoresp is not null and cont<>@CtCoresp))
	--	begin
	--		set @pas=@pas+1
	--		set @CodIPrim=RTrim(left(isnull(@CodIntrare,''), (case when @pas<=26 then 12 else 11 end)))+RTrim((case when @pas>26 then CHAR(64+(@pas-1)/26) else '' end))+CHAR(64+(@pas-1)%26+1)
	--	end
	--end
	IF isnull(@CodIPrim, '') = ''
		-- mai jos, unde a fost trimis parametrul @Data am pus '1901-01-01' (in 2 locuri), pentru a verifica intreg stocul la primitor, nu doar cel cu data egala cu data documentului
		SET @CodIPrim = dbo.cautareCodIntrare(isnull(@Cod, ''), isnull(@GestPrim, ''), 'F', isnull(@CodIntrare, ''), 
				@PretStoc, 0, isnull(@CtCoresp, ''), 0, 0, '1901-01-01', '1901-01-01', '', '', '', '', '', '')

	--stoc la primitor
	select @CtCoresp=(case when isnull(@CtCoresp,'')='' then cont else @CtCoresp end), 
		@LocatiePrim=(case when isnull(@LocatiePrim, '')='' then locatie else @LocatiePrim end), @DataExp=(case when isnull(@DataExp, '01/01/1901')<='01/01/1901' then data_expirarii else @DataExp end)
	from stocuri
	where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim

	if isnull(@LocatiePrim, '')='' 
		set @LocatiePrim=isnull(@LocatieStoc, '')
	if isnull(@DataExp,'')=''
		set @DataExp=@Data

	--if @CtCoresp is null set @CtCoresp=dbo.formezContStocFol(@Cod)
	if isnull(@CtCoresp,'')='' set @CtCoresp=isnull(@CtStoc,'') 

	if isnull(@CtVen,'')='' set @CtVen=(case when 1=1 then '' else RTrim(@Ct602)+(case when @AnLM602=1 then '.'+RTrim(isnull(@LM,'')) else '' end)+(case when @AnCtSt602=1 then RTrim(substring(isnull(@CtStoc,''), 4, 9)) else '' end) end)
	if isnull(@CtInterm,'')=''  set @CtInterm=(case when 1=1 then '' else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(isnull(@CtStoc,'') , 4, 9)) else '' end) end)

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
			exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
			set @NrPozitie=@NrPozitie+1
			
			IF OBJECT_ID('tempdb..#PFInserat') IS NOT NULL
				DROP TABLE #PFInserat
			CREATE TABLE #PFInserat (idPozDoc INT)

			SET @comandaSql = N'
				INSERT pozdoc (
					Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
					Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
					Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
					Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
					Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
					Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+'
					)
				OUTPUT inserted.idPozDoc INTO #PFInserat(idPozDoc)
				VALUES (
				@Sb, @tip, @Numar, isnull(@Cod,''''), @Data, isnull(@GestPred,''''), isnull(@Cantitate,0), 0, @PretStoc, 0, 
				0, 0, 0, 0, isnull(@Utilizator,''''), @dataoperarii, @oraoperarii, 
				isnull(@CodIntrare,''''), isnull(@CtStoc,'''') , isnull(@CtCoresp,''''), 0, 0, ''E'', 
				isnull(@LocatiePrim,''''), @DataExp, @NrPozitie, isnull(@LM,''''), isnull(@Comanda,''''), isnull(@Barcod,''''), 
				isnull(@CtInterm,''''), isnull(@CtVen,''''), 0, '''', '''', isnull(@GestPrim,''''), '''', 
				@Stare, @CodIPrim, '''', '''', 0, @Data, @Data, 0, 0, 
				0, 0, isnull(@GestDest,''''), isnull(@Jurnal,''''),(case when @subtip=@tip then null else @subtip end)'
				+(case when @areDetalii=1 then ', @detalii' else '' end)+')'			
			
			exec sp_executesql @statement=@comandaSql, @params=N'
					@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @GestPred CHAR(9), @Cantitate FLOAT, 
					@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare varchar(20), 
					@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@LocatiePrim char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
					@comanda char(40),@Barcod CHAR(30),@CtInterm VARCHAR(40), @CtVen VARCHAR(40), @GestPrim CHAR(9), @Stare int, 
					@GestDest varchar(100),@CodIPrim varchar(100),@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
					@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @GestPred=@GestPred , @Cantitate=@Cantitate , 
					@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare , 
					@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@LocatiePrim =@LocatiePrim , @DataExp =@DataExp, @NrPozitie =@NrPozitie , 
					@LM =@LM ,@comanda =@comanda ,@Barcod =@Barcod ,@CtInterm =@CtInterm , @CtVen =@CtVen ,@GestPrim =@GestPrim ,@GestDest=@GestDest,
					@Stare =@Stare ,@CodIPrim =@CodIPrim ,@Jurnal =@Jurnal ,@subtip =@subtip,@dataoperarii=@dataoperarii,
					@oraoperarii=@oraoperarii
						
			exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
			
			SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #PFInserat
				FOR XML raw, root('Inserate')
				)
		end
	---stop adaugare pozitie noua in pozdoc-----
		
	-----start modificare pozitie existenta in pozdoc----
	if @update=1
		begin			
			SET @comandaSql = N'
				UPDATE pozdoc
				SET '+		
					(case when @Cod is null then '' else 'Cod= @cod' end)+
					(case when @GestPred is null then '' else ',Gestiune=@GestPred' end)+
					(case when @Cantitate is null then '' else ',Cantitate=convert(decimal(11,3),@Cantitate)' end)+
					(case when @PretStoc is null then ''  else ',Pret_de_stoc=convert(decimal(11,5),@PretStoc)' end)+
					',utilizator=@Utilizator'+
					',data_operarii = @dataoperarii'+
					',ora_operarii=@oraoperarii'+
					(case when @CodIntrare is null then '' else ',Cod_intrare=@CodIntrare' end)+
					(case when @CtStoc is null then '' else ',Cont_de_stoc=@CtStoc' end)+
					(case when @CtCoresp is null then '' else ',Cont_corespondent =@CtCoresp' end)+
					(case when @LocatiePrim is null then '' else ',Locatie=@LocatiePrim' end)+
					(case when @DataExp is null then '' else ',Data_expirarii =@DataExp' end)+
					(case when @LM is null then '' else ',Loc_de_munca=@LM' end)+
					(case when @Comanda is null then '' else ',Comanda =@Comanda' end)+
					(case when @Barcod is null then '' else ',Barcod=@Barcod' end)+				
					(case when @CtInterm is null then '' else ',Cont_intermediar =@CtInterm' end)+
					(case when @CtVen is null then '' else ',Cont_venituri=@CtVen' end) +
					(case when @GestPrim is null then '' else ',Gestiune_primitoare =@GestPrim' end)+
					(case when @Stare is null then '' else ',Stare =@Stare ' end)+
					(case when @CodIPrim is null then '' else ',Grupa=@CodIPrim ' end)+
					(case when @GestDest is null then '' else ',Contract =@GestDest' end)+
					(case when @Jurnal is null then '' else ',Jurnal=@Jurnal' end)+					
					(CASE WHEN @areDetalii=1 THEN ', detalii = @detalii ' else '' end)+

				'WHERE subunitate = @Sb
						AND tip = @tip
						AND numar = @Numar
						AND data = @Data
						AND numar_pozitie = @NrPozitie
				'
				exec sp_executesql @statement=@comandaSql, @params=N'
					@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @GestPred CHAR(9), @Cantitate FLOAT, 
					@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare CHAR(13), 
					@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@LocatiePrim char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
					@comanda char(40),@Barcod CHAR(30),@CtInterm VARCHAR(40), @CtVen VARCHAR(40), @GestPrim CHAR(9), @Stare int, 
					@GestDest varchar(100),@CodIPrim varchar(100),@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
					@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @GestPred=@GestPred , @Cantitate=@Cantitate , 
					@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare , 
					@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@LocatiePrim =@LocatiePrim , @DataExp =@DataExp, @NrPozitie =@NrPozitie , 
					@LM =@LM ,@comanda =@comanda ,@Barcod =@Barcod ,@CtInterm =@CtInterm , @CtVen =@CtVen ,@GestPrim =@GestPrim ,@GestDest=@GestDest,
					@Stare =@Stare ,@CodIPrim =@CodIPrim ,@Jurnal =@Jurnal ,@subtip =@subtip,@dataoperarii=@dataoperarii,
					@oraoperarii=@oraoperarii
		end
		-----stop modificare pozitie existenta in pozdoc----
	
	IF @docInserate IS NULL
		SET @docInserate = ''

	SET @parXmlScriereIesiri = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIesiri) + convert(VARCHAR(max), @docInserate))
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuPF)'
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
