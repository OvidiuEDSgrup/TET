--***
Create procedure Declaratia39x_tabela @sesiune varchar(50)='', @parxml xml=null
as

declare @comanda_str varchar(max)
select @comanda_str='
if object_id(''tempdb..#tvarecap'') is null
	create table #tvarecap (subunitate varchar(20))

alter table #tvarecap add
	--> trunchi comun d390 si d394:
	tert varchar(100), codfisc varchar(100), dentert varchar(1000), tipop varchar(100), baza decimal(15,3),
	numar varchar(100), numarD varchar(100), tipD varchar(100),	data datetime, factura varchar(100), valoare_factura decimal(15,3), explicatii varchar(1000), tip varchar(100),
	cota_tva int, discFaraTVA decimal(15,3), discTVA decimal(15,3),
	data_doc datetime, ordonare varchar(100), drept_ded varchar(100),
	cont_TVA varchar(100), cont_coresp varchar(100), exonerat int, vanzcump varchar(100), numar_pozitie int, tipDoc varchar(100), cod varchar(100), factadoc  varchar(100), contf varchar(100)
	--> suplimentare pentru d390
	, tara varchar(100), baza_22 decimal(15,3) default 0, tva_22 decimal(15,3) default 0, cont_de_stoc varchar(40), idpozitie int
	--> suplimentare pentru d394
	, tva decimal(15,3) default 0, codNomenclator varchar(100) default '''', invers int default 0
	, setdate int default 0'	-->setdate e nivelul: 0=facturi, 1=terti, 2=totaluri
	
if object_id('tempdb..#tvarecap') is null
	set @comanda_str=replace(@comanda_str,'#tvarecap','#D394det')
--test	select @comanda_str for xml path('')
exec (@comanda_str)
