create view yso_vIaCodvama with schemabinding as 
select rtrim(Cod) as Cod, Denumire
	, Val1 as Tip_cod, case Val1 when 0 then 'Cod vamal' when 1 then 'Cod nom. combinat' else '' end as Den_tip
	, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament
	, rtrim(Alfa1) as Cod_NC8
	, rtrim(Alfa2) as UM_suplimentara
	--,CONVERT(nvarchar(500),'') as _eroareimport
from dbo.codvama c
	--inner join dbo.nomencl n on n.cod=c.cod

GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[yso_vIaCodvama]([Cod] ASC) WITH (STATISTICS_NORECOMPUTE = ON);


GO
CREATE UNIQUE NONCLUSTERED INDEX [modificabile]
    ON [dbo].[yso_vIaCodvama]([Cod] ASC)
    INCLUDE([Denumire], [Tip_cod], [UM], [UM2], [Coef_conv], [Taxa_UE], [Taxa_AELS], [Taxa_GB], [Taxa_alte_tari], [Comision_vamal], [Randament], [Cod_NC8], [UM_suplimentara]) WITH (STATISTICS_NORECOMPUTE = ON);

