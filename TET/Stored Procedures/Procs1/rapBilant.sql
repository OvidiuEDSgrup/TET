--***
create procedure rapBilant @calcul int,	--> 1=cu calcul, 0=fara calcul
	@categ varchar(20)=null, 
	@data_jos datetime,
	@data_sus datetime,
	@element_1 varchar(20)=null
as
begin
	set transaction isolation level read uncommitted
	declare @q_calcul int, @q_categ varchar(20), @q_data_jos datetime, @q_data_sus datetime, @dataCalc datetime
	select @q_calcul=@calcul ,@q_categ=@categ ,@q_data_jos=@data_jos ,@q_data_sus=@data_sus, @dataCalc=dbo.eom(dateadd(M,-1,@q_data_jos))
	if (@q_categ is null) return
	If @q_calcul = 1  exec dbo.CalcCategInd @q_categ, @dataCalc, @q_data_sus,0,0
		
	select 
		@q_data_jos=isnull((select max(data) from expval e inner join compcategorii c on e.Cod_indicator=c.Cod_Ind
			where c.Cod_Categ=@q_categ and e.Data<=@q_data_jos),@q_data_jos)
		,@q_data_sus=isnull((select max(data) from expval e inner join compcategorii c on e.Cod_indicator=c.Cod_Ind
			where c.Cod_Categ=@q_categ and e.Data<=@q_data_sus),@q_data_sus)
	
	select cod_indicator, max(descriere_expresie) descriere_expresie, cod_categ, rand
		,sum(val_initiala) val_initiala, sum(val_finala) val_finala, max(c.denumire_categ) denumire_categ
		,max(@q_data_jos) as data_jos, max(@q_data_sus) as data_sus
	from(
		select i.cod_indicator,max(i.descriere_expresie) descriere_expresie,c.cod_categ
			,c.rand
			,sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as val_initiala
			,0 as val_finala  
			,max(cat.denumire_categ) denumire_categ
			from indicatori i
		left outer join compcategorii c on c.cod_ind = i.cod_indicator  
		inner join categorii cat on cat.cod_categ = c.cod_categ  
		left outer join expval v1 on i.cod_indicator = v1.cod_indicator and v1.data = @q_data_jos
			 and (@element_1 is null or v1.Element_1=@element_1)
		where c.cod_categ = @q_categ and c.rand<>0
		group by i.cod_indicator,c.cod_categ,c.rand--,v1.data,v2.data
		union all
		select i.cod_indicator,max(i.descriere_expresie) descriere_expresie,c.cod_categ
			,c.rand
			,0 as val_initiala
			,sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as val_finala
			,max(cat.denumire_categ) denumire_categ
			from indicatori i  
		left outer join compcategorii c on c.cod_ind = i.cod_indicator  
		inner join categorii cat on cat.cod_categ = c.cod_categ  
		left outer join expval v1 on i.cod_indicator = v1.cod_indicator and v1.data = @q_data_sus 
				 and (@element_1 is null or v1.Element_1=@element_1)
		where c.cod_categ = @q_categ and c.rand<>0
		group by i.cod_indicator,c.cod_categ,c.rand--,v1.data,v2.data
		) c
	group by c.cod_indicator,c.cod_categ,c.rand
	order by c.rand
end
