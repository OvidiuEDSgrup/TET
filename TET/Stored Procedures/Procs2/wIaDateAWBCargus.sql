	
create procedure wIaDateAWBCargus @sesiune varchar(50), @parXML xml 
as
	declare 
		@url varchar(500), @awb varchar(200), @utilizatorCargus varchar(200), @parolaCargus varchar(300), @idContract int

	exec luare_date_par 'AR','USRCARGUS',0,0,@utilizatorCargus OUTPUT
	exec luare_date_par 'AR','PASCARGUS',0,0,@parolaCargus OUTPUT	

	select 
		@idContract = @parXML.value('(/*/@idContract)[1]','int'),
		@url='http://webexpress.cargus.ro/custom_print/shipment_import/'

	select @awb=awb from Contracte where idContract=@idContract

	IF OBJECT_ID('tempdb.dbo.#date_car') IS NOT NULL
		drop table #date_car

	IF @awb is not null
	begin
		create table #date_car (awb varchar(200), observatii varchar(300), download varchar(1000))

		insert into #date_car (awb, observatii, download)
		select @awb, 'Nota de transport A4','<a href="' +  @url+'view_awb.php'+'?user='+RTRIM(@utilizatorCargus)+'&parola='+RTRIM(@parolaCargus)+'&awb='+RTRIM(@awb)+'" target="_blank" /><u> Click </u></a>'
		insert into #date_car (awb, observatii, download)
		select @awb, 'Etichete 10x15 cm','<a href="' +  @url+'view_label.php'+'?user='+RTRIM(@utilizatorCargus)+'&parola='+RTRIM(@parolaCargus)+'&awb='+RTRIM(@awb)+'" target="_blank" /><u> Click </u></a>'

		select * from #date_car for xml raw, root('Date')
	end
