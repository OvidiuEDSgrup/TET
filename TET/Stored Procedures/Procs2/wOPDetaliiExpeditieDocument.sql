
create procedure wOPDetaliiExpeditieDocument @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@tert varchar(20), @delegat varchar(20), @tip varchar(2), @numar varchar(20), @data datetime, @detalii xml, @mesajEroare varchar(500),
		@dendelegat varchar(100), @dentertdelegat varchar(100), @nou bit, @data_expedierii datetime, @ora_expedierii varchar(6),
		@observatii varchar(300), -- observatii expeditie
		@nume varchar(150), @prenume varchar(150), -- cand parsam delegatInexistent (fullname delegat), punem in aceste doua variabile
		@delegatInexistent varchar(300), -- nu exista in infotert
		@cDataExpedierii varchar(30), @nrauto varchar(20)

	set @tert = @parXML.value('(/*/detalii/row/@tertdelegat)[1]', 'varchar(20)')
	set @delegat = @parXML.value('(/*/detalii/row/@delegat)[1]', 'varchar(20)')
	set @dentertdelegat = @parXML.value('(/*/detalii/row/@dentertdelegat)[1]', 'varchar(100)')
	set @dendelegat = @parXML.value('(/*/detalii/row/@dendelegat)[1]', 'varchar(100)')
	set @data_expedierii = @parXML.value('(/*/detalii/row/@data_expedierii)[1]', 'datetime')
	set @ora_expedierii = @parXML.value('(/*/detalii/row/@ora_expedierii)[1]', 'varchar(6)')
	set @observatii = @parXML.value('(/*/detalii/row/@observatii)[1]', 'varchar(300)')
	set @nrauto = @parXML.value('(/*/detalii/row/@nrauto)[1]', 'varchar(20)')

	set @nou = isnull(@parXML.value('(/*/@nou)[1]', 'bit'), 0)

	set @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	if @tip in ('AA','AB')
		set @tip = 'AP'
	set @numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)')
	set @data = @parXML.value('(/*/@data)[1]', 'datetime')
	set @delegatInexistent = replace(@delegat, ' ', ',')

	set @nume = dbo.fStrToken(@delegatInexistent, 1, ',')
	set @prenume = dbo.fStrToken(@delegatInexistent, 2, ',')

	
	if @nou = 1 and exists (select 1 from infotert i where i.Subunitate = 'C1' and i.Identificator = @delegat and i.Tert = @tert)
		raiserror('Ati specificat un delegat valid! Debifati optiunea "Nou".', 16, 1)
	

	if @nou = 1 -- daca @nou e bifat si nu exista delegatul in infotert
	begin
		select 'Adaugare delegat' nume, 'APC' codmeniu, 'O' tipmacheta,
			(select @tert tert, @numar numar, @data data, @tip tip, @nume nume, @prenume prenume,
				@data_expedierii data_expedierii, @ora_expedierii ora_expedierii, @observatii observatii for xml raw, type) dateInitializare
		for xml raw('deschideMacheta'), root('Mesaje')
	end
	else
	begin

		if not exists (select 1 from infotert i where i.Subunitate = 'C1' and i.Identificator = @delegat and i.Tert = @tert)
			raiserror('Delegatul sau Tertul delegat nu exista! Specificati un delegat valid.', 16, 1)

		select top 1 @detalii = detalii from doc where tip = @tip and numar = @numar and data = @data

		/** Pentru compatibilitate cu SQL Server 2005 (XQuery nu suporta tipul datetime) */
		SELECT @cDataExpedierii = CONVERT(varchar(30), @data_expedierii, 126)

		if @detalii is null
			set @detalii = '<row/>'

		if @detalii.value('(/row/@tertdelegat)[1]', 'varchar(20)') is not null                          
			set @detalii.modify('replace value of (/row/@tertdelegat)[1] with sql:variable("@tert")')                             
		else                   
			set @detalii.modify ('insert attribute tertdelegat {sql:variable("@tert")} into (/row)[1]') 

		if @detalii.value('(/row/@delegat)[1]', 'varchar(20)') is not null                          
			set @detalii.modify('replace value of (/row/@delegat)[1] with sql:variable("@delegat")')                             
		else                   
			set @detalii.modify ('insert attribute delegat {sql:variable("@delegat")} into (/row)[1]')

		if @detalii.value('(/row/@dentertdelegat)[1]', 'varchar(100)') is not null                          
			set @detalii.modify('replace value of (/row/@dentertdelegat)[1] with sql:variable("@dentertdelegat")')                             
		else                   
			set @detalii.modify ('insert attribute dentertdelegat {sql:variable("@dentertdelegat")} into (/row)[1]') 

		if @detalii.value('(/row/@dendelegat)[1]', 'varchar(100)') is not null                          
			set @detalii.modify('replace value of (/row/@dendelegat)[1] with sql:variable("@dendelegat")')                             
		else                   
			set @detalii.modify ('insert attribute dendelegat {sql:variable("@dendelegat")} into (/row)[1]') 

		if @detalii.value('(/row/@data_expedierii)[1]', 'varchar(30)') is not null
			set @detalii.modify('replace value of (/row/@data_expedierii)[1] with sql:variable("@cDataExpedierii")')
		else
			set @detalii.modify('insert attribute data_expedierii {sql:variable("@cDataExpedierii")} into (/row)[1]')

		if @detalii.value('(/row/@ora_expedierii)[1]', 'varchar(6)') is not null
			set @detalii.modify('replace value of (/row/@ora_expedierii)[1] with sql:variable("@ora_expedierii")')
		else
			set @detalii.modify('insert attribute ora_expedierii {sql:variable("@ora_expedierii")} into (/row)[1]')

		if @detalii.value('(/row/@observatii)[1]', 'varchar(300)') is not null
			set @detalii.modify('replace value of (/row/@observatii)[1] with sql:variable("@observatii")')
		else
			set @detalii.modify('insert attribute observatii {sql:variable("@observatii")} into (/row)[1]')

		if @detalii.value('(/row/@nrauto)[1]', 'varchar(20)') is not null
			set @detalii.modify('replace value of (/row/@nrauto)[1] with sql:variable("@nrauto")')
		else
			set @detalii.modify('insert attribute nrauto {sql:variable("@nrauto")} into (/row)[1]')

		update top(1) doc set detalii = @detalii where tip = @tip and numar = @numar and data = @data
	end

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (wOPDetaliiExpeditieDocument)' + convert(varchar(5), ERROR_LINE())
	raiserror(@mesajEroare, 16, 1)
end catch
