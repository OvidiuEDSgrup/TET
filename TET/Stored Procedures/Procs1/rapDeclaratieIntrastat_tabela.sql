--***
Create procedure rapDeclaratieIntrastat_tabela
as
declare @eroare varchar(2000)
set @eroare=''
begin try
if object_id('tempdb..#intrastat') is null create table #intrastat (nr_ord int null)
alter table #intrastat add tip varchar(20) null, numar varchar(200) null, data datetime null, cod varchar(200) null, cod_vamal varchar(200) null,
		cod_NC8 varchar(20), val_facturata decimal(15,3), val_statistica decimal(15,3), masa_neta decimal(17,5), 
		UM2 varchar(20), cant_UM2 decimal(17,5), natura_tranzactie_a varchar(20), natura_tranzactie_b varchar(20), cond_livrare varchar(20), mod_transport varchar(20), 
		tara_tert varchar(20), tara_origine varchar(20), dencodv varchar(80), cif_partener varchar(20), tert varchar(13), punct_livrare varchar(5), factura varchar(20), cantitate float
		
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapDeclaratieIntrastat_tabela)'
end catch
