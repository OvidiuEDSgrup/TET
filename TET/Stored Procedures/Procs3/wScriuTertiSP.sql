--***

create procedure wScriuTertiSP @sesiune varchar(50), @parXML xml OUTPUT
as
declare @iDoc int, @Sub char(9), @AdrComp int, @CodTertCodFisc int, @ContFImpl char(13), @ContBImpl char(13), 
	@mesaj varchar(200), @tert char(13), @cod_fiscal char(16), @alt_tert char(13), @referinta int, @tabReferinta int, @mesajEroare varchar(100), 
	@UltTert int,@locTerti int ,@JudTerti int, @eroare int,@tip_tert char(1), @detalii xml, @docDetalii xml, @email varchar(2000), @dataAzi datetime, @TipTVAUnitate char(1)
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 
exec luare_date_par 'GE', 'ADRCOMP', @AdrComp output, 0, ''
exec luare_date_par 'GE', 'CFISCSUGE', @CodTertCodFisc output, 0, ''
exec luare_date_par 'GE', 'CONTFURN', 0, 0, @ContFImpl output   
exec luare_date_par 'GE', 'CONTBENEF', 0, 0, @ContBImpl output   
exec luare_date_par 'GE', 'LOCTERTI', @LocTerti output, 0, ''
exec luare_date_par 'GE', 'JUDTERTI', @JudTerti output, 0, ''

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#yso_xmlt') IS NOT NULL
	drop table #yso_xmlt

begin try
	select isnull(ptupdate, 0) as ptupdate, upper(ltrim(rtrim(tert))) tert, isnull(tert_vechi, tert) as tert_vechi, ltrim(rtrim(denumire)) denumire, 
		upper(ltrim(rtrim(cod_fiscal))) cod_fiscal, isnull(cod_fiscal_vechi, '') as cod_fiscal_vechi, 
		upper(ltrim(rtrim(localitate))) localitate, judet, tara, 
		ltrim(rtrim(adresa)) adresa, ltrim(rtrim(strada)) strada, ltrim(rtrim(numar)) numar, bloc, scara, apartament, cod_postal, 
		ltrim(rtrim(telefon_fax)) telefon_fax, ltrim(rtrim(banca)) banca, upper(ltrim(rtrim(cont_in_banca))) cont_in_banca, 
		decontari_valuta, grupa, cont_furnizor, cont_beneficiar, data_tert, categ_pret, 
		sold_maxim_beneficiar, discount, termen_livrare, termen_scadenta, reprezentant, functie_reprezentant, 
		lm, responsabil, info1, info2, info3, nr_ord_reg, tip_tert, neplatitor_de_tva, nomenclator_special, isnull(email,'') email, tiptva, o_tiptva, faravalidare, detalii
	into #yso_xmlt
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii',
		ptupdate int '@update', 
		tert char(13) '@tert', 
		tert_vechi char(13) '@o_tert', 
		denumire char(80) '@dentert', 
		cod_fiscal char(16) '@codfiscal', 
		cod_fiscal_vechi char(16) '@o_codfiscal', 
		localitate char(35) '@localitate', 
		judet char(20) '@judet', 
		tara char(20) '@tara', 
		adresa char(60) '@adresa', 
		strada char(30) '@strada', 
		numar char(8) '@numar', 
		bloc char(6) '@bloc', 
		scara char(5) '@scara', 
		apartament char(3) '@apartament', 
		cod_postal char(8) '@codpostal', 
		telefon_fax char(20) '@telefonfax', 
		banca char(20) '@banca', 
		cont_in_banca char(35) '@continbanca', 
		decontari_valuta int '@decontarivaluta', 
		grupa char(3) '@grupa', 
		cont_furnizor char(13) '@contfurn', 
		cont_beneficiar char(13) '@contben', 
		data_tert datetime '@datatert', 
		categ_pret int '@categpret', 
		sold_maxim_beneficiar float '@soldmaxben', 
		discount float '@discount', 
		termen_livrare int '@termenlivrare', 
		termen_scadenta int '@termenscadenta', 
		reprezentant char(30) '@reprezentant', 
		functie_reprezentant char(30) '@functiereprezentant', 
		lm char(9) '@lm', 
		responsabil char(30) '@responsabil', 
		info1 char(35) '@info1', 
		info2 char(35) '@info2', 
		info3 char(30) '@info3', 
		nr_ord_reg char(20) '@nrordreg', 
		tip_tert int '@tiptert', 
		neplatitor_de_tva int '@neplatitortva', 
		nomenclator_special int '@nomspec',
		email varchar(2000) '@email', -- mitz: am lasat 2000, pt. clientii care au nevoie(se poate mari coloana daca nu e replicare.
		tiptva char(1) '@tiptva',
		o_tiptva char(1) '@o_tiptva',
		faravalidare int '@faravalidare'
	)
	exec sp_xml_removedocument @iDoc 
	
	set @tert=@parXML.value('(/row/@tert)[1]','char(13)') 
	declare @judet varchar(20), @userASiS varchar(20), @contButiliz varchar(20)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	select @judet=isnull(nullif(@parXML.value('(/row/@judet)[1]','varchar(20)'),''),(select t.judet from terti t where t.Tert=@tert))
		,@contButiliz=coalesce(nullif(@parXML.value('(/row/@contben)[1]','varchar(20)'),'')
			,(select top 1 p.Valoare from proprietati p where p.Tip='UTILIZATOR' and p.Cod_proprietate='CONTBENEF' and p.Cod=@userASiS 
					and p.Valoare_tupla='' and p.Valoare<>''),@ContBImpl)
	
	if @parXML.value('(/row/@judet)[1]','varchar(20)') is null
		set @parXML.modify('insert attribute judet {sql:variable("@judet")} into (/row)[1]')
	else
		if @parXML.value('(/row/@judet)[1]','varchar(20)')<>@judet
			set @parXML.modify('replace value of (/row/@judet)[1] with sql:variable("@judet")')			    
		
	if @parXML.value('(/row/@contben)[1]','varchar(20)') is null
		set @parXML.modify('insert attribute contben {sql:variable("@contButiliz")} into (/row)[1]')
	else
		if @parXML.value('(/row/@contben)[1]','varchar(20)')<>@contButiliz
			set @parXML.modify('replace value of (/row/@contben)[1] with sql:variable("@contButiliz")')			    
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wScriuTertiSP)'
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#yso_xmlt') IS NOT NULL
	drop table #yso_xmlt

--select @mesaj as mesajeroare for xml raw
