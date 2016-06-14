select *, 
--update bp set 
Loc_de_munca=ISNULL(a.Cod_gestiune,'210.'+dbo.fStrToken(bp.Vinzator,2,'_'))
from bp join gestiuni g on g.Cod_gestiune=bp.Loc_de_munca and g.Tip_gestiune<>'a'
left join gestiuni a on a.Cod_gestiune=REPLACE(bp.Loc_de_munca,'211.','210.') and a.Tip_gestiune='a'
--where a.Cod_gestiune is null

select *, 
--update bp set 
gestiune=ISNULL(a.Cod_gestiune,'210.'+dbo.fStrToken(bp.Vinzator,2,'_'))
from antetBonuri bp join gestiuni g on g.Cod_gestiune=bp.Gestiune and g.Tip_gestiune<>'a'
left join gestiuni a on a.Cod_gestiune=REPLACE(bp.Gestiune,'211.','210.') and a.Tip_gestiune='a'
--where a.Cod_gestiune is null