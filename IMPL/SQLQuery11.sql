select dbo.formezCodIntrare(p.tip,p.numar,p.data,p.cod,p.gestiune,p.cont_de_stoc,p.pret_de_stoc)
,* from pozdoc p where p.Tip='AP' and p.Gestiune='212' and p.Cantitate<0 and p.Cod_intrare=''

--update pozdoc
set Cod_intrare= dbo.formezCodIntrare(p.tip,p.numar,p.data,p.cod,p.gestiune,p.cont_de_stoc,p.pret_de_stoc)
from pozdoc p where p.Tip='AP' and p.Gestiune='211' and p.Cantitate<0 and p.Cod_intrare=''