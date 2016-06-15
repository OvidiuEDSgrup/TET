--***
create procedure rapGraficIndicator (@datajos datetime, @datasus datetime, @indicator varchar(20))
as

select e.valoare,e.data,
	e.cod_indicator, i.denumire_indicator as denumire
	,s.val_min,s.val_max,isnull(c.tip_grafic,0) as tip_grafic
	from expval e 
		inner join indicatori i on e.cod_indicator=i.cod_indicator
		left join semnific s on s.referinta=1 and s.indicator=e.cod_indicator
		left join colind c on c.Cod_indicator=i.Cod_Indicator and c.Numar=0
		where @indicator is not null and 
			e.cod_indicator=@indicator and e.data between @datajos and @datasus and e.tip='E'
	--group by e.data
	order by e.data,e.valoare desc
 --group by cod_indicator
