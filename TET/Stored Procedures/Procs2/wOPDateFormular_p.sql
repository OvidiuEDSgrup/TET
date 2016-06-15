--***
create procedure wOPDateFormular_p @sesiune varchar(50), @parXML xml
as

	declare
		@tip varchar(2), @detalii xml, @numar varchar(20), @data datetime, @gestiune varchar(20)
	select
		@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/row/@numar)[1]', 'varchar(20)'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(20)')

	if @tip in ('RM', 'RC', 'RS', 'RA', 'RF')
	begin
		declare
			@denmembru1 varchar(150), @denmembru2 varchar(150), @denmembru3 varchar(150), @denmembru4 varchar(150),
			@membru1 varchar(50), @membru2 varchar(50), @membru3 varchar(50), @membru4 varchar(50),
			@observatii varchar(300), @gestionar varchar(50), @dengestionar varchar(150)

		if @tip in ('RC', 'RA', 'RF')
			set @tip = 'RM'
		
		/** Daca nu avem detalii gestionar/comisie in document, vom lua din gestiuni.detalii */
		select top 1 @detalii = detalii from doc where tip = @tip and numar = @numar and data = @data

		if @detalii is null or @detalii.exist('(/row/@gestionar)[1]') = 0
			select top 1 @detalii = detalii from gestiuni where cod_gestiune = @gestiune

		select
			@gestionar = isnull(@detalii.value('(/row/@gestionar)[1]', 'varchar(50)'), ''),
			@membru1 = isnull(@detalii.value('(/row/@membru1)[1]', 'varchar(50)'), ''),
			@membru2 = isnull(@detalii.value('(/row/@membru2)[1]', 'varchar(50)'), ''),
			@membru3 = isnull(@detalii.value('(/row/@membru3)[1]', 'varchar(50)'), ''),
			@membru4 = isnull(@detalii.value('(/row/@membru4)[1]', 'varchar(50)'), ''),
			@dengestionar = isnull(@detalii.value('(/row/@dengestionar)[1]', 'varchar(150)'), ''),
			@denmembru1 = isnull(@detalii.value('(/row/@denmembru1)[1]', 'varchar(150)'), ''),
			@denmembru2 = isnull(@detalii.value('(/row/@denmembru2)[1]', 'varchar(150)'), ''),
			@denmembru3 = isnull(@detalii.value('(/row/@denmembru3)[1]', 'varchar(150)'), ''),
			@denmembru4 = isnull(@detalii.value('(/row/@denmembru4)[1]', 'varchar(150)'), ''),
			@observatii = isnull(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '')
		
		select
			@gestionar as detalii_gestionar,
			@dengestionar as detalii_dengestionar,
			@membru1 as detalii_membru1,
			@denmembru1 as detalii_denmembru1,
			@membru2 as detalii_membru2,
			@denmembru2 as detalii_denmembru2,
			@membru3 as detalii_membru3,
			@denmembru3 as detalii_denmembru3,
			@membru4 as detalii_membru4,
			@denmembru4 as detalii_denmembru4,
			@observatii as detalii_observatii
		for xml raw, root('Date')
	end

	if @tip in ('CM', 'PP', 'DF')
	begin
		declare
			@persPrimitoare varchar(50), @persPredatoare varchar(50),
			@denPersPrimitoare varchar(200), @denPersPredatoare varchar(200),
			@sefComp varchar(50), @denSefComp varchar(200)

		select
			@persPrimitoare = isnull(@parXML.value('(/row/detalii/row/@persPrimitoare)[1]', 'varchar(50)'), ''),
			@persPredatoare = isnull(@parXML.value('(/row/detalii/row/@persPredatoare)[1]', 'varchar(50)'), ''),
			@denPersPrimitoare = isnull(@parXML.value('(/row/detalii/row/@denPersPrimitoare)[1]', 'varchar(150)'), ''),
			@denPersPredatoare = isnull(@parXML.value('(/row/detalii/row/@denPersPredatoare)[1]', 'varchar(150)'), ''),
			@sefComp = isnull(@parXML.value('(/row/detalii/row/@sefComp)[1]', 'varchar(50)'), ''),
			@denSefComp = isnull(@parXML.value('(/row/detalii/row/@denSefComp)[1]', 'varchar(150)'), '')

		select
			@persPrimitoare as detalii_persPrimitoare,
			@denPersPrimitoare as detalii_denPersPrimitoare,
			@persPredatoare as detalii_persPredatoare,
			@denPersPredatoare as detalii_denPersPredatoare,
			@sefComp as detalii_sefComp,
			@denSefComp as detalii_denSefComp
		for xml raw, root('Date')
	end
