select p.Contract,* -- delete p
from pozdoc p where p.Numar like 'AG940327' and p.Cod='BST-CRB061604'
select p.Tert,* -- delete p
from pozdoc p where p.Gestiune='211.ag' and p.Cod_intrare='ST876893' and p.Cod='BST-CRB061604'
--'AG940335'
select * from antetBonuri a where a.Factura='AG940335'

select * -- delete p
from pozcon p where p.Contract='AG980370            ' and p.Cod<>'BST-CRB061604'