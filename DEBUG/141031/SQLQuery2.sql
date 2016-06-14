create table #documente (nrp int identity(1,1),c char(1))

set identity_insert #documente on 
insert #documente (nrp,c)
select 1,'a'
set identity_insert #documente off 
