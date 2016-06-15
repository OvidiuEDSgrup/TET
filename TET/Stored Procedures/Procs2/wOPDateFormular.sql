---***
create procedure wOPDateFormular @sesiune varchar(50), @parXML xml
as
begin try
	
	declare
		@utilizator varchar(20), @tip varchar(2), @numar varchar(20), @data datetime,
		@detalii xml, @mesajEroare varchar(500),
		@observatii varchar(300) -- declarat aici pentru ca observatiile apar la fiecare formular in parte

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		/** Date identificare document */
		@tip = @parXML.value('(/parametri/@tip)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/parametri/@numar)[1]', 'varchar(20)'),
		@data = @parXML.value('(/parametri/@data)[1]', 'datetime')
	
	if @tip in ('RC','RA','RF')
		set @tip = 'RM'

	/** Detaliile documentului identificat */
	select top 1 @detalii = detalii from doc where tip = @tip and numar = @numar and data = @data

	/** Mai jos sunt campurile care se completeaza si se pun in doc.detalii 
		Se vor citi din parXML doar campurile specifice pentru fiecare tip de document.
	*/
	if @tip in ('CM', 'PP', 'DF') -- Date formular Predari/Consumuri/Dari in folosinta (aceleasi campuri de adaugat in detalii)
	begin
		declare
			@persPredatoare varchar(50), @persPrimitoare varchar(50),
			@denPersPredatoare varchar(200), @denPersPrimitoare varchar(200),
			@sefComp varchar(50), @denSefComp varchar(200)
		select
			@persPredatoare = isnull(@parXML.value('(/parametri/detalii/row/@persPredatoare)[1]', 'varchar(50)'), ''),
			@persPrimitoare = isnull(@parXML.value('(/parametri/detalii/row/@persPrimitoare)[1]', 'varchar(50)'), ''),
			@denPersPredatoare = isnull(@parXML.value('(/parametri/detalii/row/@denPersPredatoare)[1]', 'varchar(200)'), ''),
			@denPersPrimitoare = isnull(@parXML.value('(/parametri/detalii/row/@denPersPrimitoare)[1]', 'varchar(200)'), ''),
			@observatii = isnull(@parXML.value('(/parametri/detalii/row/@observatii)[1]', 'varchar(300)'), ''),
			@sefComp = isnull(@parXML.value('(/parametri/detalii/row/@sefComp)[1]', 'varchar(50)'), ''),
			@denSefComp = isnull(@parXML.value('(/parametri/detalii/row/@denSefComp)[1]', 'varchar(150)'), '')
		
		if @persPredatoare = '' set @denPersPredatoare = ''
		if @persPrimitoare = '' set @denPersPrimitoare = ''
		if @sefComp = '' set @denSefComp = ''

		if (@persPredatoare = @persPrimitoare) and not (@persPredatoare = '' or @persPrimitoare = '')
			raiserror('Nu poate fi acelasi salariat selectat!', 16, 1)

		if @detalii is null
			set @detalii = '<row/>'
		
		/** Persoana primitoare */
		if @detalii.value('(/row/@persPrimitoare)[1]', 'varchar(50)') is not null                          
			set @detalii.modify('replace value of (/row/@persPrimitoare)[1] with sql:variable("@persPrimitoare")')                             
		else                   
			set @detalii.modify ('insert attribute persPrimitoare {sql:variable("@persPrimitoare")} into (/row)[1]')

		if @detalii.value('(/row/@denPersPrimitoare)[1]', 'varchar(150)') is not null                          
			set @detalii.modify('replace value of (/row/@denPersPrimitoare)[1] with sql:variable("@denPersPrimitoare")')                             
		else                   
			set @detalii.modify ('insert attribute denPersPrimitoare {sql:variable("@denPersPrimitoare")} into (/row)[1]')

		/** Persoana predatoare */
		if @detalii.value('(/row/@persPredatoare)[1]', 'varchar(50)') is not null                          
			set @detalii.modify('replace value of (/row/@persPredatoare)[1] with sql:variable("@persPredatoare")')                             
		else                   
			set @detalii.modify ('insert attribute persPredatoare {sql:variable("@persPredatoare")} into (/row)[1]')

		if @detalii.value('(/row/@denPersPredatoare)[1]', 'varchar(150)') is not null                          
			set @detalii.modify('replace value of (/row/@denPersPredatoare)[1] with sql:variable("@denPersPredatoare")')                             
		else                   
			set @detalii.modify ('insert attribute denPersPredatoare {sql:variable("@denPersPredatoare")} into (/row)[1]')

		/** Observatii */
		if @detalii.value('(/row/@observatii)[1]', 'varchar(300)') is not null
			set @detalii.modify('replace value of (/row/@observatii)[1] with sql:variable("@observatii")')
		else
			set @detalii.modify('insert attribute observatii {sql:variable("@observatii")} into (/row)[1]')

		/** Sef de compartiment */
		if @detalii.value('(/row/@sefComp)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@sefComp)[1] with sql:variable("@sefComp")')
		else
			set @detalii.modify('insert attribute sefComp {sql:variable("@sefComp")} into (/row)[1]')

		if @detalii.value('(/row/@denSefComp)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@denSefComp)[1] with sql:variable("@denSefComp")')
		else
			set @detalii.modify('insert attribute denSefComp {sql:variable("@denSefComp")} into (/row)[1]')

		update top(1) doc set detalii = @detalii where tip = @tip and numar = @numar and data = @data
	end

	if @tip in ('RM', 'RC', 'RS','RA','RF') -- Date formular Receptii/Receptii chitante/Receptii servicii
	begin
		declare
			@membru1 varchar(50), @membru2 varchar(50), @membru3 varchar(50), @membru4 varchar(50),
			@denmembru1 varchar(150), @denmembru2 varchar(150), @denmembru3 varchar(150), @denmembru4 varchar(150),
			@gestionar varchar(50), @dengestionar varchar(150)
		select
			@gestionar = isnull(@parXML.value('(/parametri/detalii/row/@gestionar)[1]', 'varchar(50)'), ''),
			@membru1 = isnull(@parXML.value('(/parametri/detalii/row/@membru1)[1]', 'varchar(50)'), ''),
			@membru2 = isnull(@parXML.value('(/parametri/detalii/row/@membru2)[1]', 'varchar(50)'), ''),
			@membru3 = isnull(@parXML.value('(/parametri/detalii/row/@membru3)[1]', 'varchar(50)'), ''),
			@membru4 = isnull(@parXML.value('(/parametri/detalii/row/@membru4)[1]', 'varchar(50)'), ''),
			@dengestionar = isnull(@parXML.value('(/parametri/detalii/row/@dengestionar)[1]', 'varchar(150)'), ''),
			@denmembru1 = isnull(@parXML.value('(/parametri/detalii/row/@denmembru1)[1]', 'varchar(150)'), ''),
			@denmembru2 = isnull(@parXML.value('(/parametri/detalii/row/@denmembru2)[1]', 'varchar(150)'), ''),
			@denmembru3 = isnull(@parXML.value('(/parametri/detalii/row/@denmembru3)[1]', 'varchar(150)'), ''),
			@denmembru4 = isnull(@parXML.value('(/parametri/detalii/row/@denmembru4)[1]', 'varchar(150)'), ''),
			@observatii = isnull(@parXML.value('(/parametri/detalii/row/@observatii)[1]', 'varchar(300)'), '')

		if @gestionar = '' set @dengestionar = ''
		if @membru1 = '' set @denmembru1 = ''
		if @membru2 = '' set @denmembru2 = ''
		if @membru3 = '' set @denmembru3 = ''
		if @membru4 = '' set @denmembru4 = ''

		if @detalii is null
			set @detalii = '<row/>'
		

		/** Gestionar */
		if @detalii.value('(/row/@gestionar)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@gestionar)[1] with sql:variable("@gestionar")')
		else
			set @detalii.modify('insert attribute gestionar {sql:variable("@gestionar")} into (/row)[1]')

		if @detalii.value('(/row/@dengestionar)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@dengestionar)[1] with sql:variable("@dengestionar")')
		else
			set @detalii.modify('insert attribute dengestionar {sql:variable("@dengestionar")} into (/row)[1]')
		

		/** Membru nr.1 din comisia de receptie */
		if @detalii.value('(/row/@membru1)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@membru1)[1] with sql:variable("@membru1")')
		else
			set @detalii.modify('insert attribute membru1 {sql:variable("@membru1")} into (/row)[1]')

		if @detalii.value('(/row/@denmembru1)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@denmembru1)[1] with sql:variable("@denmembru1")')
		else
			set @detalii.modify('insert attribute denmembru1 {sql:variable("@denmembru1")} into (/row)[1]')
		
		/** Membru nr.2 din comisia de receptie */
		if @detalii.value('(/row/@membru2)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@membru2)[1] with sql:variable("@membru2")')
		else
			set @detalii.modify('insert attribute membru2 {sql:variable("@membru2")} into (/row)[1]')

		if @detalii.value('(/row/@denmembru2)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@denmembru2)[1] with sql:variable("@denmembru2")')
		else
			set @detalii.modify('insert attribute denmembru2 {sql:variable("@denmembru2")} into (/row)[1]')
		

		/** Membru nr.3 din comisia de receptie */
		if @detalii.value('(/row/@membru3)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@membru3)[1] with sql:variable("@membru3")')
		else
			set @detalii.modify('insert attribute membru3 {sql:variable("@membru3")} into (/row)[1]')

		if @detalii.value('(/row/@denmembru3)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@denmembru3)[1] with sql:variable("@denmembru3")')
		else
			set @detalii.modify('insert attribute denmembru3 {sql:variable("@denmembru3")} into (/row)[1]')


		/** Membru nr.4 din comisia de receptie */
		if @detalii.value('(/row/@membru4)[1]', 'varchar(50)') is not null
			set @detalii.modify('replace value of (/row/@membru4)[1] with sql:variable("@membru4")')
		else
			set @detalii.modify('insert attribute membru4 {sql:variable("@membru4")} into (/row)[1]')

		if @detalii.value('(/row/@denmembru4)[1]', 'varchar(150)') is not null
			set @detalii.modify('replace value of (/row/@denmembru4)[1] with sql:variable("@denmembru4")')
		else
			set @detalii.modify('insert attribute denmembru4 {sql:variable("@denmembru4")} into (/row)[1]')


		/** Observatii */
		if @detalii.value('(/row/@observatii)[1]', 'varchar(300)') is not null
			set @detalii.modify('replace value of (/row/@observatii)[1] with sql:variable("@observatii")')
		else
			set @detalii.modify('insert attribute observatii {sql:variable("@observatii")} into (/row)[1]')

		update top(1) doc set detalii = @detalii where tip = @tip and numar = @numar and data = @data
	end

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (wOPDateFormular)'
	raiserror(@mesajEroare, 16, 1)
end catch
