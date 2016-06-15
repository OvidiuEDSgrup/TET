create view tpretun as
select month(pretun.data_lunii) as 'Luna',year(pretun.data_lunii) as 'An',
comenzi.descriere,lm.denumire,cheltuieli_totale,cantitate,pret_unitar
from pretun,comenzi,lm
where pretun.comanda=comenzi.comanda and pretun.loc_de_munca=lm.cod