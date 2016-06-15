CREATE  procedure [dbo].[iaArborePlan] @id int,@eAntec bit,@flat xml out,@cantitate float = 0
as
begin
		declare @doc xml
		set @flat=''
		if @eAntec = 1		
			set @doc = 
			(
				select   
					(case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) as denumire ,
					(case when tip='O' then 'Operatie' when tip='R' then 'Reper' when tip='S' then 'Structura' when tip='M' then 'Material' end )as _grupare, 
					((case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) +' ('+rtrim(cod)+')') as denumireCod,
					(case when tip='M' then (select rtrim(um) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(um) from catop where cod=pozTehnologii.Cod) else '' end) as um ,
					 convert(xml,dbo.iaArboreAntec(id)),id as id,
					(case when @cantitate>0 then convert(decimal(10,2),cantitate*@cantitate) else convert(decimal(10,2),cantitate) end ) as cantitate,ISNULL(cantitate_i,0) as cant_i,
					rtrim(cod) as cod, idp as idParinte, rtrim(resursa) as lm, convert(decimal(10,2),pret) as pret ,tip as tip,
					isnull(convert(decimal(10,2),ordine_o),0) as ordine,id as idReal
				from pozTehnologii
				where idp=@id and tip not in ('E','L')
				for xml raw,root('row')
			)
		else
			set @doc = 
			(
				select   
					(case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) as denumire ,
					(case when tip='O' then 'Operatie' when tip='R' then 'Reper' when tip='S' then 'Structura' when tip='M' then 'Material' end )as _grupare, 
					((case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) +' ('+rtrim(cod)+')') as denumireCod,
					(case when tip='M' then (select rtrim(um) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(um) from catop where cod=pozTehnologii.Cod) else '' end) as um ,
					(case when (@cantitate>0 and tip in ('R','O','M')) then convert(xml,dbo.iaArboreTehn(id,cantitate*@cantitate)) 
										else convert(xml,dbo.iaArboreTehn(id,DEFAULT))end),	
					(case when tip in ('R')  then (select t.id from pozTehnologii t where t.tip='T' and t.idp is null and t.cod=pozTehnologii.cod) 
					when (tip='M' and (select dbo.areTehnologie(cod)) > 0) then (select dbo.areTehnologie(cod)) else id  end) as id,
					(case when @cantitate>0 then convert(decimal(10,2),cantitate*@cantitate) else convert(decimal(10,2),cantitate) end ) as cantitate,ISNULL(cantitate_i,0) as cant_i,
					rtrim(cod) as cod, idp as idParinte, rtrim(resursa) as lm, convert(decimal(10,2),pret) as pret ,tip as tip,
					isnull(convert(decimal(10,2),ordine_o),0) as ordine,id as idReal
				from pozTehnologii
				where idp=@id and tip not in ('A','L')
				for xml raw,root('row')
			)		

		exec transformaArbore @doc,@flat out
end
