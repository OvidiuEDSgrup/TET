---**
create procedure pRulajeConturi_tabela @sesiune varchar(50)=null, @parxml xml=null
as
if object_id('tempdb..#pRulajeConturi_t') is null
	create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
alter table #pRulajeConturi_t add Cont char(40), Cont_parinte char(40), suma_debit decimal(20,3), suma_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), Denumire_cont varchar(100), valuta varchar(100),
					loc_de_munca varchar(1000) default '', indbug varchar(1000) default '', nivel int default 1
