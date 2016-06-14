select * 
into #c
from Contracte c where c.tip='RN'
declare @id int
declare @p xml

	set @p=(select distinct r.idContract from Contracte r where r.tip='RN' for xml raw, type)
	exec updateStareSetContracte null,@p	