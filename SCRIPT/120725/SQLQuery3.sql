--/*
select * 
--*/update p set p.Loc_munca=i.Loc_munca
from infotert p inner join infotert i on i.Subunitate=p.Subunitate and i.Tert=p.Tert and i.Identificator='' and p.Identificator<>''
where i.Loc_munca<>p.Loc_munca