select * from PozContracte p join Contracte c on c.idContract=p.idContract
where p.stare is not null