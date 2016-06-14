select p.Factura,p.Locatie,p.Tert,p.Contract,* from pozdoc p where p.Cod like 'BST-CRB061604' and '211.AG' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data
select * from istoricstocuri i --where i.Cod like 'BST-CRB061604' and '211.AG' in (i.Cod_gestiune)
order by i.Data_lunii

select * from stocuri i where i.Cod like 'BST-CRB06160_' and '211.AG' in (i.Cod_gestiune)
order by i.Data

select * from fStocuriCen('2014-09-23','BST-CRB061604','211.AG',null,1,1,1,null,null,null,null,null,null,null,null,null,null) s