
(select * from stocuri s where s.Comanda like '2810824124246' 
and s.Contract like '9820290'
and s.Cod_gestiune='700'
and s.Cod in ('1807cu3','5243G015004000'))

select * from pozdoc p where p.Numar like '[0-9]00[0-9][0-9]'
and p.Gestiune='700' 
and p.Cod in ('1807cu3','5243G015004000')

select * from stocuri s where s.Cod_gestiune='700' and s.Cod in ('1807cu3','5243G015004000')
and exists
(select * from pozdoc p where p.Numar like '[0-9]00[0-9][0-9]'
and p.Gestiune=s.Cod_gestiune 
and p.Cod=s.Cod and s.Cod_intrare=p.Cod_intrare
)