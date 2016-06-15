--***
create procedure wscriuAD @parXmlpozadoc xml output
as 
begin try
	declare @Numar char(8), @Data datetime, @Tip char(2), 
		@Tert varchar(13), @FacturaStanga varchar(20), @ContDeb varchar(40), @FacturaDreapta varchar(20), @ContCred varchar(40), 
		@Suma float, @Valuta char(3), @Curs float, @Suma_valuta float, @update bit, @subtip varchar(2), @mesaj varchar(200),
		@TVA11 float, @TVA22 float, @Explicatii varchar(50), @Numar_pozitie int, @o_DifTVA float,@o_TVA22 float,
		@TertBenef varchar(13), @LM varchar(9), @Comanda varchar(40), @Utilizator varchar(10), @Jurnal char(3), 
		@DataFact datetime, @DataScad datetime, @SumaDif float, @ContDif varchar(40), @AchitFact float, @DifTVA float, @Stare int,
		@tiptva int, @docInserate XML

	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlpozadoc
	
	select @Numar=isnull(numar,''),@Data=data,@Suma=suma,@Tert=tert,@FacturaStanga=factura_stanga,
		@ContDeb=cont_deb,@FacturaDreapta=factura_dreapta,@ContCred=cont_cred,
		@Valuta=valuta,@Curs=curs,@LM=lm,@Comanda=comanda_bugetari,@TertBenef=tert_benef,
		@Suma_valuta=suma_valuta,@TVA11=cota_TVA,@TVA22=suma_tva,@o_TVA22=o_suma_tva,@Explicatii=explicatii,
		@Utilizator=ISNULL(utilizator,''),@Numar_pozitie=ISNULL(numar_pozitie,0),@Jurnal=jurnal,
		@DataFact=data_Facturii,@DataScad=data_scadentei,@update=ptupdate,@tip=tip,@subtip=subtip,
		@Stare=null,@SumaDif=sumadifcurs, @ContDif=contdifcurs, @AchitFact=achitfact,@DifTVA=diftva,
		@o_DifTVA=o_diftva,@tiptva=tiptva
	
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip', 
		numar varchar(8) '@numar',
		data datetime '@data',
		tert varchar(13) '@tert',
		factura_stanga varchar(20) '@factura_stinga',
		ext_datadocument datetime '@ext_datadocument',
		factura_dreapta varchar(20) '@factura_dreapta',
		cont_deb varchar(40) '@cont_deb',	
		data_facturii datetime '@data_facturii',
		data_scadentei datetime '@data_scadentei',
		cont_cred varchar(40) '@cont_cred',		
		suma float '@suma',	
		tert_benef varchar(13) '@tert_benef',
		valuta varchar(3) '@valuta' , 
		curs varchar(14) '@curs',
		suma_valuta float '@suma_valuta',	
		cota_TVA float '@cota_TVA',
		suma_tva float '@suma_tva',
		o_suma_tva float '@o_suma_tva',
		explicatii varchar(40) '@explicatii', 
		comanda_bugetari varchar(40) '@comanda_bugetari', 
		lm varchar(9) '@lm', 
		utilizator varchar(20) '@utilizator',
		numar_pozitie int '@numar_pozitie', 
		jurnal varchar(3) '@jurnal', 
		ptupdate bit '@update',
		diftva float '@diftva',
		o_diftva float '@o_diftva',	
		sumadifcurs float '@sumadifcurs',
		contdifcurs varchar(40) '@contdifcurs', 
		achitfact float '@achitfact',
		tiptva int '@tiptva'
	)
	set @Comanda=@parXmlpozadoc.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end
	
	if abs(isnull(@Suma,0))<0.01 and abs(isnull(@Suma_valuta,0))<0.01 and abs(isnull(@TVA22,0))<0.001
		return --Mircea: cre' ca ar tb. scos acest return pt. ca la tip TVA 3 se poate ca suma si suma_valuta sa fie nule!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	declare @Sb char(9), @CuDifCurs int, @CtCheltDifcF varchar(40), @CtVenDifcF varchar(40), @CtCheltDifcB varchar(40), @CtVenDifcB varchar(40), 
		@TipFactSt char(1), @TipFactDr char(1), @TertFactDr char(13), @DenTert char(80),@CudifTVAsif int
    
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'DIFINR', @CuDifCurs output, 0, ''
	exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output
	exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output
	exec luare_date_par 'GE', 'DIFCHB', 0, 0, @CtCheltDifcB output
	exec luare_date_par 'GE', 'DIFVEB', 0, 0, @CtVenDifcB output
	exec luare_date_par 'GE', 'DIFTVASIF', @CudifTVAsif output, 0, ''
    
    --tratare loc de munca, daca nu este introdus pe macheta
	if ISNULL(@LM,'')=''
		if @tip='FB' or @tip='CF' or @tip='SF'
			select @LM=ISNULL(Loc_de_munca,'') from facturi where Factura=isnull(@FacturaStanga,'') and tert=@Tert
		else
			select @LM=ISNULL(Loc_de_munca,'') from facturi where Factura=isnull(@FacturaDreapta,'') and tert=@Tert	
	
	if @lm=''
		set @lm=isnull((select max(cod) from LMFiltrare where utilizator=@utilizator),'')
	if @Data is null set @Data=CONVERT(datetime, convert(char(10), getdate(), 101), 101)

	if ISNULL(@Numar, '')=''
	begin
		declare @UltNrFol int, @PerUnicDoc int, @NuModiUltNr int, @PerioadaJos datetime, @PerioadaSus datetime
		exec luare_date_par 'DO', 'NRUNIC', 0, @PerUnicDoc output, ''
		exec luare_date_par 'GE', 'MODIULTNR', @NuModiUltNr output, 0, ''
		set @PerioadaJos=(case @PerUnicDoc when 0 then dbo.BOY(@Data) when 1 then dbo.BOM(@Data) when 2 then @Data else '01/01/1901' end)
		set @PerioadaSus=(case @PerUnicDoc when 0 then dbo.EOY(@Data) when 1 then dbo.EOM(@Data) when 2 then @Data else '12/31/2999' end)
		exec luare_date_par 'DO', 'ALTEDOC', 0, @UltNrFol output, ''
		if @NuModiUltNr = 0 
			set @UltNrFol = @UltNrFol + 1
		while exists (select 1 from adoc where subunitate=@Sb and tip=@Tip and numar_document=ltrim(convert(char(12), @UltNrFol)) and data between @PerioadaJos and @PerioadaSus)
		begin
			set @UltNrFol = @UltNrFol + 1
			if @UltNrFol > 99999999
				set @UltNrFol = 1
		end
		set @Numar = ltrim(convert(char(12), @UltNrFol))
		if @NuModiUltNr = 0
			exec setare_par 'DO', 'ALTEDOC', null, null, @UltNrFol, null
	end

	select @TipFactSt=(case when @Tip in ('CO', 'SF', 'CF', 'C3') then 'F' else 'B' end), 
		@TipFactDr=(case when @Tip in ('FF', 'SF', 'CF') then 'F' else 'B' end), 
		@TertFactDr=isnull((case when @Tip='C3' then isnull(@TertBenef,'') else @Tert end), '')

	if @Tip<>'FF' and isnull(@ContDeb, '')=''
	begin
		select @ContDeb=Cont_de_tert from facturi where Subunitate=@Sb and tip=(case @TipFactSt when 'F' then 0x54 else 0x46 end) and tert=isnull(@Tert,'') and Factura=isnull(@FacturaStanga,'')
		select @ContDeb=(case when @TipFactSt='F' then cont_ca_furnizor else cont_ca_beneficiar end) from terti where isnull(@ContDeb, '')='' and Subunitate=@Sb and Tert=isnull(@Tert,'')
		set @ContDeb=isnull(@ContDeb, '')
	end
	if @Tip<>'FB' and isnull(@ContCred, '')=''
	begin
		select @ContCred=Cont_de_tert from facturi where Subunitate=@Sb and tip=(case @TipFactDr when 'F' then 0x54 else 0x46 end) and tert=@TertFactDr and Factura=isnull(@FacturaDreapta,'')
		select @ContCred=(case when @TipFactDr='F' then cont_ca_furnizor else cont_ca_beneficiar end) from terti where isnull(@ContCred, '')='' and Subunitate=@Sb and Tert=@TertFactDr
		set @ContCred=isnull(@ContCred, '')
	end

	if abs(isnull(@Suma, 0))<0.01 and isnull(@Valuta,'')<>'' and abs(isnull(@Curs,0))>=0.0001
		set @Suma=round(convert(decimal(18, 5), isnull(@Suma_valuta,0)*isnull(@Curs,0)), 2)
	
	--if ABS(@Suma)>=0.01 and ABS(@TVA11)>=0.01 and ABS(ISNULL(@TVA22, 0))<0.01
	if (ISNULL(@TVA22,0)=0 and @update=0 or @update=1 and @o_TVA22=@TVA22 and @o_TVA22 is not null) and @tip not in ('CO','C3')
		set @TVA22=ROUND(convert(decimal(18, 5), isnull(@Suma,0)*isnull(@TVA11,0)/(100+(case when @tip in ('CB','CF') then isnull(@TVA11,0) else 0 end))), 2)

	if ISNULL(@Explicatii, '')=''
	begin
		select @Explicatii=@Tip + ' ' + Denumire from terti where Subunitate=@Sb and tert=isnull(@Tert,'')
		set @Explicatii=ISNULL(@Explicatii, '')
	end

	select @DataFact=(case when ISNULL(@DataFact, '01/01/1901')<='01/01/1901' then Data else @DataFact end), 
		@DataScad=(case when ISNULL(@DataScad, '01/01/1901')<='01/01/1901' then Data_scadentei else @DataScad end)
	from facturi 
	where @Tip in ('SF', 'FF', 'IF', 'FB') and Subunitate=@Sb and tert=Tert and tip=(case when @Tip in ('SF', 'FF') then 0x54 else 0x46 end)
		and Factura=(case when @Tip in ('SF', 'FF') then isnull(@FacturaDreapta,'') else isnull(@FacturaStanga,'') end)

	if ISNULL(@DataFact, '01/01/1901')<='01/01/1901'
		set @DataFact=@Data
	if ISNULL(@DataScad, '01/01/1901')<='01/01/1901'
	begin
		declare @ZileScad int
		select @ZileScad=0
		select @ZileScad=discount from infotert where Subunitate=@Sb and tert=isnull(@Tert,'') and Identificator=''
		if @ZileScad<=0 and @Tip in ('IF', 'FB')
			exec luare_date_par 'GE', 'SCADENTA', 0, @ZileScad output, ''
		set @DataScad=DATEADD(d, @ZileScad, @DataFact)
	end

	if ISNULL(@TertBenef, '')=''
	begin
		if @Tip in ('FF', 'FB')
		begin
			declare @ParCtTVA char(9), @CtTVA varchar(40)

			set @ParCtTVA=(case when @Tip='FF' and LEFT(isnull(@ContCred,''), 3)='408' or @Tip='FB' and LEFT(@ContDeb, 3)='418' then 'CNEEXREC' 
				when @Tip='FF' then 'CDTVA' else 'CCTVA' end)
			exec luare_date_par 'GE', @ParCtTVA, 0, 0, @CtTVA output
			set @TertBenef=@CtTVA
		end
		else if @Tip<>'C3' and isnull(@Valuta,'')<>'' and isnull(@Suma_valuta,0)<>''
			set @TertBenef=ltrim(convert(char(13), convert(decimal(12, 2), isnull(@Suma_valuta,0)*isnull(@TVA11,0)/(100+(case when @Tip not in ('FF', 'SF', 'FB', 'IF') then isnull(@TVA11,0) else 0 end)))))
	end

	select @SumaDif=ISNULL(@SumaDif, 0), @ContDif=ISNULL(@ContDif, ''), 
		@AchitFact=ISNULL(@AchitFact, 0),@Stare=ISNULL(@Stare, 0)
		
	--tratare diferenta tva daca nu este introdusa pe macheta
	if (@DifTVA is null and @update=0)or(@update=1 and @DifTVA=@o_DifTVA)
		if @Tip='FF' or @Tip='FB'
			set @DifTVA=isnull(@Suma_valuta,0)*isnull(@TVA11,0)/100
		else
			if @CudifTVAsif=1	
			begin
				if @Tip='SF' 
					select @DifTVA=isnull(@TVA22,0)-(TVA_11+TVA_22) from facturi where Factura=isnull(@FacturaStanga,'') and tert=isnull(@Tert,'')
				if @Tip='IF'
					select @DifTVA=isnull(@TVA22,0)-(TVA_11+TVA_22) from facturi where Factura=isnull(@FacturaDreapta,'') and tert=isnull(@Tert,'')
			end
			else
				if @Tip='IF' and exists (select 1 from facturi where Factura=isnull(@FacturaDreapta,'') and tert=isnull(@Tert,'') and valuta<>'' and curs>0)
					select @DifTVA=isnull(@TVA22,0)*(1-curs/isnull(@Curs,0)) from facturi where Factura=isnull(@FacturaDreapta,'') and tert=isnull(@Tert,'')
	set @DifTVA=isnull(convert(decimal(12,2),@DifTVA),0)				
	
	declare @Data_operarii datetime, @Ora_operarii char(6) 
	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
	
	if isnull(@Utilizator, '')='' 
		set @Utilizator=dbo.fIaUtilizator(null)
		
	
	-----------------start scriere pozitie noua in pozadoc------------------------
	if @update=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @Numar_pozitie output, ''--alocare numar pozitie
		set @Numar_pozitie=@Numar_pozitie+1
		
		while exists (select 1 from pozadoc where subunitate=@Sb and tip=@Tip and Numar_document=@Numar and data=@Data and numar_pozitie=@Numar_pozitie)
			set @Numar_pozitie=@Numar_pozitie + 1 			
	
		CREATE TABLE #AdocInserat (idPozAdoc INT)

		insert pozadoc
			(Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, 
			Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif, 
			Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal)
		OUTPUT inserted.idPozadoc INTO #AdocInserat(idPozadoc)	
		values 
			(@Sb, @Numar, @Data, isnull(@Tert,''), @Tip, isnull(@FacturaStanga,''), isnull(@FacturaDreapta,''), isnull(@ContDeb,''), isnull(@ContCred,''), isnull(@Suma,0), isnull(@TVA11,0), isnull(@TVA22,0), 
			@Utilizator, @Data_operarii, @Ora_operarii, @Numar_pozitie, isnull(@TertBenef,''), @Explicatii, isnull(@Valuta,''), isnull(@Curs,0), isnull(@Suma_valuta,0), @ContDif, @SumaDif, 
			@LM, isnull(@Comanda,''), @DataFact, @DataScad, @tiptva, @AchitFact, @DifTVA, isnull(@Jurnal,''))
			
		exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Numar_pozitie, ''--setare nr pozitie ca ultim nr utilizat	

		SET @docInserate = (
			SELECT idpozadoc idpozadoc
			FROM #AdocInserat
			FOR XML raw, root('Inserate')
			)	

	end
	
	-----------------stop scriere pozitie noua in pozadoc----------------------------
	
	-----------------start modificare pozitie existenta in pozadoc-------------------
	if @update=1
	begin
		update pozadoc set
			Tert=(case when @Tert is null then tert else @Tert end),
			Factura_stinga=(case when @FacturaStanga is null then Factura_stinga else @FacturaStanga end),
			Factura_dreapta=(case when @FacturaDreapta is null then Factura_dreapta else @FacturaDreapta end),
			Cont_deb=(case when @ContDeb is null then Cont_deb else @ContDeb end),
			Cont_cred=(case when @ContCred is null then Cont_cred else @ContCred end),
			Suma=(case when @Suma is null then Suma else convert(decimal(11,3),@Suma) end),
			TVA11=(case when @TVA11 is null then TVA11 else convert(decimal(11,3),@TVA11) end),
			TVA22=(case when @TVA22 is null then TVA22 else convert(decimal(11,3),@TVA22) end),
			Utilizator=@Utilizator,
			Data_operarii=@Data_operarii,
			Ora_operarii=@Ora_operarii,
			Tert_beneficiar=(case when @TertBenef is null then Tert_beneficiar else @TertBenef end),
			Explicatii=(case when @Explicatii is null then Explicatii else @Explicatii end),
			Valuta=(case when @Valuta is null then Valuta else @Valuta end),
			Curs=(case when @Curs is null then Curs else convert(decimal(11,3),@Curs) end),				
			Suma_valuta=(case when @Suma_valuta is null then Suma_valuta else convert(decimal(11,3),@Suma_valuta) end),
			Cont_dif=(case when @ContDif is null then Cont_dif else @ContDif end),
			Suma_dif=(case when @SumaDif is null then Suma_dif else convert(decimal(11,3),@SumaDif) end),				
			Loc_munca=(case when @LM is null then Loc_munca else @LM end),				
			Comanda=(case when @Comanda is null then Comanda else @Comanda end),
			Data_fact=(case when @DataFact is null then Data_fact else @DataFact end),
			Data_scad=(case when @DataScad is null then Data_scad else @DataScad end),
			Stare=(case when @tiptva is null then Stare else @tiptva end),				
			Achit_fact=(case when @AchitFact is null then Achit_fact else convert(decimal(11,3),@AchitFact) end),
			Dif_TVA=(case when @DifTVA is  null then Dif_TVA else convert(decimal(11,3),@DifTVA) end),
			Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end)			
		where subunitate=@Sb and tip=@Tip and Numar_document=@Numar and data=@Data and numar_pozitie=@Numar_pozitie	
			
	end 
	-----------------stop modificare pozitie existenta in pozadoc---------------------

	--returnare idpozadoc
	IF @docInserate IS NULL
		SET @docInserate = ''
	SET @parXmlpozadoc = CONVERT(XML, convert(VARCHAR(max), @parXmlpozadoc) + convert(VARCHAR(max), @docInserate))
	
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


