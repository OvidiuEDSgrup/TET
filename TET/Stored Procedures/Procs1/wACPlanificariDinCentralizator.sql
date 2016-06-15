
create procedure wACPlanificariDinCentralizator @sesiune varchar(50), @parXML XML
as


	select
		ap.idAntet cod,
		'Numar: ' + ap.numar + '- Data: '+ convert(varchar(10), ap.data, 103) denumire,
		'Resursa:'+ rs.descriere +'- ' +Convert(varchar(100),ISNULL(poz.nr,0)) + ' poz' info		
	from AntetPlanificare ap
	JOIN Resurse rs on ap.idResursa=rs.id
	OUTER APPLY
	(
		select

			count(1) nr
		from Planificare where idAntet=ap.idAntet
	) poz
	where ISNULL(ap.detalii.value('(/*/@stare)[1]','int') ,0)=0
	for xml raw, root('Date')
