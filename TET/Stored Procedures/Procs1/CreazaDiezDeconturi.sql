create procedure CreazaDiezDeconturi @numeTabela varchar(100)
AS
--	tabela utilizata in procedura pDeconturi. In aceasta tabela sunt prelucrate datele in pDeconturi.
if 	@numeTabela='#docdec'
	alter table #docdec
		add	marca char(6), decont varchar(40), tip_document char(2), numar_document varchar(20), data datetime, in_perioada char(1), valoare float, achitat float, 
			cont varchar(40), cont_coresp varchar(40), fel char(1), valuta char(3), curs float, valoare_valuta float, achitat_valuta float, tert char(13), factura char(20), 
			explicatii char(50), numar_pozitie int, loc_de_munca char(9), comanda char(40), data_scadentei datetime, cantitate float, debit_credit char(1), 
			idPozitieDoc int, tabela varchar(20),indbug varchar(50)

--	tabela utilizata in procedurile ce apeleaza pDeconturi (varianta detaliata). In aceasta tabela sunt returnate datele in varianta detaliata.
if 	@numeTabela='#docdeconturi'
	alter table #docdeconturi
		add	marca char(6), decont varchar(40), tip_document char(2), numar_document varchar(20), data datetime, in_perioada char(1), valoare float, achitat float, 
			cont varchar(40), cont_coresp varchar(40), fel char(1), valuta char(3), curs float, valoare_valuta float, achitat_valuta float, tert char(13), factura char(20), 
			explicatii char(50), numar_pozitie int, loc_de_munca char(9), comanda char(40), data_scadentei datetime, cantitate float, debit_credit char(1), 
			idPozitieDoc int, tabela varchar(20), indbug varchar(50)

--	tabela utilizata in procedurile ce apeleaza pDeconturi (varianta centralizata=fosta fDeconturiCen). In aceasta tabela sunt returnate datele in varianta centralizata.
if 	@numeTabela='#pdeconturi'
	alter table #pdeconturi
		add	Tip char(2), Marca char(6), Decont varchar(40), Cont varchar(40), Data datetime, Data_scadentei datetime, Valoare float, Valuta char(3), Curs float, 
			Valoare_valuta float, Decontat float, Sold float, Decontat_valuta float, Sold_valuta float, Loc_de_munca char(9), Comanda char(40), Data_ultimei_decontari datetime, Explicatii char(50)  

