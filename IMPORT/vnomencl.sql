CREATE PROC yso_test @UM smallint, @tipPret char(20) AS

SELECT preturi.Cod_produs, preturi.UM, preturi.Tip_pret, preturi.Data_inferioara, preturi.Ora_inferioara, preturi.Data_superioara, preturi.Ora_superioara, preturi.Pret_vanzare, preturi.Pret_cu_amanuntul, preturi.Utilizator, preturi.Data_operarii, preturi.Ora_operarii
FROM TEST.dbo.preturi preturi
WHERE (preturi.UM=@UM) AND (preturi.Tip_pret=@tipPret)
ORDER BY preturi.Pret_vanzare

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
-- Author:		yso_ftest
-- Create date: 
-- Description:	
-- =============================================
CREATE FUNCTION yso_ftest 
(	
	-- Add the parameters for the function here
	@um int, 
	@tipPret char(20)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT preturi.Cod_produs, preturi.UM, preturi.Tip_pret, preturi.Data_inferioara, preturi.Ora_inferioara, preturi.Data_superioara, preturi.Ora_superioara, preturi.Pret_vanzare, preturi.Pret_cu_amanuntul, preturi.Utilizator, preturi.Data_operarii, preturi.Ora_operarii
FROM TEST.dbo.preturi preturi
WHERE (preturi.UM=@UM) AND (preturi.Tip_pret=@tipPret)
)
GO

create view yso_vtest as
	SELECT ROW_NUMBER() OVER(ORDER BY Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii) nrcrt
	,preturi.Cod_produs, preturi.UM, preturi.Tip_pret, preturi.Data_inferioara, preturi.Ora_inferioara, preturi.Data_superioara, preturi.Ora_superioara, preturi.Pret_vanzare, preturi.Pret_cu_amanuntul, preturi.Utilizator, preturi.Data_operarii, preturi.Ora_operarii
FROM TEST.dbo.preturi preturi
--WHERE (preturi.UM=@UM) AND (preturi.Tip_pret=@tipPret)
go
DROP view yso_vtestn 
GO
create view yso_vtestn as
SELECT ROW_NUMBER() OVER(ORDER BY n.Cod) nrcrt,
		rtrim(n.cod) as cod
		,rtrim(n.denumire) as denumire
		,n.tip
		, dbo.denTipNomenclator(n.tip) as dentip
		,rtrim(n.grupa) as grupa
		, rtrim(isnull(grupe.Denumire,n.grupa)) as degrupa
		,rtrim(n.um) as um,isnull(RTRIM(um.Denumire),'') as denum,
		RTRIM(n.Furnizor) as furnizor, isnull(rtrim(terti.Denumire),'') as denfurnizor
		, rtrim(n.Tip_echipament) as observatii,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_cu_amanuntul, isnull(PretImplicit.Pret_cu_amanuntul, n.pret_cu_amanuntul)), 0)) as pret,
		convert(decimal(12,3),n.pret_stoc) as pret_stocn,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_vanzare, isnull(PretImplicit.Pret_vanzare, n.Pret_vanzare)), 0)) as pretvanzare,
		convert(decimal(12,3),n.Pret_vanzare) as pretvanznom,
		rtrim(n.cont) as cont,rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont
		, convert(decimal(12,3),n.cota_tva) as cotatva,
		pozeria.fisier as poza, --rog lasati fara isnull
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare		
	from nomencl n 
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = '1' and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = '1' and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left join preturi pretCat on pretCat.Cod_produs=n.Cod and pretCat.um=4 and pretCat.Tip_pret=1 and pretCat.Data_superioara='2999-01-01' 
		left join preturi PretImplicit on PretImplicit.Cod_produs=n.Cod and PretImplicit.um=1 and PretImplicit.Tip_pret=1 and PretImplicit.Data_superioara='2999-01-01' 
		left outer join PozeRIA on pozeria.tip='N' and pozeria.cod=n.cod
go
drop PROC yso_istoricStocuri
go
CREATE PROC yso_istoricStocuri @UM smallint=null, @tipPret char(20)=null AS

select TOP @UM * from istoricStocuri where Subunitate=@UM