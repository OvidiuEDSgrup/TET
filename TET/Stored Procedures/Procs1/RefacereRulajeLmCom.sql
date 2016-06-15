create procedure [dbo].[RefacereRulajeLmCom] @dDataJos datetime, @dDataSus datetime, @cCont char(13), @nInLei int, @nInValuta int, @cValuta char(3), @LM char(9), @Comanda char(20), @GrpLM int, @GrpCom int
as
if @dDataJos is null set @dDataJos='01/01/1901'
if @dDataSus is null set @dDataSus='12/31/2999'

if @cCont is null set @cCont=''
if @nInLei is null set @nInLei=1
if @nInValuta is null set @nInValuta=1
if @cValuta is null set @cValuta=''
if @LM is null set @LM=''
if @Comanda is null set @Comanda=''
if @GrpLM is null set @GrpLM=1
if @GrpCom is null set @GrpCom=1

declare @cSub char(9), @nAnImpl int, @nLunaImpl int, @nAnInch int, @nLunaInch int, 
	@dDataImpl datetime, @dDataInch datetime, @dDataJosRecalc datetime

set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')
set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
set @nAnInch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)

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
(case when @GrpLM=1 then p.loc_de_munca else '' end) as loc_de_munca, 
(case when @GrpCom=1 then p.comanda else '' end) as comanda, 
sum(round(convert(decimal(15, 3),p.suma), 2)) as RulDeb
into #RulDeb
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_debitor=a.cont
and @nInLei=1 and p.suma<>0
and p.loc_de_munca like RTrim(@LM)+'%'
and (@Comanda='' or p.comanda=@Comanda)
group by p.cont_debitor, dbo.eom(p.data), 
(case when @GrpLM=1 then p.loc_de_munca else '' end), (case when @GrpCom=1 then p.comanda else '' end)

select p.cont_creditor as Cont, space(3) as Valuta, dbo.eom(p.data) as Data, 
(case when @GrpLM=1 then p.loc_de_munca else '' end) as loc_de_munca, 
(case when @GrpCom=1 then p.comanda else '' end) as comanda, 
sum(round(convert(decimal(15, 3),p.suma), 2)) as RulCred
into #RulCred
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_creditor=a.cont
and @nInLei=1 and p.suma<>0
and p.loc_de_munca like RTrim(@LM)+'%'
and (@Comanda='' or p.comanda=@Comanda)
group by p.cont_creditor, dbo.eom(p.data), 
(case when @GrpLM=1 then p.loc_de_munca else '' end), (case when @GrpCom=1 then p.comanda else '' end)

insert #RulDeb
select p.cont_debitor, p.valuta, dbo.eom(p.data) as Data, 
(case when @GrpLM=1 then p.loc_de_munca else '' end) as loc_de_munca, 
(case when @GrpCom=1 then p.comanda else '' end) as comanda, 
sum(round(convert(decimal(15, 3),p.suma_valuta), 2))
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_debitor=a.cont
and @nInValuta=1 and p.valuta<>'' and p.suma_valuta<>0 and (@cValuta='' or p.valuta=@cValuta)
and p.loc_de_munca like RTrim(@LM)+'%'
and (@Comanda='' or p.comanda=@Comanda)
group by p.cont_debitor, p.valuta, dbo.eom(p.data), 
(case when @GrpLM=1 then p.loc_de_munca else '' end), (case when @GrpCom=1 then p.comanda else '' end)

insert #RulCred
select p.cont_creditor, p.valuta, dbo.eom(p.data) as Data, 
(case when @GrpLM=1 then p.loc_de_munca else '' end) as loc_de_munca, 
(case when @GrpCom=1 then p.comanda else '' end) as comanda, 
sum(round(convert(decimal(15, 3),p.suma_valuta), 2))
from pozincon p, dbo.arbconturi(@cCont) a 
where p.subunitate=@cSub and p.data between @dDataJosRecalc and @dDataSus and p.cont_creditor=a.cont
and @nInValuta=1 and p.valuta<>'' and p.suma_valuta<>0 and (@cValuta='' or p.valuta=@cValuta)
and p.loc_de_munca like RTrim(@LM)+'%'
and (@Comanda='' or p.comanda=@Comanda)
group by p.cont_creditor, p.valuta, dbo.eom(p.data), 
(case when @GrpLM=1 then p.loc_de_munca else '' end), (case when @GrpCom=1 then p.comanda else '' end)

select @cSub as Subunitate, isnull(d.cont, c.cont) as Cont, 
isnull(d.valuta, c.valuta) as Valuta, isnull(d.data, c.data) as Data, 
isnull(d.loc_de_munca, c.loc_de_munca) as loc_de_munca, isnull(d.comanda, c.comanda) as comanda,
sum(isnull(d.RulDeb, 0)) as Rulaj_debit, sum(isnull(c.RulCred, 0)) as Rulaj_credit
into #RulDebCred
from #RulDeb d 
full outer join #RulCred c on d.cont=c.cont and d.valuta=c.valuta and d.data=c.data	
	and d.loc_de_munca=c.loc_de_munca and d.comanda=c.comanda
group by isnull(d.cont, c.cont), isnull(d.valuta, c.valuta), isnull(d.data, c.data), 
	isnull(d.loc_de_munca, c.loc_de_munca), isnull(d.comanda, c.comanda)

drop table #RulDeb
drop table #RulCred

delete r
from rulaje_lmcom r 
left outer join dbo.arbconturi(@cCont) a on @cCont<>'' and r.cont=a.cont
left outer join conturi c on r.subunitate=c.subunitate and r.cont=c.cont
where r.subunitate=@cSub and r.data between @dDataJosRecalc and @dDataSus and Day(r.data)<>1
and (@cCont='' or a.cont is not null)
and (r.valuta='' and @nInLei=1 or r.valuta<>'' and @nInValuta=1 and (@cValuta='' or r.valuta=@cValuta))
and r.loc_de_munca like RTrim(@LM)+'%'
and (@Comanda='' or r.comanda=@Comanda)

insert Rulaje_lmcom
(Subunitate, Cont, Valuta, Data, Loc_de_munca, Comanda, Rulaj_debit, Rulaj_credit)
select Subunitate, Cont, Valuta, Data, Loc_de_munca, Comanda, Rulaj_debit, Rulaj_credit
from #RulDebCred

drop table #RulDebCred

exec RefacereRulajeParinteLmCom @dDataJos, @dDataSus, @cCont, @nInLei, @nInValuta, @cValuta, 0
