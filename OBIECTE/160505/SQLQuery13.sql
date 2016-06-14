select top (100) * 
from antetBonuri a where a.Bon is not null
order by a.IdAntetBon desc