CREATE FUNCTION [dbo].[yso_fTransferuriPachete] 
(	
	-- Add the parameters for the function here
	@subunitate varchar(10)
	,@cod varchar(20)
	,@gestiune varchar(10)
	,@cod_intrare varchar(20)
	,@data datetime
	--,@nrluni int
)
RETURNS TABLE AS RETURN 
with transferuri as
	(select p.Subunitate, p.Data, p.Cod
		,Gestiune=(case when p.Cantitate>=0.001 then p.Gestiune else p.Gestiune_primitoare end)
		,Cod_intrare=(case when p.Cantitate>=0.001 then p.Cod_intrare else p.Grupa end)
		,Gestiune_primitoare=(case when p.Cantitate>=0.001 then p.Gestiune_primitoare else p.Gestiune end)
		,Cod_intrare_primitor=(case when p.Cantitate>=0.001 then p.Grupa else p.Cod_intrare end)
	from pozdoc p where p.Subunitate='1' and p.Tip='TE' and abs(p.Cantitate)>=0.001)
	-- Add the SELECT statement with parameter references here
	select distinct p.Subunitate, p.Gestiune_primitoare, p.Cod_intrare_primitor
	from transferuri p
	where p.Subunitate=@subunitate and p.Cod=@cod 
		and p.Gestiune=@gestiune and p.Cod_intrare=@cod_intrare

