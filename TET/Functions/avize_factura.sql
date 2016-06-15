--***
create function  avize_factura (@factura char(20), @tert char(13), @tip char(20)) returns char(100) as
begin 
	declare @cText char(100), @nfetch int, @numar varchar(20), @cSub char(9) 
	set @cText = '' 
	select @cSub=left(val_alfanumerica,9) from par where tip_parametru='GE' and parametru='SUBPRO'
	declare tmpav cursor for 
	select distinct rtrim(numar) from doc 
	where @tip in ('AP', '') and subunitate=@cSub and tip='AP' and factura=@factura and (@tert='' or cod_tert=@tert) 
	union all 
	select distinct rtrim(d.numar) from doc d, pozadoc p 
	where @tip in ('IF', '') and p.subunitate=@cSub and p.tip='IF' and p.factura_stinga=@factura and (@tert='' or p.tert=@tert) 
	and d.subunitate=p.subunitate and d.tip='AP' and p.factura_dreapta=d.factura and d.cod_tert=p.tert 
	open tmpav 
	fetch next from tmpav into @numar 
	set @nfetch = @@fetch_status 
	while @nfetch = 0 
	begin 
		set @cText = RTrim(@cText) + ',' + RTrim(@numar) 
		fetch next from tmpav into @numar 
		set @nfetch = @@fetch_status 
	end 
 
	if RTrim(@cText) <> '' set @cText = substring(@cText, 2, 100) 
 
	close tmpav 
	deallocate tmpav 
 
	return @cText 
end 
