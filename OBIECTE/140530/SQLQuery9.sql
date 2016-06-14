SELECT p.Pret_cu_amanuntul,p.Pret_amanunt_predator,p.Gestiune_primitoare,* FROM pozdoc p where p.Data='2014-05-27' and p.Numar='IS100001'
select * -- update p set val_logica=0
from par p where p.Parametru like 'fara%'
--exec RefacereStocuri null,null,null,null,null,null