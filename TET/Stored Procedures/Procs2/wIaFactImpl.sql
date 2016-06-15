--***
create procedure [dbo].wIaFactImpl @sesiune varchar(30), @parXML XML
AS  
begin  
	declare @data_implementare datetime,@data_jos datetime,@data_sus datetime,@an_impl int,@luna_impl int,@mod_impl int,@tiptert char(1)
	select  @data_implementare='1901-01-01',
			@data_jos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '1901-01-01') ,
			@data_sus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '2901-01-01') 
			,@tiptert=isnull(@parXML.value('(/row/@tiptert)[1]', 'char(1)'), '') 

	exec luare_date_par @tip='GE', @par='ANULIMPL', @val_l=0, @val_n=@an_impl output, @val_a=''
	exec luare_date_par @tip='GE', @par='LUNAIMPL', @val_l=0, @val_n=@luna_impl output, @val_a=''
	exec luare_date_par @tip='GE', @par='IMPLEMENT', @val_l=@mod_impl output, @val_n=0, @val_a=''		

	select top 100 (case a.tip when 0x46 then 'B' when 0x54 then 'F' else '' end) as tiptert,convert(decimal(17,4),sum(a.Valoare))as t_valoare,convert(decimal(17,4),sum(a.sold))as t_sold,
			convert(decimal(17,4),sum(a.Achitat))as t_achitat,COUNT(*) as nr_facturi,@data_sus as datasus,@data_jos as datajos,
			(case a.tip when 0x46 then 'Facturi beneficiari' when 0x54 then 'Facturi furnizori' else '' end) as dentiptert
	from factimpl a
	where a.Data between @data_jos and @data_sus	
	and (@tiptert='' or (@tiptert='B' and a.tip=0x46 or @tiptert='F' and a.tip=0x54) )
	group by a.tip
	order by a.Tip desc
	for xml raw
end
