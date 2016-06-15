--***
create procedure wScriuPI @parXmlPozplin xml
as 
begin try
	declare @Cont varchar(40), @Data datetime, @Numar char(10), @Plata_incasare char(2), @Tert char(13), @Factura char(20), 
		@Cont_corespondent varchar(40), @Suma float, @Valuta char(3), @Curs float, @Suma_valuta float, 
		@TVA11 float, @TVA22 float, @Explicatii char(50), @LM char(9), @Comanda char(40), @Comanda_bugetari char(40), @Utilizator char(10), 
		@Numar_pozitie int, @Jurnal char(3), @Marca char(6), @DecontEfect varchar(40), @DataScadDecEf datetime,@Ext_datadocument datetime,
		@update bit,@tip varchar(2),@subtip varchar(2),@mesaj varchar(200),@ext_cont_in_banca varchar(35), @tipTVA int,
		@ext_serie_CEC varchar(5), @ext_numar_CEC varchar(20), @ext_cont_in_banca_tert varchar(35), @ext_banca_tert varchar(20), 
		@detalii xml, @docDetalii XML,@idPozPlin int

	set @DecontEfect=''
	declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlPozplin

	select @idPozPlin=idPozPlin,@Numar=numar,@Data=data,@Suma=suma,@Tert=tert,@Factura=factura,
		@cont=isnull(cont,''),@Plata_incasare=isnull(plata_incasare,0),@Cont_corespondent=cont_corespondent,
		@Valuta=valuta,@Curs=curs,@LM=lm,@Comanda=ISNULL(comanda,''),@Comanda_bugetari=ISNULL(comanda_bugetari,''),
		@Suma_valuta=suma_valuta,@TVA11=cota_TVA,@TVA22=suma_tva,@Explicatii=explicatii,
		@Utilizator=ISNULL(utilizator,''),@Numar_pozitie=ISNULL(numar_pozitie,0),@Jurnal=jurnal,@Marca=marca,
		@DecontEfect=decont_efect,@DataScadDecEf=data_scadentei,@Ext_datadocument=ext_datadocument,@update=ptupdate,
		@tip=tip,@subtip=subtip,@ext_cont_in_banca=isnull(ext_cont_in_banca,''), @tipTVA=tipTVA,@ext_serie_CEC=ISNULL(ext_serie_CEC,''),
		@ext_numar_CEC=isnull(ext_numar_CEC,''), @ext_cont_in_banca_tert=ISNULL(ext_cont_in_banca_tert,''), @ext_banca_tert=ISNULL(ext_banca_tert,''),@detalii=detalii
	from OPENXML(@iDoc, '/row')
	WITH 
	(
		idPozPlin int '@idPozPlin',
		detalii xml 'detalii',
		tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip', 
		numar varchar(8) '@numar',
		data datetime '@data',
		tert varchar(13) '@tert',
		factura varchar(20) '@factura',
		ext_datadocument datetime '@ext_datadocument',
		ext_cont_in_banca varchar(35) '@ext_cont_in_banca',
		data_scadentei datetime '@data_scadentei',
		cont varchar(40) '@cont',		
		plata_incasare varchar(9) '@plata_incasare',
		cont_corespondent varchar(40) '@cont_corespondent',
		suma float '@suma',	
		valuta varchar(3) '@valuta' , 
		curs float '@curs',
		suma_valuta float '@suma_valuta',	
		cota_TVA float '@cota_TVA',
		suma_tva float '@suma_tva',
		explicatii varchar(40) '@explicatii', 
		comanda varchar(40) '@comanda',  
		comanda_bugetari varchar(40) '@comanda_bugetari',  
		lm varchar(9) '@lm', 
		utilizator varchar(20) '@utilizator',
		numar_pozitie int '@numar_pozitie', 
		jurnal varchar(3) '@jurnal', 
		marca varchar(6) '@marca', 
		decont_efect varchar(40) '@decont_efect',		
		tipTVA int '@tipTVA',
		ptupdate bit '@update',		
		ext_serie_CEC varchar(5) '@ext_serie_CEC',--campul serie_CEC din extpozplin, utilizat pentru seria efectelor
		ext_numar_CEC varchar(20) '@ext_numar_CEC',--campul numar_CEC din extpozplin, utilizat pentru numarul efectelor
		ext_cont_in_banca_tert varchar(35) '@ext_cont_in_banca_tert',--campul cont_in_banca_tert din extpozplin, utilizat pentru contul efectelor
		ext_banca_tert varchar(20) '@ext_banca_tert'--campul banca_tert din extpozplin, utilizat pentru banca emitenta pentru efecte		
	)
	-- recitire comanda: din cursor nu stie sa citeasca cu spatiile din fata
	--set @Comanda=ISNULL(@parXmlPozplin.value('(/row/@comanda_bugetari)[1]', 'varchar(40)'), '') 
	set @Comanda=ISNULL(@parXmlPozplin.value('(/row/@comanda)[1]', 'varchar(40)'), '') 
	set @Comanda_bugetari=ISNULL(@parXmlPozplin.value('(/row/@comanda_bugetari)[1]', 'varchar(40)'), '') 
	if @Comanda=''
		set @Comanda=@Comanda_bugetari
	if @Comanda<>'' and @Comanda_bugetari<>''
		set @Comanda=substring(@Comanda,1,20)+substring(@Comanda_bugetari,21,20)
	if isnull(@utilizator,'')=''
	begin 
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
		return -1
	end
	
	if abs(isnull(@Suma,0))<0.01 and abs(isnull(@Suma_valuta,0))<0.01
		return

	
	declare @Sb char(9), @CuDifCurs int, @CtCheltDifcF varchar(40), @CtVenDifcF varchar(40), @CtCheltDifcB varchar(40), @CtVenDifcB varchar(40), 
		@OpFurn int, @CuFactura int, @ValutaFactura char(3), @CursFactura float, @AtrCt int, @AtrCtC int, 
		@CuDecont int, @ValutaDecont char(3), @CursDecont float, @CuEfect int, @ValutaEfect char(3), @CursEfect float, 
		@ValutaFactDecEf char(3), @CursFactDecEf float, @AchitFact float, @CursValutaFact float, 
		@SumaDif float, @ContDif varchar(40), @DenCtCoresp char(80), @Nume char(50), @DenTert char(80)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'GE', 'DIFINR', @CuDifCurs output, 0, ''
	exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output
	exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output
	exec luare_date_par 'GE', 'DIFCHB', 0, 0, @CtCheltDifcB output
	exec luare_date_par 'GE', 'DIFVEB', 0, 0, @CtVenDifcB output

	if ISNULL(@Numar, '')=''
	begin	/* -- s-a schimbat numerotarea pentru toate incasarile din modelul din AsisPlus in Ria.
			if @Plata_incasare in ('IB', 'IC', 'ID')
			begin
				declare @SugerChit int, @AutoChit int, @UltNrChit int
				exec luare_date_par 'GE', 'SUGERCHIT', @SugerChit output, 0, ''
				exec luare_date_par 'GE', 'AUTCH', @AutoChit output, 0, ''
				exec luare_date_par 'GE', 'ULTNRCH', 0, @UltNrChit output, ''
				if @SugerChit=1 and @AutoChit=1
				begin
					set @UltNrChit=@UltNrChit+1
					set @Numar=@UltNrChit
					exec setare_par 'GE', 'ULTNRCH', null, null, @UltNrChit, null
				end
			end
			if ISNULL(@Numar, '')=''
			begin
				declare @IncNrPlin int, @UltNrPlin int
				exec luare_date_par 'GE', 'INCNRPLIN', @IncNrPlin output, 0, ''
				exec luare_date_par 'DO', 'PLATINC', 0, @UltNrPlin output, ''
				if @IncNrPlin=1
				begin
					set @UltNrPlin=@UltNrPlin+1
					set @Numar=@UltNrPlin
					exec setare_par 'DO', 'PLATINC', null, null, @UltNrPlin, null
				end
			end
			set @Numar=isnull(@Numar, '')
			*/
				declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)
					set @tipPentruNr='IB' 
					set @LM = (case when @LM is null then '' else @LM end)
					set @Jurnal = (case when @Jurnal is null then '' else @Jurnal end)
					set @fXML = '<row/>'
					set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
					set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
					set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
					set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
					set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
			
					exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocPrimit output
			
					if isnull(@NrDocPrimit,0)=0
						raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
					set @numar=@NrDocPrimit
	end

	set @OpFurn=(case when left(@Plata_incasare, 1)='P' and @Plata_incasare<>'PS' or @Plata_incasare='IS' then 1 else 0 end)
	set @CuFactura=(case when @Plata_incasare in ('PF','PR','PS','IB','IR','IS') then 1 else 0 end)
	select @ValutaFactura='', @CursFactura=0, @ValutaDecont='', @CursDecont=0, @ValutaEfect='', @CursEfect=0

	select @Cont_corespondent=(case when isnull(@Cont_corespondent,'')='' then cont_de_tert else @Cont_corespondent end), 
		@ValutaFactura=valuta, @CursFactura=curs, 
		@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end)
		/*,@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)*/
	from facturi
	where @CuFactura=1 and subunitate=@Sb and tip=(case when @OpFurn=1 then 0x54 else 0x46 end) and tert=isnull(@Tert,'') and factura=isnull(@Factura,'')

	select @AtrCt=(case when cont=@Cont then sold_credit else @AtrCt end), 
		@AtrCtC=(case when cont=@Cont_corespondent then sold_credit else @AtrCtC end), 
		@DenCtCoresp=(case when cont=@Cont_corespondent then Denumire_cont else @DenCtCoresp end)
	from conturi 
	where subunitate=@Sb and (cont=@Cont or cont=@Cont_corespondent)

	select @CuDecont=(case when @AtrCt=9 or @AtrCtC=9 then 1 else 0 end), 
		   @CuEfect=(case when @AtrCt=8 or @AtrCtC=8 then 1 else 0 end)

	if @CuDecont=1 and isnull(@DecontEfect, '')=''
		select @DecontEfect=convert(varchar(9), isnull(max(convert(decimal(12,0), decont)), 0) + 1) from deconturi where subunitate=@Sb and tip='T' and marca=isnull(@Marca,'') and isnumeric(decont)<>0
	if @CuEfect=1 and isnull(@DecontEfect, '')=''
		select @DecontEfect='BO'+convert(varchar(9), isnull(max(convert(decimal(12,0), substring(nr_efect,3,8))), 0) + 1) from efecte where subunitate=@Sb and tip=(case when @OpFurn=1 then 'P' else 'I' end) and tert=isnull(@Tert,'') and nr_efect like 'BO%' and isnumeric(substring(nr_efect,3,8))<>0 

	if @CuFactura=0 or @CuDecont=1
		set @CuDifCurs=0

	/* Cristy
	Aici se completeaza locul de munca si comanda cu datele din decont respectiv efect
	in cazul in care sunt nule sau necompletate. 
	Las locul de munca completat dar comanda nu o vom sugera din efect sau decont*/	
	select @ValutaDecont=valuta, @CursDecont=curs, 
		@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end)
		/*,@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)*/
	from deconturi
	where @CuDecont=1 and subunitate=@Sb and tip='T' and marca=isnull(@Marca,'') and decont=@DecontEfect

	select @ValutaEfect=valuta, @CursEfect=curs, 
		@LM=(case when isnull(@LM, '')='' then loc_de_munca else @LM end)/*, 
		@Comanda=(case when isnull(@Comanda, '')='' then comanda else @Comanda end)*/
	from efecte
	where @CuEfect=1 and subunitate=@Sb and tip=(case when @OpFurn=1 then 'P' else 'I' end) and tert=isnull(@Tert,'') and nr_efect=ISNULL(@DecontEfect,'')

	select @AchitFact=0, @CursValutaFact=isnull((case when @Plata_incasare in ('PC', 'IC') then @tipTVA else 0 end),0), @SumaDif=0, @ContDif=''

	if abs(isnull(@Suma_valuta,0))>=0.01
	begin
		if isnull(@Valuta,'')=''
			set @Valuta=(case when @CuFactura=1 then @ValutaFactura when @CuDecont=1 then @ValutaDecont when @CuEfect=1 then @ValutaEfect else isnull(@Valuta,'') end)
		if @Valuta<>'' and abs(isnull(@Curs,0))<0.0001
			select top 1 @Curs=curs from curs where valuta=@Valuta and data<=@Data order by data DESC
		
		if abs(isnull(@Suma,0))<0.01 and isnull(@Valuta,'')<>'' and abs(isnull(@Curs,0))>=0.0001
			set @Suma=round(convert(decimal(18, 5), isnull(@Suma_valuta,0)*isnull(@Curs,0)), 2)
		
		-- cica nu mai tratam achitarea unei facturi in alta moneda decat a facturii :))
		select @ValutaFactDecEf=(case when @CuFactura=1 then @ValutaFactura when @CuDecont=1 then @ValutaDecont when @CuEfect=1 then @ValutaEfect else '' end)
		select @CursFactDecEf=(case when @CuFactura=1 then @CursFactura when @CuDecont=1 then @CursDecont when @CuEfect=1 then @CursEfect else '' end)
		set @AchitFact=round(convert(decimal(18, 5), (case when isnull(@Valuta,'')='' then 0 when (@CuDecont=1 and @Plata_incasare='ID' or @CuFactura=1 and @CuDifCurs=1 or @AtrCt=9 or @AtrCtC<>9) and @ValutaFactDecEf not in ('', isnull(@Valuta,'')) and abs(@CursFactDecEf)<>0 then isnull(@Suma_valuta,0)*isnull(@Curs,0)/@CursFactDecEf else isnull(@Suma_valuta,0) end)), 2)
		set @CursValutaFact=isnull(round(convert(decimal(11, 5), (case when @CursValutaFact<>0 then @CursValutaFact when isnull(@Valuta,'')='' then 0 when (@CuDecont=1 and @Plata_incasare='ID' or @CuFactura=1 and @CuDifCurs=1) and @ValutaFactDecEf not in ('', isnull(@Valuta,'')) and @AchitFact<>0 then isnull(@Curs,0)*isnull(@Suma_valuta,0)/@AchitFact else isnull(@Curs,0) end)), 4),0)
		
		if isnull(@Valuta,'')<>'' and @CuDifCurs=1 and @CursFactDecEf>0
		begin
			set @SumaDif=round(convert(decimal(18, 5), round(@AchitFact*@CursValutaFact,2)-
				round(@AchitFact*@CursFactDecEf,2)), 2)
			set @ContDif=(case when left(@Plata_incasare, 1)='P' and (isnull(@Curs,0)-@CursFactura>=0.0001 or @SumaDif>=0.01) or left(@Plata_incasare, 1)='I' and (isnull(@Curs,0)-@CursFactura<=-0.0001 or @SumaDif<=-0.01) then (case when @CtCheltDifcB='' or @Plata_incasare in ('PF', 'PR') then @CtCheltDifcF else @CtCheltDifcB end) else (case when @CtVenDifcB='' or @Plata_incasare in ('PF', 'PR') then @CtVenDifcF else @CtVenDifcB end) end)
		end
	end

	if substring(@Plata_incasare, 2, 1)='C' and @TVA11<>0 and ISNULL(@TVA22, 0)=0
		set @TVA22=ROUND(convert(decimal(18, 5), isnull(@Suma,0)*@TVA11/(100.00+@TVA11)), 2)

	if @CuDecont=1
		set @ContDif=isnull(@Marca,'')

	if ISNULL(@Explicatii, '')=''
	begin
		select @Nume=nume from personal where @CuDecont=1 and Marca=isnull(@Marca,'')
		select @DenTert=denumire from terti where @CuDecont=0 and (@CuFactura=1 or @AtrCtC=8) and Subunitate=@Sb and Tert=isnull(@Tert,'')
		set @Explicatii=isnull(left((case when @CuDecont=1 then @Nume when @CuFactura=1 or @AtrCtC=8 then @DenTert else @DenCtCoresp end), 50), '')
	end

	declare @Data_operarii datetime, @Ora_operarii char(6) 
	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
	if isnull(@Utilizator, '')='' 
		set @Utilizator=dbo.fIaUtilizator(null)
	
	-----------------start scriere pozitie noua in pozplin si dupa caz in  extpozplin------------------------
	if @update=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @Numar_pozitie output, ''--alocare numar pozitie
		set @Numar_pozitie=@Numar_pozitie+1
		
		while exists (select 1 from pozplin where subunitate=@Sb and Cont=@Cont and data=@Data and numar=@Numar and Numar_pozitie=@Numar_pozitie)
			set @Numar_pozitie=@Numar_pozitie + 1 

		delete from extpozplin where subunitate=@Sb and cont=@Cont and data=@Data and numar_pozitie=@Numar_pozitie and Numar=@Numar
				
		insert extpozplin
			(Subunitate, Cont, Data, Numar, Numar_pozitie, Tip, Cont_corespondent, Marca, Decont, Data_scadentei, Suma, Suma_achitat, Banca, Cont_in_banca, 
			Numar_justificare, Data_document, Serie_CEC, Numar_CEC, Banca_tert, Cont_in_banca_tert, Jurnal)
		values
			(@Sb, @Cont, @Data, @Numar, @Numar_pozitie, '', '', @Marca, ISNULL(@DecontEfect,''), @DataScadDecEf, 0, 0, '', @ext_cont_in_banca,
			'', @Ext_datadocument, @ext_serie_CEC, @ext_numar_CEC, @ext_banca_tert, @ext_cont_in_banca_tert, '')

		insert into pozplin 
			(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, 
			Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, 
			Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
			Cont_dif, Suma_dif, Achit_fact, Jurnal)
		values 
			(@Sb, @Cont, @Data, @Numar, @Plata_incasare, isnull(@Tert,''), isnull(@Factura,''), isnull(@Cont_corespondent,''), 
			isnull(convert(decimal(17,2),@Suma),0), isnull(@Valuta,''), isnull(convert(decimal(11,4),@Curs),0), isnull(convert(decimal(17,4),@Suma_valuta),0), 
			convert(decimal(11,4),@CursValutaFact), convert(decimal(11,2),@TVA11), ISNULL(convert(decimal(11,2),@TVA22),0), @Explicatii, isnull(@LM,''), @Comanda, @Utilizator, 
			@Data_operarii, @Ora_operarii, @Numar_pozitie, @ContDif, convert(decimal(11,2),@SumaDif), convert(decimal(11,2),@AchitFact), isnull(@Jurnal,''))
			
			exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Numar_pozitie, ''--setare nr pozitie ca ultim nr utilizat
			
		SET @docDetalii = (
				SELECT @Sb subunitate, @Numar_pozitie numarpozitie, @Cont cont, @Data data, 'pozplin' as tabel, @detalii
				for xml raw
				)
		exec wScriuDetalii @parXML=@docDetalii

	end
	-----------------stop scriere pozitie noua in pozplin si dupa caz in  extpozplin----------------------------
	
	-----------------start modificare pozitie existenta in pozplin si dupa caz in extpozplin---------------------
	if @update=1
		begin
			update pozplin set
				Numar=(case when @Numar is null then Numar else @Numar end),
				Tert=(case when @Tert is null then tert else @Tert end),
				Factura=(case when @Factura is null then Factura else @Factura end),
				Cont_corespondent=(case when @Cont_corespondent is null then Cont_corespondent else @Cont_corespondent end),
				Suma=(case when @Suma is null then Suma else convert(decimal(17,2),@Suma) end),
				Valuta=(case when @Valuta is null then Valuta else @Valuta end),
				Curs=(case when @Curs is null then Curs else convert(decimal(11,4),@Curs) end),
				Suma_valuta=(case when @Suma_valuta is null then Suma_valuta else convert(decimal(17,4),@Suma_valuta) end),
				Curs_la_valuta_facturii=(case when @CursValutaFact is null then Curs_la_valuta_facturii else convert(decimal(11,4),@CursValutaFact) end),
				TVA11=(case when @TVA11 is null then TVA11 else convert(decimal(11,2),@TVA11) end),
				TVA22=(case when @TVA22 is null then TVA22 else convert(decimal(11,2),@TVA22) end),
				Explicatii=(case when @Explicatii is null then Explicatii else @Explicatii end),
				Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),
				Comanda=@Comanda,
				Utilizator=@Utilizator,
				Data_operarii=@Data_operarii,
				Ora_operarii=@Ora_operarii,
				Cont_dif=(case when @ContDif is null then Cont_dif else @ContDif end),
				Suma_dif=(case when @SumaDif is null then Suma_dif else convert(decimal(11,2),@SumaDif) end),
				Achit_fact=(case when @AchitFact is null then Achit_fact else convert(decimal(11,2),@AchitFact) end),
				Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end)			
			where idPozPlin=@idPozPlin
		
			SET @docDetalii = (
					SELECT @Sb subunitate, @Numar_pozitie numarpozitie, @Cont cont, @Data data, 'pozplin' as tabel, @detalii
					for xml raw
					)
			exec wScriuDetalii @parXML=@docDetalii

			if not exists (select 1 from extpozplin where subunitate=@Sb and cont=@Cont and data=@Data /*and numar=@Numar*/ and numar_pozitie=@Numar_pozitie)			
				insert extpozplin
					(Subunitate, Cont, Data, Numar, Numar_pozitie, Tip, Cont_corespondent, Marca, Decont, Data_scadentei, Suma, Suma_achitat, Banca, 
					Cont_in_banca, Numar_justificare, Data_document, Serie_CEC, Numar_CEC, Banca_tert, Cont_in_banca_tert, Jurnal)
				values
					(@Sb, @Cont, @Data, @Numar, @Numar_pozitie, '', '', @Marca, ISNULL(@DecontEfect,''), @DataScadDecEf, 0, 0, '', @ext_cont_in_banca, 
					'', @Ext_datadocument, @ext_serie_CEC, @ext_numar_CEC, @ext_banca_tert, @ext_cont_in_banca_tert, '')
			else	
				update extpozplin set
					Numar=(case when @Numar is null then Numar else @Numar end),
					Cont_corespondent=(case when @Cont_corespondent is null then Cont_corespondent else @Cont_corespondent end),
					Marca=(case when @Marca is null then Marca else @Marca end),
					Decont=(case when @DecontEfect is null then Decont else @DecontEfect end),
					Data_scadentei=@DataScadDecEf,
					Data_document=@Ext_datadocument	,
					Cont_in_banca=@ext_cont_in_banca,
					Serie_CEC=@ext_serie_CEC,
					Numar_CEC=@ext_numar_CEC,
					Banca_tert=@ext_banca_tert,
					Cont_in_banca_tert=@ext_cont_in_banca_tert
				where subunitate=@Sb and cont=@Cont and data=@Data /*and numar=@Numar*/ and numar_pozitie=@Numar_pozitie		
		
		end 
	-----------------stop modificare pozitie existenta in pozplin si dupa caz in extpozplin---------------------
	
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
--sp_help extpozplin
