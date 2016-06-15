create procedure valoriDocument_tabela
as
declare @eroare varchar(2000)
set @eroare=''
begin try

	if object_id('tempdb..#valdoc') is null create table #valdoc (subunitate varchar(9) null)
	alter table #valdoc add 
		Tip varchar(2), Numar varchar(20), Data datetime, Cont_corespondent varchar(40), Cont_venituri varchar(40), 
		Cantitate float, Valoare float, Tva_11 float, Tva_22 float, Valoare_valuta float, Valoare_pret_amanunt float, Numar_pozitii int,
		Valoare_valuta_tert float
	
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
end catch