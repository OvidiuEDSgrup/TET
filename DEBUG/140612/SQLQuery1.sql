select *,
--UPDATE pozplin set
decont='145/1'
from pozplin p where p.Subunitate='1' and p.Cont='5311.1' and p.Data between '2014-03-01' and '2014-03-31' and p.Plata_incasare='PD' and p.marca='145'
--alter table pozplin enable trigger plindec
--exec RefacereDeconturi null,null,null
