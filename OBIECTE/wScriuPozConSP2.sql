--***
if exists (select * from sysobjects where name ='wScriuPozConSP2')
drop procedure wScriuPozConSP2
go
--***
create procedure wScriuPozConSP2 @sesiune varchar(50), @parXML xml output 
as 
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @termen datetime, @termene datetime, @o_termene datetime, @data1 datetime, @lm char(9), @modplata char(8), @o_modplata char(8),
	@info1_antet char(13), @info2_antet float, @info3_antet float, @info4_antet float, @info5_antet float, @info6_antet char(20), 
	@numar_pozitie int, @cod char(20), @o_cod char(20), @cantitate float, @cant_aprobata float, @Tcantitate float, @cantitate_UM1 float, @cantitate_UM2 float, @cantitate_UM3 float, 
	@cod_intrare char(13), @cota_TVA float, @pret float, @Tpret float, @valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5), 
	@categ_pret int, @lot char(200), @data_expirarii datetime, @obiect varchar(20), 
	@info1_pozitii float, @info2_pozitii char(13), @info3_pozitii float, @info4_pozitii char(200), @info5_pozitii char(13), 
	@info6_pozitii datetime, @info7_pozitii datetime, @info8_pozitii float, @info9_pozitii float, @info10_pozitii float, @info11_pozitii float, 
	@info12_pozitii varchar(200), @info13_pozitii varchar(200), @info14_pozitii varchar(200), @info15_pozitii varchar(200), @info16_pozitii varchar(200), @info17_pozitii varchar(200), 
	@tipGrp char(2), @numarGrp char(20), @tertGrp char(20), @dataGrp datetime, @sir_numere_pozitii varchar(max), 
	@sub char(9), @CantAprob0BKBP int, @TermPeSurse int, @docXMLIaPozContract xml, @userASiS varchar(20), 
	@gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),
	@stare char(1), @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @subtip char(2), 
	@eroare xml,@contclient varchar(20),@procpen float,@update int,@Ttermen datetime,
	@Gluni int, @nr int, @scadenta int , @periodicitate int,@explicatii_pozitii varchar(50),@mesaj varchar(200),
	@contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),@gestdepozitBK varchar(20),
	@T1 float,@T2 float,@T3 float,@T4 float,@T5 float,@T6 float,@T7 float,@T8 float,@contractcor varchar(20),
	@T9 float,@T10 float,@T11 float,@T12 float,@jurnal varchar(20),@detalii xml,  @docDetalii xml, 
	@MULTICDBK int, -->setarea care permite operarea BK/BP cu acelasi cod pe mai multe pozitii
	@inchiriere int -->setarea care identifica cazul cu cantitatea constanta (ex. suprafata)

begin try
	--BEGIN TRAN
	 
		set @eroare = dbo.wfValidareContract(@parXML)
		begin
			set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
			if @mesaj<>''
			raiserror(@mesaj, 11, 1)
		end	
	
	--if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConSP')
	--begin
	--	exec wScriuConSP @sesiune=@sesiune, @parXML=@parXML output
	--	select 'Atentie: se apeleaza procedura wScriuConSP din procedura wScriuPozCon. Contactati distribuitorul aplicatiei pt. a '+
	--		'corecta functionarea aplicatiei(apelare wScriuPozConSP2).' as textMesaj, 'Functionare nerecomandata' as titluMesaj
	--	for xml raw,root('Mesaje')
	--end
	
	select	@update = isnull(@parXML.value('(/row/row/@update)[1]','int'),0),
			@Ttermen = isnull(@parXML.value('(/row/row/@Ttermen)[1]','datetime'),''),
			@gestProprietate='', @clientProprietate='', @lmProprietate='',@gestdepozitBK='',
			@jurnal =isnull(@parXML.value('(/row/@jurnal)[1]','varchar(20)'),'')
	
	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),
			@CantAprob0BKBP=isnull((case when Parametru='CNAZBKBP' then Val_logica else @CantAprob0BKBP end),0),
			@TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0),
			@MULTICDBK=isnull((case when Parametru='MULTICDBK' and Tip_parametru='UC' then Val_logica else @MULTICDBK end),0),
			@inchiriere=isnull((case when Parametru='CHIRIE' and Tip_parametru='UC' then Val_logica else @inchiriere end),0)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('CNAZBKBP','POZSURSE','MULTICDBK','CHIRIE'))

	declare @lCuTermene bit
	select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'  
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	
	select @gestProprietate=(case when cod_proprietate='GESTBK' then valoare else isnull(@gestProprietate,'') end), 
		@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else isnull(@clientProprietate,'') end), 
		@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else isnull(@lmProprietate,'') end),
		@gestdepozitBK=(case when cod_proprietate='GESTDEPBK' then valoare else isnull(@gestdepozitBK,'') end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTBK', 'CLIENT', 'LOCMUNCA','GESTDEPBK') and valoare<>''
	
	set @stare=0
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozconsp2 cursor for
	select detalii,tip, upper([contract]), data, 
	upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else ''/*@gestProprietate*/ end)) as gestiune, 
	upper(isnull(gestiune_primitoare, '')) as gestiune_primitoare, 
	upper((case when isnull(tert, '')<>'' then tert when tip in ('BF', 'BK', 'BP') then ''/*@clientProprietate*/ else '' end)) as tert, 
	upper(isnull(factura, '')) as factura, 
	--extcon
	isnull(contclient,'') as contclient,
	isnull(procpen,'') as procpen,
	isnull(contr_cadru,'') as contr_cadru,
	isnull(ext_camp4,'') as ext_camp4,
	isnull(ext_camp5,'1901-01-01') as ext_camp5,
	isnull(ext_modificari,'') as ext_modificari,
	isnull(ext_clauze,'') as ext_clauze,
	
	isnull(termen_pozitii, isnull(termen_antet, data)) as termen, 
	isnull(subtip, tip) as subtip, 
	isnull(scadenta,0) as scadenta,
	--termene
	isnull(termene, data) as termene,
	isnull(o_termene, '') as o_termene,
	isnull(data1,data) as data1,
	
	upper(case when isnull(lm,'')<>'' then lm else @lmProprietate end) as lm, 
	isnull(info1_antet, '') as info1_antet, isnull(info2_antet, 0) as info2_antet, isnull(info3_antet, 0) as info3_antet, 
	isnull(info4_antet, 0) as info4_antet, isnull(info5_antet, 0) as info5_antet, isnull(info6_antet, '') as info6_antet, 
	isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod, isnull(o_cod,'') as o_cod, 
	isnull(cantitate, 0) as cantitate, 
	isnull(cant_aprobata, 0) as cant_aprobata, 
	
	--termene
	isnull(Tcantitate, 0) as Tcantitate,
	isnull(cantitate_UM1, 0) as cantitate_UM1, isnull(cantitate_UM2, 0) as cantitate_UM2, isnull(cantitate_UM3, 0) as cantitate_UM3, 
	pret, 
	
	--termene
	Tpret,
	
	cota_TVA, 
	upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(explicatii_pozitii,'')as explicatii_pozitii, upper(isnull(explicatii,'')) as explicatii, 
	discount, isnull(punct_livrare, '') as punct_livrare, upper(isnull(modplata, '')) as modplata, isnull(o_modplata,'') as o_modplata, 
	(case when isnull(categ_pret_pozitii, 0)<>0 then categ_pret_pozitii when isnull(categ_pret_antet, 0)<>0 then categ_pret_antet else 0 end) /*isnull(categ_pret,0)*/ as categ_pret, 
	upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901') as data_expirarii, isnull(obiect, '') as obiect, 
	isnull(info1_pozitii, 0) as info1_pozitii, isnull(info2_pozitii, '') as info2_pozitii, 
	isnull(info3_pozitii, 0) as info3_pozitii, isnull(info4_pozitii, '') as info4_pozitii, isnull(info5_pozitii, '') as info5_pozitii, 
	--isnull(info6_pozitii, '01/01/1901') as info6_pozitii, 
	--isnull(info7_pozitii, '01/01/1901') as info7_pozitii, 
	isnull(info8_pozitii, 0) as info8_pozitii, isnull(info9_pozitii, 0) as info9_pozitii, isnull(info10_pozitii, 0) as info10_pozitii, isnull(info11_pozitii, 0) as info11_pozitii, isnull(info12_pozitii, '') as info12_pozitii, isnull(info13_pozitii, '') as info13_pozitii, isnull(info14_pozitii, '') as info14_pozitii, isnull(info15_pozitii, '') as info15_pozitii, isnull(info16_pozitii, '') as info16_pozitii, isnull(info17_pozitii, '') as info17_pozitii, 
	isnull(Gluni,0) as Gluni,	isnull(periodicitate,0) as periodicitate,
	isnull(contractcor,'') as contractcor
		
	from OPENXML(@iDoc, '/row/row') 
	WITH 
	(
		detalii xml '../detalii',
		tip char(2) '../@tip', 
		[contract] char(20) '../@numar',
		data datetime '../@data',
		gestiune_antet char(9) '../@gestiune',
		gestiune_primitoare char(13) '../@gestprim', 
		tert char(13) '../@tert',
		punct_livrare char(5) '../@punctlivrare', 
		modplata char(8) '@modplata', 
		o_modplata char(8) '@o_modplata', 
		factura char(20) '../@factura',
		contractcor varchar(50) '../@contractcor',
		categ_pret_antet int '../@categpret',
		--extcon
		contclient varchar(10) '../@contclient',
		procpen varchar(10) '../@procpen',
		contr_cadru varchar(50) '../@contr_cadru',
		ext_camp4 varchar(50) '../@ext_camp4',
		ext_camp5 datetime '../@ext_camp5',
		ext_modificari varchar(50) '../@ext_modificari',
		ext_clauze varchar(500)'../@ext_clauze',
		
		
		termen_antet datetime '../@termen',
		termen_pozitii datetime '@termen',
		subtip char(2) '@subtip',
		scadenta int '../@scadenta', 
		
		--termene
		termene datetime '@termene',
		o_termene datetime '@o_termene',
		
		data1 datetime '@data1',
		
		lm char(9) '../@lm',
		explicatii char(50) '../@explicatii', 
		info1_antet char(13) '../@info1', 
		info2_antet float '../@info2', 
		info3_antet float '../@info3', 
		info4_antet float '../@info4', 
		info5_antet float '../@info5', 
		info6_antet char(20) '../@info6', 
		numar_pozitie int '@numarpozitie',
		cod char(20) '@cod',
		o_cod char(20) '@o_cod',
		cantitate decimal(17, 5) '@cantitate',
		cant_aprobata decimal(17, 5) '@cant_aprobata',
		
		--termene
		Tcantitate decimal(17, 5) '@Tcantitate',
		cantitate_UM1 decimal(17, 5) '@cantitateum1',
		cantitate_UM2 decimal(17, 5) '@cantitateum2',
		cantitate_UM3 decimal(17, 5) '@cantitateum3',
		cota_TVA decimal(5, 2) '@cotatva', 
		gestiune_pozitii char(9) '@gestiune', 
		pret float '@pret', 
		
		--termene
		Tpret float '@Tpret',
		
		valuta char(3) '../@valuta', 
		curs float '@curs', 
		discount float '@discount', 
		categ_pret_pozitii int '@categpret', 
		lot char(200) '@lot', 
		data_expirarii datetime '@dataexpirarii', 
		obiect varchar(20) '@obiect', 
		explicatii_pozitii char(200) '@explicatii', 
		info1_pozitii float '@info1', 
		info2_pozitii char(13) '@info2', 
		info3_pozitii float '@info3', 
		info4_pozitii char(200) '@info4', 
		info5_pozitii char(13) '@info5', 
		--info6_pozitii datetime '@info6', 
		--info7_pozitii datetime '@info7', 
		info8_pozitii float '@info8', 
		info9_pozitii float '@info9', 
		info10_pozitii float '@info10', 
		info11_pozitii float '@info11', 
		info12_pozitii varchar(200) '@info12', 
		info13_pozitii varchar(200) '@info13', 
		info14_pozitii varchar(200) '@info14', 
		info15_pozitii varchar(200) '@info15', 
		info16_pozitii varchar(200) '@info16', 
		info17_pozitii varchar(200) '@info17',
		Gluni int '@Gluni',
		periodicitate int '@periodicitate'
	) 

	open crspozconsp2
	fetch next from crspozconsp2 into @detalii, @tip, @contract, @data, @gestiune, @gestiune_primitoare, 
		@tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari,
		@ext_clauze, @termen, @subtip, @scadenta,
		--termene
		@termene, @o_termene,@data1, 
		
		@lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet, 
		@numar_pozitie, @cod, @o_cod, @cantitate, @cant_aprobata, 
		
		--termene
		@Tcantitate, 
		
		@cantitate_UM1, @cantitate_UM2, @cantitate_UM3, 
		@pret, 
		
		--termene
		@Tpret,
		
		@cota_tva, @valuta, @curs,@explicatii_pozitii, @explicatii, @discount, @punct_livrare, 
		@modplata,@o_modplata, @categ_pret, @lot, @data_expirarii, @obiect, @info1_pozitii, 
		@info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii, 
		--@info6_pozitii, @info7_pozitii, 
		@info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii, 
		@info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, 
		@info17_pozitii, @Gluni, @periodicitate,@contractcor
		
	while @@fetch_status = 0
	begin 
		declare @nrPozXml int
		set @nrPozXml=isnull(@nrPozXml,0)+1
		
		if exists (select 1 from con c where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and @tip='BF' and Mod_plata<>@modplata)
			update con set Mod_plata=@modplata
			where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and @tip='BF'
		
		if @tip in ('BK') 
		begin 	
			declare @detalii_poz xml
			set @detalii_poz=@parXML.query('/row/row[sql:variable("@nrPozXml")]/detalii')
			--@parXML.value('(/row/row/@discount)[sql:variable("@nrPozXml")][1]','varchar(20)'),'')
			set @docDetalii= (select 'pozcon' as tabel, rtrim(@contract) contract, @tip tip, rtrim(@tert) tert, convert(varchar(10),@data,101) data, @sub subunitate, @cod cod
				, @detalii_poz	for xml raw, type )
			--select @docDetalii
			exec wScriuDetaliiSP2 @parXML=@docDetalii
		end
		if @sesiune='' select docDetalii=@docDetalii
	
		fetch next from crspozconsp2 into @detalii, @tip, @contract, @data, @gestiune, @gestiune_primitoare, 
			@tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze,@termen, @subtip, 
			@scadenta,
			--termene
			@termene, @o_termene,@data1,  
			
			@lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet, 
			@numar_pozitie, @cod, @o_cod, @cantitate, @cant_aprobata, 
			
			--termene
			@Tcantitate, 
			
			@cantitate_UM1, @cantitate_UM2, @cantitate_UM3, 
			@pret, 
			
			--termene
			@Tpret,
			
			@cota_tva, @valuta, @curs, @explicatii_pozitii,@explicatii, @discount, @punct_livrare, @modplata, @o_modplata, @categ_pret, 
			@lot, @data_expirarii, @obiect, @info1_pozitii, @info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii, 
			--@info6_pozitii, @info7_pozitii, 
			@info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii, 
			@info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, @info17_pozitii, 
			@Gluni, @periodicitate,@contractcor
	end
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	set @mesaj = ERROR_MESSAGE()+'(wScriuPozConSP2)'
end catch
--
declare @cursorStatus int
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozconsp2' and session_id=@@SPID )
if @cursorStatus=1 
	close crspozconsp2 
if @cursorStatus is not null 
	deallocate crspozconsp2 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

if ISNULL(@mesaj,'')!=''
	raiserror(@mesaj, 11, 1)
