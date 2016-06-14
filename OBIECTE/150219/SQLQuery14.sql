select p.*,c.numar from necesaraprov n right join Contracte c on c.numar=n.Numar and c.data=n.Data and c.tip='RN'
right join PozContracte p on p.idContract=c.idContract and p.idPozContract=n.Numar_pozitie
where n.Numar_pozitie is null

select * from Contracte c left join necesaraprov n on n.Numar=c.numar and n.Data=c.data 
where c.tip='RN' and c.numar like 'if%'
select * from JurnalContracte j where j.idContract=39
--and n.Numar_pozitie is null