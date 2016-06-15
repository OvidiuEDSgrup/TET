--***
create function fOrdineElement_1_TB (@categorie varchar(50))
returns @ordonareElement table (ordine int, element_1 varchar(50), din_tabel bit)
as
begin
	--declare @ordonareElement table (setOrdonare int, ordine int, element_1 varchar(50))
	insert into @ordonareElement(ordine, element_1, din_tabel)
	select o.ordine, rtrim(o.element_1), 1
	from cfgOrdineElement1 o where o.categorie=@categorie
	order by o.ordine
	
	declare @maxOrdineCfg int
	select @maxOrdineCfg=isnull((select max(ordine) from cfgOrdineElement1 c where c.categorie=@categorie),0)

	insert into @ordonareElement(ordine, element_1, din_tabel)
	select @maxOrdineCfg+row_number() over (order by element_1) ordine, rtrim(element_1), 0
	from expval e inner join compcategorii c on e.Cod_indicator=c.Cod_Ind
	where c.Cod_Categ=@categorie
		and not exists (select 1 from @ordonareElement o where e.element_1=o.element_1)
	group by e.element_1
	order by e.Element_1
	return
end
