
CREATE PROCEDURE wTvaContracte_tabela @sesiune VARCHAR(50)=null, @parXML XML=null
as

if object_id('tempdb..#diezpozcontracte') is null
	create table #diezpozcontracte (idpozcontract int)

alter table #diezpozcontracte add idcontract int--, cantitate float, pret float, discount float, cota_tva float ,detalii_cota_tva float
	,cantitate float , valoare float, valoarePV float, totalcutva float, cota_tva float