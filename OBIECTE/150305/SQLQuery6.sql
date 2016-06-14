select * -- delete j
from JurnalContracte j join Contracte c on c.idContract=j.idContract
where c.tip='RN'  and j.utilizator='ASIS'
and j.stare>0
begin tran

declare @x xml
set @x=(select idContract from Contracte c where c.tip='RN' for xml raw,root('Date'), type)
select @x
EXEC updateStareSetContracte '',@X

rollback tran