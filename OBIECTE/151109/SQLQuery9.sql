select * --update m set meniu='RN_FILIALE'
-- delete m
from webConfigMeniuUtiliz m left join webConfigMeniuUtiliz u on u.IdUtilizator=m.IdUtilizator and u.Meniu='RN_FILIALE'
where m.Meniu like 'RN' and u.Meniu is not null