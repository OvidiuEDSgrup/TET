--***
create procedure wScriuPP @parXmlScriereIntrari xml output

as
begin try
	declare @Numar varchar(20), @Data datetime , @Gestiune char(9), @Cod char(20), @Cantitate float, 
		@CtStoc varchar(40), @PretStoc float, @CodIntrare char(13) , @Locatie char(30), @Valuta char(3), @Curs float, 
		@LM char(9), @Comanda char(40), @Tert char(13), @AccCump float, @Suprataxe float, @DataExp datetime,
		@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @Lot char(13), @NrPozitie int,@update bit,
		@tip varchar(2),@subtip varchar(2),@mesaj varchar(200), @detalii xml, @docDetalii XML, @docInserate XML, @barcod char(30)
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIntrari
	
	select @Numar=isnull(numar,''),@Data=data,@Gestiune=gestiune,@Cod=cod,@Cantitate=cantitate,
		@CtStoc=cont_stoc,@PretStoc=pret_stoc,@CodIntrare=cod_intrare,@Locatie=ISNULL(locatie,''),
		@Valuta=valuta,@Curs=curs,@LM=lm,@Comanda=comanda_bugetari,@Tert=ISNULL(tert,''),
		@AccCump=accizecump,@Suprataxe=suprataxe,@Serie=isnull(serie,0),@Utilizator=ISNULL(utilizator,''),
		@Jurnal=jurnal,@Stare=stare,@Lot=lot,@NrPozitie=ISNULL(numar_pozitie,0),@update=ptupdate,
		@tip=tip,@subtip=subtip,@DataExp=data_expirarii, @detalii=detalii,@barcod=barcod
	
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		detalii xml 'detalii',
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
		cantitate decimal(17, 5) '@cantitate',	
		valuta varchar(3) '@valuta' , 
		curs varchar(14) '@curs',
		pret_stoc float '@pret_stoc',
		lm varchar(9) '@lm', 
		comanda_bugetari varchar(40) '@comanda_bugetari', 
		jurnal varchar(3) '@jurnal', 
		stare int '@stare',
		utilizator varchar(20) '@utilizator', 
		data_expirarii datetime '@data_expirarii',
		serie varchar(20) '@serie',
		numar_pozitie int '@numar_pozitie',
		accizecump float '@accizecump', 
		lot varchar(13) '@lot',
		cont_corespondent varchar(40) '@cont_corespondent',
		suprataxe float '@suprataxe', 
		barcod varchar(30) '@barcod',
		ptupdate int '@update'
		
	)
	set @Comanda=@parXmlScriereIntrari.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end
	declare @Sb char(9), @Cont711 varchar(40), @AnLM711 int, @AnCtSt711 int, @DVE int, 
		@RotPretV int, @SumaRotPret float, @StocComP int, 
		@TipNom char(1), @PStocNom float, @PValutaNom float, 
		@PretValuta float, @AnCtStoc varchar(40), @CtCoresp varchar(40), 
		@AccDat float, @StersPozitie int,@Serii int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output--obtinere subunitate
	exec luare_date_par 'GE', 'CONTP', @AnLM711 output, 0, @Cont711 output
	exec luare_date_par 'GE', 'ANCTSPRD', @AnCtSt711 output, 0, ''
	exec luare_date_par 'GE', 'DVE', @DVE output, 0, ''
	exec luare_date_par 'GE', 'ROTPRETV', @RotPretV output, @SumaRotPret output, ''
	exec luare_date_par 'GE', 'STOCPECOM', @StocComP output, 0, ''
	exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

	exec iauNrDataDoc 'PP', @Numar output, @Data output, 0
	if @Stare is null set @Stare=3

	set @TipNom=''
	set @PStocNom=0
	set @PValutaNom=0
	select @TipNom=tip, @PStocNom=pret_stoc, @PValutaNom=pret_in_valuta
	from nomencl
	where cod=@Cod

--daca primim valuta si cursul este diferit de 0, calculam pretul valuta din pret stoc
	if isnull(@PretValuta,0)=0 and ISNULL(@PretStoc,0)<>0 and isnull(@Curs,0)>0 and ISNULL(@valuta,'')<>''
		set @PretValuta=isnull(@PretStoc,0)/isnull(@Curs,0)
	else	
		set @PretValuta=(case when isnull(@Valuta,'')<>'' then @PValutaNom else 0 end)

	if isnull(@PretStoc, 0)=0
		begin
			set @PretStoc=(case when isnull(@Valuta,'')='' then @PStocNom else round(convert(decimal(18,5), @PretValuta*isnull(@Curs,0)), 5) end)
			if isnull(@Valuta,'')<>'' and @RotPretV=1 and abs(@SumaRotPret)>=0.00001 and exists (select 1 from sysobjects where type in ('FN', 'IF') and name='rot_pret') 
				set @PretStoc=dbo.rot_pret(isnull(@PretStoc,0), @SumaRotPret) 
		end

	if isnull(@CtStoc, '')=''
		set @CtStoc=dbo.formezContStoc(isnull(@Gestiune,''), isnull(@Cod,''), isnull(@LM,''))

	if left(@CtStoc, 1)='8'
		set @CtCoresp=''
	if @CtCoresp is null
		begin
			set @AnCtStoc=isnull((select max(case when cont_parinte<>'' then substring(@CtStoc, len(cont_parinte)+1, 13) else '' end) from conturi where subunitate=@Sb and cont=@CtStoc), '')
			set @CtCoresp=RTrim(@Cont711)+(case when @AnLM711=1 then '.'+isnull(@LM,'') when @AnCtSt711=1 and @TipNom='P' then @AnCtStoc else '' end)
		end
		
	if isnull(@DataExp,'01/01/1901')<='01/01/1901'
		set @DataExp=@Data	

	if isnull(@Utilizator,'')=''
		set @Utilizator=dbo.fIaUtilizator(null)--identificare utilizator

	----->>>>>>>start cod pentru adaugare pozitie noua in pozdoc<<<<<------
	if @update=0 and @subtip<>'SE'
	begin
	
		if isnull(@CodIntrare, '')=''--daca nu s-a introdus un cod de intrare, se genereaza din program 
			set @CodIntrare=dbo.formezCodIntrare('PP', @Numar, @Data, isnull(@Cod,''), isnull(@Gestiune,''), @CtStoc, isnull(@PretStoc,0))
		set @AccDat=(case when @DVE=1 then 100 else 0 end)
		
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''--alocare numar pozitie
		set @NrPozitie=@NrPozitie+1
		
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
			begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
				select @cod = (case when @Cod is null then '' else @cod end ),
						   @Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						   @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end)
				exec wScriuPDserii 'PP', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
				set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='PP' and Numar=@Numar and data=@Data and Gestiune=@gestiune and cod=@Cod 
															  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
			end
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------
		
		IF OBJECT_ID('tempdb..#PPInserat') IS NOT NULL
			DROP TABLE #PPInserat

		CREATE TABLE #PPInserat (idPozDoc INT)
		
		insert pozdoc
			(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
			Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
			Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
			Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
			Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
			Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
			Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip) 
		OUTPUT inserted.idPozDoc INTO #PPInserat(idPozDoc)
		values
			(@Sb, 'PP', @Numar, isnull(@Cod,''), @Data, isnull(@Gestiune,''), convert(decimal(11,3),isnull(@Cantitate,0)), convert(decimal(11,5),@PretValuta), convert(decimal(11,5),isnull(@PretStoc,0)), 0, 
			0, 0, 0, 0, isnull(@Utilizator,''), convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
			@CodIntrare, @CtStoc, @CtCoresp, 0, 0, 'I', 
			(case when @StocComP=1 then isnull(@Comanda,'') else @Locatie end), @DataExp, @NrPozitie, isnull(@LM,''), isnull(@Comanda,''), isnull(@barcod,''), 
			'', '', 0, @Tert, '', '', '', 
			@Stare, isnull(@Lot,''), '', isnull(@Valuta,''), isnull(@Curs,0), @Data, @Data, 1, 0, 
			0, @AccDat, '', isnull(@Jurnal,''),(case when @subtip=@tip then null else @subtip end))
	
		SET @docInserate = (
				SELECT idPozDoc idPozDoc
				FROM #PPInserat
				FOR XML raw, root('Inserate')
				)
		
		SET @docDetalii = (
		SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, 'PP' tip, isnull(@Gestiune,'') gestiune, @cod cod, @CodIntrare 
						codintrare,'pozdoc' as tabel, @detalii
			for xml raw
			)
		exec wScriuDetalii @parXML=@docDetalii
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc
	end
	-----stop adaugare pozitie noua in pozdoc-----

	-----start modificare pozitie existenta in pozdoc----
	if @update=1 or @subtip='SE'
	begin
		
		---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
			begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui
				select @cod = (case when @Cod is null then '' else @cod end ),
						   @Gestiune = (case when @Gestiune is null then '' else @Gestiune end),
						   @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end)
				exec wScriuPDserii 'PP', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
				set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='PP' and Numar=@Numar and data=@Data and Gestiune=@gestiune and cod=@Cod 
															  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii
			end
		
		if @subtip='SE'
			begin--daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc 
				update pozdoc set Cantitate=(case when @Cantitate is null then Cantitate else @Cantitate end)
				where subunitate=@Sb and tip='PP' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
			end			
		----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------	
		
		else	
		update pozdoc set 
				Cod=(case when @Cod is null then Cod else @cod end),
				Gestiune=(case when @Gestiune is null then Gestiune else @Gestiune end),
				Cantitate=(case when @Cantitate is null then  Cantitate else @Cantitate end),
				Pret_valuta=(case when @PretValuta is null then convert(decimal(11,5),Pret_valuta) else convert(decimal(11,5),@PretValuta) end),
				Pret_de_stoc=(case when @PretStoc is null then convert(decimal(11,5),Pret_de_stoc) else convert(decimal(11,5),@PretStoc) end),
				Utilizator=@Utilizator,
				Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),
				Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
				Cod_intrare=(case when @CodIntrare is null then Cod_intrare else @CodIntrare end),
				Cont_de_stoc=(case when @CtStoc is null then Cont_de_stoc else @CtStoc end),
				Cont_corespondent=(case when @CtCoresp is null then Cont_corespondent else @CtCoresp end),
				Data_expirarii=(case when @DataExp is null then Data_expirarii else @DataExp end),		
				Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),
				Comanda=(case when @Comanda is null then Comanda else @Comanda end),
				Barcod=(case when @Barcod is null then Barcod else @Barcod end),
				Stare=(case when @Stare is null then Stare else @Stare end),
				Grupa=(case when @Lot is null then Grupa else @Lot end),
				Valuta=(case when @Valuta is null then Valuta else @Valuta end),
				Curs=(case when @Curs is null then Curs else convert(decimal(11,3),@Curs) end),
				Suprataxe_vama=(case when @Suprataxe is null then Suprataxe_vama else convert(decimal(11,3),@Suprataxe) end),
				Accize_cumparare=(case when @AccCump is null then Accize_cumparare else convert(decimal(11,3),@AccCump) end),
				Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end)
					
		where subunitate=@Sb and tip='PP' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
		
		SET @docDetalii = (
		 SELECT @Sb subunitate, @NrPozitie numarpozitie, @Numar numar, @Data data, 'PP' tip, isnull(@Gestiune,'') gestiune, @cod cod, @CodIntrare 
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
begin catch end catch


