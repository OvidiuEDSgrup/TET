
create procedure wIaDateCentralizatorPlanificare @sesiune varchar(50), @parXML XML
as
begin try
	declare
		@mesaj varchar(1000), @f_numar varchar(20), @f_resursa varchar(200), @idAntet int

	select
		@f_numar='%'+ISNULL(replace(@parXML.value('(/*/@f_numar)[1]','varchar(20)'),' ' ,'%'),'%')+'%',
		@f_resursa='%'+ISNULL(replace(@parXML.value('(/*/@f_resursa)[1]','varchar(20)'),' ' ,'%'),'%')+'%',
		@idantet=@parXML.value('(/*/@idAntet)[1]','int')


	select
		ap.numar numar, convert(varchar(10), ap.data, 101) data, rs.descriere denresursa, rs.id resursa, ISNULL(poz.nr,0) pozitii,
		CONVERT(VARCHAR(10), dataora_start, 101) + ' ' + convert(VARCHAR(80), dataora_start, 8) AS dataora_start,
		CONVERT(VARCHAR(10), dataora_stop, 101) + ' ' + convert(VARCHAR(80), dataora_stop, 8) AS dataora_stop,
		(CASE when ap.detalii.value('(/*/@stare)[1]','int')=1 then'#808080' END) AS culoare,
		(CASE when isnull(ap.detalii.value('(/*/@stare)[1]','int') ,0) <> 0 then 1 else 0 end ) as _nemodificabil,
		ap.idAntet idAntet
	from AntetPlanificare ap
	JOIN Resurse rs on ap.idResursa=rs.id
	OUTER APPLY
	(
		select

			count(1) nr
		from Planificare where idAntet=ap.idAntet
	) poz
	where (@IDANTET IS NULL OR ap.idantet = @idantet)
	for xml raw, root('Date')

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wIaDateCentralizatorPlanificare)'
	raiserror(@mesaj, 11, 1)
end catch
