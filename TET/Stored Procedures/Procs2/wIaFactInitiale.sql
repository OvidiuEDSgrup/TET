--***
create procedure [dbo].wIaFactInitiale @sesiune varchar(30), @parXML XML
AS  
begin  
	declare @data_implementare datetime,@data_jos datetime,@data_sus datetime,@an_impl int,@luna_impl int,@mod_impl int
	select  @data_implementare='1901-01-01',
			@data_jos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '1901-01-01') ,
			@data_sus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '2901-01-01') 

	exec luare_date_par @tip='GE', @par='ANULIMPL', @val_l=0, @val_n=@an_impl output, @val_a=''
	exec luare_date_par @tip='GE', @par='LUNAIMPL', @val_l=0, @val_n=@luna_impl output, @val_a=''
	exec luare_date_par @tip='GE', @par='IMPLEMENT', @val_l=@mod_impl output, @val_n=0, @val_a=''		

	select top 100 a.tip as tiptert,convert(decimal(17,4),sum(a.Valoare))as t_valoare,convert(decimal(17,4),sum(a.sold))as t_sold,
			convert(decimal(17,4),sum(a.Achitat))as t_achitat,COUNT(*) as nr_facturi,convert (char(10),a.data_an,101)as data_an,
			(case a.tip when 'B' then 'Facturi beneficiari' when 'F' then 'Facturi furnizori' else '' end) as dentiptert,
			@data_jos as datajos,@data_sus as datasus
	from istfact a
	--where a.Data between @data_jos and @data_sus	
	group by a.tip,a.Data_an
	order by a.Tip desc
	for xml raw
end

--select * from istfact
