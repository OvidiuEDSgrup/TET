create procedure CreazaDiezFacturi @numeTabela varchar(100)
AS
--	tabela utilizata in procedura FacturiPeConturi
if 	@numeTabela='#facturiPeConturi'
	alter table #facturiPeConturi
		add factura varchar(20), data_factura datetime, Data_scadentei datetime,
			sold float, loc_de_munca varchar(13), comanda varchar(40), valuta varchar(3), curs float, 
			valoare float, tva_22 float, cont_de_tert varchar(40), indbug varchar(50), nr_cont_fact int

--	tabela utilizata in procedura pFacturi. In aceasta tabela sunt prelucrate datele in pFacturi.
if 	@numeTabela='#docfac'
	alter table #docfac
		add	subunitate char(9), tert char(13), factura char(20), tip char(2), numar char(20), data datetime, valoare float, tva float, achitat float, 
			valuta char(3), curs float, total_valuta float, achitat_valuta float, loc_de_munca char(13), comanda char(40),
			cont_de_tert varchar(40), fel int, cont_coresp varchar(40), explicatii char(50), numar_pozitie int, gestiune char(13), 
			data_facturii datetime, data_scadentei datetime, nr_dvi char(13), barcod char(30), contTVA varchar(40), cod char(20), cantitate float, 
			contract char(20), efect varchar(100), pozitie int identity, data_platii datetime, punct_livrare char(5), achitare_efect_in_curs float, idPozitieDoc int, tabela varchar(20),indbug varchar(50), determinant int

--	tabela utilizata in procedurile ce apeleaza pFacturi (varianta detaliata). In aceasta tabela sunt returnate datele in varianta detaliata.
if 	@numeTabela='#docfacturi'
	alter table #docfacturi
		add	subunitate char(9), tert char(13), factura char(20), tip char(2), numar char(20), data datetime, valoare float, tva float, achitat float, 
			valuta char(3), curs float, total_valuta float, achitat_valuta float, loc_de_munca char(13), comanda char(40),
			cont_de_tert varchar(40), fel int, cont_coresp varchar(40), explicatii char(50), numar_pozitie int, gestiune char(13), 
			data_facturii datetime, data_scadentei datetime, nr_dvi char(13), barcod char(30), contTVA varchar(40), cod char(20), cantitate float, 
			contract char(20), efect varchar(100), pozitie int, data_platii datetime, punct_livrare char(5), achitare_efect_in_curs float,tabela varchar(20),indbug varchar(50)

--	tabela utilizata in procedurile ce apeleaza pFacturi (varianta centralizata=fosta fFacturiCen). In aceasta tabela sunt returnate datele in varianta centralizata.
if 	@numeTabela='#pfacturi'
	alter table #pfacturi
		add	loc_de_munca varchar(13), tip binary, factura varchar(20), tert varchar(13), data datetime, data_scadentei datetime, 
			valoare float, tva float, valuta char(3), curs float, valoare_valuta float, achitat float, sold float, cont_factura varchar(40), 
			achitat_valuta float, sold_valuta float, comanda varchar(40), data_ultimei_achitari datetime, achitat_interval float, achitat_interval_plata float, explicatii varchar(2000)
