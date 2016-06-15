CREATE PROCEDURE wmTiparireEtichete @sesiune varchar(50), @parXML xml
AS
	declare @utilizator varchar(200), @actiuni XML, @date XML, @cod varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator= @utilizator OUTPUT
	
	IF OBJECT_ID('temp_ListareCodBare') IS NULL
		create table temp_ListareCodBare(utilizator varchar(100), cod varchar(20))

	select
		@cod=@parXML.value('(/*/@cod)[1]','varchar(20)')

	IF @cod IS NOT NULL
		insert into temp_ListareCodBare (cod, utilizator)
		select @cod, @utilizator
		where @cod not in (select cod from temp_ListareCodBare where utilizator=@utilizator)


	set @actiuni=
	(
		select
			'C' as tipdetalii, 'Adauga' denumire, '0x0000ff' as culoare,'wmNomenclator' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza, 
			'wmTiparireEtichete' 'wmNomenclator.procdetalii', 1 as toateAtr, 'C' 'wmNomenclator.tipdetalii'
		for xml raw
	)
	set @date=
	(
		select 
			rtrim(n.cod) cod, rtrim(n.denumire) denumire, 'Cod bare: '+ rtrim(cb.Cod_de_bare) as info
		from temp_ListareCodBare tcb
		JOIN Nomencl n on tcb.cod=n.cod
		JOIN codbare cb on cb.Cod_produs=n.cod
		where tcb.utilizator=@utilizator
		for xml raw
	)


	select @actiuni, @date for xml PATH('Date')


