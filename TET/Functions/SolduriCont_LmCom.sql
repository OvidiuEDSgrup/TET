create function dbo.SolduriCont_LmCom (@cCont char(13), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9), @cComanda char(40))
returns @sold table
(Sold_debitor float, Sold_creditor float)
as begin

if @cCont is null set @cCont=''
if @cValuta is null set @cValuta=''
--if @dData is null set @dData=convert(datetime, convert(char(10), getdate(), 104), 104)
if @cJurnal is null set @cJurnal=''
if @cLM is null set @cLM=''
if @cComanda is null set @cComanda=''

declare @cSub char(9), @nAnulImpl int, @nLunaImpl int, @dDataImpl datetime, @dDataIncLuna datetime, @dDataIncAn datetime,
 @dDataSusRulaje datetime, @dDataJosPozincon datetime, @cTipCont char(1), @nDiferenta float, @nRulDeb float, @nRulCred float

set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
set @nAnulImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), '')
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), '')
set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnulImpl-1901, '01/01/1901'))
if @dDataImpl>@dData set @dData=@dDataImpl

set @dDataIncLuna=dbo.bom(@dData)
set @dDataIncAn=dateadd(month, 1-month(@dDataIncLuna), @dDataIncLuna)

set @dDataSusRulaje=@dData-(case when @dData>@dDataIncAn then 1 else 0 end)
--deocamdata luam doar sold din rulaje_lmcom; cand/daca vom lua si rulaje lunare se va sterge linia urmatoare
set @dDataSusRulaje=@dDataIncAn
set @dDataJosPozincon=dbo.bom(@dDataSusRulaje+1)

set @cTipCont=isnull((select max(tip_cont) from conturi where subunitate=@cSub and cont=@cCont), 'B')

select @nDiferenta=sum(isnull(diferenta, 0))
from
(
 select sum(round(convert(decimal(15, 3), r.rulaj_debit), 2)-round(convert(decimal(15, 3), r.rulaj_credit), 2)) as diferenta
 from rulaje_lmcom r
 where r.subunitate=@cSub and r.cont=@cCont and r.valuta=@cValuta
 and r.data between @dDataIncAn and @dDataSusRulaje
 and r.loc_de_munca like RTrim(@cLM)+'%' and (@cComanda='' or r.comanda=@cComanda)
 union all
 select sum((case when p.cont_debitor=a.cont 
  then round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2) else 0 end)
 -(case when p.cont_creditor=a.cont 
  then round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2) else 0 end))
 from pozincon p, dbo.ArbConturi(@cCont) a
 where p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1
 and (p.cont_debitor=a.cont or p.cont_creditor=a.cont)
 and (@cValuta='' or p.valuta=@cValuta) and (@cJurnal='' or p.jurnal=@cJurnal)
 and p.loc_de_munca like RTrim(@cLM)+'%' and (@cComanda='' or p.comanda=@cComanda)
) d

set @nRulDeb=(case when @cTipCont='A' then @nDiferenta when @cTipCont='P' or @nDiferenta<0 then 0 else @nDiferenta end)
set @nRulCred=(case when @cTipCont='P' then -@nDiferenta when @cTipCont='A' or @nDiferenta>0 then 0 else -@nDiferenta end)

insert @sold
values (@nRulDeb, @nRulCred)
return
end
