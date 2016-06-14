drop trigger yso_tr_necesaraprov 
go
create trigger yso_tr_necesaraprov on pozcontracte after insert,update,delete as

delete n
from necesaraprov n join Contracte c on c.tip='RN' and c.numar=n.Numar and c.data=n.Data join deleted d on d.idPozContract=n.Numar_pozitie

delete n
from necesaraprov n join Contracte c on c.tip='RN' and c.numar=n.Numar and c.data=n.Data join inserted i on i.idPozContract=n.Numar_pozitie

insert necesaraprov (Numar,Data,Numar_pozitie,Gestiune,Cod,Cantitate,Stare,Loc_de_munca,Comanda,Numar_fisa,Utilizator,Data_operarii,Ora_operarii,detalii)
select Numar,Data,i.idPozContract,c.Gestiune,Cod,Cantitate,0,Loc_de_munca,Comanda='',Numar_fisa='',s.Utilizator,GETDATE(),Ora_operarii='',i.detalii
from inserted i join Contracte c on c.idContract=i.idContract
CROSS APPLY (select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.modificabil, j.utilizator 
	from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc,j.idJurnal desc) s
where c.tip='RN'