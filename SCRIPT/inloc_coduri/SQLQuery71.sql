select Gestiune_primitoare,Cont_intermediar,*
--update pozdoc set Cont_intermediar='371.1' 
from pozdoc 
where tip='AP' and data between '05/01/2014' and '07/31/2014' and gestiune_primitoare not like '378%'  and gestiune_primitoare<>'' and Cont_intermediar=''
order by data