select p.Gestiune_primitoare,p.Cont_intermediar,* --Gestiune_primitoare='378.0'
-- update p set Gestiune_primitoare='378.0'
from pozdoc  p
where tip='AP' and data between '08/01/2014' and '08/31/2014' 
and gestiune_primitoare not  like '378%' and Cont_intermediar=''

exec faInregistrariContabile