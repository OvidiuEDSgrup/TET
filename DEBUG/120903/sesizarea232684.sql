/*
Problema a fost observata la descarcarea bonului 2 din 22-08-2012 casa 2,adus cu Ctrl+H din interfata PVria, pentru instalatorul 
MARIES ALINA, cod 2810824124246. Ce s-a observat a fost ca bonul avea alta valoare decat comanda de livrare 9820293 cu gest prim 700,
din care s-a generat transferul 9320206. Comanda de livrare a avut rol de confirmare/proforma pentru client si nu se putea ca bonul final
sa aiba alta valoare decat comanda de livrare initiala. De acum ma voi referi la com livr cu termenul de contract 
si la comanda asis din bp cu prescurtarea comanda.
Pt a gasi cauza am luat un cod de articol(caci ele sunt mai multe) la care pretul din bon era altul decat pretul din contract, de ex TR0073,
si am parcurs traseul invers celui de vanzare, astfel:
*/

--Am cautat sa vad ce stoc a luat la descarcare TE-ul automat din gest 700 si am gasit ca TE 20001 din 22-08-2012 a luat pt codul TR0073 
--codul de intrare IMPL1B.
select p.Comanda,p.Factura,* from pozdoc p where p.Tip='TE' and p.Gestiune='700' and p.Cod='TR0073' 
and p.Data='2012-08-22' and p.Numar like '2%[1,2]' 

--apoi am cautat in stocuri sa vad daca acel cod de intrare era sau nu rezervat si am gasit ca era defapt rezervat pt contractul 9820293 
select * from stocuri s where s.Cod_gestiune='700' and s.Cod='TR0073' AND s.Cod_intrare like 'IMPL1[B,E]%'

--apoi am cautat sa verific daca intr-adevar transfrul de intrare in gest 700 pt acest cod de intrare a fost facut pe acest contract,
--si daca nu cumva au mai fost si alte transferuri pe alte comenzi sau alte contracte
select p.Comanda,p.Factura,* from pozdoc p where p.Tip='TE' and p.Gestiune_primitoare='700' and p.Cod='TR0073' and p.Grupa like 'IMPL1[B,E]%'

--apoi am verificat daca intr-adevar pozitiile de bon primar au fost facute cu aceasta comanda si contract,adica daca ei au facturat 
--intr-adevar din ctr+H
select a.Contract,bp.Comanda_asis,bp.Contract,* from bp inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon 
where bp.Cod_produs='TR0073' and a.Data_bon='2012-08-22' and a.Casa_de_marcat=2 and a.Numar_bon in (1,2)

/*
In concluzie se poate observa ca procedura de descarcare a bonului 1 facut pe comanda 2810824124246 dar fara contract
, a consumat pt TE 20001 doua bucati din codul de intrare IMPL1B care era pastrat pt contractul 9820293 in gest de rezervari 700.
Drept urmare cand s-a ajuns la descarcarea bonului 2 facut tot pe comanda 2810824124246 dar cu contractul 9820293, operatorul nu a mai avut 
stoc suficient pe comanda 9820293(a putut lua doar 13 buc) adusa cu ctrl+H in interfata PV si a fost nevoit sa ia pe bonul curent 
si din stocul de pe aceeasi comanda 2810824124246 dar fara contract (si anume inca 2 buc pe codul de intrare IMPL1E,din stocul instalatorului).
El astfel a reusit sa respecte contractul ca si cantitate dar nu si ca valoare, fiindca preturile de pe cele doua coduri de intrare
se poate observa ca difera (caci instalatorului i s-a acordat un discount mai mare decat clientului adus de el,cum se intampla de obicei aici).
*/