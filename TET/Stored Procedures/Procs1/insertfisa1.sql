--***
CREATE procedure insertfisa1 @pLm char(20),@pCom char(20),@pNivel int,@pNivelMax int,@pCantPond float,@pArtSup char(20),@pExceptArtSup char(20),@pExcArtNeincl char(20),@pArtInf char(20),@pDetalDOC int,@pSub char(20),@pDinf datetime,@pDsup datetime,@pGrCom

 int,@pComenziNedet char(100),@pArtCalcNedet char(100),@pNrOrd int	
as
begin
declare @cDesc char(100),@nCant float,@nPret float,@nValoare float,@nNivelUrm int,@nFetch int,@cLm char(20),@cComanda char(20),@cNume char(100),@nCantPond float,@cArticol char(20)
declare @cTip char(2),@cNumar char(20),@dData datetime,@cCont char(20),@nLm int,@cComDinGr char(20),@cLMDinGr char(9),@cComAnt char(20),@cTip_descriere char(1),@cCod_descriere char(20),@cLocM_descriere char(9),@nLuna int,@nAn int
declare @lSCom int,@lSLM int,@nNrOrd int,@nNrPar int,@nNrPar1 int,@cNrOrd int,@dDJos datetime,@dDSus datetime,@dDatatmp datetime,@gArticol char(20)
declare @tt table(lm_sup char(20),comanda_sup char(20),art_sup char(20),art_inf char(20),numar int identity)
--acesti doi parametrii trebuie scosi
set @lSCom=1
set @lSLM=1
--acesti doi parametrii trebuie scosi
set @nLm=(select max(lungime) from strlm where costuri=1)
declare @minune cursor,@minune1 cursor
if @pCantPond is null	set @pCantPond=0
if @pDetalDOC is null	set @pDetalDoc=0
if @pNivel=0 truncate table fisacmdtmp
set @nNivelUrm=@pNivel+1

insert into @tt(lm_sup,comanda_sup,art_sup,art_inf)
select lm_sup,comanda_sup,art_sup,art_inf
from #tt
where not(lm_sup='' and comanda_sup='' and art_sup in ('P','R','S','N','A')) and lm_sup like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end and ((@pGrCom<>0 and @pNivel=0 and comanda_sup like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else

 '' end) or comanda_sup like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end) and #tt.data between @pDinf and @pDsup
group by lm_sup,comanda_sup,art_sup,art_inf

set @minune=cursor for
 select p.numar, year(data),month(data),isnull(artcalc.denumire,case when cs.art_sup='L' then 'REGIE LOC MUNCA' when cs.art_sup='G' then 'REGIE GENERALA' when cs.art_sup='T' then 'COSTURI PRELUATE' else '' end),(case when cs.art_sup='T' then cs.art_inf else cs.art_sup end),sum(cantitate*@pCantPond),
 sum(cantitate*valoare)/(case when @pCantPond=0 then 1 else sum(cantitate*@pCantPond) end),sum(cantitate*valoare*(case when @pCantPond=0 then 1 else @pCantPond end)),cs.art_sup,cs.art_inf,cs.comanda_sup,cs.lm_sup
 from #tt cs
 inner join @tt p on p.lm_sup=cs.lm_sup and p.comanda_sup=cs.comanda_sup and p.art_sup=cs.art_sup and p.art_inf=cs.art_inf
 left join artcalc on (case when cs.art_inf='T' then cs.art_sup else cs.art_inf end)=artcalc.articol_de_calculatie
 where not(cs.lm_sup='' and cs.comanda_sup='' and cs.art_sup in ('P','R','S','N','A')) 
 and cs.lm_sup like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end 
 and ((@pGrCom<>0 and @pNivel=0 and cs.comanda_sup like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end) or cs.comanda_sup like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end) 
 and cs.data between @pDinf and @pDsup 
 and ((case when cs.art_inf='T' then cs.art_sup else cs.art_inf end)<>'N' or month(cs.data)=month(@pDinf) and year(cs.data)=year(@pDinf))
 group by p.numar,year(data),month(data),cs.lm_sup,cs.comanda_sup,artcalc.denumire,cs.art_sup,cs.art_inf,ordinea_in_raport 
 order by cs.comanda_sup,isnull(ordinea_in_raport,99)
	
open @minune 
fetch from @minune into @cNrOrd,@nAn,@nLuna,@cDesc,@cArticol,@nCant,@nPret,@nValoare,@cLm,@cComanda,@cComDinGr,@cLMDinGr
set @gArticol=@cArticol
set @nFetch=@@fetch_status set @cComAnt = '*' 
while @nFetch=0
begin
	if (@pExcArtNeincl='' or @cArticol not in (select articol_de_calculatie from tmpartc where ordinea_in_raport=0))
	begin
	if (@pGrCom<>0 and @pNivel=0 and @cComDinGr <> @cComAnt)
	begin
	set @nNrOrd=@nNrOrd+1
	
	insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
	values (@nNrOrd,@pNivel,'Comanda: '+RTrim(@cComDinGr),0,0,0,'','',@cLm,@cComanda,@cArticol,@pNrOrd)

	set @cComAnt = @cComDinGr
	end

	if exists(select * from fisacmdtmp where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd)
	begin
	update fisacmdtmp set cantitate=cantitate+@nCant,valoare=valoare+@nValoare,pret=valoare/cantitate
	where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd
	set @nNrOrd=isnull((select numar_de_ordine from fisacmdtmp where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd),0)
	end
	else
	begin
	set @nNrOrd=isnull((select max(numar_de_ordine) from fisacmdtmp),0)+1
	insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
	values (@nNrOrd,@pNivel,@cDesc,@nCant,@nPret,@nValoare,'A',@cArticol,@cLm,@cComanda,@cArticol,@pNrOrd)
	end
	if patindex('%,'+rtrim(@cArticol)+',%',@pArtCalcNedet)<>0 and @pNivel>0 break
	if @pNivel<@pNivelMax and @cArticol<>'N' and (@pArtSup='' or @cArticol in (select articol_de_calculatie from tmpartc where ordinea_in_raport>0)) and (@pExceptArtSup='' or @cArticol not in (select articol_de_calculatie from tmpartc where ordinea_in_raport

<0)) 
	begin
	set @dDatatmp=dateadd(year,@nAn-1901,'01/01/1901') 
	set @dDatatmp=dateadd(month,@nLuna,@dDatatmp)
	set @dDSus=dateadd(day,-1,@dDatatmp)
	set @dDJos=dateadd(month,-1,@dDatatmp)
	set @nCantPond=@pCantPond
	execute insertfisa @cLMDinGr,@cComDinGr,@nNivelUrm,@pNivelMax,@nCantPond,@cLm,'','',@cComanda,@pDetalDoc,@pSub,@dDJos,@dDSus,@pGrCom,@pComenziNedet,@pArtCalcNedet,@nNrOrd,0
	end
	end
	fetch from @minune into @cNrOrd,@nAn,@nLuna,@cDesc,@cArticol,@nCant,@nPret,@nValoare,@cLm,@cComanda,@cComDinGr,@cLMDinGr
	set @nFetch=@@fetch_status
 end
 close @minune
 deallocate @minune
 end
