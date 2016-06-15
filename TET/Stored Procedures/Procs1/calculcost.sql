--***
CREATE procedure calculcost @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null   
as
set arithabort off
set ansi_warnings off
declare @cLm char(20),@cCom char(20),@cArt char(20),@gLM char(20),@gCom char(20),@gArt char(20)
declare @nFetch int,@nValoare float,@nCantitate float,@nCost float,@nPas int,@nSchimb int,@nMaiAre int
declare @nDecReg int,@nDecRegL int--decontare Regie loc de munca ca si dupa venituri
declare @lArdealul int,@nLm int
set @nDecRegL=isnull((select val_numerica from par where tip_parametru='PC' and parametru='DECREGL'),0)
set @lArdealul=isnull((select val_logica from par where tip_parametru='SP' and parametru='ARDEALUL'),0)
set @nLm=isnull((select max(lungime) from strlm where costuri=1),0) 

set @nPas=1
set @nSchimb=1
set @nMaiAre=(select count(*) from costtmp where parcurs=0)
set @nSchimb=(select count(*) from costtmp,costuri where 
	lm_sup=lm and comanda_sup=comanda and costtmp.cantitate*valoare<>0 and (costuri.rezolvat=0 or parcurs=0))

while @nMaiAre>0 and @nSchimb>0
begin
	--Sterg regie loc de munca cu baza 0
	delete from costtmp where exists(select * from costuri where lm_inf=lm and comanda_inf=comanda and comanda='' and art_sup='L' and rezolvat=2 and costtmp.cantitate=0)
	delete from costtmp where exists(select * from costuri where lm_inf=lm and comanda_inf=comanda and comanda<>'' and rezolvat=1 and costuri.costuri=0 and art_inf<>'N')
	declare costtmp cursor for
	select lm_sup,comanda_sup,art_sup,cantitate,valoare from costtmp
		where cantitate*valoare<>0 and parcurs=0 AND ART_SUP not in ('P','S','N','R','A')
		order by lm_sup,comanda_sup
	open costtmp
	fetch next from costtmp into @cLM,@cCom,@cArt,@nCantitate,@nValoare
	set @nFetch=@@fetch_status
	while @nFetch=0
	begin
		set @gLM=@cLM
		set @gCom=@cCom
		set @gArt=@cArt
		set @nCost=0
		while @gLM=@cLM and @gCom=@cCom and @gArt=@cArt and @nFetch=0
		begin
			set @nCost=@nCost+@nCantitate*@nValoare
			fetch next from costtmp into @cLM,@cCom,@cArt,@nCantitate,@nValoare	
			set @nFetch=@@fetch_status
		end
		update costuri set costuri=costuri+@nCost where lm=@gLM and comanda=@gCom
	end
	close costtmp
	deallocate costtmp
	update costtmp set parcurs=@nPas where cantitate*valoare<>0 and parcurs=0
	update costuri set rezolvat=1 
		where rezolvat=0 and abs(costuri)>0.001 and not exists(select lm_sup,comanda_sup from costtmp where costtmp.art_sup not in ('P','S','N','R','A') and parcurs=0 and lm_sup=costuri.lm and comanda_sup=costuri.comanda)
	
	/*Rezolvarea problemei bazei lm*/

	if @nDecRegL<2 --Se pune baza din articole de calculatie
		update costuri set cantitate=(
			select isnull(sum(costtmp.cantitate*costtmp.valoare),1) from costtmp,costtmp t2 where t2.lm_sup=costtmp.lm_sup and t2.comanda_sup=costtmp.comanda_sup and t2.art_sup='L' 
				and	t2.lm_inf=costuri.lm and costtmp.lm_sup like rtrim(t2.lm_inf)+'%' and costuri.comanda='' and costtmp.comanda_sup<>'' and costtmp.parcurs>0 
				and (costtmp.art_inf in (select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1) or costtmp.art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1)))
			where lm<>'' and comanda='' and lm not in (select distinct LEFT(lm_sup,LEN(LM)) from costtmp where parcurs=0 and art_sup not in ('L','G') and art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1))
	else if @nDecRegL=2--Se pune baza din venituri
		update costuri set cantitate=cant from costuri,(select left(p1.loc_de_munca,@nLm) as lm,isnull(sum(suma),0) as cant from pozincon p1 where p1.cont_creditor like '7%' and p1.cont_debitor not like '121%' and p1.Comanda<>''
		and data between @dDataJos and @dDataSus and exists (select * from costtmp t2 where t2.art_sup='L' and left(p1.loc_de_munca,@nLm)=t2.lm_sup and p1.comanda=t2.comanda_sup )
		group by left(p1.loc_de_munca,@nLm)) calcule
		where costuri.lm=calcule.lm and costuri.comanda='' and costuri.rezolvat=0
	else if @nDecRegL=3 --Se pune regie unitara pentru fiecare comanda - valoare egala
		update costuri set cantitate=a.oameni 
		from 
		(select lm_inf lm, sum(cantitate) oameni from costtmp where costtmp.tip='RL' and costtmp.art_sup='L' group by lm_inf) a
		where a.lm=costuri.lm and costuri.comanda=''

	update costuri set rezolvat=2
		where rezolvat=1 and abs(pret)>0.000000000001 and lm<>'' and comanda='' 
		and (@nDecRegL>1 or lm not in (select distinct left(lm_sup,len(lm)) from costtmp where parcurs=0 and art_sup not in ('L','G') and art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1)))

	/*Actualizare coeficient pentru regie loc de munca*/
	update costuri set pret=costuri/cantitate,rezolvat=2
		where costuri*cantitate<>0 and rezolvat=1 and lm<>'' and comanda=''
	
	/*Actualizare tabela costtmp cu baza si coeficienti*/
	update costtmp set valoare=costuri.pret from costuri where costtmp.lm_inf=costuri.lm and
		--costtmp.art_sup<>'G' and Nu inteleg la ce e buna linia asta
		costtmp.comanda_inf=costuri.comanda	and costuri.rezolvat=2 and costuri.pret<>0 and parcurs=0
	

	if @nDecRegL<2 --Se pune baza din articole de calculatie
		update costtmp set
		cantitate=(select isnull(sum(cantitate*valoare),0) from costtmp tmp1 where 
		tmp1.lm_sup=costtmp.lm_sup and tmp1.comanda_sup=costtmp.comanda_sup and tmp1.parcurs>0
		and (tmp1.art_inf in 
		(select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1)
		OR tmp1.art_sup in 
		(select articol_de_calculatie from artcalc where baza_pt_regia_sectiei=1)))
		where art_sup='L' and parcurs=0 and valoare<>0  and costtmp.comanda_inf=''
		and costtmp.lm_inf<>''
	else  if @nDecRegL=2--Se pune baza din venituri
		update costtmp set CANTITATE=cant 
			from (select left(p1.loc_de_munca,@nLm) as lm,rtrim(comanda) as comanda,isnull(sum(suma),0) as cant from pozincon p1
				where p1.cont_creditor like '7%' and p1.cont_debitor not like '121%' and p1.Comanda<>''	and data between @dDataJos and @dDataSus and exists (select * from costtmp t2 where t2.art_sup='L' and left(p1.loc_de_munca,@nLm)=t2.lm_sup and p1.comanda=t2.comanda_sup )
				group by left(p1.loc_de_munca,@nLm),comanda) calcule
			where costtmp.lm_inf=calcule.lm and costtmp.comanda_sup=calcule.comanda and COSTTMP.ART_SUP='L'
	else if @nDecRegL=3--Se pune baza egala cu 1 intotdeauna
		update costtmp set CANTITATE=1
			where COSTTMP.ART_SUP='L'

	/*Rezolvarea problemei de decontare */
	update costuri set cantitate=
		(select isnull(sum(cantitate),0) from costtmp where costtmp.comanda_inf=costuri.comanda and	costtmp.lm_inf=costuri.lm and costtmp.art_inf='T' and costuri.rezolvat=1 and costtmp.tip<>'CX')
		where costuri.rezolvat=1 and costuri.comanda<>'' and cantitate=0
	update costuri set pret=costuri/cantitate where costuri.rezolvat=1 and cantitate<>0 and comanda<>''
	update costtmp set valoare=costuri.pret 
		from costuri
		where (costtmp.art_inf='T' and costtmp.comanda_inf=costuri.comanda and costtmp.lm_inf=costuri.lm
			and costtmp.valoare=0 and costtmp.parcurs=0 and costtmp.comanda_inf<>''
			and costuri.rezolvat=1)
		or
			(costtmp.art_sup='T' and costtmp.comanda_sup=costuri.comanda and costtmp.lm_sup=costuri.lm
			and costtmp.valoare=0 and costtmp.parcurs=0 and costtmp.comanda_sup<>''
			and costuri.rezolvat=1)

	/*Regie Generala*/
	exec calculregie @dDataJos,@dDataSus

	set @nMaiAre=(select count(*) from costtmp where parcurs=0)
	set @nSchimb=(select count(*) from costtmp where parcurs=0 and cantitate*valoare<>0)

	set @nPas=@nPas+1
	--set @nMaiAre=0
end

if @nMaiAre>0
	update costuri set nerezolvate=(select count(*) from costtmp where costtmp.comanda_sup=costuri.comanda and costtmp.lm_sup=costuri.lm and costtmp.parcurs=0)

if isnull((select costuri from costuri where lm='' and comanda=''),0)=0
begin
	delete from costtmp where tip='RG'
	update costuri set rezolvat=3 where lm='' and comanda=''
	update costuri set nerezolvate=0, rezolvat=rezolvat+1 where nerezolvate=1
	return
end
