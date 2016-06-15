--***
create procedure [dbo].[regii] @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null  
as  
begin  
/*Se insereaza decontari de tip regie loc de munca sau generala pentru cele ce nu au asa ceva*/  
declare @cRegieNedec char(20),@cArtGen char(20),@cArtLm char(20),@lNeterminata int,@lDafora int,@lItinerar int  
declare @bucla int,@nLm int, @cArtX char(20), @subunitate char(9)  
set @subunitate = (select val_alfanumerica from par where tip_parametru = 'GE' and parametru = 'SUBPRO')   
set @cArtX=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='ARTCALX')  ,'FX')
set @nLm=(select max(lungime) from strlm where costuri=1)  
set @cArtLm=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='REGLOCMUN'),'L')  
set @lNeterminata=isnull((select val_logica from par where tip_parametru='PC' and parametru='LUCRSI'),0)  
set @lItinerar=isnull((select val_logica from par where tip_parametru='PC' and parametru='ITINERAR'),0)  
set @cArtGen=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='REGENERAL') ,'G') 
set @cRegieNedec=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='CHELTNED')  ,'')
set @lDafora=isnull((select val_logica from par where tip_parametru='GE' and parametru='DAFORA')  ,0)
  
/*Trebuie buclate auxiliarele deoarece directele pot veni tot de aici*/  
set @bucla=1  
while @bucla>0  
begin  
 insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
 select distinct @dDataSus,LEFT(LOC_DE_MUNCA_beneficiar,@nLm),comanda_beneficiar, (case when art_calc_benef='' then @cArtX else art_calc_benef end),  
	lm_sup,comanda_sup,'T',1,0,0,'DA','' 
from costtmp t1,comenzi  
where comenzi.subunitate = @subunitate and t1.comanda_sup=comenzi.comanda and comenzi.tip_comanda='X' 
	and not exists (select * from costtmp t2 where t1.lm_sup=t2.lm_inf and t1.comanda_sup=t2.comanda_inf)  
 set @bucla=@@rowcount  
end  

insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
select distinct @dDataSus,(case when @cRegieNedec='Regie loc munca' then lm_sup else '' end)  
	,(case when @cRegieNedec='Regie loc munca' then isnull((select RTrim(left(comanda,20)) from speciflm where loc_de_munca=lm_sup),'') else '' end),  
	'T',lm_sup,comanda_sup,'T',1,0,0,'DL','' 
from costtmp t1,comenzi  
where comenzi.subunitate = @subunitate and t1.COMANDA_inf<>'' and t1.comanda_sup=comenzi.comanda and comenzi.tip_comanda not in ('P','R','A','L','S')   
	and not exists (select * from costtmp t2 where t1.lm_sup=t2.lm_inf and t1.comanda_sup=t2.comanda_inf and t2.art_inf<>'N')  
  
/*Inserare decontari de tip regie loc de munca pentru comenzi tip 'L' - Ghita, 22.04.2004*/  
insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
select distinct @dDataSus,lm_sup,'','T',lm_sup,comanda_sup,'T',1,0,0,'DL','' 
from costtmp t1,comenzi  
where comenzi.subunitate = @subunitate and t1.COMANDA_inf<>'' and t1.comanda_sup=comenzi.comanda and comenzi.tip_comanda='L'   
  
/*Completare loc de munca si comanda cu nimic '' pentru cele ce incarca pe articole  
de calculatie de tip regie loc de munca sau regie generala*/  
update costtmp set comanda_sup='' where art_inf=@cArtLM  or (comanda_inf in (select comanda from comenzi where tip_comanda='L' and subunitate = @subunitate))  
update costtmp set lm_sup='',comanda_sup='' where art_inf=@cArtGen or (lm_sup='' and comanda_sup<>'') or (comanda_inf in (select comanda from comenzi where tip_comanda='G' and subunitate = @subunitate ))  
  
/*REGIE LOC DE MUNCA - primita de comenzi*/  
INSERT INTO COSTTMP (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
select distinct @dDataSus,t1.lm_sup,t1.comanda_sup,'L',t2.lm_sup,'','T',0,0,0,'RL','' 
from costtmp t1,costtmp t2 
where t1.lm_sup<>'' and t2.lm_sup<>'' and t2.comanda_sup='' and t1.comanda_sup<>'' and t1.lm_sup like rtrim(t2.lm_sup)+'%'  
and (select tip_comanda from comenzi where comanda=t1.comanda_sup and subunitate = @subunitate ) not in ('L','G')   
and t1.lm_sup+t1.comanda_sup not in (select lm_sup+comanda_sup from costtmp where exists (select 1 from costtmp t2 where costtmp.lm_sup=t2.lm_inf and costtmp.comanda_sup=t2.comanda_inf and t2.tip='DY'))  
-- 3 linii mai sus: Ghita, 22.04.2004-20.05.2004  
  
/*Sterg regia loc de munca la cele care dau regie loc de munca*/  
delete from costtmp  
where comanda_inf='' and lm_inf in (select loc_de_munca from speciflm where RTrim(left(comanda,20))<>'') 
	or exists (select * from costtmp t2 where costtmp.lm_inf=t2.lm_sup and costtmp.comanda_inf='' and costtmp.art_sup='L' and costtmp.tip='RL' 
		and t2.comanda_sup='' and costtmp.lm_sup=t2.lm_inf and costtmp.comanda_sup=t2.comanda_inf)  
  
/*Sterg regia locului de munca la cele ce nu au baza pentru a primi regie loc de munca*/  
DELETE FROM COSTTMP WHERE  ART_SUP='L' AND TIP='RL' 
	and NOT EXISTS  (SELECT * FROM COSTTMP T2 WHERE COSTTMP.LM_SUP=T2.LM_SUP AND COSTTMP.COMANDA_SUP=T2.COMANDA_SUP 
		AND (T2.ART_SUP IN (SELECT ARTICOL_DE_CALCULATIE FROM ARTCALC WHERE BAZA_PT_REGIA_SECTIEI=1) OR  T2.ART_INF IN (SELECT ARTICOL_DE_CALCULATIE FROM ARTCALC WHERE BAZA_PT_REGIA_SECTIEI=1)  
))  
  
/*Se insereaza regie generala la locurile de munca ce nu pot da pe regie proprie*/  
--Ghita, 21.02.2008, am scos linia de mai jos, pentru a evita 'duplicate index':  
  
update costtmp set comanda_sup=left(comanda,20) from speciflm where costtmp.lm_sup=speciflm.LOC_DE_MUNCA and costtmp.comanda_sup=''  
  
insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar)
select distinct @dDataSus,(case when @lDafora=1 then left(lm_sup,2) else '' end),  
	(case when @lDafora=1 then isnull((select RTrim(left(comanda,20)) from speciflm where speciflm.loc_de_munca=left(lm_sup,2)),'') else '' end),'T',lm_sup,comanda_sup,'T',1,0,0,'GL','' 
from costtmp t1  
where t1.lm_sup<>'' and t1.comanda_sup='' and t1.lm_sup not in  (select lm_inf from costtmp t2 where t2.comanda_inf='')  
  
/*Cheltuieli ca si regia generala -> Vezi desfacere*/  
if exists(select * from costtmp t,comenzi c where c.subunitate = @subunitate and t.comanda_sup=c.comanda and c.tip_comanda='D')  
begin  
 delete from costtmp where lm_inf<>'' and comanda_inf in (select comanda from comenzi where tip_comanda='D' and subunitate = @subunitate)  
  
 insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar)
 select distinct @dDataSus,costtmp.lm_sup,costtmp.comanda_sup,'D',  
	 t2.lm_sup,  
	t2.comanda_sup,  
	'T',0,0,0,'DE','' 
 from costtmp,comenzi, (select distinct lm_sup,comanda_sup from costtmp,comenzi c2 where c2.comanda=costtmp.comanda_sup and c2.tip_comanda='D') as t2   
 where comenzi.subunitate = @subunitate and costtmp.comanda_sup=comenzi.comanda and comenzi.tip_comanda in ('P','R')   
end  
/*Regie generala*/  
/*Daca exista se insereaza*/  
if exists(select * from costtmp where lm_sup='' and comanda_sup='' and art_sup not in ('P','R','S','N'))  
 insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
 select distinct @dDataSus,lm_sup,comanda,'G','','','T',0,0,0,'RG','' from costtmp,comenzi where comenzi.subunitate = @subunitate and comanda_sup=comenzi.comanda and  
 comenzi.tip_comanda in ('P','R')  
  
/*Sterg regia generala la cele ce nu au baza pentru a primi regie generala*/  
declare @nDecReg int  
set @nDecReg=isnull((select val_numerica from par where tip_parametru='PC' and parametru='DECREG'),0)  
if @nDecReg=0  
begin  
 DELETE FROM COSTTMP 
	WHERE ART_SUP in ('G','D') AND NOT EXISTS  (SELECT * FROM COSTTMP T2 WHERE COSTTMP.LM_SUP=T2.LM_SUP AND COSTTMP.COMANDA_SUP=T2.COMANDA_SUP AND   
		(T2.ART_SUP IN (SELECT ARTICOL_DE_CALCULATIE FROM ARTCALC WHERE BAZA_PT_REGIA_GENERALA=1) OR  
		T2.ART_INF IN (SELECT ARTICOL_DE_CALCULATIE FROM ARTCALC WHERE BAZA_PT_REGIA_GENERALA=1)  
 ))  
end  
  
if @lNeterminata=1 and @lItinerar=0  
begin  
 insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
 select @dDataSus,'','',comenzi.tip_comanda,costuri.lm,costuri.comanda,'T',1,0,0,'PX',''  
 from costuri,comenzi 
 where comenzi.subunitate = @subunitate and costuri.comanda=comenzi.comanda and comenzi.tip_comanda in ('P','R','A','S') 
	and  not exists (select * from costtmp where costtmp.lm_inf=costuri.lm and costtmp.comanda_inf=costuri.comanda and art_inf<>'N')  
	and costuri.comanda in (select comanda_inf from costtmp t1 where lm_sup='' and comanda_sup='' and art_sup in ('P','R','S') group by comanda_inf)  
end  
  
/*Rezolvare erori*/  
delete from costtmp where costtmp.lm_inf<>'' and costtmp.comanda_inf<>'' and not exists  
(select * from costtmp t2 where costtmp.lm_inf=t2.lm_sup and costtmp.comanda_inf=t2.comanda_sup)  
/*Pregatire rezolvare costuri*/  
if not exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[costuri]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)  
	CREATE TABLE costuri (lm char(20),comanda char(20),costuri float,cantitate float,pret float(53), rezolvat int,nerezolvate int)  
truncate table costuri  
insert into costuri (lm,comanda,costuri,cantitate,pret,rezolvat,nerezolvate)
select distinct lm_sup,comanda_sup,0,0,0,0,0  
from costtmp  
/*Generare automata de neterminata*/  
  
insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
select @dDataSus,'','',(case when @lNeterminata=1 and comenzi.tip_comanda<>'A' then 'N' else comenzi.tip_comanda end),costuri.lm,costuri.comanda,'T',1,0,0,'NE',''  
from costuri,comenzi 
where comenzi.subunitate = @subunitate and costuri.comanda=comenzi.comanda and comenzi.tip_comanda in ('P','R','A','S') 
	and not exists (select * from costtmp where costtmp.lm_inf=costuri.lm and costtmp.comanda_inf=costuri.comanda and art_inf<>'N')  
  
end
