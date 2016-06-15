CREATE FUNCTION [dbo].[iaArboreTehn]
(
    @id int,@cantitate float = 0
)
RETURNS XML
AS

BEGIN
declare 
	@tip varchar(1),@idt int
	--Daca este tipul R nu vom gasi copii ca si avand IDP ID-ul lui, ci vor fi cu tipul T in pozTehnologii la codul respectiv
	set @tip=(select tip from pozTehnologii where id=@id )
	if @tip='R'
	begin
		set @idt = (select id from pozTehnologii where cod = ( select cod from pozTehnologii where id=@id) and idp is NULL)
		set @id=@idt
	end	 
	
	if @tip='M'
	begin
		declare @cod varchar(20)
		set @cod=(select cod from pozTehnologii where id=@id) 
		if (select tip from nomencl where cod=@cod)='P'
		begin
			if (select count(1) from tehnologii where codNomencl = @cod ) > 0
			begin
				set @cod= (select top 1 cod from tehnologii where codNomencl=@cod)
				set @id= (select top 1 id from pozTehnologii where tip='T' and cod=@cod)
			end
		end
	end	
	
	RETURN 
	(	
		select 
			(case when tip in ('M','Z') then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) as denumire ,
			(case when tip in ('M','Z') then (select rtrim(um) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(um) from catop where cod=pozTehnologii.Cod) end ) as um,
			(case when tip='R' then 'RS' when tip='M' then 'MT' when tip='O' then 'OP' when tip='Z' then 'RZ' else 'TT' end)as subtip ,
			((case when tip in ('M','Z') then (select rtrim(denumire) from nomencl where cod= pozTehnologii.cod) when tip='O' then  (select rtrim(Denumire) from catop where cod=pozTehnologii.Cod) else '' end) +' ('+rtrim(cod)+')') as denumireCod,
			(case when tip in ('R')  then (select t.id from pozTehnologii t where t.tip='T' and t.idp is null and t.cod=pozTehnologii.cod) 
					when (tip='M' and (select dbo.areTehnologie(cod)) > 0) then (select dbo.areTehnologie(cod)) else id  end) as id,
			(case when tip='O' then 'Operatie' when tip='R' then 'Reper'  when (tip='M' and (select tip from nomencl where cod=pozTehnologii.cod)='P' )then 'Semifabricat' when tip='Z' then 'Rezultat' else 'Material' end )as _grupare, 
			isnull(convert(decimal(10,2),ordine_o),0) as ordine,rtrim(cod) as cod, idp as idParinte,id as idReal,ISNULL(convert(decimal(16,6),cantitate_i),0) as cant_i,
			rtrim(resursa) as lm,CONVERT(decimal(12,3),pret) as pret ,tip as tip,
			(case when @cantitate>0 then CONVERT(decimal(16,6),cantitate*@cantitate) else convert(decimal(16,6),cantitate) end) as cantitate,
			--(case when (@cantitate>0 and (tip='R' or (select tip from pozTehnologii where id=idp)='R')) then convert(xml,dbo.iaArboreTehn(id,cantitate*@cantitate)) else convert(xml,dbo.iaArboreTehn(id,DEFAULT)) end)
			(case when (@cantitate>0 ) then convert(xml,dbo.iaArboreTehn(id,cantitate*@cantitate)) else convert(xml,dbo.iaArboreTehn(id,DEFAULT)) end)
		from pozTehnologii 
		where idp=@id and tip not in ('A','L','E')
		order by idp 
		for xml raw,type
	)

END
