
create procedure wIaUrlServiciuCargus @url varchar(600) OUTPUT
as
begin
	declare 
		@utilizatorCargus varchar(200), @parolaCargus varchar(200), @url_serviciu varchar(600)

	set @url_serviciu='http://webexpress.cargus.ro/custom_print/shipment_import/nt.php'

	exec luare_date_par 'AR','USRCARGUS',0,0,@utilizatorCargus OUTPUT
	exec luare_date_par 'AR','PASCARGUS',0,0,@parolaCargus OUTPUT

	select @utilizatorCargus=rtrim(@utilizatorCargus), @parolaCargus=RTRIM(@parolaCargus)

	select @url=@url_serviciu+'?user='+@utilizatorCargus+'&parola='+@parolaCargus


end
