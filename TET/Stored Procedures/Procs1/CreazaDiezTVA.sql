create procedure CreazaDiezTVA @numeTabela varchar(100)
AS
--	tabela utilizata in procedura TVACumparari si in rapJurnalTVACumparari
if 	@numeTabela='#tvacump'
	alter table #tvacump
		add numar varchar(20),numarD varchar(40),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,
			explicatii varchar(50),tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(30),drept_ded varchar(1),
			cont_TVA varchar(40),cont_coresp varchar(40),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf varchar(40), 
			detalii xml,tip_tva int,dataf datetime,cont_de_stoc varchar(40),idpozitie int

--	tabela utilizata in procedura rapJurnalTVACumparari si Declaratia300Cump
if @numeTabela='#jtvacump'
	alter table #jtvacump
		add data datetime, cod_tert char(13), furnizor varchar(80), codfisc varchar(20), total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, scutite float
			,baza_intra float, tva_intra float, scutite_intra float, neimpoz_intra float, baza_oblig_1 float,tva_oblig_1 float, baza_oblig_2 float, tva_oblig_2 float
			,explicatii char(50), cont_tva varchar(40), detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(20), data_doc datetime, valoare_doc float, cota_tva_doc int, suma_tva_doc float
			,baza_intra_serv float, tva_intra_serv float, scutite_intra_serv float, baza_oblig_1_serv float,tva_oblig_1_serv float

--	tabela utilizata in procedura TVAVanzari si in rapJurnalTVAVanzari
if 	@numeTabela='#tvavanz'
	alter table #tvavanz
		add numar varchar(20),numarD varchar(40),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float
			,explicatii varchar(50),tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(100),drept_ded varchar(1)
			,cont_TVA varchar(40),cont_coresp varchar(40),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf varchar(40), 
			detalii xml,tip_tva int,dataf datetime,cont_de_stoc varchar(40),idpozitie int

--	tabela utilizata in procedura rapJurnalTVAVanzari si Declaratia300Vanz
if 	@numeTabela='#jtvavanz'
	alter table #jtvavanz
		add data datetime, cod_tert char(13), beneficiar char(80), codfisc char(20), total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_5 float, tva_5 float
			,baza_txinv float, tva_txinv float, regim_spec float, afara_ded float, afara_fara float, scutite_intra_ded_1 float, scutite_intra_ded_2 float
			,scutite_ded_alte float, scutite_fara float, neimpozabile float, explicatii char(50), detal_doc int, care_jurnal int
			,tip_doc char(2), nr_doc char(20), data_doc datetime, valoare_doc float, cota_tva_doc int, suma_tva_doc float
				,afara_ded_serv float, baza_txinv_cump float, tva_txinv_cump float, baza_txinv_cump_9 float, tva_txinv_cump_9 float
