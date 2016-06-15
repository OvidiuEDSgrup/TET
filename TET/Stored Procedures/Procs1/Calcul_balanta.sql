--***
create procedure Calcul_balanta @pLuna int, @pAn int, @lCentralizata bit, @lContCor bit, @lInValuta bit, @lIn_val_ref bit, @cValuta char(3), @nCurs float, @cLM char(9)
as

if object_id('tempdb..#rezbalanta') is not null	drop table #rezbalanta

declare @cHostID varchar(8)
Set @cHostID =  isnull((select convert(char(8), abs(convert(int, host_id())))),'')
Delete from balanta where hostid = @cHostID

create table #rezbalanta (subunitate varchar(20) default '1')
exec rapBalantaContabilaLocm_tabela

exec rapBalantaContabilaLocm @ContJos='', @ContSus='z', @pLuna=@pLuna, @pAn=@pAn, @valuta=@cValuta, @curs=@nCurs, @cLM=@cLM,
	@pelocm=0, @TipBalanta=2, @direct=0

insert into balanta(Subunitate, Cont, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, hostid)
select Subunitate, Cont, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, @cHostID
from #rezbalanta
