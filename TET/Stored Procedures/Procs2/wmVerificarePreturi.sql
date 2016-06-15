
create procedure wmVerificarePreturi @sesiune varchar(50),@parXML XML      
as 
	declare 
		@date xml, @adaugare xml, @cod varchar(20), @trimitelatip xml, @utilizator varchar(100), @pret float 

	select
		@cod=@parXML.value('(/*/@cod)[1]','varchar(20)')

	IF @cod IS NOT NULL
	begin
		exec wIaUtilizator @sesiune=@sesiune, @utilizator= @utilizator output

		create table #preturi(cod varchar(20),nestlevel int)
		exec CreazaDiezPreturi

		insert into #preturi(cod, nestlevel)
		select @cod, @@NESTLEVEL

		exec wIaPreturi @sesiune=@sesiune, @parXML=@parXML

		select top 1 @pret=pret_amanunt from #preturi
		
		set @date=
		(
			select
				@cod cod, rtrim(n.denumire) denumire,'Pret: '+convert(varchar(10), convert(decimal(15,2),isnull(@pret,0)))+ ' -cod bare: '+rtrim(cb.Cod_de_bare) info
			from nomencl n 
			JOIN codbare cb on cb.Cod_produs=n.cod
			where n.cod=@cod
			for xml raw
		)


		set @trimitelatip=
		(
			select
				'0x0000ff' as culoare,  'Tipareste eticheta' denumire, 'assets/Imagini/Meniu/Bonuri.png' as poza,@cod cod, 'wmTiparireEtichete' as procdetalii, 'C' as tipdetalii
			for xml raw
		)
	end


	set @adaugare=
	(
		select
			'C' as tipdetalii, 'Verifica articol' denumire, '0x0000ff' as culoare,'wmNomenclator' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza, 
			'wmVerificarePreturi' 'wmNomenclator.procdetalii', 1 as toateAtr, 'C' 'wmNomenclator.tipdetalii', '1' as _neimportant
		for xml raw
	)

	IF @cod IS NULL
		select 'autoSelect' as actiune, 1 as _neimportant 
	for xml raw, root('Mesaje')

	select 
		1 as _neimportant 
	for xml raw,root('Mesaje')

	select 
		@adaugare,@trimitelatip, @date 
	for xml path('Date')
