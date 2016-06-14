/*
select *
,matched_upd=case when r.Subunitate is not null and d.Subunitate is not null and r.Loc_de_munca=d._cod_nou then 'matched upd' else '' end 
,matched_del=case when r.Subunitate is not null and d.Subunitate is not null and r.Loc_de_munca=d._cod_vechi then 'matched del' else '' end
,not_matched=case when r.Subunitate is not null and d.Subunitate is null then 'matched del' else '' end
from rulaje r full outer join
(
select _cod_vechi=c.Cod_vechi,_cod_nou=c.Cod_nou
	,Subunitate, Cont, Data, Valuta, Loc_de_munca
	,Rulaj_credit=sum(r.Rulaj_credit), Rulaj_debit=sum(r.Rulaj_debit)
from rulaje r 
	inner join yso_CodInl c on c.Tip=-2 and c.Cod_vechi=r.Loc_de_munca
group by Subunitate, Cont, Data, Valuta, Loc_de_munca, c.Cod_vechi, c.Cod_nou
) d on d.Subunitate=r.Subunitate and d.Data=r.Data and d.Cont=r.Cont and d.Valuta=r.Valuta and r.Loc_de_munca in (d._cod_vechi,d._cod_nou)
*/
--select * from yso_CodInl c where c.tip=-2
--pozincon

if OBJECT_ID('tempdb..#rulaje') is not null drop table #rulaje

select top 0 * into #rulaje from rulaje

/*
select r.* 
--*/ delete v
/*
into #rulaje
--*/output deleted.* into #rulaje
from rulaje v
	inner join yso_CodInl c on c.Tip=-2 and c.Cod_vechi=v.Loc_de_munca
	inner join rulaje d on d.Subunitate=v.Subunitate and d.Cont=v.Cont and d.Data=v.Data and d.Valuta=v.Valuta 
		and d.Loc_de_munca=c.Cod_nou
where c.Tip=-2

--/*
update v set
--*/ select 
Rulaj_debit=v.Rulaj_debit+d.Rulaj_debit
,Rulaj_credit=v.Rulaj_credit+d.Rulaj_credit
--,*
from rulaje v
	inner join yso_CodInl c on c.Tip=-2 and c.Cod_nou=v.Loc_de_munca
	inner join #rulaje d on d.Subunitate=v.Subunitate and d.Cont=v.Cont and d.Data=v.Data and d.Valuta=v.Valuta 
		and d.Loc_de_munca=c.Cod_vechi
where c.Tip=-2

if OBJECT_ID('tempdb..#pozincon') is not null drop table #pozincon

select top 0 * into #pozincon from pozincon

/*
select --d.Numar_pozitie,d.Loc_de_munca,d.Suma,
v.* 
--*/ delete v
/*
into #pozincon
--*/output deleted.* into #pozincon
from pozincon v
	inner join yso_CodInl c on c.Tip=-2 and c.Cod_vechi=v.Loc_de_munca
	inner join pozincon d on d.Subunitate=v.Subunitate and v.Tip_document=d.Tip_document and v.Numar_document=d.Numar_document 
		and d.Data=v.Data and d.Valuta=v.Valuta 
		and v.Cont_debitor=d.Cont_debitor and v.Cont_creditor=d.Cont_creditor and v.Comanda=d.Comanda and v.Numar_pozitie=d.Numar_pozitie
		and d.Loc_de_munca=c.Cod_nou
where c.Tip=-2

--/*
update v set
--*/ select 
Suma=v.Suma+d.Suma
,Suma_valuta=v.Suma_valuta+d.Suma_valuta
,Curs=(v.Curs+d.Curs)/2
--,*
from pozincon v
	inner join yso_CodInl c on c.Tip=-2 and c.Cod_nou=v.Loc_de_munca
	inner join #pozincon d on d.Subunitate=v.Subunitate and v.Tip_document=d.Tip_document and v.Numar_document=d.Numar_document 
		and d.Data=v.Data and d.Valuta=v.Valuta 
		and v.Cont_debitor=d.Cont_debitor and v.Cont_creditor=d.Cont_creditor and v.Comanda=d.Comanda and v.Numar_pozitie=d.Numar_pozitie
		and d.Loc_de_munca=c.Cod_vechi
where c.Tip=-2

-- select * from #pozincon p order by p.data

--update mandatar set loc_munca=upper(@codnou) where loc_munca = @codvechi

declare @codnou nvarchar(50)='1LG_TR_01', @codvechi nvarchar(50)='1LOG0101'

select *
from rulaje v cross apply (select loc_de_munca
	from rulaje n where n.loc_de_munca = @codnou 
		and  n.Subunitate=v.Subunitate and  n.Cont=v.Cont and  n.Data=v.Data and  n.Valuta=v.Valuta) n 
where v.loc_de_munca = @codvechi
 and v.data>='2012-12-01'

if OBJECT_ID('tempdb..#rulaje') is not null drop table #rulaje
select top 0 * into #rulaje from rulaje
delete v 
output deleted.* into #rulaje -- select *
from rulaje v cross apply (select loc_de_munca
from rulaje n where n.loc_de_munca = @codnou 
 and  n.Subunitate=v.Subunitate and  n.Cont=v.Cont and  n.Data=v.Data and  n.Valuta=v.Valuta) n 
where v.loc_de_munca = @codvechi
 and v.data>='2012-12-01'
 
if @@ROWCOUNT>0 update n set
Rulaj_debit= n.Rulaj_debit+v.Rulaj_debit
, Rulaj_credit= n.Rulaj_credit+v.Rulaj_credit
from rulaje n cross apply (select Rulaj_debit, Rulaj_credit
from #rulaje v where v.loc_de_munca = @codvechi 
 and  n.Subunitate=v.Subunitate and  n.Cont=v.Cont and  n.Data=v.Data and  n.Valuta=v.Valuta) v 
where n.loc_de_munca = @codnou
 and n.data>='2012-12-01'
 
 --Cannot insert duplicate key row in object 'dbo.rulaje' with unique index 'Principal'. 
 --The duplicate key value is (1        , 401          , Jan 31 2012 12:00AM,    , 1LG_TR_01).
 select * from rulaje r where r.Loc_de_munca in ('1LOG0101','1LG_TR_01')
 and r.Data='2012-01-31' 
 and r.Cont='401'
 
 update rulaje set loc_de_munca=upper('1LG_TR_01') where loc_de_munca = '1LOG0104'
 
 select top 1 *--@idindex=i.index_id, @idobject=i.object_id
				from sys.index_columns ic 
					inner join sys.columns c on c.object_id=ic.object_id and c.column_id=ic.column_id
					inner join sys.indexes i on i.object_id=ic.object_id and i.index_id=ic.index_id 
					inner join sys.objects o on o.object_id=c.object_id
				where i.is_unique=1 and o.name='proprietati' and c.name='valoare' order by i.index_id 
				
select * from yso_DetTabInl d where d.Camp_Magic='proprietati'
and d.Tip=-2

cod vechi 1MAGSV04 
cod nou 1VZ_SV_01 
update proprietati set valoare=upper('VZ_SV_01') where valoare = '1MAGSV04'
 and tip='UTILIZATOR' and cod_proprietate='LOCMUNCA'
1MAGSV04 ,1VZ_SV_01 

update proprietati 
set cod=upper('1VZ_IF_01') 
 output deleted.*
 where cod = '1VNZ0103'
 and tip='LM'
 
 
1VNZ0103 ,1VZ_IF_01

select * from proprietati p where p.Tip='LM' 
and p.Cod in ('1VNZ0103','1VZ_IF_01')
1VNZ0103 ,1VZ_IF_01