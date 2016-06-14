drop procedure [dbo].[yso_rapFisaTerti_structFisa]
GO

--****
create procedure [dbo].[yso_rapFisaTerti_structFisa]
as
begin
	if object_id('tempdb..#fisa') is null
		create table #fisa (ceva char(1) default '')
	alter table #fisa add sursa varchar(200), denumire varchar(200), oras varchar(200), furn_benef varchar(1), subunitate varchar(20), tert varchar(20),
		factura varchar(20), tip varchar(20), numar varchar(20), data datetime, soldi decimal(15,4), --soldi_valuta decimal(15,4), 
		valoare decimal(15,4),
		tva decimal(15,4), achitat decimal(15,4), valuta  varchar(20), curs decimal(15,4), total_valuta decimal(15,4), achitat_valuta decimal(15,4), 
		loc_de_munca  varchar(20), comanda  varchar(40), cont_de_tert  varchar(20), fel int, cont_coresp varchar(20), explicatii  varchar(500),
		numar_pozitie  varchar(20), gestiune  varchar(20), data_facturii datetime, data_scadentei datetime, nr_dvi  varchar(40), 
		barcod varchar(500), pozitie varchar(20), peSold bit, sold_cumulat decimal(15,5),
		soldi_lei decimal(15,5), valoare_lei decimal(15,5), tva_lei decimal(15,5), achitat_lei decimal(15,5), sold_cumulat_lei decimal(15,5)--/*sp
		,[contract] varchar(20), operator varchar(20), zona varchar(20), nume_operator varchar(50), den_zona varchar(50)  --sp*/
end
GO


