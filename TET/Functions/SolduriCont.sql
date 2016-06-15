--***
create function  SolduriCont (@cCont varchar(40), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9))
returns @sold table
(Sold_debitor float, Sold_creditor float)
as begin

if @cCont is null set @cCont=''
if @cValuta is null set @cValuta=''
--if @dData is null set @dData=convert(datetime, convert(char(10), getdate(), 104), 104)
if @cJurnal is null set @cJurnal=''
if @cLM is null set @cLM=''

declare @cSub char(9), @nAnulImpl int, @nLunaImpl int, @dDataImpl datetime, @dDataIncLuna datetime, @dDataIncAn datetime,
 @dDataSusRulaje datetime, @dDataJosPozincon datetime, @cTipCont char(1), @nAreAnalitice int, @nDiferenta float, @nRulDeb float, @nRulCred float, 
 @RulPeLocm int 

declare @utilizator varchar(20), @fltLmUt int
declare @LmUtiliz table(valoare varchar(200), cod varchar(20))

select @utilizator=dbo.fiautilizator('')

insert into @LmUtiliz (valoare)
--select valoare, cod_proprietate from fPropUtiliz() where cod_proprietate='LOCMUNCA' and valoare<>''
select l.cod from lmfiltrare l where l.utilizator=@utilizator

set	@fltLmUt=isnull((select count(1) from @LmUtiliz),0)

set @RulPeLocm=isnull((select val_logica from par where tip_parametru='GE' and parametru='RULAJELM'), 0)
set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
set @nAnulImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), '')
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), '')
set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnulImpl-1901, '01/01/1901'))
if @dDataImpl>@dData set @dData=@dDataImpl

set @dDataIncLuna=dbo.bom(@dData)
set @dDataIncAn=dateadd(month, 1-month(@dDataIncLuna), @dDataIncLuna)

set @dDataSusRulaje=@dData-(case when @dData>@dDataIncAn then 1 else 0 end)
set @dDataJosPozincon=dbo.bom(@dDataSusRulaje+1)

set @cTipCont='B'
set @nAreAnalitice=0
select @cTipCont=tip_cont, @nAreAnalitice=are_analitice 
	from conturi where subunitate=@cSub and cont=@cCont

declare @pdif table (diferenta float)
declare @arbcnt table (Cont varchar(40) primary key)
insert @arbcnt select Cont from dbo.ArbConturi(@cCont) where @nAreAnalitice=1

insert @pdif
	select sum(round(convert(decimal(15, 3), r.rulaj_debit), 2)-round(convert(decimal(15, 3), r.rulaj_credit), 2)) as diferenta
		from rulaje r
		where r.subunitate=@cSub and r.cont=@cCont and r.valuta=@cValuta
			and r.data between @dDataIncAn and @dDataSusRulaje 
			and (@RulPeLocm=0 or r.loc_de_munca like RTrim(@cLM)+'%' and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=r.loc_de_munca)))

union all
	select sum(round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2))
		from pozincon p
		where @nAreAnalitice=0 and p.subunitate=@cSub 
			and p.data between @dDataJosPozincon and dateadd(d,-1,@dData)
			and p.cont_debitor=@cCont 
			and (@cValuta='' or p.valuta=@cValuta) 
			and (@cJurnal='' or p.jurnal=@cJurnal)
			and (@RulPeLocm=0 or p.loc_de_munca like RTrim(@cLM)+'%' and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca)))
	union all
	select -sum(round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2))
		from pozincon p
		where @nAreAnalitice=0 and p.subunitate=@cSub 
			and p.data between @dDataJosPozincon and dateadd(d,-1,@dData)
			and p.cont_creditor=@cCont 
			and (@cValuta='' or p.valuta=@cValuta) 
			and (@cJurnal='' or p.jurnal=@cJurnal)
			and (@RulPeLocm=0 or p.loc_de_munca like RTrim(@cLM)+'%' and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca)))

union all
	select sum(round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2))
		from pozincon p, @arbcnt a
		where @nAreAnalitice=1 and p.subunitate=@cSub and p.data between @dDataJosPozincon and dateadd(d,-1,@dData)
			and p.cont_debitor=a.cont 
			and (@cValuta='' or p.valuta=@cValuta) and (@cJurnal='' or p.jurnal=@cJurnal)
			and (@RulPeLocm=0 or p.loc_de_munca like RTrim(@cLM)+'%' 
			and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca)))
		union all
		select -sum(round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2))
		from pozincon p, @arbcnt a
		where @nAreAnalitice=1 and p.subunitate=@cSub and p.data between @dDataJosPozincon and dateadd(d,-1,@dData)
			and p.cont_creditor=a.cont 
			and (@cValuta='' or p.valuta=@cValuta) and (@cJurnal='' or p.jurnal=@cJurnal)
			and (@RulPeLocm=0 or p.loc_de_munca like RTrim(@cLM)+'%' 
			and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.loc_de_munca)))

select @nDiferenta=sum(isnull(diferenta, 0)) from @pdif


set @nRulDeb=(case when @cTipCont='A' then @nDiferenta when @cTipCont='P' or @nDiferenta<0 then 0 else @nDiferenta end)
set @nRulCred=(case when @cTipCont='P' then -@nDiferenta when @cTipCont='A' or @nDiferenta>0 then 0 else -@nDiferenta end)

insert @sold
	values (@nRulDeb, @nRulCred)
return
end
