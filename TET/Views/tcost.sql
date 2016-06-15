create view tcost as
select year(cost.data_lunii) as 'Anul',month(cost.data_lunii) as 'Luna',artcalc.denumire as 'Articol',lm.denumire as 'Locmunca',comenzi.descriere,
valoare
from cost,artcalc,lm,comenzi where
cost.tip_inregistrare='RD' and 
cost.articol_de_calculatie=artcalc.articol_de_calculatie and 
cost.loc_de_munca=lm.cod and cost.comanda=comenzi.comanda