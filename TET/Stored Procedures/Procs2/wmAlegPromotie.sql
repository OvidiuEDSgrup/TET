CREATE procedure wmAlegPromotie @sesiune varchar(50), @parXML xml
as

	declare 
		@utilizator varchar(50)
	set transaction isolation level READ UNCOMMITTED

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	if @utilizator is null 
		return -1

	SELECT
		'wmScriuPozitieComanda' procdetalii, dbo.f_wmIaForm('PROMO') form,
		p.denumire denumire, 'Articol promo:'+rtrim(n.denumire) info,'D' tipdetalii,
		'1' as _toateAtr, p.idPromotie idpromotie
	FROM Promotii p
	JOIN NOmencl n on n.cod=p.cod and convert(date,GETDATE()) between p.dela and p.panala
	for xml raw, root('Date')
