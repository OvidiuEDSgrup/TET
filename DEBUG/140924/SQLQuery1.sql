select p.Contract,* from pozdoc p where p.Factura='AG940327'
and p.Cod='BST-CRB061604'
and p.Cod_intrare='ST876893'            

select * from pozdoc p where p.Cod='BST-CRB061604'
and 'ST876893' in (p.Cod_intrare,p.Grupa)