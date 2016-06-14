select * from par p where p.Parametru like 'OLDINCON'
declare @compUrmaPozincon int
exec luare_date_par 'GE','OLDINCON',@compUrmaPozincon OUTPUT,0,''
select @compUrmaPozincon 