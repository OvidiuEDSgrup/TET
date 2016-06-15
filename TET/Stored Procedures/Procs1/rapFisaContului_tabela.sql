--***
create procedure rapFisaContului_tabela @sesiune varchar(50)='', @parxml xml=null
as
begin
	if object_id('tempdb..#fisa') is null
		create table #fisa(cont varchar(100))

	alter table #fisa add denumire_cont varchar(2000), cont_parinte varchar(100), tip_document varchar(2), numar_document varchar(100), data datetime,
		cont_debitor varchar(100), cont_creditor varchar(100), suma_deb decimal(18,3), suma_cred decimal(18,3), sold_deb decimal(18,3), sold_cred decimal(18,3),
		suma_deb_valuta decimal(18,3), suma_cred_valuta decimal(18,3), sold_deb_valuta decimal(18,3), sold_cred_valuta decimal(18,3), explicatii  varchar(4000),
		numar varchar(100), jurnal varchar(1000), ID varchar(2), subtotal varchar(1000), tip_cont varchar(100), are_analitice bit, are_rulaje bit, valuta varchar(100)
		,den_subtotal varchar(4000) default '', numar_pozitie varchar(100) default 0
--	drop table #fisa
--	select * from #fisa
end
