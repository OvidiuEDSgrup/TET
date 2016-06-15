--***
CREATE procedure calculCont
--declare 
@camp char(20),@pDataJ datetime,@pDataS datetime
-- se va pune proprietate pe locuri de munca LMBILANT, se vor lua in calcul cele care au valoarea 1
-- @defalclm=1 daca exista cel putin un LMBILANT=1 
-- daca @defaclclm=1 pentru locurile de munca neluate in baza proprietatii se va pune o linie fara locm, ca sa se inchida
as

declare @defalclm int
set @defalclm=0
declare @nLunaI int,@nAnulI int,@dDataI datetime,@semn int,@cHostID char(8)

set @cHostID = convert(char(8),abs(convert(int, host_id())))
set @nLunaI=(select val_numerica from par where tip_parametru='GE' and parametru='LUNAIMPL')
set @nAnulI=(select val_numerica from par where tip_parametru='GE' and parametru='ANULIMPL')
set @dDataI=ltrim(str(@nLunaI))+'/01/'+ltrim(str(@nAnulI))
set @dDataI=dateadd(month,1,@dDataI)
if @pDataJ<@dDataI set @pDataJ=@dDataI
if @pDataJ>@pDataS return

if exists(select * from proprietati where tip='LM' and cod_proprietate='LMINCHCONT' and Valoare='1')
	set @defalclm=1
create table #lmptbil(cod varchar(20))
insert into #lmptbil select cod from proprietati where tip='LM' and cod_proprietate='LMINCHCONT' and Valoare='1'

declare @boyDataJ datetime,@boyDataS datetime,@cCont char(13),@cTipC char(1),@nLuna int,@dData datetime
/*
set @camp='SCR4111'
set @pDataJ='01/01/2005'
set @pDataS='10/31/2005'
*/

  if left(@camp,2) in ('SI','RL','RC','SC')
   begin

    set @boyDataJ='01/01/'+str(year(@pDataJ))
    set @boyDataS='01/01/'+str(year(@pDataS))
    set @nLuna=month(@pDataJ)
    set @cCont=rtrim(substring(@camp,4,13))
	select @cTipC=tip_cont from conturi where cont=@cCont
	
	if @cTipC is null and 0=1
	begin
		declare @msgErr varchar(255)
		set @msgErr='calculCont: Eroare la configurare cont:'+@cCont
		raiserror(@msgErr,16,1)
		return
	end
	
	select distinct data_lunii 
	into #cs
	from fcalendar(@pDataJ,@pDataS)

	select c.data_lunii,rr.loc_de_munca,sum(rr.rdrc) as rdrc,sum(rr.rcd) as rcd,sum(rr.rcc) as rcc
	into #rul
	from #cs c
	cross apply 
		(select c.data_lunii,(case when @defalclm=1 then  l.cod else '' end) as loc_de_munca,
			sum((case when r.data=@boydataJ then 0 else r.rulaj_debit end)) as rcd,
			sum((case when r.data=@boyDataJ then 0 else r.rulaj_credit end)) as rcc,
			sum(r.rulaj_debit-r.rulaj_credit) as rdrc
		from rulaje r 
		left outer join #lmptbil l on r.Loc_de_munca like rtrim(l.cod)+'%'
		where r.cont=@cCont and r.valuta='' and r.data between @boyDataJ and c.data_lunii 
		and (r.data=@boyDataJ or not(month(r.data)=1 and day(r.data)=1)) -- fara solduri initiale doar primul sold initial
		and (@defalclm=0 or l.cod is not null)
		group by r.data,(case when @defalclm=1 then  l.cod else '' end)) rr
	group by c.Data_lunii,rr.loc_de_munca

	drop table #cs

    alter table #rul add rd float default 0,rc float default 0,suma float default 0
	update #rul set rd=isnull(rulaj_debit,0),rc=isnull(rulaj_credit,0)
	from rulaje where rulaje.cont=@cCont and rulaje.Valuta='' and rulaje.Data=#rul.data_lunii and rulaje.Loc_de_munca=#rul.Loc_de_munca

	if left(@camp,2)='SC' -- Sold curent
	begin
		if substring(@camp,3,1)='R' 
		begin
			if @cTipC='A'
				update #rul set suma=rdrc
			else if @cTipC='P' 
				update #rul set suma=-rdrc
			else if @cTipC='B' --aici mai depindem de o chestie
				update #rul set suma=abs(rdrc) 
		end
		else if substring(@camp,3,1)='D' --SCC - sold credit
		begin
			if @cTipC='A' 
				update #rul set suma=rdrc
			if @cTipC='P' 
				update #rul set suma=0
			else if @cTipC='B' --punem doar cele negative
				update #rul set suma=rdrc where rdrc>0
		end
		else if substring(@camp,3,1)='C' --SCC - sold credit
		begin
			if @cTipC='A'
				update #rul set suma=0
			if @cTipC='P' 
				update #rul set suma=-rdrc
			else if @cTipC='B' --punem doar cele negative
			begin
				update #rul set suma=abs(rdrc) where rdrc<0
			end
		end
		
	end
	else if left(@camp,2)='SI' -- Sold initial
	begin
		if substring(@camp,3,1)='R' or substring(@camp,3,1)='D' --SCR - sold curent sau SCD sold curent debit (rdrc e pe debit de fapt)
		begin
			if @cTipC='A'
				update #rul set suma=rdrc-rcd+rcc
			--else if @cTipC='P' --nu facem nimic
			else if @cTipC='B' --punem doar cele pozitive
				update #rul set suma=rdrc-rcd+rcc where rdrc-rcd+rcc>0
		end
		else if substring(@camp,3,1)='C' --SCC - sold credit
			--if @cTipC='A' nu facem nimic
			if @cTipC='P' 
				update #rul set suma=-rdrc+rcd-rcc
			else if @cTipC='B' --punem doar cele negative
				update #rul set suma=-rdrc+rcd-rcc where rdrc+rcd-rcc<0
	end
	else if left(@camp,2)='RL' -- Rulaj lunar
	begin
		if substring(@camp,3,1)='D' --RLD - Rulaj lunar debit
			update #rul set suma=rd
		else if substring(@camp,3,1)='C' --SCC - sold credit
				update #rul set suma=rc
	end
	else if left(@camp,2)='RC' -- Rulaj cumulat
	begin
		if substring(@camp,3,1)='D' --RCD - Rulaj cumulat debit
			update #rul set suma=rcd
		else if substring(@camp,3,1)='C' --SCC - sold credit
				update #rul set suma=rcc
	end
	--select * from #rul --pentru debug

   --select * from #rul
   delete from expval where cod_indicator=@camp and data between @pDataj and @pDataS
   insert into expval (Cod_indicator,Tip,Data,Element_1,Element_2,Element_3,Element_4,Element_5,Valoare)
    select @camp,'E',data_lunii,loc_de_munca,'','','','',isnull(suma,0)
   from #rul
 end
if not exists(select * from tmp_calculat where hostid=@cHostID and cod=@camp)
	insert into tmp_calculat(hostid,cod) values(@cHostID,@camp)
