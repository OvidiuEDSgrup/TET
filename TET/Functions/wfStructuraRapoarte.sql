--***

create function [dbo].[wfStructuraRapoarte](@ParentId uniqueidentifier=null)
returns xml
as begin

declare @utilizator varchar(10)
SET @utilizator = dbo.fIaUtilizator('')
--nu se da return daca nu se gaseste utilizator deoarece oricum nu face nimic daca nu il gaseste

declare @RapoarteUtilizator table(caleRaport varchar(500))

if exists (select 1 from sys.objects o where o.name='webConfigRapoarte')
insert into @RapoarteUtilizator (caleRaport) select caleRaport from webConfigRapoarte where utilizator=@utilizator
else insert into @RapoarteUtilizator (caleRaport) select convert(varchar(500),[Path]) --COLLATE
from ReportServer..Catalog

return
(
      select [Type] as '@tipnumeric', (case [Type] when 1 then 'Director' else 'Raport' end) as '@tip', 
      [Path] as '@cale', [Name] as '@nume', ItemId as '@Id', 
      dbo.wfStructuraRapoarte(ItemId)
      from ReportServer..Catalog r inner join @RapoarteUtilizator c 
            on r.[Path]=(convert(varchar(500),c.caleRaport) collate SQL_Latin1_General_CP1_CI_AS
            )
      where (@ParentId is null and ParentId is null or ParentId=@ParentId)
      and exists (select 1 from ReportServer..catalog r1 where r1.path like rtrim(r.path)+'%' and r1.Type=2)
      FOR XML PATH (N'row'), TYPE
)
end
