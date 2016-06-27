CREATE PROCEDURE [dbo].[IntocmireFactBenef] @hostID char(10) as 
--DECLARE @hostID char(10) 
--SET @hostID='4460'
--drop table [yso].[pozFactBenefTmp]

if OBJECT_ID('dbo.pozFactBenefTmp') IS NULL
BEGIN
	CREATE TABLE [dbo].[pozFactBenefTmp](
		Terminal [char](10) NOT NULL,
		[Subunitate] [char](9) NOT NULL,
		[Numar_document] [char](8) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Tert] [char](13) NOT NULL,
		[Tip] [char](2) NOT NULL,
		[Factura_stinga] [char](20) NOT NULL,
		[Factura_dreapta] [char](20) NOT NULL,
		[Cont_deb] [char](13) NOT NULL,
		[Cont_cred] [char](13) NOT NULL,
		sumaFactSt [float] NOT NULL,
		tvaFactSt [float] NOT NULL
	) ON [PRIMARY]
	CREATE UNIQUE NONCLUSTERED INDEX unic on [dbo].[pozFactBenefTmp] (Terminal, Subunitate, Tip, Numar_document, Data, Tert, Factura_stinga, Factura_dreapta)
END

DELETE [dbo].[pozFactBenefTmp]
WHERE Terminal=@hostID

INSERT INTO [dbo].[pozFactBenefTmp]
           ([Terminal]
           ,[Subunitate]
           ,[Numar_document]
           ,[Data]
           ,[Tert]
           ,[Tip]
           ,[Factura_stinga]
           ,[Factura_dreapta]
           ,[sumaFactSt]
           ,[tvaFactSt])
select @hostID, pa.Subunitate, pa.Numar_document, pa.Data, pa.Tert, pa.Tip, pa.factura_stinga, pa.factura_dreapta
	,sum(suma)as sumaFactSt, sum(tva22) as tvaFactSt
from pozadoc pa
	INNER JOIN avnefac ON pa.subunitate=avnefac.subunitate AND pa.tip=avnefac.tip AND pa.numar_document=avnefac.numar AND pa.data=avnefac.data  
WHERE avnefac.terminal=@hostID
GROUP BY pa.Subunitate, pa.Tip, pa.Numar_document, pa.Data, pa.Tert, pa.factura_stinga, pa.factura_dreapta
