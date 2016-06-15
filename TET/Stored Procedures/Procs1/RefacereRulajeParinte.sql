--***
create procedure RefacereRulajeParinte @dDataJos datetime, @dDataSus datetime, @cCont varchar(40), @nInLei int, @nInValuta int, @cValuta char(3), @SiSoldIncAn int
as
if @dDataJos is null set @dDataJos='01/01/1901'
if @dDataSus is null set @dDataSus='12/31/2999'

if @cCont is null set @cCont=''
if @nInLei is null set @nInLei=1
if @nInValuta is null set @nInValuta=1
if @cValuta is null set @cValuta=''
if @SiSoldIncAn is null set @SiSoldIncAn=0

declare @cSub char(9), @ContP varchar(40), @ValutaP char(3), @DataP datetime, @RulDebP float, @RulCredP float, @LmP char(9), @IndbugP varchar(20)

set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')

if not (@dDataJos=@dDataSus and @SiSoldIncAn=1)
begin
	set @dDataJos=dbo.bom(@dDataJos)
	set @dDataSus=dbo.eom(@dDataSus)
end

delete rulaje
from rulaje r 
left outer join dbo.arbconturi(@cCont) a on @cCont<>'' and r.cont=a.cont
left outer join conturi c on r.subunitate=c.subunitate and r.cont=c.cont
where r.subunitate=@cSub and r.data between @dDataJos and @dDataSus 
and (@SiSoldIncAn=1 or Day(r.data)<>1)
and (@cCont='' or a.cont is not null)
and (r.valuta='' and @nInLei=1 or r.valuta<>'' and @nInValuta=1 and (@cValuta='' or r.valuta=@cValuta))
and isnull(c.are_analitice, 0)=1

declare tmprul cursor for
select c.cont_parinte, r.valuta, r.data, sum(r.rulaj_debit), sum(r.rulaj_credit), r.loc_de_munca, r.indbug
from rulaje r, dbo.arbconturi(@cCont) a, conturi c 
where r.subunitate=@cSub and r.data between @dDataJos and @dDataSus 
	and (@SiSoldIncAn=1 or Day(r.data)<>1)
	and r.cont=a.cont and r.subunitate=c.subunitate and r.cont=c.cont
	and (r.valuta='' and @nInLei=1 or r.valuta<>'' and @nInValuta=1 and (@cValuta='' or r.valuta=@cValuta))
	and c.are_analitice=0 and c.cont_parinte<>''
group by c.cont_parinte, r.valuta, r.data, r.loc_de_munca, r.indbug

open tmprul
fetch next from tmprul into @ContP, @ValutaP, @DataP, @RulDebP, @RulCredP, @LmP, @IndbugP
while @@fetch_status=0
begin
	exec AdaugInRulaje @cSub, @ContP, @ValutaP, @DataP, @RulDebP, @RulCredP, @LmP, @IndbugP
 
	fetch next from tmprul into @ContP, @ValutaP, @DataP, @RulDebP, @RulCredP, @LmP, @IndbugP
end

close tmprul
deallocate tmprul

if @SiSoldIncAn=1
begin
	update rulaje
	set Rulaj_debit=(case c.tip_cont when 'A' then r.Rulaj_debit-r.Rulaj_credit when 'P' then 0 else (case when r.Rulaj_debit-r.Rulaj_credit>=0 then r.Rulaj_debit-r.Rulaj_credit else 0 end) end), 
		Rulaj_credit=(case c.tip_cont when 'P' then r.Rulaj_credit-r.Rulaj_debit when 'A' then 0 else (case when r.Rulaj_credit-r.Rulaj_debit>=0 then r.Rulaj_credit-r.Rulaj_debit else 0 end) end)
	from rulaje r, dbo.arbconturi(@cCont) a, conturi c 
	where r.subunitate=@cSub and r.data between @dDataJos and @dDataSus 
		and Month(r.data)=1 and Day(r.data)=1
		and r.cont=a.cont and r.subunitate=c.subunitate and r.cont=c.cont
		and (r.valuta='' and @nInLei=1 or r.valuta<>'' and @nInValuta=1 and (@cValuta='' or r.valuta=@cValuta))
	--and c.are_analitice=1
end
