--***
CREATE procedure wIaHartaAgenti @sesiune varchar(50), @parXML xml
as
begin
	set transaction isolation level READ UNCOMMITTED
	declare @filtruagent varchar(100),@filtrulocalitate varchar(100),@user varchar(50)
	set @filtruagent = '%'+isnull(@parXML.value('(/row/@agent)[1]', 'varchar(100)'), '')+'%'

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@user output

	if @user is null
		return -1	

	select rtrim(u.Nume) as descriere,convert(decimal(17,6),g.x) cx, convert(decimal(17,6),g.y) cy,
		'0xFF0000' as culoare,
		'<font color="#002060"><b>Data exacta: </b>' + rtrim(convert(datetime,g.data,133)) + '<br>' +
		'<b>Viteza aprox.: </b>' + convert(varchar,g.kmph)+' kmh <br>'+ '</font>' as info
	from GpsTracking g
		inner join utilizatori u on g.Cod=u.ID
	where g.tip='AGENT' 
		and g.cod like '%'+@filtruagent+'%'
		and convert(datetime,getdate(),101)=convert(datetime,g.Data,101)
	order by g.id desc
	for xml raw

	select top 1
		30 as refresh,
		convert(varchar(10),convert(decimal(17,6),g.x)) + ',' + convert(varchar(10),convert(decimal(17,6),g.y)) as _centreaza 
	from GpsTracking g
	where g.tip='AGENT' 
		and g.cod like '%'+@filtruagent+'%'
	order by id desc
	for xml raw,root('Mesaje')

end
