--***
create procedure  [wScriuPozplin] @sesiune varchar(50), @parXML xml 
as

declare @fara_luare_date varchar(1), @tip char(2), @cont varchar(40), @data datetime, @marca_antet char(6), @decont_antet varchar(40), @tert_antet char(13), @efect_antet varchar(20), 
	@marca char(6), @decont varchar(40), @tert char(13), @efect varchar(20), @mesaj varchar(200),
	@subtip char(2), @numar char(10), @factura char(20), @cont_corespondent varchar(40), @suma float, 
	@valuta char(3), @curs float, @suma_valuta float, @cota_TVA float, @suma_TVA float, @explicatii char(50), 
	@lm char(9), @comanda char(20), @numar_pozitie int, @jurnal char(3), @data_scadentei datetime, 
	@tipGrp char(2), @contGrp varchar(40), @dataGrp datetime, @marcaGrp char(6), @decontGrp varchar(40), @tertGrp char(13), @efectGrp varchar(20), 
	@plata_incasare char(2), @in_valuta int, @op_furn int, @factura_poz char(20), @cont_cor_poz varchar(40), @sold_fact float, @sold_valuta_fact float, 
	@suma_poz float, @suma_valuta_poz float, @decont_efect varchar(40), @nr_poz_out int, @sir_numere_pozitii varchar(max), 
	@sub char(9), @RepSumeF int, @ExcepAv int, @CtAvFurn varchar(40), @CtAvBen varchar(40), @Bugetari int, 
    @indbug char(20), @comanda_bugetari varchar(40), @tipTVA int, @ptupdate bit,@ext_cont_in_banca varchar(35), @detalii_antet xml, 
	@userASiS varchar(20), @jurnalProprietate varchar(3), @contProprietate varchar(40), @detalii xml, 
	@docXMLIaPozplin xml, @eroare xml,@ext_datadocument datetime,@lista_lm bit,@ft int, @apelDinProcedura int,
	@ext_serie_CEC varchar(5), @ext_numar_CEC varchar(20), @ext_cont_in_banca_tert varchar(35), @ext_banca_tert varchar(20),@idPozPlin int, @facturiPeConturi int, 
	@dateInitializare XML, @contcorespondent varchar(20)

exec luare_date_par 'GE','SUBPRO',0,0,@sub output
exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''

--	Am citit aici datele din XML pentru a putea apela MACHETA PENTRU INCASARI/PLATI FACTURI SELECTIV
SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
select	@fara_luare_date=ISNULL(@parXML.value('(//@fara_luare_date)[1]', 'char(1)'), '0'),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(20)'), ''),
		@subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(20)'), ''),
		@cont=ISNULL(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''),
		@efect_antet=ISNULL(@parXML.value('(/row/@efect)[1]', 'varchar(20)'), ''),
		@numar=ISNULL(@parXML.value('(/row/row/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/row//row/@tert)[1]', 'varchar(20)'), ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')),
		@marcaGrp=ISNULL(@parXML.value('(/row/row/@marca)[1]', 'varchar(20)'), ISNULL(@parXML.value('(/row/@marca)[1]', 'varchar(20)'), '')),
		@decontGrp=ISNULL(@parXML.value('(/row/row/@decont)[1]', 'varchar(40)'), ISNULL(@parXML.value('(/row/@decont)[1]', 'varchar(40)'), '')),
		@tertGrp=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),
		@efectGrp=ISNULL(@parXML.value('(/row/@efect)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@factura=ISNULL(@parXML.value('(/row/row/@factura)[1]', 'varchar(20)'), ''),
		@lm=ISNULL(@parXML.value('(/row/row/@lm)[1]', 'varchar(9)'), ''),
		@jurnal=ISNULL(@parXML.value('(/row/row/@jurnal)[1]', 'varchar(20)'), ''),
		@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), ''),
		@curs=ISNULL(@parXML.value('(/row/@curs)[1]', 'float'), 0),
		@suma=ISNULL(@parXML.value('(/row/row/@suma)[1]', 'float'), 0),
		@suma_valuta=ISNULL(@parXML.value('(/row/row/@sumavaluta)[1]', 'float'), 0),
		@ptupdate=ISNULL(@parXML.value('(/row/row/@update)[1]', 'int'), 0),
		@contcorespondent=ISNULL(@parXML.value('(/row/row/@contcorespondent)[1]', 'varchar(20)'), '')

select @tipGrp=@tip, @contGrp=@cont, @dataGrp=@data, @facturiPeConturi=0
if @parXML.exist('(/row/detalii/row)[1]') = 1
		set @detalii_antet = @parXML.query('(/row/detalii/row)[1]')
if @parXML.exist('(/row/row/detalii/row)[1]') = 1
		set @detalii = @parXML.query('(/row/row/detalii/row)[1]')

select @plata_incasare=
	(case 
		when @tip='RE' and (@subtip='PN' or @subtip='PV' or @subtip='PX'/*PX->subtip de plata avans*/) then 'PF'
		when @tip='RE' and @subtip='IX'/*IX->subtip de incasare avans*/ then 'IB'
		when @tip='RE' and @subtip in ('PA', 'PE') then 'PD'
		when @tip='RE' and @subtip in ('IA', 'IE') then 'ID'
		when @tip='EF' and @subtip='PT' or @subtip='PF' or @subtip='PV' and abs(@suma_valuta)>=0.01 then 'PF' 
		when @tip='EF' and @subtip='IT' or @subtip='IB' or @subtip='IV' and abs(@suma_valuta)>=0.01 then 'IB' 
		else @subtip 
	end)

if @plata_incasare in ('IB','PF') and isnull(@factura,'')<>'' --and @bugetari=1
	and exists (select 1 from sysobjects where [type]='P' and [name]='FacturiPeConturi')
Begin
	if object_id('tempdb..#facturiPeConturi') is not null
		drop table #facturiPeConturi
	create table #facturiPeConturi (tert varchar(13))
	exec CreazaDiezFacturi @numeTabela='#facturiPeConturi'

	if @parXML.value('(/*/*/@tipOperatiune)[1]','varchar(2)') IS NULL
		set @parXML.modify ('insert attribute tipOperatiune {sql:variable("@plata_incasare")} into (/row/row)[1]')
	else 
		set @parXML.modify('replace value of (/row/row/@tipOperatiune)[1] with sql:variable("@plata_incasare")')

	exec FacturiPeConturi @sesiune=@sesiune, @parXML=@parXML output
	if exists (select 1 from #facturiPeConturi where nr_cont_fact>1)
		set @facturiPeConturi=1
End

--pentru IB si PF, daca nu s-a introdus factura se apeleaza MACHETA PENTRU INCASARI/PLATI FACTURI SELECTIV
if @tip in ('RE','EF','DR','DE') and @subtip not in ('PX','IX')/*pentru avansuri nu apelam macheta de incasari/plati facturi selectv*/ 
	and @plata_incasare in ('IB','PF') and (isnull(@factura,'')='' or @facturiPeConturi=1) and @ptupdate<>1 and @apelDinProcedura=0
begin 
	set @dateInitializare=
	(
		select @plata_incasare as tipOperatiune, RTRIM(@tert) as tert, convert(char(10), @data, 101) as data, RTRIM(@lm) as lm, rtrim(@marcaGrp) as marca, rtrim(@decontGrp) as decont,
			case when isnull(@suma_valuta,0)<>0 then CONVERT(decimal(17,5),@suma_valuta) else CONVERT(decimal(17,5),@suma) end as suma, 
			RTRIM(@cont) as cont, RTRIM(@numar) as numar, @factura as factura, RTRIM(@jurnal) as jurnal, 
			(case when isnull(@parXML.value('(/*/row/@valuta)[1]', 'varchar(3)'),isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'),''))<>'' then @valuta else '' end) as valuta,
			(case when isnull(@parXML.value('(/*/row/@valuta)[1]', 'varchar(3)'),isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'),''))<>'' then CONVERT(decimal(12,5),@curs) else 0 end) as curs, 
			@detalii_antet as detalii_antet, @detalii as detalii, 
			@contcorespondent as contcorespondent,
			--date suplimentare necesare pentru efecte
			@tip as tipEd, rtrim(@efect_antet) as efect_antet/*, @ext_cont_in_banca as ext_cont_in_banca, @ext_serie_CEC as ext_serie_CEC, @ext_numar_CEC as ext_numar_CEC,
			@ext_cont_in_banca_tert as ext_cont_in_banca_tert, @ext_banca_tert ext_banca_tert, convert(char(10),@data_scadentei,101) as data_scadentei,
			convert(char(10),@ext_datadocument,101) as ext_datadocument*/
		for xml raw ,root('row')
	)

	SELECT 'Operatie pentru plati/incasari facturi.'  nume, 'PI' codmeniu, 'D' tipmacheta, 'RE' tip,'PI' subtip, 'O' fel,
		(SELECT @dateInitializare) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

	--pentru efecte este nevoie sa trimitem si tipul efectului ca data de initializare	
	if @tip='EF'
	begin
		declare @tipefect varchar(1)
		set @tipefect=rtrim(LEFT(@plata_incasare,1))
		if @parXML.value('(/row/@tipefect)[1]', 'varchar(2)') is not null                          
			set @parXML.modify('replace value of (/row/@tipefect)[1] with sql:variable("@tipefect")')
		else
			set @parXML.modify ('insert attribute tipefect{sql:variable("@tipefect")} into (/row)[1]')

	--	citesc si aici contul pentru cazul in care nu s-a completat contul in macheta
		set @cont=isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'),'')
	end

	-- punem si subunitatea pentru a o avea in datele de antet (folositoare pt. tabul de note contabile)		
	if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
	else
		set @parXML.modify ('insert attribute subunitate{sql:variable("@sub")} into (/row)[1]') 
	
	--nrdocument
	if @parXML.value('(/row/@nrdocument)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@nrdocument)[1] with sql:variable("@cont")') 
	else
		set @parXML.modify ('insert attribute nrdocument {sql:variable("@cont")} into (/row)[1]') 			
	-- pt initializare
	select @parXML for xml raw('dateAntet'), root('Mesaje')

	set @docXMLIaPozplin='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tip)+'" cont="'+rtrim(@cont)+'" data="'+convert(char(10), @data, 101)+'" '
		+(case when @tip='EF' then 'tert="'+rtrim(@tert)+'" tipefect="'+rtrim(LEFT(@plata_incasare,1))+'" efect="'+rtrim(@efect_antet)+'" ' else '' end)
		+'/>'	
	exec wIaPozplin @sesiune=@sesiune, @parXML=@docXMLIaPozplin
			
	return
end	

--pentru subtip='IR'- incasare proforma, apelez procedura pentru tratare proforme
if @subtip='IR'
begin
	exec wOPIncasareProforme @sesiune=@sesiune, @parXML=@parXML
	
	-- punem si subunitatea pentru a o avea in datele de antet (folositoare pt. tabul de note contabile)		
	if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
	else
		set @parXML.modify ('insert attribute subunitate{sql:variable("@sub")} into (/row)[1]') 
	
	--nrdocument
	if @parXML.value('(/row/@nrdocument)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@nrdocument)[1] with sql:variable("@cont")') 
	else
		set @parXML.modify ('insert attribute nrdocument {sql:variable("@cont")} into (/row)[1]') 			

	-- pt initializare
	select @parXML for xml raw('dateAntet'), root('Mesaje')

	set @docXMLIaPozplin='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tip)+'" cont="'+rtrim(@cont)+'" data="'+convert(char(10), @data, 101)+'"/>'	
	exec wIaPozplin @sesiune=@sesiune, @parXML=@docXMLIaPozplin
	return
end

--pentru subtip=PA (Plata decont)/IA (Restituire decont), apelez operatia de REPARTIZARE SUME DECONTATE CA PLATA DECONT si eventual restituire decont (daca sold decont pozitiv) pe indicatori.
if @bugetari=1 and @subtip in ('PA','IA') and @suma=0 and exists (select 1 from deconturi where Subunitate=@sub and marca=@marcaGrp and decont=@decontGrp and Decontat<>0)
begin
	set @dateInitializare=
	(
		select @plata_incasare as tipOperatiune, convert(char(10), @data, 101) as data, RTRIM(@lm) as lm, rtrim(@marcaGrp) as marca, rtrim(@decontGrp) as decont,
			case when isnull(@suma_valuta,0)<>0 then CONVERT(decimal(17,5),@suma_valuta) else CONVERT(decimal(17,5),@suma) end as suma, 
			RTRIM(@cont) as cont, RTRIM(@numar) as numar, 
			(case when isnull(@parXML.value('(/*/row/@valuta)[1]', 'varchar(3)'),isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'),''))<>'' then @valuta else '' end) as valuta,
			(case when isnull(@parXML.value('(/*/row/@valuta)[1]', 'varchar(3)'),isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'),''))<>'' then CONVERT(decimal(12,5),@curs) else 0 end) as curs, 
			@detalii_antet as detalii_antet, @detalii as detalii
		for xml raw ,root('row')
	)

	SELECT 'Operatie pentru repartizare plata decont.'  nume, 'PI' codmeniu, 'D' tipmacheta, 'DE' tip, 'RD' subtip, 'O' fel,
		(SELECT @dateInitializare) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

	-- punem si subunitatea pentru a o avea in datele de antet (folositoare pt. tabul de note contabile)		
	if @parXML.value('(/row/@subunitate)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@subunitate)[1] with sql:variable("@sub")') 
	else
		set @parXML.modify ('insert attribute subunitate{sql:variable("@sub")} into (/row)[1]') 
	
	--nrdocument
	if @parXML.value('(/row/@nrdocument)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@nrdocument)[1] with sql:variable("@cont")') 
	else
		set @parXML.modify ('insert attribute nrdocument {sql:variable("@cont")} into (/row)[1]') 			
	-- pt initializare
	select @parXML for xml raw('dateAntet'), root('Mesaje')

	set @docXMLIaPozplin='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tip)+'" cont="'+rtrim(@cont)+'" data="'+convert(char(10), @data, 101)+'" '+'/>'	
	exec wIaPozplin @sesiune=@sesiune, @parXML=@docXMLIaPozplin
			
	return
end

--Am mutat apelul wScriuPozplinSP inainte de wScriuPlin - sa se excute wScriuPlin si daca exista wScriuPozplinSP. De regula wScriuPozplinSP doar modifica @parXML.
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozplinSP')
	exec wScriuPozplinSP @sesiune, @parXML output

if exists (select * from sysobjects where name ='wScriuPlin') 
begin
	exec wScriuPlin @sesiune, @parXML OUTPUT
end
else /*Incepe Vechiul wScriuPozplin de baza*/
begin
	begin try
		--BEGIN TRAN
		SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
	
		set @eroare=dbo.wfValidarePozplin(@parXML)
	
		if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
		begin
			set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
			raiserror(@mesaj, 11, 1)
		end

		exec luare_date_par 'GE','REPSUMEF',0,@RepSumeF output,''
		exec luare_date_par 'GE','EXCEP419',@ExcepAv output,0,''
		exec luare_date_par 'GE','CFURNAV',0,0,@CtAvFurn output
		exec luare_date_par 'GE','CBENEFAV',0,0,@CtAvBen output
		if @CtAvFurn='' set @CtAvFurn='409'
		if @CtAvBen='' set @CtAvBen='419'
	
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

		set @jurnalProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='JURNAL'), '')
		set @contProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CONTPLIN'), '')

		--@lista_lm va fi 1 daca utilizatorul curent are atasate locuri de munca in prorpietati, 0 altfel
		select @lista_lm=dbo.f_arelmfiltru(@userASiS)
	
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
		declare crspozplin cursor for
		select 
		idPozPlin,
		isnull(tip_antet, '') as tip, 
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
			idPozPlin int '@idPozPlin',

			detalii xml 'detalii',
			tip_antet char(2) '../@tip', 
			cont_antet varchar(40) '../@cont', 
			data_antet datetime '../@data', 
			marca_antet char(6) '../@marca', 
			decont_antet varchar(40) '../@decont', 
			tert_antet char(13) '../@tert', 
			efect_antet varchar(20) '../@efect',
			valuta_antet char(3) '../@valuta', 
			curs_antet float '../@curs', 
		
			ext_datadocument_antet datetime '../@ext_datadocument',--data la care beneficiarul a facut plata(se ia in calcul la calculul penalitatilor)
			ext_cont_in_banca_antet varchar(35) '../@ext_cont_in_banca',--campul cont_in_banca din extpozplin
			ext_serie_CEC_antet varchar(5) '../@ext_serie_CEC',--campul serie_CEC din extpozplin, utilizat pentru seria efectelor
			ext_numar_CEC_antet varchar(20) '../@ext_numar_CEC',--campul numar_CEC din extpozplin, utilizat pentru numarul efectelor
			ext_cont_in_banca_tert_antet varchar(35) '../@ext_cont_in_banca_tert',--campul cont_in_banca_tert din extpozplin, utilizat pentru contul efectelor
			ext_banca_tert_antet varchar(20) '../@ext_banca_tert',--campul banca_tert din extpozplin, utilizat pentru banca emitenta pentru efecte		
		
			cont_pozitii varchar(40) '@cont', 
			data_pozitii datetime '@data', 
			marca_pozitii char(6) '@marca', 
			decont_pozitii varchar(40) '@decont', 
			tert_pozitii char(13) '@tert', 
			efect_pozitii varchar(20) '@efect', 
			subtip char(2) '@subtip', 
			numar char(10) '@numar', 
			factura char(20) '@factura', 
			cont_corespondent varchar(40) '@contcorespondent', 
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

		open crspozplin
		fetch next from crspozplin into @idPozPlin,@tip, @cont, @data, @marca_antet, @decont_antet, @tert_antet, @efect_antet, 
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
--	mutat partea pentru incasari/plati facturi selectiv la inceput pentru a functiona daca se apeleaza wScriuPlin
		
			if (@tip='RE' and @subtip in ('IA') or @tip='DE' and left(@subtip, 1)='P') and @numar='' set @numar=@decont
			if @tip='EF' and left(@subtip, 1)='P' and @numar='' set @numar=@efect
			--IF @numar='' -- nu luam aici din plaja de IB definita in ED, deoarece acea plaja este utilizata in machetele 
			-- de generare chitante de incasare facturi, cum ar fi: operatia de incasare de pe macheta Avize, operatia de incasare din ASiSmobile
				-- ia din plaja

			set @op_furn=(case when left(@plata_incasare, 1)='P' and @plata_incasare<>'PS' or @Plata_incasare='IS' then 1 else 0 end)
			set @decont_efect=(case when @decont<>'' then @decont else @efect end)
		
			--in cazul in care pentru deconturi si efecte, nu se introduce contul corespondent sau suma, aceste informatii se iau din decont/efect

			if @cont_corespondent='' and @plata_incasare not in ('PF','PA','PS','IB','IA','IS') and @tip not in ('DE', 'EF') and @decont_efect<>''
			begin
				select @cont_corespondent=case when @cont_corespondent='' then cont else @cont_corespondent end,
					@suma= case when @suma=0 then sold else @suma end 
				from deconturi
				where @decont<>'' and subunitate=@sub and tip='T' and marca=@marca and decont=@decont
			
				select @cont_corespondent=case when @cont_corespondent='' then cont else @cont_corespondent end,
					@suma= case when @suma=0 then sold else @suma end 
				from efecte
				where @decont='' and @efect<>'' and subunitate=@sub and tip=(case when @op_furn=1 then 'P' else 'I' end) and tert=@tert and nr_efect=@efect
			end
		
			if @cont_corespondent='' and @subtip='PA' /*In caz implicit de plata avans sa puna 542*/
					set @cont_corespondent='542'

			-- daca se efectueaza o plata avans catre o marca, atunci se ia locul de munca corespunzator marcii respective
			if @tip='RE' and @subtip='PA' and ISNULL(@lm,'')='' and ISNULL(@marca,'')<>''
				 set @lm=(select MAX(loc_de_munca) from personal where Marca=@marca)
			 
			if ISNULL(@lm,'')='' 
			begin
				declare @lm_proprietate varchar(20)
				set @lm_proprietate=( select top 1 cod from lmfiltrare l where l.utilizator=@userASiS)
				if ISNULL(@lm_proprietate,'')<>''
					set @lm=@lm_proprietate
			end
		
			--daca se face PF sau IB si se completeaza factura, dar nu se completeaza suma, suma va fi preluata de pe factura
			if @plata_incasare in ('PF','IB') and ((isnull(@suma,0)=0 and @in_valuta=0)or (ISNULL(@suma_valuta,0)=0 and @in_valuta=1)) 
				and ISNULL(@factura,'')<>'' and isnull(@tert,'')<>''
			begin		
				if @in_valuta=1	
					select @suma_valuta=Sold_valuta from facturi where factura=@factura and tert=@tert	
				else
					select @suma=sold from facturi where factura=@factura and tert=@tert	
			end
		
			while abs(case when @in_valuta=1 then @suma_valuta else @suma end)>=0.01
			begin
				select @factura_poz=@factura, @cont_cor_poz=@cont_corespondent, 
					@sold_fact=@suma, @sold_valuta_fact=@suma_valuta, @nr_poz_out=@numar_pozitie
				-- Ghita, 24.05.2012: vom merge totdeauna pe tabela facturi (vezi si wACFacturi)
				--    daca se va reveni la fTerti se va face o tabela temporara de facturi pe locul de munca la intrare in ASiSria
				if 1=1 -- @lista_lm=0--daca utilizatorul nu are definite locuri de munca in proprietati, se va parcurge tabela facturi
				begin
					select top 1 @factura_poz=factura, @cont_cor_poz=(case when @cont_cor_poz='' then cont_de_tert else @cont_cor_poz end), 
						@sold_fact=sold, @sold_valuta_fact=sold_valuta
					from facturi
						left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=Loc_de_munca 
					where @plata_incasare in ('PF', 'IB') and @factura='' and @numar_pozitie=0 
						and @subtip not in ('PX','IX') --pentru subtipurile specifice plati/incasari AVANS sa nu se ia factura din facturi					
						and (case when @in_valuta=1 then @suma_valuta else @suma end)>=0.01
						and subunitate=@sub and tip=(case when @op_furn=1 then 0x54 else 0x46 end) and tert=@Tert
						and (@RepSumeF not in (1, 3) or @Cont_corespondent='' or cont_de_tert=@Cont_corespondent)
						and (@RepSumeF<>2 or loc_de_munca like RTrim(@LM)+'%')
						and left(cont_de_tert, 3) not in ('408', '418')
						and (@ExcepAv=0 or cont_de_tert not like RTrim(case when @op_furn=1 then @CtAvFurn else @CtAvBen end)+'%')
						and (@in_valuta=0 or @valuta<>'' and valuta=@valuta)
						and (case when @in_valuta=1 then sold_valuta else sold end)>=0.01
						and (@lista_lm=0 or lu.cod is not null)
					order by data	
				end	
			
				else --daca utilizatorul are definite locuri de munca in proprietati, se va parcurge tabela returnata 
					 --de fFacturiCen(de unde vin date filtrate pe locurile de munca pe care are drept utilizatorul)
				begin
					declare @tiptert varchar(1), @parXMLFact xml
					set @tiptert=(case when @op_furn=1 then 'F' else 'B' end)

					/* se preiau datele in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturiCen */
					if object_id('tempdb..#pfacturi') is not null 
						drop table #pfacturi
					create table #pfacturi (subunitate varchar(9))
					exec CreazaDiezFacturi @numeTabela='#pfacturi'
					set @parXMLFact=(select @tiptert as furnbenef, 1 as cen, rtrim(@tert) as tert, 1 as grfactura for xml raw)
					exec pFacturi @sesiune=null, @parXML=@parXMLFact

					select top 1 @factura_poz=factura, @cont_cor_poz=(case when @cont_cor_poz='' then cont_factura else @cont_cor_poz end), 
						@sold_fact=sold, @sold_valuta_fact=sold_valuta
					from #pfacturi
					--from dbo.fFacturiCen(@tiptert, '01/01/1901', '01/01/2099',@tert, null, 0, 1, null, 0, 0, null)
					where @plata_incasare in ('PF', 'IB') and @factura='' and @numar_pozitie=0 
						and (case when @in_valuta=1 then @suma_valuta else @suma end)>=0.01
						and subunitate=@sub 
						and (@RepSumeF not in (1, 3) or @Cont_corespondent='' or cont_factura=@Cont_corespondent)
						and (@RepSumeF<>2 or loc_de_munca like RTrim(@LM)+'%')
						and left(cont_factura, 3) not in ('408', '418')
						and (@ExcepAv=0 or cont_factura not like RTrim(case when @op_furn=1 then @CtAvFurn else @CtAvBen end)+'%')
						and (@in_valuta=0 or @valuta<>'' and valuta=@valuta)
						and (case when @in_valuta=1 then sold_valuta else sold end)>=0.01
					order by data
				end
				--pentru avansuri, se va da automat un numar unic pe tert de factura: AV1,AV2...AVn
				if isnull(@factura_poz,'')='' and @plata_incasare in ('PF', 'IB')
					select top 1 @factura_poz='AV'+convert(varchar(20),isnull(max(substring(rtrim(ltrim(factura)),3,len(rtrim(ltrim(factura)))-2)),0)+1) 
					from facturi 
					where subunitate=@sub and tert=@tert and factura like 'AV%' and isnumeric(substring(rtrim(ltrim(factura)),3,len(rtrim(ltrim(factura)))-2))>0
			
				if @in_valuta=1
				begin
					set @suma_valuta_poz=(case when abs(@suma_valuta)-abs(@sold_valuta_fact)>=0.01 then @sold_valuta_fact else @suma_valuta end)
					set @suma_valuta=@suma_valuta-@suma_valuta_poz
					set @suma_poz=0
				end
				else begin
					set @suma_poz=(case when abs(@suma)-abs(@sold_fact)>=0.01 then @sold_fact else @suma end)
					set @suma=@suma-@suma_poz
					set @suma_valuta_poz=0
				end

				--in cazul in care plata_incasare este PF sau IB, factura nu este consitutita ca factura in sistem 
				if @plata_incasare in ('PF', 'IB') and  @numar_pozitie=0 and (not exists (select factura from facturi where Factura=@factura and tert=@tert) or @factura='')
				begin
					if isnull(@cont_cor_poz,'')='' --daca nu este completat contul corespondent
						if @subtip in ('IX','PX')--daca suntem pe subtip de avans, contul corespondent se va lua din parametrii
						begin
							set @cont_cor_poz=(case when @op_furn=1 then @CtAvFurn else @CtAvBen end)
							if @cota_TVA=0 and @in_valuta=0
							begin
								set @cota_TVA=24.00
								set @suma_TVA=@suma_poz*24.00/124.00
							end
						end
						else--pentru PF si IB, se va lua contul corespondent din tabela de terti
							select @cont_cor_poz=(case when @op_furn=1 then Cont_ca_furnizor else Cont_ca_beneficiar end) 
							from terti where Subunitate=@sub and tert=@tert
				end	
			
			-------------------Start Modificari bugetari-------------------------		
			--	scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
			if @Bugetari='1' and 1=0
			begin 
				if @indbug=''--daca indicatorul nu a fost introdus de utilizator atunci il generam automat
					if left(@cont,1) in ('6','7')
						exec wFormezIndicatorBugetar @Cont=@cont,@Lm=@lm,@Indbug=@indbug output 
					else
						if @plata_incasare not in ('PF','IB')
							exec wFormezIndicatorBugetar @Cont=@cont_cor_poz,@Lm=@lm,@Indbug=@indbug output
						else
							if @plata_incasare in ('PF','IB') 
							begin
							declare @OpFurn int, @CuFactura int
							set @OpFurn=(case when left(@Plata_incasare, 1)='P' and @Plata_incasare<>'PS' or @Plata_incasare='IS' then 1 else 0 end)
							set @CuFactura=(case when @Plata_incasare in ('PF','PR','PS','IB','IA','IS') then 1 else 0 end)
							set @indbug= (select isnull(substring(Comanda,21,20), '') 
								from facturi where @CuFactura=1 and tip=(case when @OpFurn=1 then 0x54 else 0x46 end) 
									and tert=@Tert and factura=@factura_poz)
							end 
					set @comanda_bugetari=convert(char(20),@comanda)+@indbug
			end
			--------------------Stop Modificari Bugetari-----------------------------	
			
			------------------start formare parametru de tip xml pentru procedura de scrierepozplin-----------------
			declare @parXmlPozplin xml,@ext_datadocumentS char(10),@data_scadenteiS char(10),@data_expirariiS char(10),@dataS char(10)
			set @dataS=CONVERT(char(10),@data,101)
			set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)
			set @ext_datadocumentS=CONVERT(char(10),@ext_datadocument,101)
		
			set @parXmlPozplin = CONVERT(xml, '<row>'+isnull(convert(varchar(max),@detalii),'') + '</row>')
			set @parXmlPozplin.modify ('insert 
						(
						attribute idPozPlin {sql:variable("@idPozPlin")},
						attribute tip {sql:variable("@tip")},
						attribute subtip {sql:variable("@subtip")},
						attribute numar {sql:variable("@numar")},
						attribute data {sql:variable("@dataS")},
						attribute tert {sql:variable("@tert")},
						attribute factura {sql:variable("@factura_poz")},
						attribute cont {sql:variable("@cont")},
						attribute plata_incasare {sql:variable("@plata_incasare")},
						attribute cont_corespondent {sql:variable("@cont_cor_poz")},					
						attribute suma {sql:variable("@suma_poz")},
						attribute valuta {sql:variable("@valuta")},
						attribute curs {sql:variable("@curs")},
						attribute suma_valuta {sql:variable("@suma_valuta_poz")},										
						attribute cota_TVA {sql:variable("@cota_TVA")},
						attribute suma_tva {sql:variable("@suma_TVA")},
						attribute update {sql:variable("@ptupdate")},
						attribute explicatii {sql:variable("@explicatii")},
						attribute lm {sql:variable("@lm")},
						attribute comanda_bugetari {sql:variable("@comanda_bugetari")},
						attribute utilizator {sql:variable("@userASiS")},
						attribute numar_pozitie {sql:variable("@nr_poz_out")},
						attribute jurnal {sql:variable("@jurnal")} ,					
						attribute tipTVA {sql:variable("@tipTVA")} ,					
						attribute marca {sql:variable("@marca")} ,
						attribute decont_efect {sql:variable("@decont_efect")} ,
						attribute data_scadentei {sql:variable("@data_scadenteiS")},
						attribute ext_datadocument {sql:variable("@ext_datadocumentS")},
						attribute ext_cont_in_banca {sql:variable("@ext_cont_in_banca")},
						attribute ext_serie_CEC {sql:variable("@ext_serie_CEC")},
						attribute ext_numar_CEC {sql:variable("@ext_numar_CEC")},
						attribute ext_cont_in_banca_tert {sql:variable("@ext_cont_in_banca_tert")},
						attribute ext_banca_tert {sql:variable("@ext_banca_tert")}
						)					
						into (/row)[1]')
						--select CONVERT(varchar(max),@parXmlPozplin)
				------------------ stop formare parametru de tip xml pentru procedura de scrierepozplin-----------------
				exec wScriuPI @ParXmlPozplin=@parXmlPozplin
						
				if @tip=@tipGrp and @cont=@contGrp and @data=@dataGrp and (@tipGrp='DE' and @marca_antet=@marcaGrp and @decont_antet=@decontGrp or @tipGrp='EF' and @tert_antet=@tertGrp and @efect_antet=@efectGrp or @tipGrp not in ('DE', 'EF'))
					set @sir_numere_pozitii=@sir_numere_pozitii+(case when @sir_numere_pozitii<>'' then ';' else '' end)+ltrim(str(@nr_poz_out))
			end
	
			fetch next from crspozplin into @idPozPlin,@tip, @cont, @data, @marca_antet, @decont_antet, @tert_antet, @efect_antet, 
				@marca, @decont, @tert, @efect, @subtip, @numar, @factura, @cont_corespondent, @suma, @valuta, @curs, @suma_valuta, 
				@cota_TVA, @suma_TVA, @explicatii, @lm, @comanda, @indbug, @numar_pozitie, @jurnal,@tipTVA, @ptupdate, @data_scadentei,@ext_datadocument,
				@ext_cont_in_banca,@ext_serie_CEC,@ext_numar_CEC,@ext_cont_in_banca_tert,@ext_banca_tert, @detalii
			set @ft=@@FETCH_STATUS
		end
/*	
		set @docXMLIaPozplin='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tipGrp)+'" cont="'+rtrim(@contGrp)+'" data="'+convert(char(10), @dataGrp, 101)+'" '
			+(case when @tipGrp='DE' then 'marca="'+rtrim(@marcaGrp)+'" decont="'+rtrim(@decontGrp)+'" ' else '' end)
			+(case when @tipGrp='EF' then 'tert="'+rtrim(@tertGrp)+'" tipefect="'+rtrim(LEFT(@plata_incasare,1))+'" efect="'+rtrim(@efectGrp)+'" ' else '' end)/*+'numerepozitii="'+@sir_numere_pozitii+'"'*/+'/>'
	
		exec wIaPozplin @sesiune=@sesiune, @parXML=@docXMLIaPozplin 
*/		
		--COMMIT TRAN
	end try
	begin catch
		--ROLLBACK TRAN
		set @mesaj =ERROR_MESSAGE()+'(wScriuPozplin)'
	end catch
	--

	declare @cursorStatus int
	set @cursorStatus=CURSOR_STATUS('global', 'crspozplin')
	if @cursorStatus=1 
		close crspozplin 
	if @cursorStatus is not null 
		deallocate crspozplin 
	--	
	begin try 
		exec sp_xml_removedocument @iDoc 
	end try 
	begin catch end catch
end

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozplinSP2')    
	exec wScriuPozplinSP2 '', @sub, @tipGrp,@contGrp,@dataGrp,@parXML

if @fara_luare_date<>'1'
begin
	declare @tipptIa varchar(2),@dataPtIa datetime, @contPtIa varchar(40), @marcaPtIa varchar(6), @decontPtIa varchar(40), @tertPtIa varchar(13), @efectPtIa varchar(20), @tipefectPtIa varchar(2)
	select @tipptIa=@parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@dataPtIa=@parXML.value('(/row/@data)[1]', 'datetime'),
		@contPtIa=@parXML.value('(/row/@cont)[1]', 'varchar(40)'),
		@marcaPtIa=@parXML.value('(/row/@marca)[1]', 'varchar(6)'),
		@decontPtIa=@parXML.value('(/row/@decont)[1]', 'varchar(40)'),
		@tertPtIa=@parXML.value('(/row/@tert)[1]', 'varchar(20)'),
		@efectPtIa=@parXML.value('(/row/@efect)[1]', 'varchar(20)'),
		@tipefectPtIa=LEFT(@parXML.value('(/row/row/@subtip)[1]', 'varchar(20)'),1)

	SET @docXMLIaPozplin = '<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tipptIa)+'" cont="'+rtrim(@contPtIa)+'" data="'+convert(char(10), @dataPtIa, 101)+'" '
			+(case when @tipptIa='DE' then 'marca="'+rtrim(@marcaPtIa)+'" decont="'+rtrim(@decontPtIa)+'" ' else '' end)
			+(case when @tipptIa='EF' then 'tert="'+rtrim(@tertPtIa)+'" tipefect="'+rtrim(@tipefectPtIa)+'" efect="'+rtrim(@efectPtIa)+'" ' else '' end)+'/>'
	exec wIaPozplin @sesiune=@sesiune, @parXML=@docXMLIaPozplin
end
if len(@mesaj)>0
	raiserror(@mesaj, 11, 1)