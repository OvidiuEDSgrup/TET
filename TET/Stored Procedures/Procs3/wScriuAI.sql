--***
create procedure wScriuAI @parXmlScriereIntrari xml output
as
	begin try
	declare @Numar varchar(20) , @Data datetime , @Gestiune char(9), @Cod char(20), @Cantitate float, @barcod char(20), 
		@CodIntrare char(13), @CtStoc varchar(40), @CtCoresp varchar(40), @PretStoc float, @Valuta char(3), @Curs float, 
		@PretAm float, @CotaTVA float, @Tert char(13), @Locatie char(30), @LM char(9), @Comanda char(40), @Explicatii char(16), 
		@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @DataExp datetime, @NrPozitie int, @PozitieNoua int, 
		@Furnizor char(13), @TVAnx float, @Lot char(13), @CantUM2 float,@update bit,@tip varchar(2),@subtip varchar(2),@mesaj varchar(200),
		@detalii xml, @docDetalii XML, @docInserate xml
	
	set @NrPozitie =0
	set @PozitieNoua =0
	set @Furnizor =''
	set  @Lot =''
	set @CantUM2 =0
	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIntrari
		
	select @Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod, @Cantitate=cantitate,@barcod=barcod,
		@CodIntrare=cod_intrare,@CtStoc=cont_stoc,@CtCoresp=cont_corespondent,@PretStoc=pret_stoc,
		@Valuta=valuta,@Curs=curs,@PretAm=pret_amanunt,@CotaTVA=cota_TVA,@Tert=ISNULL(tert,''),@Locatie=ISNULL(locatie,''),
		@LM=lm,@Comanda=comanda_bugetari,@Explicatii=explicatii,@Serie=isnull(serie,0),@Utilizator=ISNULL(utilizator,''),
		@Jurnal=jurnal,@Stare=stare,@DataExp=data_expirarii,@NrPozitie=ISNULL(numar_pozitie,0),@Lot=lot,
		@update=isnull(ptupdate,0),@tip=tip,@subtip=subtip,@detalii = detalii		
	
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		detalii xml 'detalii',
		tip char(2) '@tip', 
		subtip char(2) '@subtip', 
		numar varchar(20) '@numar',
		data datetime '@data',
		tert char(13) '@tert',
		gestiune char(9) '@gestiune',
		cod char(20) '@cod',
		cod_intrare char(20) '@cod_intrare',
		cont_stoc varchar(40) '@cont_stoc', 	
		locatie char(30) '@locatie', 
		cantitate float '@cantitate',	
		barcod char(20) '@barcod',
		valuta varchar(3) '@valuta' , 
		curs varchar(14) '@curs',
		pret_amanunt float '@pret_amanunt', 
		pret_stoc float '@pret_stoc',
		lm char(9) '@lm', 
		comanda_bugetari char(40) '@comanda_bugetari', 
		jurnal char(3) '@jurnal', 
		stare int '@stare',
		data_expirarii datetime '@data_expirarii',
		utilizator char(20) '@utilizator', 
		serie char(20) '@serie',
		cota_TVA float '@cota_TVA',
		numar_pozitie int '@numar_pozitie',
		accizecump float '@accizecump', 
		lot char(13) '@lot',
		cont_corespondent varchar(40) '@cont_corespondent',
		suprataxe float '@suprataxe', 
		ptupdate int '@update',
		explicatii varchar(30) '@explicatii'		
	)
	set @Comanda=@parXmlScriereIntrari.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end
	
	declare @Sb char(9), @RotPretV int, @SumaRotPret float, @Ct378 varchar(40), @AnGest378 int, @AnGr378 int, 
		@Ct4428 varchar(40), @AnGest4428 int, @CtCorespAI varchar(40), @CuCtIntermAI int, @CtIntermAI varchar(40), 
		@CtIntermTEVal varchar(40), @Cust35 int, @Cust8 int, @StocComP int, 
		@TipNom char(1), @PStocNom float, @PValutaNom float, @CotaTVANom float, @PretAmNom float, @GrNom char(13), 
		@PretValuta float, @SumaTVA float, @CtAdaosPrim varchar(40), @CtTVAnxPrim varchar(40), 
		@TipMiscare char(1), @CtInterm varchar(40), @StersPozitie int,@Serii int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'ROTPRETV', @RotPretV output, @SumaRotPret output, ''
	exec luare_date_par 'GE', 'CADAOS', @AnGest378 output, @AnGr378 output, @Ct378 output
	exec luare_date_par 'GE', 'CNTVA', @AnGest4428 output, 0, @Ct4428 output
	exec luare_date_par 'GE', 'CCORAI', 0, 0, @CtCorespAI output
	exec luare_date_par 'GE', 'CONT_AI?', @CuCtIntermAI output, 0, ''
	exec luare_date_par 'GE', 'CONT_AI', 0, 0, @CtIntermAI output
	exec luare_date_par 'GE', 'CALTE', 0, 0, @CtIntermTEVal output
	exec luare_date_par 'GE', 'STCUST35', @Cust35 output, 0, ''
	exec luare_date_par 'GE', 'STCUST8', @Cust8 output, 0, ''
	exec luare_date_par 'GE', 'STOCPECOM', @StocComP output, 0, ''
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

	exec iauNrDataDoc 'AI', @Numar output, @Data output, 0
	if @Stare is null set @Stare=3

	set @TipNom=''
	set @PStocNom=0
	set @PValutaNom=0
	set @CotaTVANom=0
	set @PretAmNom=0
	set @GrNom=''

	select @TipNom=tip, @PStocNom=pret_stoc, @PValutaNom=pret_in_valuta, @CotaTVANom=cota_TVA, 
		@PretAmNom=pret_cu_amanuntul, @GrNom=grupa
	from nomencl
	where cod=isnull(@Cod,'')

--daca primim valuta si cursul este diferit de 0, calculam pretul valuta din pret stoc
	if isnull(@PretValuta,0)=0 and ISNULL(@PretStoc,0)<>0 and isnull(@Curs,0)>0 and ISNULL(@valuta,'')<>''
		set @PretValuta=isnull(@PretStoc,0)/isnull(@Curs,0)
	else	
		set @PretValuta=(case when isnull(@Valuta,'')<>'' then @PValutaNom else 0 end)

	if isnull(@PretStoc, 0)=0
	begin
		set @PretStoc=(case when isnull(@Valuta,'')='' then @PStocNom else round(convert(decimal(18,5), @PretValuta*isnull(@Curs,0)), 5) end)
		if isnull(@Valuta,'')<>'' and @RotPretV=1 and abs(@SumaRotPret)>=0.00001 and exists (select 1 from sysobjects where type in ('FN', 'IF') and name='rot_pret') 
			set @PretStoc=dbo.rot_pret(@PretStoc, @SumaRotPret) 
	end

	if isnull(@PretAm, 0)=0
		set @PretAm=@PretAmNom
	set @TVAnx=isnull(@TVAnx, @CotaTVANom)
	set @SumaTVA=round(convert(decimal(17,4), @PretStoc*isnull(@Cantitate,0)*isnull(@CotaTVA,0)/100), 2)
	set @TipMiscare=(case when @TipNom in ('F','R', 'S') then 'V' else 'I' end)
	
	if isnull(@CtStoc, '')=''
		set @CtStoc=dbo.formezContStoc(isnull(@Gestiune,''), isnull(@Cod,''), isnull(@LM,''))

	set @CtTVAnxPrim=(case when @TipNom='F' then '' else RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end) end)
	set @CtAdaosPrim=(case when @TipNom='F' then '' else RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@Gestiune,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end) end)

	if isnull(@CtCoresp, '')=''
		set @CtCoresp=(case when @CtCorespAI<>'' then @CtCorespAI when @CuCtIntermAI=1 then @CtIntermAI when @CtIntermTEVal<>'' then RTrim(@CtIntermTEVal)+(case when left(@CtIntermTEVal, 3)='482' then '.'+isnull(@Gestiune,'') else '' end) when left(isnull(@CtStoc,''), 1)='8' then ''  else '7588' end)
	set @CtInterm=(case when abs(@SumaTVA)<0.01 then '' when @CuCtIntermAI=1 then @CtIntermAI else @CtTVAnxPrim end)

	if @Tert is null or isnull(@Tert, '')<>'' and not (@Cust35=1 and left(isnull(@CtCoresp,''), 2)='35' or @Cust8=1 and left(isnull(@CtCoresp,''), 1)='8' or @TipNom='F')
		set @Tert=''
	
	-- de aici
	declare @binar varbinary(128)
	set @binar=cast('modificarescriuintrare' as varbinary(128))
	--set CONTEXT_INFO @binar

	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)

	---start adaugare pozitie noua in pozdoc-----
	if @update=0 and @subtip<>'SE'
		begin
			if isnull(@CodIntrare, '')=''--daca nu s-a introdus un cod de intrare, se genereaza din program
				set @CodIntrare=dbo.formezCodIntrare('AI', @Numar, @Data, isnull(@Cod,''), isnull(@Gestiune,''), isnull(@CtStoc,''), isnull(@PretStoc,0))
			if isnull(@DataExp, '01/01/1901')<='01/01/1901'
				set @DataExp=@Data
		
			exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
			set @NrPozitie=@NrPozitie+1
		
			---->>>>>>>>start cod specific lucrului pe serii<<<<<<----------------
			if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
				begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
					select @cod = (case when @Cod is null then '' else @cod end ),
						   @Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						   @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
						   @CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
					exec wScriuPDserii 'AI', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
					set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='AI' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
																  and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
				end
			----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
			IF OBJECT_ID('tempdb..#AIInserat') IS NOT NULL
			DROP TABLE #AIInserat

			CREATE TABLE #AIInserat (idPozDoc INT)
		
			insert pozdoc
				(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
				Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, 
				Ora_operarii, Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
				Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
				Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
				Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
				Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip) 
			OUTPUT inserted.idPozDoc INTO #AIInserat(idPozDoc)
			values
				(@Sb, 'AI', @Numar, isnull(@Cod,''), @Data, isnull(@Gestiune,''), isnull(@Cantitate,0), @PretValuta, isnull(@PretStoc,0), 0, 
				0, @PretAm, @SumaTVA, isnull(@CotaTVA,0), isnull(@Utilizator,''), convert(datetime, convert(char(10), getdate(), 104), 104),
				RTrim(replace(convert(char(8), getdate(), 108), ':', '')), isnull(@CodIntrare,''), isnull(@CtStoc,''), isnull(@CtCoresp,''), @TVAnx, 0, @TipMiscare, 
				(case when @StocComP=1 then isnull(@Comanda,'') else @Locatie end), @DataExp, @NrPozitie, isnull(@LM,''), isnull(@Comanda,''), isnull(@barcod,''), 
				@CtInterm, @Furnizor, 0, @Tert, left(isnull(@Explicatii,''), 8), @CtAdaosPrim, '', 
				@Stare, isnull(@Lot,''), @CtTVAnxPrim, isnull(@Valuta,''), isnull(@Curs,0), @Data, @Data, 0, 0, 
				0, 0, substring(isnull(@Explicatii,''), 9, 8), isnull(@Jurnal,''),(case when @subtip=@tip then null else @subtip end))
		
			exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
		
			SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #AIInserat
				FOR XML raw, root('Inserate')
				)	
		
			SET @docDetalii = (
				SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, 'pozdoc' as tabel, @detalii
				for xml raw
				)
			exec wScriuDetalii @parXML=@docDetalii
		
		end
		-----stop adaugare pozitie noua in pozdoc-----
		
	-----start modificare pozitie existenta in pozdoc----
	if @update=1 or @subtip='SE'--cod pentru modificare pozitie pozdoc/adaugare pozitie de serie pe subtip SE
		begin
			---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
			if isnull((select max(left(UM_2, 1)) from nomencl where cod=isnull(@Cod,'')), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
				begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
					select @cod = (case when @Cod is null then '' else @cod end ),
						   @Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						   @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),
						   @CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end)
					exec wScriuPDserii 'AI', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
					set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='AI' and Numar=@Numar and data=@Data and Gestiune=isnull(@Gestiune,'') and cod=isnull(@Cod,'') 
																  and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
				end
			
			if @subtip='SE'--daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
				begin
					update pozdoc set Cantitate=(case when @Cantitate is null then Cantitate else @Cantitate end)
					where subunitate=@Sb and tip='AI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
				end				
			----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
			
			else	
			update pozdoc set 
					Cod=(case when @Cod is null then Cod else @cod end),
					Gestiune=(case when @Gestiune is null then Gestiune else @Gestiune end),
					Cantitate=(case when @Cantitate is null then Cantitate else convert(decimal(11,3),@Cantitate) end),
					Pret_valuta=(case when @PretValuta is null then convert(decimal(11,5),Pret_valuta) else convert(decimal(11,5),@PretValuta) end),
					Pret_de_stoc=(case when @PretStoc is null then convert(decimal(11,5),Pret_de_stoc) else convert(decimal(11,5),@PretStoc) end),
					Pret_cu_amanuntul=(case when @PretAm is null then convert(decimal(11,5),Pret_cu_amanuntul) else convert(decimal(11,5),@PretAm) end),
					TVA_deductibil=(case when @SumaTVA is null then convert(decimal(11,5),TVA_deductibil) else convert(decimal(11,5),@SumaTVA) end),
					Cota_TVA=(case when @CotaTVA is null then convert(decimal(11,5),Cota_TVA) else convert(decimal(11,5),@CotaTVA) end),
					Utilizator=@Utilizator,
					Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
					Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
					Cod_intrare=(case when @CodIntrare is null then Cod_intrare else @CodIntrare end),
					Cont_de_stoc=(case when @CtStoc is null then Cont_de_stoc else @CtStoc end),
					Cont_corespondent=(case when @CtCoresp is null then Cont_corespondent else @CtCoresp end),
					TVA_neexigibil=(case when @TVAnx is null then convert(decimal(11,5),TVA_neexigibil) else convert(decimal(11,5),@TVAnx) end),
					Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),
					Data_expirarii=(case when @DataExp is null then Data_expirarii else @DataExp end),
					Comanda=(case when @Comanda is null then Comanda else @Comanda end),
					barcod=(case when @barcod is null then barcod else @barcod end),
					Cont_intermediar=(case when @CtInterm is null then @CtInterm else @CtInterm end),
					Stare=(case when @Stare is null then Stare else @Stare end),
					Grupa=(case when @Lot is null then Grupa else @Lot end),
					Factura=(case when @Explicatii is null then Factura else left(@Explicatii, 8) end),
					Gestiune_primitoare=(case when @CtAdaosPrim is null then Gestiune_primitoare else @CtAdaosPrim end),
					Cont_factura=(case when @CtTVAnxPrim is null then Cont_factura else @CtTVAnxPrim end),
					Valuta=(case when @Valuta is null then Valuta else @Valuta end),
					Curs=(case when @Curs is null then Curs else convert(decimal(11,3),@Curs) end),
					--Accize_cumparare=(case when @TipNom='F' then 0 else isnull(@Cantitate,0) end),
					Contract=(case when @Explicatii is null then Contract else substring(@Explicatii, 9, 8) end),
					Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end)					
			where subunitate=@Sb and tip='AI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
			
			SET @docDetalii = (
				SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, @Tip tip, @Gestiune gestiune, @cod cod, @CodIntrare 
					codintrare,'pozdoc' as tabel, @detalii
				for xml raw
				)
			exec wScriuDetalii @parXML=@docDetalii
		end
	-----stop modificare pozitie existenta in pozdoc----
	
	-->returnare idPozDoc
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlScriereIntrari = CONVERT(XML, convert(VARCHAR(max), @parXmlScriereIntrari) + convert(VARCHAR(max), @docInserate))	
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch 
end catch


