create FUNCTION [dbo].[iaArboreAntec]
(
    @id int
)
RETURNS XML
AS
BEGIN
	RETURN 
	(	
		select 
			(case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) as denumire ,
			(case when tip='M' then (select rtrim(um) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(um) from catop where cod=pozTehnologii.Cod) end ) as um,			
			((case when tip='M' then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) +' ('+rtrim(cod)+')') as denumireCod,
			(case when tip='O' then 'Operatie' when tip='R' then 'Reper'  when (tip='M' and (select tip from nomencl where cod=pozTehnologii.cod)='P' )then 'Semifabricat' else 'Material' end )as _grupare, 
			CONVERT(decimal(10,2),cantitate) as cantitate, rtrim(resursa) as lm,CONVERT(decimal(10,2),pret) as pret ,tip as tip,
			isnull(convert(decimal(10,2),ordine_o),0) as ordine,rtrim(cod) as cod,  id as id, idp as idParinte,ISNULL(cantitate_i,0) as cant_i,
			convert(xml,dbo.iaArboreAntec(id))
		from pozTehnologii 
		where idp=@id and tip <> 'E'
		order by tip 
		for xml raw,type
	)

END
