create procedure wOPModificareDatePozitie @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePozitieSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePozitieSP @sesiune, @parXML
	return @returnValue
end
begin try
	declare 
		@tert varchar(30), @numar varchar(30), @data datetime, @tip varchar(2), @sumaTVA decimal(15,2),@o_sumaTVA decimal(15,2), @contstoc varchar(40),@o_contstoc varchar(40),
		@cotatva decimal(5,2),@o_cotatva decimal(5,2),@cod varchar(40), @binar varbinary(128), @bugetari int,@numar_pozitie int,
		@pamanunt decimal(17,5),@o_pamanunt decimal(17,5),@curs decimal(17,5),@pvaluta decimal(17,5),@o_pvaluta decimal(17,5),@pvanzare decimal(17,5),@o_pvanzare decimal(17,5),
		@indbug varchar(20), @o_indbug varchar(20), @contcorespondent varchar(40),@o_contcorespondent varchar(40), @contintermediar varchar(40),@o_contintermediar varchar(40),
		@contfactura varchar(40),@o_contfactura varchar(40), @contvenituri varchar(40),@o_contvenituri varchar(40), @tipTVA decimal(12,0),  @o_tipTVA decimal(12,0), 
		@sub varchar(9), @codintrare varchar(13),@o_codintrare varchar(13), @gestiune varchar(9), @o_gestiune varchar(9), @xmlPozDoc xml, @update int, @idpozdoc int, 
		@detaliiPoz xml, @detaliiAntet xml, @taraorigine varchar(50), @indicatorBugetar varchar(50),@comanda varchar(20), @o_comanda varchar(20)

	select 
		@tert=isnull(@parXML.value('(/parametri/@tert)[1]','varchar(30)'),''),
		@numar=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(30)'),''),
		@numar_pozitie=isnull(@parXML.value('(/parametri/@numarpozitie)[1]','int'),0),
		@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),''),
		@tip=isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@cotatva=isnull(@parXML.value('(/parametri/@cotatva)[1]','decimal(5,2)'),0),
		@o_cotatva=isnull(@parXML.value('(/parametri/@o_cotatva)[1]','decimal(5,2)'),0),
		@sumaTVA=isnull(@parXML.value('(/parametri/@sumaTVA)[1]','decimal(15,2)'),0),
		@o_sumaTVA=isnull(@parXML.value('(/parametri/@o_sumaTVA)[1]','decimal(15,2)'),0),
		@cod=isnull(@parXML.value('(/parametri/@cod)[1]','varchar(30)'),''),
		@pamanunt=isnull(@parXML.value('(/parametri/@pamanunt)[1]','decimal(17,5)'),0),
		@o_pamanunt=isnull(@parXML.value('(/parametri/@o_pamanunt)[1]','decimal(17,5)'),0),
		@curs=isnull(@parXML.value('(/parametri/@curs)[1]','decimal(17,5)'),0),
		@pvaluta=isnull(@parXML.value('(/parametri/@pvaluta)[1]','decimal(17,5)'),0),
		@o_pvaluta=isnull(@parXML.value('(/parametri/@o_pvaluta)[1]','decimal(17,5)'),0),
		@pvanzare=isnull(@parXML.value('(/parametri/@pvanzare)[1]','decimal(17,5)'),0),
		@o_pvanzare=isnull(@parXML.value('(/parametri/@o_pvanzare)[1]','decimal(17,5)'),0),
		@contstoc=isnull(@parXML.value('(/parametri/@contstoc)[1]','varchar(40)'),''),
		@o_contstoc=isnull(@parXML.value('(/parametri/@o_contstoc)[1]','varchar(40)'),''),
		@contcorespondent=isnull(@parXML.value('(/parametri/@contcorespondent)[1]','varchar(40)'),''),
		@o_contcorespondent=isnull(@parXML.value('(/parametri/@o_contcorespondent)[1]','varchar(40)'),''),
		@contintermediar=isnull(@parXML.value('(/parametri/@contintermediar)[1]','varchar(40)'),''),
		@o_contintermediar=isnull(@parXML.value('(/parametri/@o_contintermediar)[1]','varchar(40)'),''),
		@contfactura=isnull(@parXML.value('(/parametri/@contfactura)[1]','varchar(40)'),''),
		@o_contfactura=isnull(@parXML.value('(/parametri/@o_contfactura)[1]','varchar(40)'),@contfactura),
		@contvenituri=isnull(@parXML.value('(/parametri/@contvenituri)[1]','varchar(40)'),''),
		@o_contvenituri=isnull(@parXML.value('(/parametri/@o_contvenituri)[1]','varchar(40)'),@contvenituri),
		@indbug=isnull(@parXML.value('(/parametri/@indbug)[1]','varchar(20)'),''),
		@o_indbug=isnull(@parXML.value('(/parametri/@o_indbug)[1]','varchar(20)'),''),
		@tipTVA=@parXML.value('(/parametri/@tiptva)[1]','decimal(12,0)'),
		@o_tipTVA=@parXML.value('(/parametri/@o_tiptva)[1]','decimal(12,0)'),
		@codintrare=isnull(@parXML.value('(/parametri/@codintrare)[1]','varchar(13)'),''),
		@o_codintrare=isnull(@parXML.value('(/parametri/@o_codintrare)[1]','varchar(13)'),''), 
		@gestiune=isnull(@parXML.value('(/parametri/@gestiune)[1]','varchar(9)'),''),		
		@o_gestiune=isnull(@parXML.value('(/parametri/@o_gestiune)[1]','varchar(9)'),''),
		@comanda=isnull(@parXML.value('(/parametri/@comanda)[1]','varchar(20)'),''),
		@update=1,
		@idpozdoc=isnull(@parXML.value('(/parametri/row/@idpozdoc)[1]','int'),0),
		@detaliiPoz = @parXML.query('/parametri[1]/detalii'),
		@taraorigine = @parXML.value('(/parametri[1]/detalii/row/@taraorigine)[1]','varchar(50)'),
		@indicatorBugetar = @parXML.value('(/parametri[1]/detalii/row/@indicator)[1]','varchar(20)') -- in pozdoc.detalii

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output	
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''

	if @cod='' or @idpozdoc=0
		raiserror('Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',16,1)

	select
		@binar=cast('specificebugetari' as varbinary(128))--sa se poata modifica sumatva si pe documentele definitive

	set @xmlPozDoc=convert(xml,replace(convert(varchar(max),@parXML),'parametri','row'))
	/* Atributul nou @sumatva_i este tratat de wScriuDoc */
	IF ISNULL(@xmlPozDoc.value('(/row/row/@sumatva)[1]','decimal(15,2)'),0)<>ISNULL(@sumaTVA,0)
		set @xmlPozDoc.modify('insert attribute sumatva_i {sql:variable("@sumaTVA")} into (/row/row)[1]')

	set @xmlPozDoc.modify('insert attribute update {sql:variable("@update")} into (/row/row)[1]')
	if @xmlPozDoc.value('(/row/row/@o_sumatva)[1]','decimal(15,2)') is null
		set @xmlPozDoc.modify('insert attribute o_sumatva {sql:variable("@o_sumaTVA")} into (/row/row)[1]')
	set @xmlPozDoc.modify('replace value of (/row/row/@sumatva)[1] with sql:variable("@sumaTVA")')
	if @xmlPozDoc.value('(/row/row/@o_cotatva)[1]','decimal(5,2)') is null
		set @xmlPozDoc.modify('insert attribute o_cotatva {sql:variable("@o_cotatva")} into (/row/row)[1]')
	set @xmlPozDoc.modify('replace value of (/row/row/@cotatva)[1] with sql:variable("@cotatva")')
	set @xmlPozDoc.modify('replace value of (/row/row/@pamanunt)[1] with sql:variable("@pamanunt")')
	set @xmlPozDoc.modify('replace value of (/row/row/@pvaluta)[1] with sql:variable("@pvaluta")')
	set @xmlPozDoc.modify('replace value of (/row/row/@contstoc)[1] with sql:variable("@contstoc")')
	set @xmlPozDoc.modify('replace value of (/row/row/@contcorespondent)[1] with sql:variable("@contcorespondent")')
	set @xmlPozDoc.modify('replace value of (/row/row/@contintermediar)[1] with sql:variable("@contintermediar")')
	set @xmlPozDoc.modify('replace value of (/row/row/@contfactura)[1] with sql:variable("@contfactura")')
	set @xmlPozDoc.modify('replace value of (/row/row/@contvenituri)[1] with sql:variable("@contvenituri")')
	set @xmlPozDoc.modify('replace value of (/row/row/@indbug)[1] with sql:variable("@indbug")')
	set @xmlPozDoc.modify('replace value of (/row/row/@codintrare)[1] with sql:variable("@codintrare")')
	set @xmlPozDoc.modify('replace value of (/row/row/@gestiune)[1] with sql:variable("@gestiune")')
	set @xmlPozDoc.modify('replace value of (/row/row/@comanda)[1] with sql:variable("@comanda")')
	set @xmlPozDoc.modify('replace value of (/row/@comanda)[1] with sql:variable("@comanda")')
	--if @xmlPozDoc.value('(/row/row/@tiptva)[1]', 'decimal(12,0)') is not null                          
	set @xmlPozDoc.modify('replace value of (/row/row/@tiptva)[1] with sql:variable("@tipTVA")')
	--else
	--	set @xmlPozDoc.modify ('insert attribute tiptva {sql:variable("@tipTVA")} into (/row/row)[1]')

	IF @bugetari=1
		set CONTEXT_INFO @binar	

	-- sterg nodurile detalii deoarece in /row[1]/detalii sunt concatenate detaliile antet/pozitii, iar in /row[1]/row[1]/detalii nu sunt valorile modificate.
	set @xmlPozdoc.modify('delete /row[1]/detalii')
	set @xmlPozdoc.modify('delete /row[1]/row[1]/detalii')

	-- citim xml antet din tabela DOC, din frame vine doar xml-ul cu detalii pozitii
	set @detaliiAntet = (select detalii from doc where Subunitate=@sub and tip=@tip and numar=@numar and data=@data for xml path(''))
	
	-- folosim aceste comenzi pt. compatibilitate SQL2005
	if @detaliiAntet is not null
	begin
		set @xmlPozdoc = convert(xml, convert(varchar(max), @xmlPozDoc)+ convert(varchar(max),@detaliiAntet))
		set @xmlPozdoc.modify('insert /detalii[1] as first into /row[1]')
		set @xmlPozdoc.modify('delete /detalii[1]')
	end

	-- pentru moment (pana cand se va trata general posibilitatea modificarii unui atribut din detalii prin modificare pozitie) am tratat individual tara de origine, sa fie cumulata la detalii pozitie.
	if @taraorigine is not null
	begin
		if @detaliiPoz is null set @detaliiPoz='<row />'
		if @detaliiPoz.value('(/detalii/row/@taraorigine)[1]','varchar(50)') is null
			set @detaliiPoz.modify ('insert attribute taraorigine {sql:variable("@taraorigine")} into (/detalii/row)[1]') 
		else 
			if @taraorigine=''
				set @detaliiPoz.modify('delete /detalii/row/@taraorigine')
			else
				set @detaliiPoz.modify('replace value of (/detalii/row/@taraorigine)[1] with sql:variable("@taraorigine")')
	end

	if @indicatorBugetar is not null
	begin
		if @detaliiPoz is null set @detaliiPoz = '<row />'
		if @detaliiPoz.value('(detalii/row/@indicator)[1]', 'varchar(20)') is null
			set @detaliiPoz.modify('insert attribute indicator {sql:variable("@indicatorBugetar")} into (/detalii/row)[1]')
		else
			if @indicatorBugetar = ''
				set @detaliiPoz.modify('delete /detalii/row/@indicator')
			else
				set @detaliiPoz.modify('replace value of (/detalii/row/@indicator)[1] with sql:variable("@indicatorBugetar")')
	end

	if @detaliiPoz is not null
	begin
		set @xmlPozdoc = convert(xml, convert(varchar(max), @xmlPozDoc)+ convert(varchar(max),@detaliiPoz))
		set @xmlPozdoc.modify('insert /detalii[1] as first into /row[1]/row[1]')
		set @xmlPozdoc.modify('delete /detalii[1]')
	end

	exec wScriuPozdoc @sesiune=@sesiune, @parXML=@xmlPozDoc

	if @tip in ('AP','AS') and @sumaTVA<>@o_sumaTVA
	begin
		update pozdoc set TVA_deductibil=@sumaTVA
			where pozdoc.idPozdoc=@idpozdoc
	end
	if @tip in ('RS') and @sumaTVA<>@o_sumaTVA and isnull(@curs,0)<>0 -- recalculez suma TVA in valuta
	begin
		update pozdoc set grupa=convert(char(13),convert(decimal(14,2),(@SumaTVA)/isnull(@Curs,0)))
			where pozdoc.idPozdoc=@idpozdoc
	end
	/* Daca s-a executat operatia prin wScriuDoc, facem return deoarece acesta a rezolvat deja cazurile de mai jos, alte legacy */
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wScriuDoc')
		return

	if @codintrare<>@o_codintrare -- daca s-a modificat codul de intrare -> se pun unele chestii automat
		update pozdoc set 
				Cod_intrare=@codintrare,
				Pret_de_stoc=s.Pret,
				Cont_de_stoc=s.Cont
			from stocuri s 
			where pozdoc.idPozdoc=@idpozdoc
				and s.Subunitate=pozdoc.Subunitate and s.Cod_gestiune=pozdoc.Gestiune and s.cod=pozdoc.cod and s.Cod_intrare=@codintrare

	set CONTEXT_INFO 0x
		
	if @tip in ('RM','RS') and @pamanunt<>@o_pamanunt-- pret amanunt la receptii
	begin
		select @pvanzare=round(@pamanunt*100/(100+nomencl.cota_tva),5)
		from nomencl where nomencl.cod=@cod and nomencl.cota_tva>0

		update preturi set pret_cu_amanuntul= (case when @pamanunt<>@o_pamanunt and Pret_cu_amanuntul=@o_pamanunt then @pamanunt else Pret_cu_amanuntul end),
			pret_vanzare=@pvanzare
		where cod_produs=@cod and um=1 and tip_pret='1'
	end

end try
begin catch
	SET CONTEXT_INFO 0x
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
