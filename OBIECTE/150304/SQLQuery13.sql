--insert necesaraprov (Numar,Data,Numar_pozitie,Gestiune,Cod,Cantitate,Stare,Loc_de_munca,Comanda,Numar_fisa,Utilizator,Data_operarii,Ora_operarii,detalii)
select c.Numar,c.Data,p.idPozContract,c.Gestiune,p.Cod,p.Cantitate,0,c.Loc_de_munca,Comanda='',Numar_fisa='',isnull(s.Utilizator,'ASIS'),GETDATE(),Ora_operarii='',p.detalii
from PozContracte p join Contracte c on c.idContract=p.idContract
left join necesaraprov n on c.numar=n.Numar and c.data=n.Data and p.idPozContract=n.Numar_pozitie
	outer apply (select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.modificabil, j.utilizator 
		from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc,j.idJurnal desc) s
where c.tip='rn' and n.Stare is null
--where n.Stare is null
--where c.idContract=@idContract