/****** Object:  StoredProcedure [dbo].[wScriuPozdocSP]    Script Date: 05/11/2012 12:16:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop procedure [dbo].[wScriuPozdocSP]
go
create procedure [dbo].[wScriuPozdocSP] @sesiune varchar(50), @parXML xml OUTPUT as

declare @tip char(2), @numar char(8), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @data_facturii datetime, @data_scadentei datetime, @lm char(9),  @lmprim char(9), 
	@numar_pozitie int, @cod char(20), @codcodi char(20), @cantitate float, @pret_valuta float, @cod_intrare char(13), @codiPrim varchar(13),
	@pret_amanunt float, @cota_TVA float, @suma_tva float, @tva_valuta float, @tipTVA int, @comanda char(20), @cont_stoc char(13), @pret_stoc float, 
	@valuta char(3), @curs float, @locatie char(30), @contract char(20), @lot char(13), @data_expirarii datetime, 
	@explicatii char(30), @jurnal char(3), @cont_factura char(13), @discount float,@discsuma float, @punct_livrare char(5), 
	@barcod char(30), @cont_corespondent char(13), @DVI char(25), @categ_pret int, @cont_intermediar char(13), @cont_venituri char(13), @TVAnx float, 
	@nume_delegat char(30), @serie_buletin char(10), @numar_buletin char(10), @eliberat_buletin char(30), @mijloc_transport char(30), @nr_mijloc_transport char(20), @data_expedierii datetime, @ora_expedierii char(6), @observatii char(200), @punct_livrare_expeditie char(5), 
	@IesFaraStoc int, @tipGrp char(2), @numarGrp char(8), @dataGrp datetime, @sir_numere_pozitii varchar(max), @sub char(9), @docXMLIaPozdoc xml, 
	@userASiS varchar(20), @gestProprietate varchar(20), @gestprimProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3), @categPretProprietate varchar(20), 
	@stare int, @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @codi_stoc char(13), @stoc float, @cant_desc float, @nr_poz_out int, 
	@eroare xml, @mesaj varchar(254), @Bugetari int, @TabelaPreturi int, @indbug varchar(20), @comanda_bugetari varchar(40), @accizecump float, @ptupdate int, 
	@NrAvizeUnitar int ,@prop1 varchar(20),@prop2 varchar(20),@serie varchar(20),@subtip varchar(2),@termenscadenta int,@Serii int,
	@zilescadenta int,@facturanesosita bit,@aviznefacturat bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(20),@suprataxe float,@o_suma_TVA float, 
	@rec_factura_existenta char(8), @data_rec_fact_exist datetime, @fetch_crspozdoc int, @TEACCODI int
	/*startsp*/,@pret_amanunt_dec decimal(17,5)/*stopsp*/
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
exec luare_date_par 'GE','PRETURI', @TabelaPreturi output, 0, ''
exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''
exec luare_date_par 'UC', 'TEACCODI', @TEACCODI output, 0, ''
exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output

begin try	
	---->>>>>>start cod specific prestari pe receptii<<<<<--------------
set @subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '')
if @subtip='RP' and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPrestariReceptii' and SCHEMA_NAME([uid])='yso')--in cazul in care suntem pe subtip specific prestarilor toata treaba se face in procedura wScriuPrestariReceptii
	exec yso.wScriuPrestariReceptii @sesiune,@parxml --procedura care face repartizarea prestarilor
	
else
begin	
	---->>>>>>stop cod specific prestari pe receptii<<<<<--------------
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='yso_wScriuPozdocSP')
		exec yso_wScriuPozdocSP @sesiune, @parXML output
	
	-- aceasta apelare se va modifica - se vor folsi proceduri de validare, care vor da direct raiserror. 
	set @eroare = dbo.wfValidarePozdoc(@parXML)
	if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
		begin
		set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
		raiserror(@mesaj, 11, 1)
		end
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	select @gestProprietate='', @gestprimProprietate='', @clientProprietate='', @lmProprietate='', @jurnalProprietate=''
	select @gestProprietate=(case when cod_proprietate='GESTIUNE' then valoare else @gestProprietate end), 
		@gestprimProprietate=(case when cod_proprietate='GESTPRIM' then valoare else @gestprimProprietate end), 
		@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else @clientProprietate end), 
		@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else @lmProprietate end), 
		@jurnalProprietate=(case when Cod_proprietate='JURNAL' then Valoare else @jurnalProprietate end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA', 'JURNAL') and valoare<>''
	print 'ajung1'
	if ISNULL(@stare,'')=''
		set @stare=3
		
	exec luare_date_par 'GE', 'FARASTOC', @IesFaraStoc output, 0, ''

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	--fetch next from crspozdoc into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert, 
	--	@factura, @data_facturii, @data_scadentei, @lm,@lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,
	--	@zilescadenta,@facturanesosita,@aviznefacturat,
	--	@cod_intrare, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc, 
	--	@valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount, 
	--	@punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx, 
	--	@accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, 
	--	@nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,
	--	@prop1,@prop2,@serie,@subtip,@o_suma_TVA
		
	select @tip=tip, @numar=upper(numar), @data=data, 
	@gestiune=upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else '' end)), 
	@gestiune_primitoare=(case when isnull(gestiune_primitoare_pozitii, '')<>'' then gestiune_primitoare_pozitii when isnull(gestiune_primitoare_antet, '')<>'' then gestiune_primitoare_antet else '' end), 
	@tert=upper((case when isnull(tert, '')<>'' then tert when tip in ('AP', 'AS') then @clientProprietate else '' end)), 
	@factura=upper(isnull(factura_pozitii, isnull(factura_antet, ''))), 
	@data_facturii=isnull(datafact, isnull(data, '01/01/1901')) ,
	@data_scadentei= isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))), 
	@lm=(case when isnull(lm_pozitii, '')<>'' then lm_pozitii when isnull(lm_antet, '')<>'' then lm_antet else @lmProprietate end), 
	@lmprim=isnull(lmprim_antet, ''), 
	@numar_pozitie=isnull(numar_pozitie, 0), 
	@cod=upper(isnull(cod, '')),
	@codcodi=upper(isnull(codcodi,isnull(cod,''))),
	@cantitate=isnull(cantitate, 0), 
	@pret_valuta=pret_valuta, 
	@tiptva=isnull(tip_TVA,0), 
	
	@zilescadenta=zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta
	@facturanesosita=isnull(facturanesosita,0),--bifa de factura nesosita
	@aviznefacturat=isnull(aviznefacturat,0),--bifa de aviz nefacturat
	
	--upper(isnull(cod_intrare, '')) as cod_intrare, 
	@pret_amanunt=isnull(pret_amanunt, 0), 
	--cota_TVA, suma_TVA, TVA_valuta, 
	--upper(case when isnull(comanda_pozitii, '')<>'' then comanda_pozitii else isnull(comanda_antet, '') end) as comanda, 
	--(case when isnull(indbug_pozitii, '')<>'' then indbug_pozitii else isnull(indbug_antet, '') end) as indbug, 
	--isnull(cont_de_stoc, '') as cont_stoc, isnull(pret_de_stoc, 0) as pret_stoc, 
	
	-----datele, curs si valuta, completate in pozitii sunt mai tari decat cele din antet
	-----(totusi recomandat configurare pentru introducere curs si valuta din antet)
	@valuta=upper(isnull(isnull(valuta,valuta_antet),'')),
	@curs=convert(decimal(12,4),isnull(isnull(curs,curs_antet),0)),	

	--upper(isnull(locatie, '')) as locatie,
	@contract=upper((case when isnull(contract_pozitii, '')<>'' then contract_pozitii else isnull(contract_antet, '') end)), 
	--upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901'), 
	--(case when isnull(explicatii_pozitii, '')<>'' then explicatii_pozitii else isnull(explicatii_antet, '') end) as explicatii, 
	--(case when isnull(isnull(jurnal, jurnalantet),'')<>'' then isnull(jurnal, jurnalantet) else @jurnalProprietate end) as jurnal,
	--(case when isnull(cont_factura_pozitii, '')<>'' then cont_factura_pozitii else /*isnull(*/cont_factura_antet/*, '')*/ end) as cont_factura, 
	@discount=isnull(discount,0),
	@discsuma=disc_suma, 
	--(case when isnull(punct_livrare_pozitii, '')<>'' then punct_livrare_pozitii else isnull(punct_livrare_antet, '') end) as punct_livrare, 
	--isnull(barcod, '') as barcod, 
	--(case when isnull(cont_corespondent_pozitii, '')<>'' then cont_corespondent_pozitii when tip in ('AI', 'AE', 'AF') then /*isnull(*/cont_corespondent_antet/*, '')*/ else '' end) as cont_corespondent, 
	--isnull(dvi, '') as dvi,
	@categ_pret=isnull(categ_pozitii, isnull(categ_antet, 0))
	--/*isnull(*/cont_intermediar/*, '')*/ as cont_intermediar, 
	--isnull((case when isnull(cont_venituri_pozitii, '')<>'' then cont_venituri_pozitii else /*isnull(*/cont_venituri_antet/*, '')*/ end),'') as cont_venituri, 
	--isnull(tva_neexigibil_pozitii, tva_neexigibil_antet) as tva_neexigibil, 
	--isnull(accizecump, 0) as accizecump, 
	--upper(isnull(nume_delegat, '')) as nume_delegat, upper(isnull(serie_buletin, '')) as serie_buletin, 
	--isnull(numar_buletin, '') as numar_buletin, upper(isnull(eliberat_buletin, '')) as eliberat_buletin, 
	--upper(isnull(mijloc_transport, '')) as mijloc_transport, upper(isnull(nr_mijloc_transport, '')) as nr_mijloc_transport, 
	--isnull(data_expedierii, '01/01/1901') as data_expedierii, isnull(ora_expedierii, '000000') as ora_expedierii, 
	--isnull(observatii, '') as observatii, isnull(punct_livrare_expeditie, '') as punct_livrare_expeditie, 
	--isnull(ptupdate,0) as ptupdate ,
	--stare as stare,
	
	--isnull(prop1,'') as prop1,
	--isnull(prop2,'') as prop2,
	--isnull(serie,'') as serie,
	--isnull(subtip,'') as subtip,
	--o_suma_TVA
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(2) '../@tip', 
		numar char(8) '../@numar',
		data datetime '../@data',
		gestiune_antet char(9) '../@gestiune',
		gestiune_primitoare_antet char(13) '../@gestprim', 
		tert char(13) '../@tert',
		factura_antet char(20) '../@factura',
		datafact datetime '../@datafacturii',
		datascad datetime '../@datascadentei',
		lm_antet char(9) '../@lm',
		lmprim_antet char(9) '../@lmprim',
		comanda_antet char(20) '../@comanda', 
		indbug_antet char(20) '../@indbug', 
		cont_factura_antet char(13) '../@contfactura', 
		cont_corespondent_antet char(13) '../@contcorespondent', 
		cont_venituri_antet char(13) '../@contvenituri', 
		explicatii_antet char(30) '../@explicatii', 
		punct_livrare_antet char(5) '../@punctlivrare',
		categ_antet char(5) '../@categpret',
		tva_neexigibil_antet float '../@tvaneexigibil',
		contract_antet char(20) '../@contract', 
		nume_delegat char(30) '../@numedelegat', 
		serie_buletin char(10) '../@seriabuletin', 
		numar_buletin char(10) '../@numarbuletin', 
		eliberat_buletin char(30) '../@eliberat', 
		mijloc_transport char(30) '../@mijloctp', 
		nr_mijloc_transport char(20) '../@nrmijloctp', 
		data_expedierii datetime '../@dataexpedierii', 
		ora_expedierii char(6) '../@oraexpedierii', 
		observatii char(200) '../@observatii', 
		punct_livrare_expeditie char(5) '../@punctlivrareexped', 
		tip_TVA int '../@tiptva',
		zilescadenta int '../@zilescadenta',--zilele de scadenta->data_scadentei se va calcula din zilele de scadenta
		facturanesosita bit '../@facturanesosita',--bifa pentru facturi nesosite, dc este pusa atunci contul facturii va fi 408(furnizori-facturi nesosite)
		aviznefacturat bit '../@aviznefacturat',--bifa pentru avize nefacturate, dc este pusa atunci contul facturii va fi luat din parametrii(cont beneficiari avize nefacturate)
		jurnalantet char(3) '../@jurnal', 
		---cursul si valuta din antet
		valuta_antet varchar(3) '../@valuta' , 
		curs_antet varchar(14) '../@curs',
		
		stare smallint '../@stare',
		
		---pozitii-----
		numar_pozitie int '@numarpozitie',
		cod char(20) '@cod',
		codcodi char(20) '@codcodi',
		factura_pozitii char(20) '@factura',
		cantitate decimal(10, 5) '@cantitate',
		pret_valuta decimal(14, 5) '@pvaluta', 
		cod_intrare char(13) '@codintrare',
		pret_amanunt decimal(14, 5) '@pamanunt', 
		cota_TVA decimal(5, 2) '@cotatva', 
		suma_TVA decimal(15, 2) '@sumatva', 
		TVA_valuta decimal(15, 2) '@tvavaluta', 
		gestiune_pozitii char(9) '@gestiune', 
		gestiune_primitoare_pozitii char(13) '@gestprim', 
		lm_pozitii char(9) '@lm', 
		comanda_pozitii char(20) '@comanda', 
		indbug_pozitii char(20) '@indbug', 
		cont_de_stoc char(13) '@contstoc', 
		pret_de_stoc float '@pstoc', 
		valuta char(3) '@valuta', 
		curs float '@curs', 
		locatie char(30) '@locatie', 
		contract_pozitii char(20) '@contract', 
		lot char(13) '@lot', 
		data_expirarii datetime '@dataexpirarii', 
		explicatii_pozitii char(30) '@explicatii', 
		jurnal char(3) '@jurnal', 
		cont_factura_pozitii char(13) '@contfactura', 
		discount float '@discount',
		disc_suma float '@discsuma',
		punct_livrare_pozitii char(5) '@punctlivrare', 
		barcod char(30) '@barcod', 
		cont_corespondent_pozitii char(13) '@contcorespondent', 
		DVI char(25) '@dvi', 
		categ_pozitii int '@categpret', 
		cont_intermediar char(13) '@contintermediar', 
		cont_venituri_pozitii char(13) '@contvenituri',
		tva_neexigibil_pozitii float '@tvaneexigibil',
		accizecump float '@accizecump', 
		ptupdate int '@update' ,
		
		
		---proprietati pt serii
		prop1 char(20) '@prop1',
		prop2 char(20) '@prop2',
		serie char(20) '@serie',
		subtip char(20) '@subtip', 
		o_suma_TVA decimal(15, 2) '@o_sumatva' 
	)
	print 'ajung1'
	if year(@data_facturii)<1921
		set @data_facturii=@data --convert(char(10),GETDATE(),101)
	if YEAR(@data_scadentei)<1921
		set @data_scadentei=@data_facturii
	if @lm=''
		set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')
	
	--daca pe macheta exista campul zilescadenta atunci datascadentei se calculeaza din zilele scadenta, altfel sa ia campul data scadentei
	if @zilescadenta is not null 
		set @data_scadentei=DATEADD(day,@zilescadenta,@data)
	
	if CHARINDEX('|',@codcodi,1)>0 and @codcodi<>@cod
	begin
	set @cod=isnull((select substring(@codcodi,1,CHARINDEX('|',@codcodi,1)-1)),@cod)
	set @cod_intrare=isnull((select substring(@codcodi,CHARINDEX('|',@codcodi,1)+1,LEN(@codcodi))),@cod_intrare)
	end
	
	if @tip in ('AP', 'AS', 'AC') and (@pret_valuta is null or @pret_valuta=0) -- or @discount is null)
	begin
		--set @categ_pret=(case when isnull(@categ_pret,0)=0 then 1 else @categ_pret end)
		declare @dXML xml, @doc_in_valuta int
		set @dXML = '<row/>'
		set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
		--set @dXML.modify ('insert attribute data {sql:variable("@data")} into (/row)[1]')
		declare @dstr char(10)
		set @dstr=convert(char(10),@data,101)			
		set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')
		set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
		set @dXML.modify ('insert attribute comandalivrare {sql:variable("@contract")} into (/row)[1]')
		set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')
		set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)
		set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')
		if @pret_valuta=0 set @pret_valuta=null
		exec wIaPretDiscount @dXML, @pret_valuta output, @discount output
		
		select @pret_valuta=isnull(@pret_valuta, 0), @discount=isnull(@discount, 0), @discsuma=ISNULL(@discsuma,0)
	
		if @tip='AP' and @pret_valuta>=0.001 and @discsuma>=0.001 and @pret_valuta>@discsuma and @discount=0
		begin
			set @pret_valuta=@pret_valuta-@discsuma
			set @parXML.modify('replace value of (/row/row/@pvaluta)[1] with sql:variable("@pret_valuta")')
		end

		/*if @tip='TE' 
		begin
			if @gestProprietate<>'' and @gestiune=''
			--if @parXML.value('(/row/row/@gestiune)[1]', 'char(9)') is null
				set @parXML.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestProprietate")')
			if @gestprimProprietate<>'' and @gestiune_primitoare=''
			--if @parXML.value('(/row/row/@gestiune)[1]', 'char(9)') is null
				set @parXML.modify('replace value of (/row/@gestprim)[1] with sql:variable("@gestprimProprietate")')
		end*/
	end
	--print 'pam'+convert(varchar,@pret_amanunt)
	if @tip in ('TE') and abs(@pret_amanunt)<0.00001  
	begin  
		set @categPretProprietate=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestiune), @categ_pret)  
		set @pret_amanunt=isnull((select top 1 pret_cu_amanuntul from preturi where cod_produs=@cod and um=@categPretProprietate order by data_inferioara desc), 0)  
		declare @grupa varchar(13), @discmax int
		select @grupa=n.grupa from nomencl n where n.Cod=@cod
		
		if  @gestiune_primitoare='700' and @discount>0
			if @grupa=''
				select 'Atentie: nu este completat grupa pt acest articol. '
				+'Completati grupa pentru a valida discountul (wScriuPozConSP).' as textMesaj
				, 'Functionare nerecomandata' as titluMesaj
				for xml raw,root('Mesaje')
			else
			begin
				select top 1 @discmax=CASE ISNUMERIC(valoare) when 1 then CONVERT(int,replace(Valoare,',','')) else null end from proprietati pr 
					where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' and cod=@grupa
				if @discmax is null
					select 'Atentie: nu este configurat discountul maxim pt grupa acestui articol. '
					+'Configurati proprietatea DISCMAX pe grupa pentru a valida discountul (wScriuPozConSP).' as textMesaj
					, 'Functionare nerecomandata' as titluMesaj
					for xml raw,root('Mesaje')
				else
					if @discount>@discmax
						raiserror('Discountul introdus depaseste maximul de %d admis pe grupa articolului (wScriuPozConSP).',11,1,@discmax)
			end
		
		set @pret_amanunt=@pret_amanunt*(1-@discount/100)
		set @pret_amanunt_dec=@pret_amanunt
		set @parXML.modify('replace value of (/row/row/@pamanunt)[1] with sql:variable("@pret_amanunt_dec")')
		--print convert(varchar,@discount)
	end

	--select @parXML
	return 0
end
end try
begin catch
	set @mesaj ='wScriuPozdocSP:'+ERROR_MESSAGE()
end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

if len(@mesaj)>0
	raiserror(@mesaj, 11, 1)

