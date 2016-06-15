
create procedure wmIaMese @sesiune varchar(50), @parXML xml 
as  
set transaction isolation level read uncommitted

	declare 
		@utilizator varchar(20), @data_ieri datetime, @idMasa int, @areCopii int
	
	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator output
	select @data_ieri=DATEADD(DAY, -2, GETDATE())
	select @idMasa=@parXML.value('(/*/@idUnitate)[1]','int')

	select 
		rtrim(u.Denumire) as denumire, 'Masa '+convert(varchar(10), t.Capacitate) +' persoane -'+/*(case  when cl.idComanda IS NOT NULL then ' -'+UPPER('user') else '' end)*/+
			'Valoare: '+convert(varchar(100), convert(decimal(15,2), cl.valoare)) as info, 
		t.idTipUnitate as idTipUnitate, u.idUnitate as idUnitate, 'server://assets/Imagini/pozemobile/masa2.png' as poza,
		1 as _toateAtr, cl.idComanda idComanda, (case when cl.idComanda IS NULL then '0x00FF00' else  '0xFF0000' end) culoare
	from Unitati u
	INNER join TipuriUnitati t on u.idTipUnitate=t.idTipUnitate
	LEFT JOIN lm l on l.cod=u.lm
	OUTER APPLY 
	(
		select 
			top 1 c.idComanda, sum(ct.cantitate*ct.pret*(1-ct.discount/100.0)) valoare
		FROM ComenziHRc c 
		JOIN ct on c.idComanda=ct.idComanda
		where c.idUnitate=u.idUnitate	
		group by c.idComanda
	) cl
	where t.Fel='M' and ((@idMasa IS NULL and u.idUnitateParinte IS NULL) OR u.idUnitateParinte=@idMasa)
	order by u.Denumire
	for xml raw, root('Date')


	IF EXISTS (select 1 from NotificariMobileHoreca where utilizator=@utilizator)
	BEGIN
		delete NotificariMobileHoreca where utilizator=@utilizator
		select 'Comanda gata de la bucatarie!' as textAlerta, 'Alerta' as titluAlerta for xml raw, root('Mesaje')
	END
	select 'Mese' as titlu,0 as areSearch,1 as _toateAtr,(case when @idMasa IS NULL then 'wmIaMese' else 'wmIaDetaliiMasa' end ) as detalii, 5 _rezident, 5 _cuRefresh
	for xml raw,Root('Mesaje')
