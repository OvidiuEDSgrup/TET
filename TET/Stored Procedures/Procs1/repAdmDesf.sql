--***
create procedure [dbo].[repAdmDesf] @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null  
as  
declare @sub char(9)
declare @nDifD float,@nDifA float 
declare @cArtAdm char(20), @cArtDesf char(20), @bazaArt int 
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
set @cArtAdm=(select val_alfanumerica from par where tip_parametru='PC' and parametru='CHADMIN')
if isnull(@cArtAdm,'')=''
	set @cArtAdm='fara'
set @cArtDesf=(select val_alfanumerica from par where tip_parametru='PC' and parametru='CHDESFAC')
if isnull(@cArtDesf,'')=''
	set @cArtDesf='fara'
set @bazaArt = isnull((select val_logica from par where tip_parametru='PC' and parametru='SGADESF'),0)
declare @nLM int
set @nLM=isnull((select max(lungime) from strlm where costuri=1),0) 

delete from coefic where data_lunii=@dDataSus and tip_coeficient in ('Z','D')
	and (@lm is null or Loc_de_munca like @lm+'%')
delete from cost where tip_inregistrare='PE' and data_lunii=@dDataSus
	and (@lm is null or Loc_de_munca like @lm+'%')

if @cArtAdm<>'fara' or @cArtDesf<>'fara'
begin
--Incarcare cheltuieli de aprovizionare si desfacere operate direct pe comenzi P si R
insert into cost
(Data_lunii, Subunitate, Loc_de_munca, Comanda, Tip_comanda, Articol_de_calculatie, Tip_inregistrare, Valoare, Valoare_fond_special, Cont_cheltuieli_sursa, Loc_de_sursa, Comanda_sursa, Articole_de_calculatie_sursa)
select @dDataSus,p.subunitate,left(p.loc_de_munca,@nLM),p.comanda,k.tip_comanda,c.articol_de_calculatie,'PE',sum(p.suma),0,'','','',''
from pozincon p 
inner join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_Debitor and c.logic=1 and c.articol_de_calculatie in (@cArtAdm,@cArtDesf) 
inner join comenzi k on k.subunitate = p.subunitate and k.comanda=p.comanda
where p.subunitate=@sub and p.cont_debitor like '6%' and p.data between @dDataJos and @dDataSus 
	and p.loc_de_munca<>'' and p.comanda<>'' and k.tip_comanda in ('P','R') 
	and exists (select * from costtmp where lm_sup='' and art_sup in ('P','R') and p.loc_de_munca=costtmp.lm_inf and p.comanda=costtmp.comanda_inf)
	and (@lm is null or p.Loc_de_munca like @lm+'%')
group by p.subunitate, left(p.loc_de_munca,@nLM),p.comanda,k.tip_comanda,c.articol_de_calculatie

--Incarcare cheltuieli de aprovizionare si desfacere pe locuri de munca, daca se merge pe baza regiei generale
insert into coefic (Data_lunii, Subunitate, Tip_coeficient, Loc_de_munca, Baza_initiala, Baza_actualizata, Cheltuieli_initiale, Cheltuieli_actualizate, Coeficient_initial, Coeficient_actualizat, Cheltuieli_initiale_FS, Cheltuieli_actualizate_FS, Coeficient_initial_FS, Coeficient_actualizat_FS)
select @dDataSus,@sub,(case when articol_de_calculatie=@cArtAdm then 'Z' else 'D' end),
left(loc_de_munca,@nLM),0,0,sum(suma),sum(suma),0,0,0,0,0,0
from pozincon,conturi 
where @bazaArt=0 and pozincon.cont_Debitor=conturi.cont and conturi.logic=1 and conturi.articol_de_calculatie in (@cArtAdm,@cArtDesf) 
	and pozincon.cont_debitor like '6%' and pozincon.data between @dDataJos and @dDataSus 
	and (pozincon.comanda='' or pozincon.comanda in (select comanda from comenzi where tip_comanda='L' and subunitate = @sub))
	and loc_de_munca in (select distinct loc_de_munca from costtmp where art_sup='G')
	and (@lm is null or pozincon.Loc_de_munca like @lm+'%')
group by left(loc_de_munca,@nLM),conturi.articol_De_calculatie

update coefic set baza_initiala=
(select isnull(sum(costtmp.cantitate),1) from costtmp where costtmp.art_sup='G' and costtmp.lm_sup=coefic.loc_de_munca)
where @bazaArt=0 and loc_de_munca<>'' and coefic.tip_coeficient in ('Z','D') and data_lunii=@dDataSus

set @nDifA=ISNULL((select sum(suma) from pozincon,conturi where pozincon.cont_debitor=conturi.cont 
	and conturi.logic=1 and conturi.articol_de_calculatie=@cArtAdm and pozincon.data between @dDataJos and @dDataSus
	and (@lm is null or Loc_de_munca like @lm+'%')
	),0)
-ISNULL((select sum(valoare) from cost where tip_inregistrare='PE' and data_lunii=@dDataSus and articol_de_calculatie=@cArtAdm
	and (@lm is null or Loc_de_munca like @lm+'%')
),0)
-ISNULL((Select sum(cheltuieli_initiale) from coefic where tip_coeficient='Z' and data_lunii=@dDataSus and baza_initiala<>1
	and (@lm is null or Loc_de_munca like @lm+'%')
),0)

set @nDifD=ISNULL((select Sum(suma) from pozincon,conturi where pozincon.cont_debitor=conturi.cont and
conturi.logic=1 and conturi.articol_de_calculatie=@cArtDesf and pozincon.data between @dDataJos and @dDataSus
	and (@lm is null or Loc_de_munca like @lm+'%')
),0)-
ISNULL((select sum(valoare) from cost where tip_inregistrare='PE' and data_lunii=@dDataSus and articol_de_calculatie=@cArtDesf
	and (@lm is null or Loc_de_munca like @lm+'%')
),0)-
ISNULL((Select sum(cheltuieli_initiale) from coefic where tip_coeficient='D' and data_lunii=@dDataSus and baza_initiala<>1
	and (@lm is null or Loc_de_munca like @lm+'%')
),0)
-- calcul @nDifDCom din tabela costtmp (com_sup tip D)
+ISNULL((select sum(cantitate*valoare) 
	from costtmp ct, comenzi c where c.subunitate=@sub and ct.comanda_sup=c.comanda and tip_comanda='D'),0)

if @nDifA<>0 and not exists(select * from coefic where loc_de_munca='' and tip_coeficient='Z' and data_lunii=@dDataSus)
insert into coefic (Data_lunii, Subunitate, Tip_coeficient, Loc_de_munca, Baza_initiala, Baza_actualizata, Cheltuieli_initiale, Cheltuieli_actualizate, Coeficient_initial, Coeficient_actualizat, Cheltuieli_initiale_FS, Cheltuieli_actualizate_FS, Coeficient_initial_FS, Coeficient_actualizat_FS)
select @dDataSus,@sub,'Z','',0,0,0,0,0,0,0,0,0,0

if @nDifD<>0 and not exists(select * from coefic where loc_de_munca='' and tip_coeficient='D' and data_lunii=@dDataSus)
insert into coefic (Data_lunii, Subunitate, Tip_coeficient, Loc_de_munca, Baza_initiala, Baza_actualizata, Cheltuieli_initiale, Cheltuieli_actualizate, Coeficient_initial, Coeficient_actualizat, Cheltuieli_initiale_FS, Cheltuieli_actualizate_FS, Coeficient_initial_FS, Coeficient_actualizat_FS)
select @dDataSus,@sub,'D','',0,0,0,0,0,0,0,0,0,0

update coefic set cheltuieli_initiale=cheltuieli_initiale+isnull(@nDifA,0)
where loc_de_munca='' and tip_coeficient='Z'  and data_lunii=@dDataSus
update coefic set cheltuieli_initiale=cheltuieli_initiale+isnull(@nDifD,0)
where loc_de_munca='' and tip_coeficient='D' and data_lunii=@dDataSus

-- De aici se calculeaza bazele
if @bazaArt=0
update coefic set baza_initiala=(select isnull(sum(cantitate),1) from costtmp where art_sup='G')
where loc_de_munca='' and tip_coeficient in ('D','Z') and data_lunii=@dDataSus
else
update coefic set baza_initiala=(select isnull(sum(cantitate*valoare),1) from costtmp
where (case when art_sup='T' then art_inf else art_sup end) in (select articol_de_calculatie from artcalc where (tip_coeficient='Z' and Baza_pt_ch_aprovizionare=1 or tip_coeficient='D' and Baza_pt_ch_desfacere=1)) and comanda_sup in 
(select comanda from comenzi k where k.subunitate = @sub and k.tip_comanda in ('P','R')))
where tip_coeficient in ('Z','D') and data_lunii=@dDataSus

update coefic set coeficient_initial=cheltuieli_initiale/baza_initiala,coeficient_actualizat=cheltuieli_initiale/baza_initiala
where data_lunii=@dDataSus and tip_coeficient in ('D','Z') and baza_initiala<>1 and baza_initiala<>0

--Se vor insera in tabela cost liniile pentru cele care nu au cheltuieli directe (sumele=0)
insert into cost
(Data_lunii, Subunitate, Loc_de_munca, Comanda, Tip_comanda, Articol_de_calculatie, Tip_inregistrare, Valoare, Valoare_fond_special, Cont_cheltuieli_sursa, Loc_de_sursa, Comanda_sursa, Articole_de_calculatie_sursa)
select distinct @dDataSus,@sub,lm_sup,comanda_sup,tip_comanda, @cArtAdm,'PE',0,0,'','','',''
from costtmp,comenzi 
where comenzi.subunitate=@sub and comanda_sup=comenzi.comanda 
and (@bazaArt=0 and art_sup='G' or @bazaArt=1 and (case when art_sup='T' then art_inf else art_sup end) in (select articol_de_calculatie from artcalc where Baza_pt_ch_aprovizionare=1) and comenzi.tip_comanda in ('P','R'))
and not exists (select * from cost where tip_inregistrare='PE' and articol_de_calculatie=@cArtAdm and loc_de_munca=lm_sup and comanda=comanda_sup and data_lunii=@dDataSus)
UNION ALL
select distinct @dDataSus,@sub,lm_sup,comanda_sup,tip_comanda, @cArtDesf,'PE',0,0,'','','',''
from costtmp,comenzi 
where comenzi.subunitate=@sub and comanda_sup=comenzi.comanda  
and (@bazaArt=0 and art_sup='G' or @bazaArt=1 and (case when art_sup='T' then art_inf else art_sup end) in (select articol_de_calculatie from artcalc where Baza_pt_ch_desfacere=1) and comenzi.tip_comanda in ('P','R'))
and not exists (select * from cost where tip_inregistrare='PE' and articol_de_calculatie=@cArtDesf and loc_de_munca=lm_sup and comanda=comanda_sup and data_lunii=@dDataSus)

--Se vor actualiza liniile aferente coeficientilor pe locuri de munca
update cost set valoare=valoare+
isnull((select coefic.coeficient_initial*costtmp.cantitate from costtmp,coefic 
	where costtmp.lm_sup=coefic.loc_de_munca and coefic.tip_coeficient=(case when articol_de_calculatie=@cArtAdm then 'Z' else 'D' end)  and costtmp.art_sup='G' and cost.loc_de_munca=lm_sup and cost.comanda=comanda_sup and coefic.data_lunii=@dDataSus),0)
where @bazaArt=0 and tip_inregistrare='PE' and data_lunii=@dDataSus and articol_de_calculatie in (@cArtAdm, @cArtDesf)
	and (@lm is null or Loc_de_munca like @lm+'%')

--Se vor actualiza liniile aferente coeficientilor generali
update cost set valoare=valoare+
isnull((select sum(coefic.coeficient_initial*costtmp.cantitate*(case when @bazaArt=0 then 1 else costtmp.valoare end)) 
from costtmp, coefic 
where coefic.loc_de_munca='' and coefic.tip_coeficient=(case when articol_de_calculatie=@cArtAdm then 'Z' else 'D' end) 
and (@bazaArt=0 and art_sup='G' or @bazaArt=1 and (case when art_sup='T' then art_inf else art_sup end) in (select articol_de_calculatie from artcalc where Baza_pt_ch_aprovizionare=1) and comanda_sup in (select comanda from comenzi k where k.subunitate = @sub and k.tip_comanda in ('P','R')))
and lm_sup=cost.loc_de_munca and comanda_sup=cost.comanda and coefic.data_lunii=@dDataSus),0)
where tip_inregistrare='PE' and data_lunii=@dDataSus and articol_de_calculatie in (@cArtAdm, @cArtDesf)
	and (@lm is null or Loc_de_munca like @lm+'%')

DELETE FROM COST WHERE DATA_LUNII=@dDataSus AND TIP_INREGISTRARE='PE' AND VALOARE=0
	and (@lm is null or Loc_de_munca like @lm+'%')
end
