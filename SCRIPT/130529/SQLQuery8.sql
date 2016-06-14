declare @codvechi varchar(20),@codnou varchar(20)
select @codvechi='1OFF07'   ,@codnou='1OF'
1MKT13   ,1VZ_MK_11

select *, --update pozincon set 
Loc_de_munca=upper(@codnou)
from pozincon
 where Loc_de_munca = @codvechi

if OBJECT_ID('tempdb..#pozincon') is not null drop table #pozincon
select top 0 * into #pozincon from pozincon
--delete v 
--output deleted.* into #pozincon
select *
from pozincon v cross apply (select Loc_de_munca
	from pozincon n where n.Loc_de_munca = @codnou 
	and  n.Subunitate=v.Subunitate and  n.Tip_document=v.Tip_document and  n.Numar_document=v.Numar_document and  n.Data=v.Data and  n.Cont_debitor=v.Cont_debitor and  n.Cont_creditor=v.Cont_creditor and  n.Comanda=v.Comanda and  n.Valuta=v.Valuta and  n.Numar_pozitie=v.Numar_pozitie) n 
where v.Loc_de_munca = @codvechi
if @@ROWCOUNT>0 update n set
Suma= n.Suma+v.Suma
, Curs= (n.Curs+v.Curs)/2
, Suma_valuta= n.Suma_valuta+v.Suma_valuta
from pozincon n cross apply (select Suma, Curs, Suma_valuta
from #pozincon v where v.Loc_de_munca = @codvechi 
 and  n.Subunitate=v.Subunitate and  n.Tip_document=v.Tip_document and  n.Numar_document=v.Numar_document and  n.Data=v.Data and  n.Cont_debitor=v.Cont_debitor and  n.Cont_creditor=v.Cont_creditor and  n.Comanda=v.Comanda and  n.Valuta=v.Valuta and  n.Numar_pozitie=v.Numar_pozitie) v 
where n.Loc_de_munca = @codnou