-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		
-- Create date: 
-- Description:	
-- =============================================
CREATE FUNCTION yso_fTransferuriPachete 
(	
	-- Add the parameters for the function here
	@subunitate varchar(10)
	,@cod varchar(20)
	,@gestiune varchar(10)
	,@cod_intrare varchar(20)
	,@data datetime
	,@luni int
)
RETURNS TABLE 
AS
RETURN 
(with transferuri as
	(select p.Subunitate, p.Data, p.Cod
		,Gestiune=(case when p.Cantitate>=0.001 then p.Gestiune else p.Gestiune_primitoare end)
		,Cod_intrare=(case when p.Cantitate>=0.001 then p.Cod_intrare else p.Grupa end)
		,Gestiune_primitoare=(case when p.Cantitate>=0.001 then p.Gestiune_primitoare else p.Gestiune end)
		,Cod_intrare_primitor=(case when p.Cantitate>=0.001 then p.Grupa else p.Cod_intrare end)
	from pozdoc p where p.Subunitate='1' and p.Tip='TE' and abs(p.Cantitate)>=0.001)
	-- Add the SELECT statement with parameter references here
	select top 1 p.Subunitate, p.Gestiune_primitoare, p.Cod_intrare_primitor
	from transferuri p
	where p.Subunitate=@subunitate and p.Cod=@cod 
		and p.Gestiune=@gestiune and p.Cod_intrare=@cod_intrare and DATEDIFF(M,@data,p.data)<=@luni
)
GO
