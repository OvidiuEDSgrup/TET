--/*
select * 
--*/update c set Loc_de_munca=isnull(nullif(i.Loc_munca,c.loc_de_munca),c.loc_de_munca),c.Scadenta=isnull(nullif(i.Discount,c.Scadenta),c.Scadenta)
from con c inner join terti t on t.Tert=c.Tert inner join infotert i on i.Tert=t.Tert and i.Identificator=''
where c.Tip='BF' and (i.Loc_munca<>c.Loc_de_munca or c.Scadenta<>i.Discount)
