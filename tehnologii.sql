--insert tehnpoz
select Cod_tehn, 'R', Cod_tehn, '', '','P' Subtip,'' Supr,'' Coef_consum,'' Randament,'1' Specific,'' Cod_inlocuit
,'' Loc_munca,'' Obs,'' Utilaj,'' Timp_preg,'' Timp_util,'' Categ_salar,'' Norma_timp,'' Tarif_unitar,'' Lungime,'' Latime
,'' Inaltime,'' Comanda,'' Alfa1,'' Alfa2,'' Alfa3,'' Alfa4,'' Alfa5,'' Val1,'' Val2,'' Val3,'' Val4,'' Val5 
from tehn t where not exists 
(select 1 from tehnpoz p where p.Cod_tehn=t.Cod_tehn and p.Tip='R')