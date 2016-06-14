select * from PozContracte p join Contracte c on c.idContract=p.idContract
where c.tip='RN' and p.stare is not null