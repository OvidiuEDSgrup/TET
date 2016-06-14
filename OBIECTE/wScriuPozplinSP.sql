--***
if exists (select * from sysobjects where name='wScriuPozplinSP')
drop procedure wScriuPozplinSP
go
--***
create procedure  [wScriuPozplinSP] @sesiune varchar(50), @parXML xml OUTPUT
as

declare @tip char(2), @cont char(13), @data datetime, @marca_antet char(6), @decont_antet char(13), @tert_antet char(13), @efect_antet char(13), 
	@marca char(6), @decont char(13), @tert char(13), @efect char(13), @mesaj varchar(200),
	@subtip char(2), @numar char(10), @factura char(20), @cont_corespondent char(13), @suma float, 
	@valuta char(3), @curs float, @suma_valuta float, @cota_TVA float, @suma_TVA float, @explicatii char(50), 
	@lm char(9), @comanda char(20), @numar_pozitie int, @jurnal char(3), @data_scadentei datetime, 
	@tipGrp char(2), @contGrp char(13), @dataGrp datetime, @marcaGrp char(6), @decontGrp char(13), @tertGrp char(13), @efectGrp char(13), 
	@plata_incasare char(2), @in_valuta int, @op_furn int, @factura_poz char(20), @cont_cor_poz char(13), @sold_fact float, @sold_valuta_fact float, 
	@suma_poz float, @suma_valuta_poz float, @decont_efect char(13), @nr_poz_out int, @sir_numere_pozitii varchar(max), 
	@sub char(9), @RepSumeF int, @ExcepAv int, @CtAvFurn char(13), @CtAvBen char(13), @Bugetari int, 
    @indbug char(20), @comanda_bugetari varchar(40), @tipTVA int, @ptupdate bit,@ext_cont_in_banca varchar(35),
	@userASiS varchar(20), @jurnalProprietate varchar(3), @contProprietate varchar(20), @detalii xml, 
	@docXMLIaPozplin xml, @eroare xml,@ext_datadocument datetime,@lista_lm bit,@ft int, @apelDinProcedura int,
	@ext_serie_CEC varchar(5), @ext_numar_CEC varchar(20), @ext_cont_in_banca_tert varchar(35), @ext_banca_tert varchar(20)

begin try
	--BEGIN TRAN
	SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
	
	set @eroare=dbo.wfValidarePozplin(@parXML)
	
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
	begin
		set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
		raiserror(@mesaj, 11, 1)
	end
/*SP
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozplinSP')
		exec wScriuPozplinSP @sesiune, @parXML output
SP*/
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','REPSUMEF',0,@RepSumeF output,''
	exec luare_date_par 'GE','EXCEP419',@ExcepAv output,0,''
	exec luare_date_par 'GE','CFURNAV',0,0,@CtAvFurn output
	exec luare_date_par 'GE','CBENEFAV',0,0,@CtAvBen output
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	if @CtAvFurn='' set @CtAvFurn='409'
	if @CtAvBen='' set @CtAvBen='419'
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	set @jurnalProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='JURNAL'), '')
	set @contProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CONTPLIN'), '')

	--@lista_lm va fi 1 daca utilizatorul curent are atasate locuri de munca in prorpietati, 0 altfel
	select @lista_lm=dbo.f_arelmfiltru(@userASiS)
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozplinsp cursor for
	select isnull(tip_antet, '') as tip, 
	(case when isnull(cont_pozitii, '')<>'' then cont_pozitii when isnull(cont_antet, '')<>'' then cont_antet else @contProprietate end) as cont, 
	(case when isnull(data_pozitii, '01/01/1901')>'01/01/1901' then data_pozitii else isnull(data_antet, '01/01/1901') end) as data, 
	upper(isnull(marca_antet, '')) as marca_antet, isnull(decont_antet, '') as decont_antet,
	upper(isnull(tert_antet, '')) as tert_antet, isnull(efect_antet, '') as efect_antet, 
	upper((case when isnull(marca_pozitii, '')<>'' then marca_pozitii else isnull(marca_antet, '') end)) as marca,
	(case when isnull(decont_pozitii, '')<>'' then decont_pozitii else isnull(decont_antet, '') end) as decont,
	upper((case when isnull(tert_pozitii, '')<>'' then tert_pozitii else isnull(tert_antet, '') end)) as tert,
	(case when isnull(efect_pozitii, '')<>'' then efect_pozitii else isnull(efect_antet, '') end) as efect,
	isnull(subtip, '') as subtip, upper(isnull(numar, '')) as numar, upper(isnull(factura, '')) as factura, 
	isnull(cont_corespondent, '') as cont_corespondent, isnull(suma, 0) as suma, upper(isnull(isnull(valuta, valuta_antet),'')) as valuta, 
	isnull(isnull(curs, curs_antet), 0) as curs, isnull(suma_valuta, 0) as suma_valuta, isnull(cota_TVA, 0) as cota_TVA, isnull(suma_TVA, 0) as suma_TVA, 
	isnull(explicatii, '') as explicatii, upper(isnull(lm, '')) as lm, 
	upper(isnull(comanda, '')) as comanda, upper(isnull(indbug, '')) as indbug, 
	isnull(numar_pozitie, 0) as numar_pozitie, 
	isnull(jurnal, '') as jurnal, 
	isnull(tipTVA, 0) as tipTVA, 
	isnull(ptupdate, 0) as ptupdate, isnull(data_scadentei, '01/01/1901') as data_scadentei,
	isnull(ext_datadocument,(case when isnull(data_pozitii, '01/01/1901')>'01/01/1901' then data_pozitii else isnull(data_antet, '01/01/1901') end)) as ext_datadocument,--daca nu se completeaza data platii se ia data incasarii din pozplin
	isnull(ext_cont_in_banca, ext_cont_in_banca_antet) as ext_cont_in_banca ,isnull(ext_serie_CEC,ext_serie_CEC_antet) as ext_serie_CEC, 
	isnull(ext_numar_CEC,ext_numar_CEC_antet) as ext_numar_CEC,	isnull(ext_cont_in_banca_tert,ext_cont_in_banca_tert_antet)as ext_cont_in_banca_tert, 
	isnull(ext_banca_tert,ext_banca_tert_antet) as ext_banca_tert, 
	detalii as detalii 
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		detalii xml 'detalii',
		tip_antet char(2) '../@tip', 
		cont_antet char(13) '../@cont', 
		data_antet datetime '../@data', 
		marca_antet char(6) '../@marca', 
		decont_antet char(13) '../@decont', 
		tert_antet char(13) '../@tert', 
		efect_antet char(13) '../@efect',
		valuta_antet char(3) '../@valuta', 
		curs_antet float '../@curs', 
		
		ext_datadocument_antet datetime '../@ext_datadocument',--data la care beneficiarul a facut plata(se ia in calcul la calculul penalitatilor)
		ext_cont_in_banca_antet varchar(35) '../@ext_cont_in_banca',--campul cont_in_banca din extpozplin
		ext_serie_CEC_antet varchar(5) '../@ext_serie_CEC',--campul serie_CEC din extpozplin, utilizat pentru seria efectelor
		ext_numar_CEC_antet varchar(20) '../@ext_numar_CEC',--campul numar_CEC din extpozplin, utilizat pentru numarul efectelor
		ext_cont_in_banca_tert_antet varchar(35) '../@ext_cont_in_banca_tert',--campul cont_in_banca_tert din extpozplin, utilizat pentru contul efectelor
		ext_banca_tert_antet varchar(20) '../@ext_banca_tert',--campul banca_tert din extpozplin, utilizat pentru banca emitenta pentru efecte		
		
		cont_pozitii char(13) '@cont', 
		data_pozitii datetime '@data', 
		marca_pozitii char(6) '@marca', 
		decont_pozitii char(13) '@decont', 
		tert_pozitii char(13) '@tert', 
		efect_pozitii char(13) '@efect', 
		subtip char(2) '@subtip', 
		numar char(10) '@numar', 
		factura char(20) '@factura', 
		cont_corespondent char(13) '@contcorespondent', 
		suma float '@suma', 
		valuta char(3) '@valuta', 
		curs float '@curs', 
		suma_valuta float '@sumavaluta', 
		cota_TVA float '@cotatva', 
		suma_TVA float '@sumatva', 
		explicatii char(50) '@explicatii', 
		lm char(9) '@lm', 
		comanda char(20) '@comanda', 
		indbug char(20) '@indbug', 
		numar_pozitie int '@numarpozitie', 
		jurnal char(3) '@jurnal', 
		tipTVA int '@tipTVA', 
		ptupdate bit '@update',
		data_scadentei datetime '@datascadentei',
		
		ext_datadocument datetime '@ext_datadocument',--data la care beneficiarul a facut plata(se ia in calcul la calculul penalitatilor)
		ext_cont_in_banca varchar(35) '@ext_cont_in_banca',--campul cont_in_banca din extpozplin
		ext_serie_CEC varchar(5) '@ext_serie_CEC',--campul serie_CEC din extpozplin, utilizat pentru seria efectelor
		ext_numar_CEC varchar(20) '@ext_numar_CEC',--campul numar_CEC din extpozplin, utilizat pentru numarul efectelor
		ext_cont_in_banca_tert varchar(35) '@ext_cont_in_banca_tert',--campul cont_in_banca_tert din extpozplin, utilizat pentru contul efectelor
		ext_banca_tert varchar(20) '@ext_banca_tert'--campul banca_tert din extpozplin, utilizat pentru banca emitenta pentru efecte
	)

	open crspozplinsp
	fetch next from crspozplinsp into @tip, @cont, @data, @marca_antet, @decont_antet, @tert_antet, @efect_antet, 
		@marca, @decont, @tert, @efect, @subtip, @numar, @factura, @cont_corespondent, @suma, @valuta, @curs, @suma_valuta, 
		@cota_TVA, @suma_TVA, @explicatii, @lm, @comanda, @indbug, @numar_pozitie, @jurnal,@tipTVA, @ptupdate, @data_scadentei,@ext_datadocument,
		@ext_cont_in_banca,@ext_serie_CEC,@ext_numar_CEC,@ext_cont_in_banca_tert,@ext_banca_tert, @detalii
		
	select @tipGrp=@tip, @contGrp=@cont, @dataGrp=@data, @marcaGrp=@marca_antet, @decontGrp=@decont_antet, 
		@tertGrp=@tert_antet, @efectGrp=@efect_antet, @sir_numere_pozitii=''

	set @ft=@@FETCH_STATUS
	while @ft=0
	begin

		if @jurnal=''
			set @jurnal=@jurnalProprietate
		set @comanda_bugetari=convert(char(20),@comanda)+isnull(@indbug,'')
		
		select @plata_incasare=(case 
				when @tip='RE' and (@subtip='PN' or @subtip='PV' or @subtip='PX'/*PX->subtip de plata avans*/) then 'PF'
				when @tip='RE' and @subtip='IX'/*IX->subtip de incasare avans*/ then 'IB'
				when @tip='RE' and @subtip in ('PA', 'PE') then 'PD'
				when @tip='RE' and @subtip in ('IA', 'IE') then 'ID'
				when @tip='EF' and @subtip='PT' or @subtip='PF' or @subtip='PV' and abs(@suma_valuta)>=0.01 then 'PF' 
				when @tip='EF' and @subtip='IT' or @subtip='IB' or @subtip='IV' and abs(@suma_valuta)>=0.01 then 'IB' 
				else @subtip 
			end),			
			@in_valuta=(case when abs(@suma_valuta)>=0.01 then 1 else 0 end)
--/*SP
		declare @nrPozXml int
		set @nrPozXml=isnull(@nrPozXml,0)+1
		
		if ISNULL(@Numar, '')=''
		begin	
			declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20), @NumarDocPrimit int
			--set @tipPentruNr='IB' 
			set @tipPentruNr=@tip 
			set @LM = (case when @LM is null then '' else @LM end)
			set @Jurnal = (case when @Jurnal is null then '' else @Jurnal end)
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
			set @fXML.modify ('insert attribute meniu {"PI_FILIALE"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
			set @fXML.modify ('insert attribute subtip {sql:variable("@subtip")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')

			exec wIauNrDocFiscale @parXML=@fXML,@Numar=@NumarDocPrimit output, @NrDoc=@NrDocPrimit output

			if isnull(@NumarDocPrimit,0)=0
				raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			set @numar=@NrDocPrimit
			
			if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@numar)[1]','varchar(10)') is null 
				set @parXML.modify ('insert attribute numar {sql:variable("@numar")} into (/row/row[sql:variable("@nrPozXml")])[1]')
			else
				set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@numar)[1] with sql:variable("@numar")')
		end

		if @tip='RE' and @subtip='IB' and isnull(@factura,'')<>''
		begin
			declare @suma_fact decimal(15,3), @comanda_fact varchar(20), @lm_fact varchar(9), @cont_fact varchar(13)
			if ISNULL(@suma,0)=0 or ISNULL(@lm,'')=''
				select top 1 @suma_fact=coalesce(nullif(@suma,0),f.sold,0)
					, @comanda_fact=coalesce(nullif(@comanda,''),f.Comanda,'') 
					, @lm_fact=coalesce(nullif(@lm,''),f.loc_de_munca,'') 
				from facturi f 
				where f.Subunitate=@sub --and f.Tip=0x46
					 and f.Tert=@tert and f.Factura=@factura
					 
			if ISNULL(@cont_corespondent,'')='' 
				select top 1 @cont_fact=p.Cont_factura from pozdoc p 
				where p.Subunitate=@sub and p.Tip='AP' and p.Tert=@tert and p.Factura=@factura order by p.data desc
			
			if ISNULL(@suma,0)=0 and isnull(@suma_fact,0)<>0
				if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@suma)[1]','decimal(15,3)') is null 
					set @parXML.modify ('insert attribute suma {sql:variable("@suma_fact")} into (/row/row[sql:variable("@nrPozXml")])[1]')
				else
					set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@suma)[1] with sql:variable("@suma_fact")')	
			
			if ISNULL(@cont_corespondent,'')='' and ISNULL(@cont_fact,'')<>''		
				if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@contcorespondent)[1]','varchar(13)') is null 
					set @parXML.modify ('insert attribute contcorespondent {sql:variable("@cont_fact")} into (/row/row[sql:variable("@nrPozXml")])[1]')
				else
					set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@contcorespondent)[1] with sql:variable("@cont_fact")')	
			
			if ISNULL(@lm,'')='' and ISNULL(@lm_fact,'')<>''		
				if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@lm)[1]','varchar(9)') is null 
					set @parXML.modify ('insert attribute lm {sql:variable("@lm_fact")} into (/row/row[sql:variable("@nrPozXml")])[1]')
				else
					set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@lm)[1] with sql:variable("@lm_fact")')
		end
		
		if isnull(@parXML.value('(/row/row[sql:variable("@nrPozXml")]/@lm)[1]','varchar(9)'),'')=''
		begin
			set @lm=(select top 1 Valoare from proprietati 
				where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('LOCMUNCASTABIL') and valoare<>'')
				
			if isnull(@lm,'')<>''
				if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@lm)[1]','varchar(9)') is null 
					set @parXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row/row[sql:variable("@nrPozXml")])[1]')
				else
					set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@lm)[1] with sql:variable("@lm")')
		end
		
		if isnull(@parXML.value('(/row/@cont)[1]','varchar(20)'),'')=''
		begin
			--set @lm=(select top 1 Valoare from proprietati 
			--	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('LOCMUNCASTABIL') and valoare<>'')
				
			if isnull(@contProprietate,'')<>''
				if @parXML.value('(/row/@cont)[1]','varchar(20)') is null 
					set @parXML.modify ('insert attribute cont {sql:variable("@contProprietate")} into (/row)[1]')
				else
					set @parXML.modify('replace value of (/row/@cont)[1] with sql:variable("@contProprietate")')
		end
		
		if @tip='RE' and @subtip='IC' --and isnull(@parXML.value('(/row/row[sql:variable("@nrPozXml")]/@o_suma)[1]','decimal(15,3)'),@suma)<>@suma
			if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@sumatva)[1]','decimal(15,3)') is not null 
				set @parXML.modify ('delete /row/row[sql:variable("@nrPozXml")]/@sumatva')
--SP*/
		fetch next from crspozplinsp into @tip, @cont, @data, @marca_antet, @decont_antet, @tert_antet, @efect_antet, 
			@marca, @decont, @tert, @efect, @subtip, @numar, @factura, @cont_corespondent, @suma, @valuta, @curs, @suma_valuta, 
			@cota_TVA, @suma_TVA, @explicatii, @lm, @comanda, @indbug, @numar_pozitie, @jurnal,@tipTVA, @ptupdate, @data_scadentei,@ext_datadocument,
			@ext_cont_in_banca,@ext_serie_CEC,@ext_numar_CEC,@ext_cont_in_banca_tert,@ext_banca_tert, @detalii
		set @ft=@@FETCH_STATUS
	end	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj =ERROR_MESSAGE()+'(wScriuPozplinSP)'
end catch
--

declare @cursorStatus int
set @cursorStatus=CURSOR_STATUS('global', 'crspozplinsp')
if @cursorStatus=1 
	close crspozplinsp 
if @cursorStatus is not null 
	deallocate crspozplinsp 
--	
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

if len(@mesaj)>0
	raiserror(@mesaj, 11, 1)