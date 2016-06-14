declare @datajos datetime='2012-07-01', @datasus datetime='2012-07-31'
	,@gest varchar(9)='211.1', @lm varchar(9)='1MKT19'

--/*decomenteaza aici (adica sterge cele doua linii de la inceputul randului) cand vrei sa faci update-ul de mai jos
select *
--*/update p set p.Loc_de_munca=@lm 
from pozdoc p where p.Tip='AC' and p.Data between @datajos and @datasus
and p.Gestiune_primitoare=@gest and p.Loc_de_munca<>@lm

--/*decomenteaza aici (adica sterge cele doua linii de la inceputul randului) cand vrei sa faci update-ul de mai jos
select *
--*/update p set p.Loc_munca=@lm 
from doc p where p.Tip='TE' and p.Data between @datajos and @datasus
and p.Gestiune_primitoare=@gest and p.Loc_munca<>@lm