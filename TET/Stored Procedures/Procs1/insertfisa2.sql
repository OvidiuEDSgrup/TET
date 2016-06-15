--***
create procedure [dbo].[insertfisa2] @pLm char(20),@pCom char(20),@pNivel int,@pNivelMax int,@pCantPond float,@pArtSup char(20),@pExceptArtSup char(20),@pExcArtNeincl char(20),@pArtInf char(20),@pDetalDOC int,@pSub char(20),@pDinf datetime,@pDsup datetime,@pGrCom int,@pComenziNedet char(100),@pArtCalcNedet char(100),@pNrOrd int
as 
begin 
declare @cDesc char(100),@nCant float,@nPret float,@nValoare float,@nNivelUrm int,@nFetch int,@cLm char(20),@cComanda char(20),@cNume char(100),@nCantPond float,@cArticol char(20) ,@subunitate char(9)
declare @cTip char(2),@cNumar char(20),@dData datetime,@cCont char(20),@nLm int,@cComDinGr char(20),@cComAnt char(20),@cTip_descriere char(1),@cCod_descriere char(20),@cLocM_descriere char(9),@nLuna int,@nAn int 
declare @lSCom int,@lSLM int,@nNrOrd int,@nNrPar int,@nNrPar1 int,@cNrOrd int,@dDJos datetime,@dDSus datetime,@dDatatmp datetime,@gArticol char(20) 
declare @tt table(lm_sup char(20),comanda_sup char(20),art_sup char(20),art_inf char(20),numar int identity) 
set @lSCom=1 
set @lSLM=1 
set @nLm=(select max(lungime) from strlm where costuri=1) 
set @subunitate = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO') 
declare @minune cursor,@minune1 cursor 
if @pCantPond is null set @pCantPond=0 
if @pDetalDOC is null set @pDetalDoc=0 
if @pNivel=0 truncate table fisacmdtmp 
set @nNivelUrm=@pNivel+1 
set @minune=cursor for select (case when lm_inf='' and comanda_inf<>'' then 'Cont: '+rtrim(comanda_inf)+'-'+isnull((select denumire_cont from conturi where subunitate=@pSub and cont=comanda_inf),'') when lm_inf<>'' and comanda_inf='' then 'Regia locului de munca:'+rtrim(lm_inf)+' - '+rtrim(isnull(lm.denumire,'')) when lm_inf='' and comanda_inf='' then 'Regia generala' else 'Loc de munca:'+lm_inf+',Comanda:'+rtrim(comanda_inf)+'-'+isnull((select max(descriere) from comenzi where comenzi.comanda=comanda_inf and comenzi.subunitate = @subunitate),'') end),(case when lm_inf='' and comanda_inf<>'' then 'C' when lm_inf<>'' and comanda_inf='' then 'L' when lm_inf='' and comanda_inf='' then 'G' else 'X' end),@pCantPond*sum(cantitate),sum(cantitate*valoare)/(case when sum(cantitate)=0 then 1 else sum(cantitate) end),@pCantPond*sum(cantitate*valoare),lm_inf,comanda_inf,art_sup 
from #tt left outer join lm on lm_inf=lm.cod 
where not(lm_sup='' and comanda_sup='' and art_sup in ('P','R','S','N','A')) and lm_sup like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end and comanda_sup like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end and art_sup=@pArtSup and art_Inf=@pArtInf and data between @pDinf and @pDsup and (1=0 or (case when art_inf='T' then art_sup else art_inf end)<>'N' or #tt.data=@pDinf) 
group by lm_inf,comanda_inf,lm.denumire,isnull(lm.denumire,''),art_sup 
open @minune 
fetch from @minune into @cDesc,@cTip_descriere,@nCant,@nPret,@nValoare,@cLm,@cComanda,@cArticol 
set @nFetch=@@fetch_status 
while @nFetch=0 
begin 
	if exists(select * from fisacmdtmp where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd) 
	begin 
		update fisacmdtmp set cantitate=cantitate+@nCant,valoare=valoare+@nValoare,pret=valoare/cantitate 
		where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd 
		set @nNrPar=isnull((select numar_de_ordine from fisacmdtmp where locm=@cLm and comanda_sup=@cComanda and art_sup=@cArticol and NrOrdp=@pNrOrd),0) 
		end 
		else 
		begin 
			set @nNrOrd=isnull((select max(numar_de_ordine) from fisacmdtmp),0)+1 
			set @nNrPar=@nNrOrd 
			insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
			values (@nNrOrd,@pNivel,@cDesc,@nCant,@nPret,@nValoare,@cTip_descriere,@cComanda,@cLm,@cComanda,@cArticol,@pNrOrd) 
		end 
		if @cTip_descriere='X' and patindex('%,'+rtrim(@cComanda)+',%',@pComenziNedet)<>0 break 
		if @pNivel<@pNivelMax 
		begin 
			if @cTip_Descriere='C' 
				set @nCantPond=@pCantPond 
			else 
			begin 
				set @nCantPond=@pCantPond*isnull(@nValoare/isnull((select sum(costuri) from #ty where data between @pDinf and @pDsup and lm=@cLm and comanda=@cComanda),1),1) 
			end
 
			if @pDetalDOC=1 
			begin 
				set @minune1=cursor for 
				select 'Document:'+tip_document+'-'+rtrim(numar_document)+' / '+convert(char(10),pozincon.data,102),'D',1,1,sum(suma)*@nCantPond,tip_document,numar_document,pozincon.data,cont_debitor 
				from pozincon
				inner join costsql cs on cs.lm_sup=@pLm and cs.comanda_sup=@pCom and cs.tip=pozincon.tip_document and pozincon.numar_document=cs.numar and cs.data=pozincon.data and cs.comanda_inf=@cComanda
				where pozincon.subunitate=@pSub 
				and (@pCom<>'' or left(pozincon.loc_de_munca,@nLm) like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end) --Fie comanda egal nimic (regia unui loc de munca), altfel nu conteaza locul de munca
				and (pozincon.comanda like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end)
				and cont_debitor=@cComanda and pozincon.data between @pDinf and @pDsup 
				group by pozincon.loc_de_munca,pozincon.comanda,tip_document,numar_document,pozincon.data,cont_debitor 

				open @minune1 
				fetch next from @minune1 into @cDesc,@cTip_descriere,@nCant,@nPret,@nValoare,@cTip,@cNumar,@dData,@cCont 
				set @nFetch=@@fetch_status 
				while @nFetch=0 
				begin 
					set @nNrOrd=isnull((select max(numar_de_ordine) from fisacmdtmp),0)+1 
					insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
					values (@nNrOrd,@pNivel+1,@cDesc,@nCant,@nPret,@nValoare,@cTip_descriere,@cTip,@cLm,@cComanda,@cArticol,@nNrPar) 
					if @pNivel+1<@pNivelMax begin if @cTip in ('CM','RS','RM','DF') 
					begin 
						set @nNrOrd=@nNrOrd+1 
						select identity(int,1,1) as Numar_de_Ordine,@pNivel+2 as nivel,left('Cod:'+p.cod+'Den:'+nomencl.denumire,100) as Descriere,sum(p.cantitate*@nCantPond) as Cantitate,sum(p.cantitate*p.pret_de_stoc)/(case when sum(p.cantitate)=0 then 1 else sum(p.cantitate) end) as Pret,sum(p.cantitate*pret_de_stoc*@nCantPond) as Valoare, 
						'I' as Tip,p.cod,@pLm as Locm,@pCom as Comanda_sup,@pArtSup as Art_Sup,@nNrOrd-1 as NrOrdP 
						into #cDocumente 
						from pozdoc p inner join nomencl on p.cod=nomencl.cod 
						where p.subunitate=@pSub and p.tip=@cTip and p.numar=@cNumar and p.data=@dData
						and (@pCom<>'' or left(p.loc_de_munca,@nLm) like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end) --Fie comanda egal nimic (regia unui loc de munca), altfel nu conteaza locul de munca
						and (p.comanda like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end)
						group by p.cod,nomencl.denumire 
						insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
						select @nNrOrd+Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,comanda_sup,art_sup,NrOrdP from #cDocumente 
						drop table #cDocumente 
					end 
					else 
					begin
						set @nNrOrd=@nNrOrd+1
						insert into fisacmdtmp (Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)
						select @nNrOrd,@pNivel+2,'Explicatii:'+max(pozincon.explicatii),1,1,sum(suma)*(case when @nCantPond=0 then 1 else @nCantPond end),'E',max(pozincon.tip_document),@pLm,@pCom,@pArtSup,@nNrOrd-1 
						from pozincon
						inner join costsql cs on cs.lm_sup=@pLm and cs.comanda_sup=@pCom and cs.tip=pozincon.tip_document and pozincon.numar_document=cs.numar and cs.data=pozincon.data and cs.comanda_inf=@cComanda
						where pozincon.subunitate=@pSub and pozincon.tip_document=@cTip and pozincon.numar_document=@cNumar and pozincon.data=@dData
						and (@pCom<>'' or left(pozincon.loc_de_munca,@nLm) like rtrim(ltrim(@pLm))+case when @lSLM=0 then '%' else '' end) --Fie comanda egal nimic (regia unui loc de munca), altfel nu conteaza locul de munca
						and (pozincon.comanda like rtrim(ltrim(@pCom))+case when @lSCom=0 then '%' else '' end)
						and cont_debitor=@cComanda and pozincon.data between @pDinf and @pDsup 
					end 
				end 
				fetch next from @minune1 into @cDesc,@cTip_descriere,@nCant,@nPret,@nValoare,@cTip,@cNumar,@dData,@cCont 
				set @nFetch=@@fetch_status 
			end 
			close @minune1 
			deallocate @minune1 
		end 
		if @nNrOrd is null set @nNrOrd=@pNrOrd+1 
		execute insertfisa @cLm,@cComanda,@nNivelUrm,@pNivelMax,@nCantPond,'','','','',@pDetalDOC,@pSub,@pDinf,@pDsup,@pGrCom,@pComenziNedet,@pArtCalcNedet,@nNrOrd,0 
	end 
	fetch from @minune into @cDesc,@cTip_descriere,@nCant,@nPret,@nValoare,@cLm,@cComanda,@cArticol 
	set @nFetch=@@fetch_status 
end 
close @minune 
deallocate @minune 
end
