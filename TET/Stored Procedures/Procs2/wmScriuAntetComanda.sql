--***
CREATE procedure wmScriuAntetComanda @sesiune varchar(50), @parXML xml OUTPUT
as
if exists(select * from sysobjects where name='wmScriuAntetComandaSP' and type='P')
begin
	exec wmScriuAntetComandaSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED
	declare 
		@utilizator varchar(100),@subunitate varchar(9),@tert varchar(20),@data datetime, @punctlivrare varchar(30), @gestpv varchar(20),@primaCon bit,
		@lm varchar(50), @explicatii varchar(80),@scadenta int, @gestprim varchar(50),@idContract int, @gestiuneDepozitBK varchar(20), @gestiune varchar(20),
		@detalii xml, @discount_unic bit, @val_discount float

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return -1

	SELECT @gestiuneDepozitBK= dbo.wfProprietateUtilizator('GESTDEPBK',@utilizator)
	/** Citire date din par */
	select	@subunitate=rtrim(Val_alfanumerica)
	from par where Tip_parametru='GE' and Parametru ='SUBPRO'

	select	@data=GETDATE(),
			@primaCon = isnull(@parXML.value('(/row/@primaCon)[1]','bit'),0),
			@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@punctlivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)'),
			@gestprim=@parXML.value('(/row/@gestprim)[1]','varchar(20)')
	
	exec adaugaAtributeXml @xmlSursa=@parXML, @xmlDest=@detalii OUTPUT ,@extrageDetalii=1

	select	@GESTPV = rtrim(dbo.wfProprietateUtilizator('GESTPV',@utilizator)),
			@explicatii=ISNULL((select top 1 rtrim(denumire) from terti where tert=@tert),''),
			@lm= rtrim(dbo.wfProprietateUtilizator('LOCMUNCA',@utilizator))

	exec luare_date_par 'AM','DISCUNICP',@discount_unic OUTPUT,0,''

	if @lm = '' 
		set @lm = null

	if @GESTPV=''
	begin
		raiserror('Agentul nu are atasata o gestiune de lucru!',11,1)
		return -1
	end

	/** 
		Daca am gestiune primitoare inseamna ca facem o comanda de "incarcare" a agentului=>  DEPOZIT -> GESTPV
		Altfel, agentul vinde => GESTPV
	**/
	 
	if @gestprim is null
		set @gestiune=@gestpv
	else
		set @gestiune=@gestiuneDepozitBK

	/* 
		Daca se lucreaza cu discount unic pe pozitii, scriu in antetul comenzii discoutul de pe tert,
		pentru a fi sugerat la pozitii
	*/
	IF @discount_unic = 1
	BEGIN
		declare @pXML xml

		create table #preturi(cod varchar(20),nestlevel int)
		exec CreazaDiezPreturi

		insert into #preturi (cod, nestlevel)
		select NULL, @@nestlevel

		set @pXML=(select @tert as tert,@data as data for xml raw)
		exec wIaPreturi @sesiune,@pXML

		select top 1 @val_discount=discount from #preturi

		-- punem valoarea discountului in detalii din antet contract

		IF @detalii IS NULL
			set @detalii=(select @val_discount discount for xml raw)
		else
			set @detalii.modify('insert attribute discount {sql:variable("@val_discount")} into (/*)[1]')
	END

	declare @input xml
	set @input=
		(
			select 
				'1' as fara_luare_date, 'CL' as tip,NULLIF(@gestiune,'') as gestiune,NULLIF(@tert,'') as tert, @lm lm,NULLIF(@gestprim,'') as gestiune_primitoare, 
				@data data,@explicatii as explicatii,NULLIF(@punctlivrare,'') as punct_livrare,@detalii detalii,
				(select NULL as cod for xml raw, TYPE)
				for xml RAW, type
		)
	exec wScriuPozContracte @sesiune=@sesiune,@parXML=@input OUTPUT
	set @idContract=@input.value('(/*/@idContract)[1]','int')	
	set @parXML.modify('insert attribute idContract {sql:variable("@idContract")} into (/*)[1]')

	if @primaCon = 1
		exec wmDetComenziTert @sesiune=@sesiune, @parXML=@parXML
