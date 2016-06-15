--***
CREATE procedure rapCateg @categ char(9),@data_jos datetime, @data_sus datetime, @calcul bit
as
set transaction isolation level read uncommitted
If @calcul = 1  exec dbo.CalcCategInd @categ,@data_jos,@data_sus,1,0

select i.cod_indicator, max(i.descriere_expresie) descriere_expresie, c.cod_categ, max(cat.denumire_categ) denumire_categ, c.rand,
	sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as val_initiala,sum(cast(isnull(v2.valoare,0) as decimal(15,2))) as val_finala  from indicatori i
left outer join compcategorii c on c.cod_ind = i.cod_indicator
inner join categorii cat on cat.cod_categ = c.cod_categ
left outer join expval v1 on i.cod_indicator = v1.cod_indicator and v1.data = @data_jos
left outer join expval v2 on i.cod_indicator = v2.cod_indicator and v2.data = @data_sus
where c.cod_categ = @categ and c.Rand<>0
group by i.cod_indicator,c.cod_categ,c.rand
order by c.rand
