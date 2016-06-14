select * from stocuri s where s.Cod in 
('9075030')
select * from pozdoc p where p.Cod='9075030'
and p.Tip='TE' and p.Gestiune_primitoare='211.BH'

select * -- update p set gestiune='101'
from pozdoc p where --p.Cod='9075030'
 p.Tip='RM' and p.Contract like '9081'