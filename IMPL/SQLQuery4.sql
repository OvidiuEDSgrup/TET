--select * from con
if exists(select * from sysobjects where name='tempcon') drop table tempcon
create table tempcon(Subunitate char(9),Tip char(2),Contract char(8),Tert char(13),Punct_livrare char(13),Data datetime,Stare char(2),Loc_de_munca char(9),Gestiune char(9),Termen datetime,Scadenta smallint,Discount real,Valuta char(3),Curs float,Mod_plata char(1),Mod_ambalare char(1),Factura char(8),Total_contractat float,Total_TVA float,Contract_coresp char(8),Mod_penalizare char(1),Procent_penalizare real,Procent_avans real,Avans float,Nr_rate smallint,Val_reziduala float,Sold_initial float,Cod_dobanda char(13),Dobanda real,Incasat float,Responsabil char(20),Responsabil_tert char(20),Explicatii char(50),Data_rezilierii datetime)
delete from tempcon
insert into tempcon
select
  '1        '     as subunitate,
  'FC'     as tip,
  '0                   '     as contract,
  a.furnizor     as tert,
  ''     as punct_livrare,
  '02/02/2012'     as data,
  '0'     as stare,
  ''     as loc_de_munca,
  '101      '     as gestiune,
  '02/02/2012'     as termen,
  0     as scadenta,
  0     as discount,
  '   '     as valuta,
  0     as curs,
  '             '    as mod_plata,
  ''     as mod_ambalare,
  ''     as factura,
  (a.de_aprovizionat*a.pret) + n.cota_TVA * (a.de_aprovizionat*a.pret) /100  as total_contractat,
  n.cota_TVA * (a.de_aprovizionat*a.pret) /100 as total_tva,
  ''     as contract_coresp,
  ''     as mod_penalizare,
  0     as procent_penalizare,
  0     as procent_avans,
  0     as avans,
  0     as nr_rate,
  0     as val_reziduala,
  0     as sold_initial,
  ''     as cod_dobanda,
  0     as dobanda,
  0     as incasat,
  ''     as responsabil,
  '                    '    as responsabil_tert,
  ''     as explicatii,
  '01/01/1901'    as data_rezilierii
from comaprovtmp a
inner join nomencl n on n.cod=a.cod
where a.utilizator='OVIDIU    ' and a.de_aprovizionat>0

-- astea nu stiu daca trebuie inserate in con/tempcon

-- de_aprovizionat      as cantitate,
-- (select pret_in_valuta from nomencl b
-- where b.cod=a.cod)     as pret,
-- 0       as pret_promotional,
-- 0       as discount,
-- ''       as factura,
-- de_aprovizionat      as cant_disponibila,
-- 0       as cant_aprobata,
-- 0       as cant_realizata,
-- 0       as cota_tva,
-- 0       as suma_tva,
-- ''       as mod_de_plata,
-- ''       as um,
-- 0       as zi_scadenta_din_luna,
-- 0       as numar_pozitie,
-- 'doua puncte 5'      as utilizator,
-- 'doua puncte 6'      as data_operarii,
-- 'doua puncte 7'      as ora_operarii

insert into con
(Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Stare, 
 Loc_de_munca, Gestiune, Termen, Scadenta, Discount, Valuta, Curs, 
 Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA, Contract_coresp, 
 Mod_penalizare, Procent_penalizare, Procent_avans, Avans, Nr_rate, Val_reziduala, 
 Sold_initial, Cod_dobanda, Dobanda, Incasat, Responsabil, Responsabil_tert, 
 Explicatii, Data_rezilierii)
 select 
 subunitate, tip, contract, tert, max(punct_livrare), data, max(stare), 
 max(loc_de_munca), max(gestiune), max(termen), max(scadenta), max(discount), max(valuta), max(curs), 
 max(mod_plata), max(mod_ambalare), max(factura), sum(total_contractat), sum(total_tva), max(contract_coresp), 
 max(mod_penalizare), max(procent_penalizare), max(procent_avans), max(avans), max(nr_rate), max(val_reziduala), 
 max(sold_initial), max(cod_dobanda), max(dobanda), max(incasat), max(responsabil), max(responsabil_tert), 
 max(explicatii), max(data_rezilierii)
 from tempcon q
 where not exists(select * from con w where w.subunitate=q.subunitate and w.tip=q.tip and w.data=q.data and w.contract=q.contract and w.tert=q.tert)
 group by subunitate, tip, contract, tert, data

drop table tempcon
