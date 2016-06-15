--***
create procedure CalculSoldConturiPeZile @sesiune varchar(50), @parXML xml
as

/**

Procedura presupune existenta tabelei cu date de conturi + data + valuta
si returneaza solduri si rulaje pe aceste tabele
create table #conturi(cont varchar(20),valuta varchar(20) default '',data datetime)

**/
if object_id('tempdb..#conturi') is null
	return

declare @Sub varchar(20),@userASiS varchar(100),@lista_lm int, @rulajePeLocm int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
set @rulajePeLocm=isnull((select max(convert(int,Val_logica)) from par where Tip_parametru='GE' and Parametru='RULAJELM'),0)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
select @lista_lm=dbo.f_arelmfiltru(@userASiS)

/*
create table #conturi(cont varchar(20),valuta varchar(20) default '',data datetime, sid float,sic float,rd float,rc float,sd float,sc float)

insert into #conturi (cont,valuta, data)
select top 100 cont,'', data 
from plin 
where data between '2015-01-01' AND '2015-05-31' and cont like '5124.8%'
union all
select top 100 cont,pr.valoare, data 
from plin 
inner join proprietati pr on pr.tip='CONT' and pr.cod=plin.cont and pr.cod_proprietate='INVALUTA'
where data between '2015-01-01' AND '2015-05-31' and cont like '5124.8%'


exec CalculSoldConturiPeZile @sesiune='', @parXML=null

select * from #conturi

drop table #conturi
*/


-- Soldul initial se ia din tabela de rulaje, de la inceputul anului pana la @dDataSFcLuna
create table #conturigrupate(cont varchar(20),valuta varchar(20),datamin datetime,datamax datetime,dataiAN datetime,dataSFLuna datetime,dataInc datetime)
insert into #conturigrupate(cont,valuta,datamin,datamax)
select cont,valuta,min(data),max(data)
from #conturi
group by cont,valuta

update #conturigrupate
set dataiAN=dbo.boy(datamin), dataSFLuna=(case when month(datamin)=1 then dbo.boy(datamin) else dateadd(day,-1,dbo.bom(datamin)) end), dataInc=dbo.bom(datamin)

create table #calcule (cont varchar(20),valuta varchar(20) default '',data datetime,sid float,sic float,rd float,rc float,sd float,sc float)
create unique clustered index idx1 on #calcule(cont,valuta,data)

/*Calcul sold din rulaje. Incepand de la DataIAN pana la Ultima data SF Luna */
insert into #calcule(cont,valuta,data,sid,sic)
select c.cont,c.valuta,c.dataSFLuna,
	isnull(sum(r.rulaj_debit-r.rulaj_credit),0) as rd, isnull(sum(r.rulaj_credit-r.rulaj_debit),0) as rc
from #conturigrupate c
left join rulaje r on r.subunitate=@sub and c.cont=r.cont and c.valuta=r.valuta and r.data between c.dataiAN and c.dataSFLuna
left join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=r.Loc_de_munca
where (@rulajePeLocm=0 or @lista_lm=0 or lu.cod is not null)
group by c.cont,c.valuta,c.dataSFLuna

/*Calcul sold din pozincon. Incepand de la Ultima data SF Luna (+1) pana la zi */
select pd.cont_debitor as cont, max(pd.valuta) as valuta, pd.data,sum(pd.suma) as debit, 0 as credit,sum(pd.suma_valuta) as debitvaluta, 0 as creditvaluta -- rulaje debit in lei si valuta 
into #pozincon
from pozincon pd 
left join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pd.Loc_de_munca
cross apply (select distinct c.dataInc, c.datamax from #conturigrupate c where c.cont=pd.cont_debitor) c
where pd.subunitate=@Sub and pd.data between c.dataInc and c.datamax 
	and (@rulajePeLocm=0 or @lista_lm=0 or lu.cod is not null)
group by pd.cont_debitor, pd.data
union all
select pc.cont_creditor as cont, max(pc.valuta) as valuta, pc.data, 0 as debit, sum(pc.suma) as credit, 0 as debitvaluta, sum(pc.suma_valuta) as creditvaluta -- rulaje credit in lei si valuta 
from pozincon pc 
left join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pc.Loc_de_munca
cross apply (select distinct c.dataInc, c.datamax from #conturigrupate c where c.cont=pc.cont_creditor) c
where pc.subunitate=@sub and pc.data between c.dataInc and c.datamax 
	and (@rulajePeLocm=0 or @lista_lm=0 or lu.cod is not null)
group by pc.cont_creditor,pc.data

select cont, data, '' as valuta, sum(debit) as rulajd, sum(credit) as rulajc -- rulaje in lei 
into #rulajec
from #pozincon 
group by cont, data
union all
select cont, data, max(valuta), sum(debitvaluta) as rulajd, sum(creditvaluta) as rulajc -- rulaje in valuta
from #pozincon 
group by cont, data

insert into #rulajec(cont,data,valuta,rulajd,rulajc) 
select c.cont as cont,c.data,'' as valuta,0,0
from #conturi c 
left join #rulajec rc on c.cont=rc.cont and c.data=rc.data and c.valuta=rc.valuta
where rc.cont is null

update c  -- cazul rulajului din 1 ianuarie 
	set rd=isnull(rulajd,0), rc=isnull(rulajc,0)
	from #calcule c, #rulajec r
	where c.cont=r.cont and c.valuta=r.valuta and c.data=r.data

insert into #calcule(cont,valuta,data,rd,rc)
select cont,valuta,data,
sum(isnull(rulajd,0)),
sum(isnull(rulajc,0))
from #rulajec
where not exists (select 1 from #calcule c where c.cont=#rulajec.cont and c.valuta=#rulajec.valuta and c.data=#rulajec.data) -- cazul rulajului din 1 ianuarie 
group by cont,valuta,data

declare @tcont varchar(20),@tvaluta varchar(20)
declare @cont varchar(20),@valuta varchar(20),@data datetime,@sid float,@sic float,@rd float,@rc float
declare @sd float,@sc float

select @tcont='',@tvaluta=''

/*
In cazul SQL 2012 vom apela o alta procedura, cea curenta va merge pe ELSE

select cont_debitor,data,sum(suma) as suma
into #rulaje
from pozincon
where cont_debitor='581' and data between '04/01/2014' and '04/30/2014'
group by cont_debitor,data
order by 2

select * from #rulaje

select 'D',data,SUM(suma) OVER (ORDER BY data rows UNBOUNDED PRECEDING)
from #rulaje
where cont_debitor='581' and data between '04/01/2014' and '04/30/2014'

drop table #rulaje

*/
DECLARE c CURSOR
    LOCAL STATIC FORWARD_ONLY READ_ONLY
	FOR
	select ca.cont,ca.valuta,ca.data,isnull(ca.sid,0),isnull(ca.sic,0),isnull(ca.rd,0),isnull(ca.rc,0)
	from #calcule ca
	order by cont,valuta,data

open c

fetch next from c into @cont,@valuta,@data,@sid,@sic,@rd,@rc
while @@fetch_status=0
begin
	if @tcont<>@cont or @tvaluta<>@valuta
	begin
		select @sd=@sid,@sc=@sic,@tcont=@cont,@tvaluta=@valuta
	end

	update #calcule set sid=@sd,sic=@sc
			,sd=@sd+@rd-@rc
			,sc=@sc+@rc-@rd
		where cont=@cont and valuta=@valuta and data=@data

	select @sd=@sd+@rd-@rc,@sc=@sc+@rc-@rd

	fetch next from c into @cont,@valuta,@data,@sid,@sic,@rd,@rc
end

close c
deallocate c

update c 
set sid=(case when cc.tip_cont='A' or cc.tip_cont='B' and sid>0 then sid else 0 end),
sic=(case when cc.tip_cont='P' or cc.tip_cont='B' and sic>0 then sic else 0 end),
sd=(case when cc.tip_cont='A' or cc.tip_cont='B' and sd>0 then sd else 0 end),
sc=(case when cc.tip_cont='P' or cc.tip_cont='B' and sc>0 then sc else 0 end)
from #calcule c
inner join conturi cc on c.cont=cc.cont

--select * from #calcule order by cont,valuta,data

update c 
	set sid=r.sid, sic=r.sic,rd=r.rd, rc=r.rc, sd=r.sd, sc=r.sc
		from #conturi c
		left join #calcule r on r.cont=c.cont and r.data=c.data and r.valuta=c.valuta 

drop table #conturigrupate
--drop table #conturi
drop table #calcule
drop table #rulajec
drop table #pozincon
