--****
create procedure rapFisaTerti_structFisa
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	if object_id('tempdb..#fisa') is null
		create table #fisa (ceva char(1) default '')
	alter table #fisa add sursa varchar(200), denumire varchar(200), oras varchar(200), furn_benef varchar(1), subunitate varchar(20), tert varchar(20),
		factura varchar(20), tip varchar(20), numar varchar(20), data datetime, soldi decimal(15,4), --soldi_valuta decimal(15,4), 
		valoare decimal(15,4),
		tva decimal(15,4), total decimal(15,4), achitat decimal(15,4), valuta  varchar(20), curs decimal(15,4), -- achitat_valuta decimal(15,4), 
		loc_de_munca  varchar(20), comanda  varchar(40), cont_de_tert  varchar(40), fel int, cont_coresp varchar(40), explicatii  varchar(500),
		numar_pozitie  varchar(20), gestiune  varchar(20), data_facturii datetime, data_scadentei datetime, nr_dvi  varchar(40), 
		barcod varchar(500), pozitie varchar(20), peSold bit, soldf decimal(15,5), sold_cumulat decimal(15,5),
		soldi_valuta decimal(15,5), valoare_valuta decimal(15,5), tva_valuta decimal(15,5), total_valuta decimal(15,5), achitat_valuta decimal(15,5), --sold_cumulat_lei 
		soldf_valuta decimal(15,5), sold_cumulat_valuta decimal(15,5), ordonare varchar(2000),
		achitat_efect decimal(15,5) default null,
		indicator varchar(100) default 0,
		--> pt fisa terti:
		grupare1 varchar(100) default null, denumire1 varchar(1000) default null,
		grupare2 varchar(100) default null, denumire2 varchar(1000) default null
end try
begin catch
	select @eroare=error_message()+' (rapFisaTerti_structFisa)'
	if object_id('tempdb..#fisa') is not null drop table #fisa
end catch
if len(@eroare)>0 raiserror(@eroare, 16, 1)
