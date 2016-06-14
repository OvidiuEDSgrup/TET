CREATE PROCEDURE yso_IntocmireFactBenef @hostID char(10) as 
--DECLARE @hostID char(10) 
--SET @hostID='4460'
--drop table [yso].[pozFactBenefTmp]

if OBJECT_ID('yso.pozFactBenefTmp') IS NULL
BEGIN
	CREATE TABLE [yso].[pozFactBenefTmp](
		Terminal [char](10) NOT NULL,
		[Subunitate] [char](9) NOT NULL,
		[Numar_document] [char](8) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Tert] [char](13) NOT NULL,
		[Tip] [char](2) NOT NULL,
		[Factura_stinga] [char](20) NOT NULL,
		[Factura_dreapta] [char](20) NOT NULL,
		sumaFactSt [float] NOT NULL,
		tvaFactSt [float] NOT NULL
	) ON [PRIMARY]
	CREATE UNIQUE NONCLUSTERED INDEX unic on [yso].[pozFactBenefTmp] (Terminal, Subunitate, Tip, Numar_document, Data, Tert, Factura_stinga, Factura_dreapta)
END

DELETE [yso].[pozFactBenefTmp]
WHERE Terminal=@hostID

INSERT INTO [yso].[pozFactBenefTmp]
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
GO
select *
FROM pozdoc 
left join pozadoc on pozadoc.subunitate=pozdoc.subunitate and pozadoc.tert=pozdoc.tert and pozadoc.factura_dreapta=pozdoc.factura 
left join avnefac on pozadoc.subunitate=avnefac.subunitate and pozadoc.tip=avnefac.tip and pozadoc.Numar_document=avnefac.numar and avnefac.data=pozadoc.data 
left join doc on pozdoc.subunitate=doc.subunitate and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data 
left join terti on pozdoc.subunitate=terti.subunitate and pozdoc.tert=terti.tert 
left join infotert on pozdoc.subunitate=infotert.subunitate and pozdoc.tert=infotert.tert and doc.Gestiune_primitoare=infotert.identificator 
left join nomencl on pozdoc.cod=nomencl.cod 
left join anexafac on anexafac.subunitate=pozdoc.subunitate and anexafac.numar_factura=pozadoc.Factura_stinga
--GROUP BY  pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune, pozdoc.tert, pozdoc.numar, pozdoc.data