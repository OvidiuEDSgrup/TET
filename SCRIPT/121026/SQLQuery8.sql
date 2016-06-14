select isnull(i.loc_de_munca,c.loc_de_munca) as loc_de_munca, 
convert(date,isnull(i.data,c.data)) as data,
isnull(i.cont,c.cont) as cont,
isnull(i.valoare,0) as valoare_incasari,
isnull(c.valoare,0) as valoare_chitante,
convert(decimal(17,2),ABS(isnull(i.valoare,0)-isnull(c.valoare,0))) as diferenta
from ##incasari i full outer join ##chitante c 
on c.loc_de_munca=i.loc_de_munca and c.data=i.data and c.cont=i.cont
where ABS(isnull(i.valoare,0)-isnull(c.valoare,0))>1
order by ABS(isnull(i.valoare,0)-isnull(c.valoare,0)) desc