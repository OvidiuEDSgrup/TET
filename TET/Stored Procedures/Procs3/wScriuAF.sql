--***
create procedure wScriuAF @parXmlScriereIntrari xml
as
begin try
	declare
		@Numar varchar(20), @Data datetime, @Gestiune char(9), @Cod char(20), @Cantitate float,	@CodIntrare char(13), @CtStoc varchar(40), @PretStoc float,
		@CtCoresp varchar(40), @CtInterm varchar(40), @Locatie char(30), @LM char(9), @Comanda char(40), @Explicatii varchar(50), @Jurnal char(3), @DataExp datetime, 
		@Stare int, @Utilizator char(10), @NrPozitie int,@update bit,@tip varchar(2),@subtip varchar(2),@mesaj varchar(200), @iDoc int,
		@Sb char(9), @CtUzura varchar(40), @AnUzura int, @PStocNom float, @StersPozitie int,@docInserate xml,
		@comandaSql nvarchar(max), @detalii XML,@areDetalii bit,  @dataoperarii datetime, @oraoperarii varchar(50)
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIntrari
	
	select 
		@Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod,@Cantitate=cantitate,
		@CodIntrare=cod_intrare,@CtStoc=cont_stoc,@PretStoc=pret_stoc,@CtCoresp=cont_corespondent,
		@CtInterm=cont_intermediar,@Locatie=locatie,@LM=lm,@Comanda=comanda_bugetari, @Explicatii=explicatii,@Jurnal=jurnal,
		@DataExp=data_expirarii,@Stare=stare,@Utilizator=ISNULL(utilizator,''),@NrPozitie=ISNULL(numar_pozitie,0),@update=ptupdate,
		@tip=tip,@subtip=subtip, @detalii=detalii	
	
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip', 
		numar varchar(20) '@numar',
		data datetime '@data',
		tert varchar(13) '@tert',
		gestiune varchar(9) '@gestiune',
		cod varchar(20) '@cod',
		cod_intrare varchar(20) '@cod_intrare',
		cont_stoc varchar(40) '@cont_stoc', 	
		locatie varchar(30) '@locatie', 
		cantitate decimal(10, 3) '@cantitate',	
		valuta varchar(3) '@valuta' , 
		curs varchar(14) '@curs',
		pret_stoc float '@pret_stoc',
		lm varchar(9) '@lm', 
		comanda_bugetari char(40) '@comanda_bugetari', 
		explicatii varchar(50) '@explicatii',
		jurnal varchar(3) '@jurnal', 
		stare int '@stare',
		data_expirarii datetime '@data_expirarii',
		utilizator varchar(20) '@utilizator', 
		serie varchar(20) '@serie',
		numar_pozitie int '@numar_pozitie',
		accizecump float '@accizecump', 
		lot varchar(13) '@lot',
		cont_corespondent varchar(40) '@cont_corespondent',
		cont_intermediar varchar(40) '@cont_intermediar',
		suprataxe float '@suprataxe', 
		ptupdate int '@update',
		detalii XML 'detalii/row'	
	)
	set @Comanda=@parXmlScriereIntrari.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output

	exec iauNrDataDoc 'AF', @Numar output, @Data output, 0
	if @Stare is null set @Stare=3

	set @PStocNom=0
	select @PStocNom=pret_stoc 
	from nomencl
	where cod=isnull(@Cod,'')

	if isnull(@PretStoc, 0)=0
		set @PretStoc=isnull(@PStocNom, 0)
	if isnull(@CtStoc,'')='' 
		set @CtStoc=dbo.formezContStocFol(isnull(@Cod,''))

	if isnull(@Locatie,'')=''
		set @Locatie=''
	if @DataExp is null
		set @DataExp=@Data

	if isnull(@CtCoresp, '')=''
		set @CtCoresp=(case when left(@CtStoc, 1)='8' then '' else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
	if isnull(@CtInterm, '')=''
		set @CtInterm=''

	if isnull(@Utilizator,'')='' 
		set @Utilizator=dbo.fIaUtilizator(null)

	
	IF EXISTS (SELECT * FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
		set @areDetalii = 1

	select 			
		@dataOperarii = convert(DATETIME, convert(CHAR(10), getdate(), 104), 104),
		@oraOperarii = RTrim(replace(convert(CHAR(8), getdate(), 108), ':', ''))
	
	if @update=0 --adaugare pozitie noua in pozdoc
		begin
			if isnull(@CodIntrare, '')=''--daca nu a fost introdus cod de intrare se genereaza din program
				set @CodIntrare=dbo.formezCodIntrare('AF', @Numar, @Data, isnull(@Cod,''), isnull(@Gestiune,''), @CtStoc, isnull(@PretStoc,0))
	
			exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--se aloca numar de pozitie pentru pozdoc
			set @NrPozitie=@NrPozitie+1
			IF OBJECT_ID('tempdb..#AFInserat') IS NOT NULL
				DROP TABLE #AFInserat
			CREATE TABLE #AFInserat (idPozDoc INT)

			SET @comandaSql = N'
				INSERT pozdoc (
					Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, 
					Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
					Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, 
					Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
					Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, 
					Accize_datorate, Contract, Jurnal,subtip'+(case when @areDetalii=1 then ', detalii' else '' end)+'
					)
				OUTPUT inserted.idPozDoc INTO #AFInserat(idPozDoc) 
				VALUES (
					@Sb, @tip, @Numar, isnull(@Cod,''''), @Data, isnull(@Gestiune,''''), isnull(@Cantitate,0), 0, isnull(@PretStoc,0), 0, 
					0, 0, 0, 0, isnull(@Utilizator,''''), @dataoperarii, @oraoperarii, 
					isnull(@CodIntrare,''''), @CtStoc, @CtCoresp, 0, 0, ''I'', 
					@Locatie, @DataExp, @NrPozitie, isnull(@LM,''''), isnull(@Comanda,''''), '''', 
					@CtInterm, '''', 0, '''', left(isnull(@Explicatii,''''), 8), '''', '''', 
					@Stare, '''', '''', '''', 0, @Data, @Data, 0, 0, 
					0, 0, '''', isnull(@Jurnal,''''),(case when @subtip=@tip then null else @subtip end)'
					+(case when @areDetalii=1 then ', @detalii' else '' end)+')'	

				exec sp_executesql @statement=@comandaSql, @params=N'
					@detalii xml, @Sb VARCHAR(10), @tip CHAR(2), @Numar VARCHAR(20), @Cod CHAR(20),@Data DATETIME, @Gestiune CHAR(9), @Cantitate FLOAT, 
					@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare CHAR(13), @Explicatii varchar(50),
					@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@Locatie char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
					@comanda char(40),@CtInterm VARCHAR(40), @Stare int,@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
					@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @Gestiune=@Gestiune, @Cantitate=@Cantitate , 
					@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare ,@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@Locatie =@Locatie, 
					@DataExp =@DataExp, @NrPozitie =@NrPozitie,@LM =@LM ,@comanda =@comanda,@CtInterm =@CtInterm ,@Stare =@Stare,@Jurnal =@Jurnal ,
					@subtip =@subtip,@dataoperarii=@dataoperarii,@oraoperarii=@oraoperarii, @Explicatii =@Explicatii
				
				
				SET @docInserate = (
					SELECT idPozDoc idPozDoc
					FROM #AFInserat
					FOR XML raw, root('Inserate')
				)	
			exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--se seteaza ultimul nr de pozitie pentru pozdoc utilizat
		end

	if @update=1 --modificare pozitie existenta in pozdoc
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
					(case when @DataExp is null then '' else ',Data_expirarii=@DataExp' end)+		
					(case when @LM is null then '' else ',Loc_de_munca = @LM 'end)+				
					(case when @Comanda is null then '' else ',Comanda=@Comanda' end)+
					(case when @CtInterm is null then '' else ',Cont_intermediar =@CtInterm' end)+
					(case when @Explicatii is null then '' else ',factura=left(@Explicatii, 8)' end)+
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
				@PretStoc FLOAT, @Utilizator VARCHAR(100), @CodIntrare CHAR(13), @Explicatii varchar(50),
				@CtStoc VARCHAR(40), @CtCoresp VARCHAR(40),@Locatie char(30), @DataExp datetime, @NrPozitie int, @LM char(9),
				@comanda char(40),@CtInterm VARCHAR(40), @Stare int,@Jurnal char(3),@subtip varchar(2),@dataOperarii datetime, @oraoperarii varchar(100)',
				@detalii = @detalii, @Sb =@Sb, @tip =@tip, @Numar =@Numar, @Cod =@Cod,@Data =@Data , @Gestiune=@Gestiune, @Cantitate=@Cantitate , 
				@PretStoc=@PretStoc,@Utilizator=@Utilizator, @CodIntrare=@CodIntrare ,@CtStoc=@CtStoc , @CtCoresp =@CtCoresp ,@Locatie =@Locatie, 
				@DataExp =@DataExp, @NrPozitie =@NrPozitie,@LM =@LM ,@comanda =@comanda,@CtInterm =@CtInterm ,@Stare =@Stare,@Jurnal =@Jurnal ,
				@subtip =@subtip,@dataoperarii=@dataoperarii,@oraoperarii=@oraoperarii, @Explicatii =@Explicatii
		end
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIntrari = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIntrari) + convert(VARCHAR(max), @docInserate))	

end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
