select * from pozdoc p where p.Cod='00600012'
and 'S096BB0AE-94E' in (p.Cod_intrare,p.Grupa) and '211.nt' in (p.Gestiune,p.Gestiune_primitoare)

select * from sysspd p where p.Cod='00600012'
and 'S096BB0AE-94E' in (p.Cod_intrare,p.Grupa) and '211.nt' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data_stergerii 


select * -- delete p
from istoricstocuri p where p.Cod='00600012'
and 'S096BB0AE-94E' in (p.Cod_intrare) and '211.nt' in (p.cod_Gestiune)

select * from dbo.fStocuri(null,'2013-10-31','00600012','211.nt','S096BB0AE-94E','','D','',0,'','','','','','',null)
select * from dbo.fStocuriCen('2013-10-31','00600012','211.nt','S096BB0AE-94E',1,1,1,'D','','','','','','','','')

select * -- update p set val_numerica=9
from par p where p.Val_numerica=10 and p.Parametru='LUNAINC  ' and p.Tip_parametru='GE'