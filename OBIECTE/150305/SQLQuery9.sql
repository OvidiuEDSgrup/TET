drop table #NAmodificate 
	select numar=isnull(i.Numar,d.Numar), data=isnull(i.Data,d.data), numar_pozitie=isnull(i.Numar_pozitie,d.numar_pozitie)
		, cantitate=coalesce(i.Cantitate,d.cantitate), stare=coalesce(i.Stare*10,-10)
	into #NAmodificate 
	from necesaraprov i full join necesaraprov d on d.Numar=i.Numar and d.Data=i.Data and d.Numar_pozitie=i.Numar_pozitie 
	where (coalesce(d.Stare*10,-15)<>coalesce(i.Stare*10,-10) or isnull(d.Cantitate,0)<>isnull(i.Cantitate,0))
drop table #RNmodificate 
	create table #RNmodificate (idContract int not null)
--/*
	select stare=coalesce(p.stare,n.stare*10,-10),p.stare,p.idContract,*, --*/ update p set
		stare=coalesce(p.stare,n.stare*10,-10)
	--output inserted.idcontract into #RNmodificate 
	from PozContracte p join Contracte c on c.idContract=p.idContract
		left join necesaraprov n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
	where isnull(p.stare,-15)<>coalesce(n.Stare*10,-10) --or isnull(p.cantitate,0)<>isnull(n.Cantitate,0)
	and c.tip='RN'
select * from PozContracte p where p.stare is null