--***
create procedure [dbo].[wScriuPozdocSP2] @sesiune varchar(50), @subunitate varchar(10), @tipGrp varchar(20), @numarGrp varchar(8), @dataGrp datetime
	, @parXML xml 
as

declare @userASiS varchar(20), @fara_luare_date varchar(1),@sub varchar(20), @tip char(2), @numar char(20), @data datetime, --@tipGrp char(2), @numarGrp char(20), @dataGrp datetime, 
	@sir_numere_pozitii varchar(max), @subtip varchar(2), @ptupdate int, @apelDinProcedura int, @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), 
	@jurnalProprietate varchar(3), 	@NrAvizeUnitar int, @NumarDocPrimit int, @gestiune char(9), @gestiune_primitoare varchar(40), @cod char(20), @cantitate decimal(17,5), @cod_intrare char(13), 
	@pret_valuta decimal(17,5), @tert char(13), @suma_tva decimal(15,2), @lm char(9), @valuta char(3), @curs float, @docXMLIaPozdoc xml, @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20), 
	@eroare xml, @mesaj varchar(max), @tip_doc varchar(2), @jurnal varchar(20), @factura char(20), @rec_factura_existenta char(20), @data_rec_fact_exist datetime, @cursorStatus int, @lDeschidereMachetaPreturi int,
	@parXmlScriereIntrari xml, @parXmlScriereIesiri xml, @searchText varchar(50), @lenNumar int, @deschidereRepCI bit, @contcorespondent varchar(40), @tip_TVA int

begin try

	declare @cont_stoc varchar(40)
	set @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
	SET @apelDinProcedura = isnull(@parXML.value('(/*/@apelDinProcedura)[1]', 'int'),0)--flag ca apelul a fost facut dintr-o alta procedura, nu din frame
	set @cod=@parXML.value('(/row/row/@cod)[1]', 'varchar(20)')
	select @cont_stoc=isnull(nullif(@parXML.value('(/row/row/@contstoc)[1]', 'varchar(20)'),''),n.Cont)
	from nomencl n where n.Cod=@cod
	
	if @tip='RS' and @cont_stoc like '622%' and @apelDinProcedura=0
	begin
		declare @ptIdPozdoc int
		if @ptupdate=1
			set @ptIdPozdoc=@parXML.value('(/row/row/@idpozdoc)[1]', 'int')
		else
			set @ptIdPozdoc=isnull(@parXmlScriereIntrari.value('(/Inserate/row/@idPozDoc)[1]', 'int'),@parXml.value('(/row/docInserate/row/@idPozDoc)[1]', 'int'))

		DECLARE @dateInitializare XML
		SET @dateInitializare=@parXML--'<row><row idpozdoc="'+ltrim(str(@ptidpozdoc))+'" /></row>'

		SELECT 'Comisionare facturi selectiv' nume, 'DO' codmeniu, 'D' tipmacheta, 'RS' tip,'CF' subtip,'O' fel,
			(SELECT @dateInitializare ) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')	
	end
end try
begin catch 
	set @mesaj=ERROR_MESSAGE()+' (wScriuPozdocSP2)'
	raiserror(@mesaj, 11, 1) 
end catch