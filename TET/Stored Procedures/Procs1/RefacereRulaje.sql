--***
create procedure RefacereRulaje @dDataJos datetime, @dDataSus datetime, @cCont varchar(40), @nInLei int, @nInValuta int, @cValuta char(3)
as
if @dDataJos is null set @dDataJos='01/01/1901'
if @dDataSus is null set @dDataSus='12/31/2999'

if @cCont is null set @cCont=''
if @nInLei is null set @nInLei=1
if @nInValuta is null set @nInValuta=1
if @cValuta is null set @cValuta=''

declare @cSub char(9), @nAnImpl int, @nLunaImpl int, @nAnInch int, @nLunaInch int, 
 @dDataImpl datetime, @dDataInch datetime, @dDataJosRecalc datetime, @rulajelm int

set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')
set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
set @nAnInch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
set @rulajelm=isnull((select top 1 val_logica from par where Tip_parametru='GE' and Parametru='RULAJELM'),0)
set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnImpl-1901, '01/01/1901'))
set @dDataInch=dateadd(month, @nLunaInch, dateadd(year, @nAnInch-1901, '01/01/1901'))

set @dDataJos=dbo.bom(@dDataJos)
set @dDataSus=dbo.eom(@dDataSus)

set @dDataJosRecalc=@dDataJos
if @dDataJosRecalc<@dDataInch
 set @dDataJosRecalc=@dDataInch
if @dDataJosRecalc<@dDataImpl
 set @dDataJosRecalc=@dDataImpl
set @dDataJosRecalc=dbo.bom(@dDataJosRecalc)

select p.cont_debitor as Cont, space(3) as Valuta, dbo.eom(p.data) as Data, 
sum(round(convert(decimal(15, 3),p.suma), 2)) as RulDeb, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug
into #RulDeb
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_debitor=a.cont
and @nInLei=1 and p.suma<>0
group by p.cont_debitor, dbo.eom(p.data), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug

select p.cont_creditor as Cont, space(3) as Valuta, dbo.eom(p.data) as Data, 
sum(round(convert(decimal(15, 3),p.suma), 2)) as RulCred, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug
into #RulCred
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_creditor=a.cont
and @nInLei=1 and p.suma<>0
group by p.cont_creditor, dbo.eom(p.data), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug

insert #RulDeb
select p.cont_debitor, p.valuta, dbo.eom(p.data) as Data, 
sum(round(convert(decimal(15, 3),p.suma_valuta), 2)), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_debitor=a.cont
and @nInValuta=1 and p.valuta<>'' and p.suma_valuta<>0 and (@cValuta='' or p.valuta=@cValuta)
group by p.cont_debitor, p.valuta, dbo.eom(p.data), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug

insert #RulCred
select p.cont_creditor, p.valuta, dbo.eom(p.data) as Data, 
sum(round(convert(decimal(15, 3),p.suma_valuta), 2)), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_creditor=a.cont
and @nInValuta=1 and p.valuta<>'' and p.suma_valuta<>0 and (@cValuta='' or p.valuta=@cValuta)
group by p.cont_creditor, p.valuta, dbo.eom(p.data), (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug

select @cSub as Subunitate, d.cont as Cont, 
d.valuta as Valuta, d.data as Data, 
sum(isnull(d.RulDeb, 0)) as Rulaj_debit,
0 as Rulaj_credit, d.lm, d.indbug, 0 grupat
into #RulDebCred
from #RulDeb d
group by d.cont, d.valuta, d.data, d.lm, d.indbug
union all
select @cSub as Subunitate, c.cont as Cont, 
c.valuta as Valuta, c.data as Data, 
0 as Rulaj_debit,
sum(isnull(c.RulCred, 0)) as Rulaj_credit, c.lm, c.indbug, 0 grupat
from #Rulcred c
group by c.cont, c.valuta, c.data, c.lm, c.indbug 

insert into #RulDebCred(Subunitate, Cont,Valuta, Data, Rulaj_debit, Rulaj_credit, lm, indbug, grupat)
select @cSub as Subunitate, Cont,Valuta, Data, sum(x.Rulaj_debit) Rulaj_debit,sum(x.Rulaj_credit) Rulaj_credit,lm,indbug,1 grupat
from #RulDebCred x
group by cont, valuta, data, lm, indbug

delete #RulDebCred where grupat=0

drop table #RulDeb
drop table #RulCred

delete rulaje
from rulaje r 
left outer join dbo.arbconturi(@cCont) a on @cCont<>'' and r.cont=a.cont
left outer join conturi c on r.subunitate=c.subunitate and r.cont=c.cont
where r.subunitate=@cSub and r.data between @dDataJosRecalc and @dDataSus and Day(r.data)<>1
and (@cCont='' or a.cont is not null)
and (r.valuta='' and @nInLei=1 or r.valuta<>'' and @nInValuta=1 and (@cValuta='' or r.valuta=@cValuta))
/*and isnull(c.are_analitice, 0)=0

delete rulaje
from rulaje r, #RulDebCred dc
where r.subunitate=dc.Subunitate and r.Cont=dc.Cont and r.Valuta=dc.Valuta and r.Data=dc.Data
*/
insert Rulaje
(Subunitate, Cont, Loc_de_munca, Indbug, Valuta, Data, Rulaj_debit, Rulaj_credit)
select Subunitate, Cont, Lm, Indbug, Valuta, Data, Rulaj_debit, Rulaj_credit
from #RulDebCred

drop table #RulDebCred

exec RefacereRulajeParinte @dDataJos, @dDataSus, @cCont, @nInLei, @nInValuta, @cValuta, 0
