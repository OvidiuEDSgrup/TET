--***
create procedure rapBalantaContabilaLocm_tabela
as
if object_id('tempdb..#rezbalanta') is null	create table #rezbalanta (subunitate varchar(20) default '1')

alter table #rezbalanta add cont varchar(200), denumire_cont varchar(2000), tip_cont varchar(1),
		are_analitice smallint, cont_parinte varchar(200), Apare_in_balanta_sintetica smallint, apare_in_balanta_de_raportare smallint,
		ContBal varchar(200), DenContBal varchar(2000),
		Sold_inc_an_debit decimal(20,4), Sold_inc_an_credit decimal(20,4), Rul_prec_debit decimal(20,4), Rul_prec_credit decimal(20,4),
		Sold_prec_debit decimal(20,4), Sold_prec_credit decimal(20,4), Total_sume_prec_debit decimal(20,4), Total_sume_prec_credit decimal(20,4),
		Rul_curent_debit decimal(20,4), Rul_curent_credit decimal(20,4), Rul_cum_debit decimal(20,4), Rul_cum_credit decimal(20,4),
		Total_sume_debit decimal(20,4), Total_sume_credit decimal(20,4), Sold_cur_debit decimal(20,4), Sold_cur_credit decimal(20,4),
		Cont_corespondent varchar(200), nivel smallint, locm varchar(100), nume_lm varchar(2000)
