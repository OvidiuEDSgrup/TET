--***

create procedure pStocuri_tabela
as
if object_id('tempdb..#docstoc') is null
	create table #docstoc(subunitate varchar(900) default '1')

alter table #docstoc add
gestiune varchar(200) default '', cont varchar(400) default '', cod varchar(200) default '', data datetime default '1901-1-1',
data_stoc datetime default '1901', cod_intrare varchar(200) default '', pret float default 0,
tip_document varchar(200) default '', numar_document varchar(200) default '', cantitate float default 0, cantitate_UM2 float default 0,
tip_miscare varchar(1000) default '', in_out varchar(100) default '', 
predator varchar(300) default '',
--predator char(20) default '',
codi_pred char(20) default '', 
jurnal varchar(20) default '',-- tert varchar(20) default '',
--codi_pred char(200) default ''
--, jurnal varchar(300) default '',
 tert varchar(200) default '',
serie varchar(200) default '', pret_cu_amanuntul float default 0, tip_gestiune varchar(1) default '', locatie varchar(300) default '', 
data_expirarii datetime default '1901-1-1', TVA_neexigibil int default 0, pret_vanzare float default 0, accize_cump float default 0,
loc_de_munca varchar(900) default '', comanda varchar(400) default '', 
[contract] varchar(200) default '', 
furnizor varchar(200) default '', lot varchar(200) default '',
--furnizor char(20) default '', lot char(20) default '',
numar_pozitie int default 0,
cont_corespondent varchar(400) default '', schimb int default 0, idIntrareFirma int default null, idIntrare int default null,
contractdinpozdoc varchar(200) default null
--> campuri initial folosite doar in fStocuriCen:
,stoc_initial decimal(15,5) default 0
,intrari decimal(15,5) default 0
,iesiri decimal(15,5) default 0
,data_ultimei_iesiri datetime default '1901-1-1'
,stoc decimal(15,5) default 0
,valoare_stoc decimal(17, 5) default 0
,stoc_initial_UM2 decimal(15,5) default 0
,intrari_UM2 decimal(15,5) default 0
,iesiri_UM2 decimal(15,5) default 0
,stoc_UM2 decimal(15,5) default 0
,grp varchar(2000) default ''
,ordine varchar(2000) default ''
,ordineIntrariCustodie varchar(2000) default ''
,dataG datetime default '2999-1-1', dataStocG datetime default '2999-1-1', pretG float default 0
,contG varchar(400) default '', dataExpG datetime default '2999-1-1', pretAmG float default 0
,locatieG varchar(300) default '', lmG varchar(900) default '', comandaG varchar(400) default '', contractG varchar(200) default ''
,furnizorG varchar(1300) default '', lotG varchar(200) default ''
,locatieCustodie varchar(300) default ''	--> in pStocuri: initial semnaleaza daca gestiunea e de tip custodie, apoi va contine locatia
