--declare @sesiune varchar(50), @parXML xml
--set @parXML=convert(xml,N'<row numar="TEST" data="02/13/2012" tert="1125411" tip="IF"><row facturastinga="345676" facturadreapta="94014" contdeb="" contcred="" suma="0" cotatva="0" diftva="0" subtip="IF"/></row>')
--set @sesiune='1BA9B5CA2A9C2'
--***
ALTER procedure [yso].[wScriuPozadoc] @sesiune varchar(50), @parXML xml as

declare @tip_antet char(2), @numar char(8), @data datetime, @tert char(13), @factura_antet char(13), 
	@subtip char(2), @tip char(2), @factura_stinga char(20), @cont_deb char(13), @tert_benef char(13), @factura_dreapta char(20), @cont_cred char(13), 
	@suma float, @valuta char(3), @curs float, @suma_valuta float, @cota_TVA float, @suma_TVA float, @explicatii char(50), 
	@lm char(9), @comanda char(20), @numar_pozitie int, @jurnal char(3), @data_facturii datetime, @data_scadentei datetime, 
	@tip_antetGrp char(2), @numarGrp char(13), @dataGrp datetime, @ptupdate bit,@utilizator varchar(50),@diftva float,
	@sir_numere_pozitii varchar(max), @sub char(9), @userASiS varchar(20), @jurnalProprietate varchar(3), 
	@docXMLIaPozadoc xml, @eroare xml, @Bugetari int,  @indbug varchar(20), @comanda_bugetari varchar(40),
	@NrDocFisc varchar(20), @fXML xml, @tipPentruNr varchar(2),@ft int
begin try
	--BEGIN TRAN
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	set @eroare=dbo.wfValidarePozadoc(@parXML)

	declare @mesaj varchar(200)	
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
	begin
		set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
		raiserror(@mesaj, 11, 1)
	end	
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozadocSP' )
		exec wScriuPozadocSP @sesiune, @parXML output
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	set @jurnalProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='JURNAL'), '')

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozadoc cursor for
	select isnull(tip, '') as tip, isnull(numar, '') as numar, isnull(data, '01/01/1901') as data, 
	upper(isnull(tert_antet, '')) as tert_antet, upper(isnull(factura_antet, '')) as factura_antet, 
	isnull(subtip, '') as subtip, upper(isnull(factura_stinga, '')) as factura_stinga, ISNULL(cont_deb, '') as cont_deb, 
	upper(isnull(tert_benef, '')) as tert_benef, upper(isnull(factura_dreapta, '')) as factura_dreapta, ISNULL(cont_cred, '') as cont_cred, 
	isnull(suma, 0) as suma, upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(suma_valuta, 0) as suma_valuta, 
	isnull(cota_TVA, 0) as cota_TVA, isnull(suma_TVA, 0) as suma_TVA, isnull(explicatii, '') as explicatii, 
	upper(isnull(lm, '')) as lm, upper(isnull(comanda, '')) as comanda, isnull(indbug, '') as indbug, isnull(numar_pozitie, 0) as numar_pozitie, isnull(jurnal, '') as jurnal, 
	isnull(data_facturii, '01/01/1901') as data_facturii, isnull(data_scadentei, '01/01/1901') as data_scadentei,isnull(diftva,0),isnull(ptupdate,0)
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(2) '../@tip', 
		numar char(8) '../@numar', 
		data datetime '../@data', 
		tert_antet char(13) '../@tert', 
		factura_antet char(20) '../@factura', 
		subtip char(2) '@subtip', 
		factura_stinga char(20) '@facturastinga', 
		cont_deb char(13) '@contdeb', 
		tert_benef char(13) '@tertbenef', 
		factura_dreapta char(20) '@facturadreapta', 
		cont_cred char(13) '@contcred', 
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
		data_facturii datetime '@datafacturii', 
		data_scadentei datetime '@datascadentei',
		diftva float '@diftva',
		ptupdate bit '@update'
	)

	open crspozadoc
	fetch next from crspozadoc into @tip_antet, @numar, @data, @tert, @factura_antet, 
		@subtip, @factura_stinga, @cont_deb, @tert_benef, @factura_dreapta, @cont_cred, 
		@suma, @valuta, @curs, @suma_valuta, @cota_TVA, @suma_TVA, @explicatii, 
		@lm, @comanda, @indbug, @numar_pozitie, @jurnal, @data_facturii, @data_scadentei,@diftva,@ptupdate
	
	select @tip_antetGrp=@tip_antet, @numarGrp=@numar, @dataGrp=@data, @sir_numere_pozitii=''
	set @ft=@@FETCH_STATUS
	while @ft=0
	begin
		if @jurnal='' set @jurnal=@jurnalProprietate
		set @comanda_bugetari=convert(char(20),@comanda)+isnull(@indbug,'')
			
		set @tip=(case when @subtip='FV' and abs(@suma_valuta)>=0.01 then 'FF' when @subtip='BV' and abs(@suma_valuta)>=0.01 then 'FB' else @subtip end)
		
		/*if @numar=''
			set @numar=(case when @tip in ('FF','SF','CB') then @factura_dreapta else @factura_stinga end)*/
		
		if @factura_antet='' and @ptupdate='0' and @tip='IF' 
		begin
				set @tipPentruNr='AP' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
				exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
				set @factura_antet=@NrDocFisc 
		end
		if @numar='' or @numar=null and @ptupdate='0' and @tip='IF' 
		begin
				set @tipPentruNr='AD' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"AD"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
				exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
				set @numar=@NrDocFisc
		end
		if @factura_stinga='' and @tip in ('FB', 'IF', 'CO', 'C3', 'CF')
			set @factura_stinga=@factura_antet
		if @factura_dreapta='' and @tip in ('FF', 'FF', 'CB')
			set @factura_dreapta=@factura_antet		
		if @ptupdate='0'
		begin --sold/(1+(tva11+tva22)/val)
		    select @suma=valoare, @suma_tva=tva_22  from doc where subunitate='1' and tip='AP' and numar=@factura_dreapta 
			select @cota_TVA=Cota_TVA from pozdoc where subunitate='1' and tip='AP' and numar=@factura_dreapta 
		end
		
		----->>>>> start cod formare parametru xml pentru procedurile de scriere documente<<<<-----
		declare @parXmlpozadoc xml,@data_facturiiS char(10),@data_scadenteiS char(10),@data_expirariiS char(10),@dataS char(10)
		set @dataS=CONVERT(char(10),@data,101)
		set @data_facturiiS=CONVERT(char(10),@data_facturii,101)
		set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)
		
		if isnull(@numar,'')='' 
			raiserror('wScriuPozadoc: numar de document nealocat!! ',11,1)
		set @parXmlpozadoc = '<row/>'
		set @parXmlpozadoc.modify ('insert 
					(
					attribute tip {sql:variable("@tip")},
					attribute subtip {sql:variable("@subtip")},
					attribute numar {sql:variable("@numar")},
					attribute data {sql:variable("@dataS")},
					attribute tert {sql:variable("@tert")},
					attribute factura_stinga {sql:variable("@factura_stinga")},
					attribute cont_deb {sql:variable("@cont_deb")},
					attribute factura_dreapta {sql:variable("@factura_dreapta")},
					attribute cont_cred {sql:variable("@cont_cred")},
					attribute suma {sql:variable("@suma")},
					attribute valuta {sql:variable("@valuta")},
					attribute curs {sql:variable("@curs")},
					attribute suma_valuta {sql:variable("@suma_valuta")},	
					attribute cota_TVA {sql:variable("@cota_TVA")},
					attribute suma_tva {sql:variable("@suma_TVA")},
					attribute explicatii {sql:variable("@explicatii")},
					attribute numar_pozitie {sql:variable("@numar_pozitie")},					
					attribute update {sql:variable("@ptupdate")},
					attribute tert_benef {sql:variable("@tert_benef")},
					attribute lm {sql:variable("@lm")},
					attribute comanda_bugetari {sql:variable("@comanda_bugetari")},
					attribute utilizator {sql:variable("@userASiS")},
					attribute jurnal {sql:variable("@jurnal")} ,	
					attribute data_scadentei {sql:variable("@data_scadenteiS")},
					attribute data_facturii {sql:variable("@data_facturiiS")},
					attribute diftva {sql:variable("@diftva")}					
					)					
					into (/row)[1]')		
		--->>>>stop cod formare parametru xml pentru procedurile de scriere documente<<<<-----
		--select @parXmlpozadoc
		exec wscriuAD @parXmlpozadoc
		
		-------------------Start Modificari bugetari-------------------------		
		if @Bugetari='1' 
		begin 
			if @indbug='' --daca indicatorul nu a fost introdus de utilizator atunci il generam automat
				if left(@cont_deb,1)in ('6') and @tip='FF'
					exec wFormezIndicatorBugetar @Cont=@cont_deb,@Lm=@lm,@Indbug=@indbug output 	  
			set @comanda_bugetari=convert(char(20),@comanda)+@indbug
			update pozadoc set comanda=@comanda_bugetari where subunitate=@sub and tip=@tip and numar_document=@numar and data=@data and numar_pozitie=@numar_pozitie
		end
		--------------------Stop Modificari Bugetari---------------------------
		
		if @tip_antet=@tip_antetGrp and @numar=@numarGrp and @data=@dataGrp 
			set @sir_numere_pozitii=@sir_numere_pozitii+(case when @sir_numere_pozitii<>'' then ';' else '' end)+ltrim(str(@numar_pozitie))
	
		fetch next from crspozadoc into @tip_antet, @numar, @data, @tert, @factura_antet, 
			@subtip, @factura_stinga, @cont_deb, @tert_benef, @factura_dreapta, @cont_cred, 
			@suma, @valuta, @curs, @suma_valuta, @cota_TVA, @suma_TVA, @explicatii, 
			@lm, @comanda, @indbug, @numar_pozitie, @jurnal, @data_facturii, @data_scadentei,@diftva,@ptupdate
		set @ft=@@FETCH_STATUS
	end
	
	set @docXMLIaPozadoc='<row subunitate="'+rtrim(@sub)+'" tip="'+rtrim(@tip_antetGrp)+'" numar="'+rtrim(@numar)+'" data="'+convert(char(10), @dataGrp, 101)+'" '/*+'numerepozitii="'+@sir_numere_pozitii+'"'*/+'/>'
	exec wIaPozadoc @sesiune=@sesiune, @parXML=@docXMLIaPozadoc 
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()
		--set @eroare='<error coderoare="1" msgeroare="'+ERROR_MESSAGE()+'"/>'
		--select @eroare FOR XML RAW	
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspozadoc' and session_id=@@SPID )
if @cursorStatus=1 
	close crspozadoc 
if @cursorStatus is not null 
	deallocate crspozadoc 
--	
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch 
end catch

GO

