--***
create procedure rapGraficeIndicatori (@datajos datetime, @datasus datetime, @categoria varchar(20), @cudate int=1)
as
select row_number() over (order by max(ordine_in_raport)) as ordine,i.cod_indicator, max(descriere_expresie) as descriere_expresie
from indicatori i
	left join compcategorii c on i.cod_indicator=c.cod_ind
	left join colind ci on ci.Cod_indicator=i.Cod_Indicator and ci.Numar=0
where (@cudate=0 or
		exists (select 1 from expval e where data between @datajos and @datasus and e.cod_indicator=i.cod_indicator))
	and (@categoria is null or c.cod_categ=@categoria) and c.rand<>0
	group by i.cod_indicator
order by max(ordine_in_raport)
