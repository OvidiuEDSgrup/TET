
create procedure wmIaDetaliiMasa @sesiune varchar(50), @parXML xml as  
set transaction isolation level read uncommitted

	declare 
		@utilizator varchar(20), @articole xml, @inchid xml, @adauga xml, @idUnitate int, @idComanda int, @lm varchar(20), @titlu varchar(200)

	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator output

	select 
		@idComanda=@parXML.value('(/*/@idComanda)[1]','int'),
		@idUnitate=@parXML.value('(/*/@idUnitate)[1]','int')
	
	select top 1 @titlu=denumire from Unitati where idUnitate=@idUnitate

	set @adauga=
	(
		select 
			'Adauga' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 
			'wmAlegCodRestaurant' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza, '1' as _toateAtr
		for xml raw, type
	)

	set @articole=
	(
		select	
			rtrim(n.denumire) as denumire, p.cod cod, 'Cant. ' + convert(varchar(10), convert(decimal(15,2),ISNULL(p.cantitate,0)))+ ' Pret ' 
				+convert(varchar(10), convert(decimal(15,2),ISNULL(p.pret,0))) + ' Disc. '+ convert(varchar(10), convert(decimal(15,2),ISNULL(p.discount,0))) info,
			'D' as tipdetalii, 'wmScriuPozitieComandaRestaurant' procdetalii, dbo.f_wmIaForm('MD') form,@idComanda idComanda, 1 as _toateAtr,
			convert(decimal(12,3),p.cantitate) as cantitate, convert(decimal(12,3),p.pret) as pret, convert(decimal(12,2),p.discount) as discount			
		from ct p
		JOIN Nomencl n on n.cod=p.cod
		where idComanda=@idComanda
		for xml raw
	)


	select @adauga, @inchid, @articole for xml path('Date')
	select @titlu titlu for xml raw, root('Mesaje')
