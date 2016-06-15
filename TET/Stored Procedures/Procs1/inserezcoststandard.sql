--***
create procedure inserezcoststandard @datajos datetime,@datasus datetime, @lm varchar(9)=null  
as 
declare  @subunitate char(9) 
set @subunitate = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO') 
--cost
delete from cost where data_lunii=@datasus 
	and (@lm is null or Loc_de_munca like @lm+'%')
insert into cost 
(Data_lunii, Subunitate, Loc_de_munca, Comanda, Tip_comanda, Articol_de_calculatie, Tip_inregistrare, Valoare, Valoare_fond_special, Cont_cheltuieli_sursa, Loc_de_sursa, Comanda_sursa, Articole_de_calculatie_sursa)
select @datasus, @subunitate, lm_sup, comanda_sup, comenzi.tip_comanda, 
(CASE WHEN ART_SUP='T' THEN art_inf ELSE ART_SUP END), 'RD', sum(cantitate*valoare), 0, 
(case when lm_inf='' and comanda_sup like '6%' then comanda_inf else '' end) 
,lm_inf, (case when lm_inf='' and comanda_sup like '6%' then '' else comanda_inf end), 
(CASE WHEN ART_SUP<>'T' THEN art_inf ELSE ART_SUP END) 
from costtmp, comenzi 
where costtmp.art_sup<>'N' and costtmp.comanda_sup=comenzi.comanda and comenzi.subunitate = @subunitate 
group by lm_sup, comanda_sup, comenzi.tip_comanda, 
(CASE WHEN ART_SUP='T' THEN art_inf ELSE ART_SUP END), comanda_inf, lm_inf, 
(CASE WHEN ART_SUP<>'T' THEN art_inf ELSE ART_SUP END) 
union 
select @datasus, @subunitate, lm_inf, comanda_inf, comenzi.tip_comanda, 
(CASE WHEN ART_SUP in ('T','N','P','R') THEN art_inf ELSE ART_SUP END), 'RC', sum(cantitate*valoare), 0, 
'', lm_sup,comanda_sup, max(CASE WHEN ART_SUP not in ('T','P','R','N') THEN art_inf ELSE ART_SUP END) 
from costtmp, comenzi 
where costtmp.art_sup<>'N' and comanda_inf<>comanda_sup and costtmp.comanda_inf=comenzi.comanda 
and comenzi.subunitate = @subunitate 
group by lm_inf, comanda_inf, comenzi.tip_comanda, (CASE WHEN ART_SUP in ('T','N','P','R') THEN art_inf ELSE ART_SUP END), comanda_sup, lm_sup
union 
select @datasus, @subunitate, lm_inf, comanda_inf, comenzi.tip_comanda, 'N', 'SI', sum(cantitate*valoare), 0, '', lm_sup, comanda_sup, ''
from costtmp,comenzi where costtmp.art_sup='N' and comenzi.subunitate = @subunitate 
and costtmp.comanda_inf=comenzi.comanda 
group by lm_inf,comanda_inf,comenzi.tip_comanda,art_sup,comanda_sup,lm_sup,art_inf 
update cost set articol_de_calculatie=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='REGLOCMUN'),'L') where articol_de_calculatie='L'
update cost set articol_de_calculatie=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='REGENERAL'),'G') where articol_de_calculatie='G'
update cost set articol_de_calculatie=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='ARTCALN'),'N') where articol_de_calculatie='N'
--costsql
delete from costsql where data between @datajos and @datasus 
	and (@lm is null or LM_SUP like @lm+'%' or lm_sup='' and comanda_sup='' and LM_inf like @lm+'%')
insert into costsql 
(DATA, LM_SUP, COMANDA_SUP, ART_SUP, LM_INF, COMANDA_INF, ART_INF, CANTITATE, VALOARE, PARCURS, Tip, Numar) 
select 
DATA, LM_SUP, COMANDA_SUP, ART_SUP, LM_INF, COMANDA_INF, ART_INF, CANTITATE, VALOARE, PARCURS, Tip, Numar 
from costtmp 
--costuri
delete from costuri where comanda in (select comanda from comenzi where tip_comanda='D') 
delete from costuriSQL where data between @datajos and @datasus 
	and (@lm is null or lm like @lm+'%')
insert into costuriSQL 
(Data, lm, comanda, costuri, cantitate, pret, rezolvat, nerezolvate) 
select @datasus,lm, comanda, costuri, cantitate, pret, rezolvat, nerezolvate 
from costuri 
where (@lm is null or lm<>'') -- nu pot scrie regie generala pe fiecare sectie 
--pretun
delete from pretun where data_lunii=@datasus 
	and (@lm is null or Loc_de_munca like @lm+'%')
insert into pretun 
(Data_lunii, Subunitate, Loc_de_munca, Comanda, Cheltuieli_totale, Cheltuieli_directe, Cantitate, Cantitate_regie_proprie, Baza_de_calcul, Baza_de_calcul_RG, Baza_de_calcul_ch_aprov, Baza_de_calcul_ch_desf, Pret_unitar, Cheltuieli_regie_proprie, Tip_comanda, Poate_primi_cheltuieli)
select @datasus,@subunitate,costuri.lm,costuri.comanda,costuri,costuri,cantitate,0,0,0,0,0,(case when cantitate=0 then costuri else pret end),0,comenzi.tip_comanda,1
from costuri,comenzi where costuri.comanda=comenzi.comanda and comenzi.subunitate = @subunitate 
--coefic
delete from coefic where data_lunii=@datasus 
	and (@lm is null or Loc_de_munca like @lm+'%')
insert into coefic 
(Data_lunii, Subunitate, Tip_coeficient, Loc_de_munca, Baza_initiala, Baza_actualizata, Cheltuieli_initiale, Cheltuieli_actualizate, Coeficient_initial, Coeficient_actualizat, Cheltuieli_initiale_FS, Cheltuieli_actualizate_FS, Coeficient_initial_FS, Coeficient_actualizat_FS)
select @datasus,@subunitate, 
(case when lm='' then 'G' else 'L' end), 
lm,cantitate,cantitate,costuri,costuri, 
(case when cantitate<5 then 0 else pret end),(case when cantitate<5 then 0 else pret end),0,0,0,0 
from costuri where comanda='' 
	and (@lm is null or lm<>'') -- nu pot scrie coef. de regie generala pe fiecare sectie 
--chind
delete from chind where data between @datajos and @datasus 
	and (@lm is null or Loc_de_munca like @lm+'%')
insert into chind 
(Subunitate, Tip_document, Numar_document, Data, Suma, Explicatii, Loc_de_munca, Comanda, Articol_de_calculatie, Cont_ch_sursa, Loc_de_munca_sursa, Comanda_sursa)
select @subunitate,tip,left(numar,8),max(data),sum(cantitate*valoare),'',lm_sup,comanda_sup,max(art_inf),comanda_inf,lm_inf,comanda_inf
from costtmp 
where comanda_sup='' and art_sup not in ('P','R','S','N') 
	and (@lm is null or lm_sup<>'') -- nu pot scrie ch.ind. regie generala pe fiecare sectie 
group by tip,left(numar,8),lm_sup,comanda_sup,art_sup,lm_inf,comanda_inf--,art_inf
