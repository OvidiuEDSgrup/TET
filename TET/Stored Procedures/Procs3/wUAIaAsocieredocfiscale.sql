--***
Create PROCEDURE  [dbo].[wUAIaAsocieredocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS

declare @codcasier varchar(20)

select @codcasier=isnull(@parXML.value('(/row/@codcasier)[1]', 'varchar(20)'), '')

select rtrim(a.id) as id,rtrim(b.tipdoc) as tipdoc,rtrim(b.serie) as serie ,rtrim(b.numarinf) as numarinf,rtrim(b.numarsup) as numarsup,
rtrim(b.ultimulnr) as ultimulnr,RTRIM(a.prioritate) as prioritate,(case when b.tipdoc='UC' then 'Contracte UA' else
 (case when b.tipdoc='UF' then 'Facturi UA' else (case when b.TipDoc='UI' then 'IncasariUA' else 'Compensari UA' end) end) end )
 +' Serie '+rtrim(b.serie) +' Nr inf '+rtrim(b.Numarinf ) +' Nr sup '+rtrim(b.Numarsup ) +' Ultimul nr '+rtrim(b.UltimulNr ) as denumire
from asocieredocfiscale a
inner join docfiscale b on a.id=b.id and b.tipdoc in ('UI','UP','UC','UF') 
where a.Cod=@codcasier
for xml raw
