select *,
--update pozdoc set 
Cont_intermediar='371.0' 
from pozdoc 
where tip='AC' and data between '05/01/2014' and '05/31/2014' and gestiune_primitoare not like '378%'  and gestiune_primitoare<>'' and Cont_intermediar=''