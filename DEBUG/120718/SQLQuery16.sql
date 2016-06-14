select *
-- update c set Loc_de_munca=i.Loc_munca,Scadenta=i.Discount
from con c 
inner join infotert i on i.Subunitate=c.Subunitate and i.Tert=c.Tert and i.Identificator=''
where c.tip='BF'
--AND c.tert='RO9175570'