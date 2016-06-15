--***
create procedure [dbo].[itinerar] @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null  
as
begin
	declare @cLmS char(20),@cLmI char(20),@cEtapa char(3),@gCom char(20),@cCom char(20),@nFetch int, @nCantitate  float,@nOrdine int, @subunitate char(9)
	declare @lItinAuto int
	set @lItinAuto=isnull((select val_logica from par where tip_parametru='PC' and parametru='ITINAUTO'),0)
	set @subunitate = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO')  
	declare itin cursor for
	select distinct costtmp.lm_sup,costtmp.comanda_sup,itiner.etapa
	from 
	(select lm_sup,comanda_sup from costtmp union select lm_inf,comanda_inf from costtmp where lm_sup='' and comanda_sup='' and art_sup in ('P','R','N','S')) as costtmp, itiner
	where costtmp.comanda_sup like rtrim(itiner.comanda)+'%' and costtmp.lm_sup=itiner.loc_de_munca and costtmp.comanda_sup=itiner.comanda 
		and costtmp.comanda_sup in (select comanda_sup from costtmp	where comanda_sup<>'' group by comanda_sup having count(distinct lm_sup)>1)
		and (@lm is null or itiner.loc_de_munca like @lm+'%')
	order by comanda_sup,etapa

	open itin
	fetch from itin into @cLmS,@cCom,@cEtapa
	set @gCom=@cCom
	set @cLmI=@cLmS
	set @nFetch=@@fetch_status
	while @nFetch=0
	begin
		set @nCantitate=isnull((select sum(cantitate) from costtmp where comanda_inf=@gCom and art_sup in ('P','R','N','S')),1)
		while @gCom=@cCom and @nFetch=0
		begin
			fetch from itin into @cLmS,@cCom,@cEtapa
			set @nFetch=@@fetch_status
			if @gCom=@cCom and @cLmS<>@cLmI 
				insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
				select @dDataSus,@cLmS,@cCom,'T',@cLmI,@cCom,'T',@nCantitate,0,0,'IT','ITINERAR'
			set @cLmI=@cLmS
		end
		set @gCom=@cCom
	end
close itin
deallocate itin
/*Specific Carei care au datele prost introduse dar ne grabim mult*/
/*Se creeaza automat un itinerar tehnologic unde exista cheltuieli*/
if @lItinAuto=1
begin
	select distinct lm_sup,comanda_sup,0 as ordine 
	into #tmpIt 
	from costtmp t1 
	where art_sup='T' and art_inf='T' and comanda_sup=comanda_inf and not exists (select * from costtmp t2 where t2.lm_inf=t1.lm_sup and t2.comanda_inf=t1.comanda_sup)
	union
	select distinct lm_sup,comanda_sup,1 as ordine 
	from costtmp t1 
	where not exists	(select * from costtmp t2 where t1.lm_sup=t2.lm_inf and t1.comanda_sup=t2.comanda_inf and art_inf<>'N')
	union
	select lm_inf,comanda_inf,2 
	from costtmp t1,comenzi 
	where t1.comanda_inf=comanda and tip_comanda in ('P','R','S') and t1.art_sup in ('P','R','S') and comenzi.subunitate = @subunitate
	order by comanda_sup,ordine

	delete from #tmpIt where comanda_sup=''
	delete from #tmpit where comanda_sup not in (select comanda from comenzi where tip_comanda in ('P','R','S') and comenzi.subunitate = @subunitate)
	delete from #tmpIt where ordine=1 and exists (select lm_sup,comanda_sup from #tmpIt t2 where ordine=0 and #tmpIt.lm_sup=t2.lm_sup and #tmpIt.comanda_sup=t2.comanda_sup)

	declare itinext cursor for
	select * from #tmpIt
	order by comanda_sup,ordine

	open itinext
	fetch from itinext into @cLmS,@cCom,@nOrdine
	set @gCom=@cCom
	set @cLmI=@cLmS
	set @nFetch=@@fetch_status
	while @nFetch=0
	begin
		set @nCantitate=isnull((select sum(cantitate) from costtmp where comanda_inf=@gCom and art_sup in ('P','R','N','S')),1)
		while @gCom=@cCom and @nFetch=0
		begin
			fetch from itinext into @cLmS,@cCom,@nOrdine
			set @nFetch=@@fetch_status
			if @gCom=@cCom and @cLmS<>@cLmI 
				insert into costtmp (DATA,LM_SUP,COMANDA_SUP,ART_SUP,LM_INF,COMANDA_INF,ART_INF,CANTITATE,VALOARE,PARCURS,Tip,Numar) 
				select @dDataSus,@cLmS,@cCom,'T',@cLmI,@cCom,'T',@nCantitate,0,0,'IE','EXTITIN'
			set @cLmI=@cLmS
		end
		set @gCom=@cCom
	end
	close itinext
	deallocate itinext
	drop table #tmpIt 
	end
end
