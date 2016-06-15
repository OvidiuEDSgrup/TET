--***
create procedure rapRaportCategorii @calcul int, @categ varchar(20), 
		@data_jos datetime, @data_sus datetime, @element_1 varchar(20)
as
begin
	set transaction isolation level read uncommitted
	declare @q_calcul int, @q_categ varchar(20), @q_data_jos datetime, @q_data_sus datetime
	set @q_calcul=@calcul set @q_categ=@categ set @q_data_jos=@data_jos set @q_data_sus=@data_sus
	if (@q_categ is null) return
	If @q_calcul = 1  exec dbo.CalcCategInd @q_categ,@q_data_jos,@q_data_sus,1,0  
	  
	select i.cod_indicator,max(i.descriere_expresie) descriere_expresie,c.cod_categ
		,c.rand
		,sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as val_initiala
		,sum(cast(isnull(v2.valoare,0) as decimal(15,2))) as val_finala  
		,max(cat.denumire_categ) denumire_categ
		from indicatori i  
	left outer join compcategorii c on c.cod_ind = i.cod_indicator  
	inner join categorii cat on cat.cod_categ = c.cod_categ  
	left outer join expval v1 on i.cod_indicator = v1.cod_indicator and v1.data = @q_data_jos  
	left outer join expval v2 on i.cod_indicator = v2.cod_indicator and v2.data = @q_data_sus 
		and v1.Element_1=v2.Element_1 and v1.Element_2=v2.Element_2
		and v1.Element_3=v2.Element_3 and v1.Element_4=v2.Element_4
		and v1.Element_5=v2.Element_5
	where c.cod_categ = @q_categ and (@element_1 is null or v1.Element_1=@element_1)
	group by i.cod_indicator,c.cod_categ,c.rand--,v1.data,v2.data  
	order by c.rand
end