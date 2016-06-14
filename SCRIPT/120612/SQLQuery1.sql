select * from syssn s where s.cod like '0016793'
select * ,
--update n set loc_de_munca=
(select MAX(s.Loc_de_munca) from syssn s where s.Cod=n.Cod and s.Loc_de_munca<>'' and s.Loc_de_munca<>n.Loc_de_munca)
from nomencl n where n.Loc_de_munca in ('#N/A' ,'')
and exists
(select 1 from syssn s where s.Cod=n.Cod and s.Loc_de_munca<>'' and s.Loc_de_munca<>n.Loc_de_munca)                                                                                                        

select * 
-- update n set n.loc_de_munca=''
from nomencl n where n.Loc_de_munca='#N/A'

