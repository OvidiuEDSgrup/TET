select * -- update f set tip=isnull(tip,''), subtip=isnull(subtip,'')
from webconfigform f left join webconfigform d on d.Meniu=f.Meniu and f.Tip=d.Tip and f.Subtip=d.Subtip and f.DataField=d.DataField
where f.Tip is null and d.Meniu is not null
--0233/234357; /282345
--em.I.junghiuprodprosper.ro
select * -- update f set tip=isnull(tip,''), subtip=isnull(subtip,'')
from webconfigstdform f where f.Tip is null or f.Subtip is null