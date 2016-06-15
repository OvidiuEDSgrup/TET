create procedure wIaRulaje @parXML xml, @sesiune varchar(50)
as
declare @f_denLm varchar(50), @datasus datetime, @datajos datetime, @tip varchar(10), @f_tipRulaj varchar(40),
		@areLM INT, @subunitate varchar(9), @f_perioada datetime, @f_Lm varchar(30), @pozRulaj varchar(30), 
		@lunaImplementare varchar(30), @anImplementare varchar(40), @dataImplementare datetime, @dataSoldInitial datetime, @tipRulaj varchar(40),
		@utilizator varchar(20)

exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output

select	@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1910-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@f_denLm = ISNULL(@parXML.value('(/row/@f_denlm)[1]','varchar(30)'),''),
		@f_Lm = ISNULL(@parXML.value('(/row/@lm)[1]','varchar(30)'),''),
		@f_tipRulaj = ISNULL(@parXML.value('(/row/@f_tiprulaj)[1]','varchar(30)'),''),
		@pozRulaj = ISNULL(@parXML.value('(/row/@tip)[1]','varchar(30)'),''),
		@f_perioada = isnull(@parXML.value('(/row/@perioada)[1]','datetime'),'1900-01-01'),
		@tipRulaj = ISNULL(@parXML.value('(/row/@tiprulaj)[1]','varchar(30)'),''),
		@subunitate=(select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),
		@areLM=dbo.f_arelmfiltru(@utilizator)

select	@lunaImplementare = (select Val_numerica  from par where Tip_parametru='GE' and Parametru='LUNAIMPL'),
		@anImplementare = (select Val_numerica  from par where Tip_parametru='GE' and Parametru='ANULIMPL')
set @dataImplementare=dbo.EOM(convert(datetime,str(@lunaImplementare,2)+'/01/'+str(@anImplementare,4),101))
set @dataSoldInitial=(case when @dataImplementare=dbo.EOY(@dataImplementare) then DateADD(day,1,@dataImplementare) else dbo.BOY(@dataImplementare) end)

select	rtrim(@subunitate) as subunitate
		, (case when month(r.data)=1 and day(r.data)=1 then 'Sold initial' else 'Rulaj' end) as tiprulaj 
		, dbo.fDenumireLuna (r.data)+' '+convert(varchar(20),YEAR(r.data)) as denPerioada
		, convert(char(10),r.Data,101) as perioada
		, rtrim(max(lm.Cod))as lm, rtrim(max(lm.Denumire)) as denlm
		, convert(decimal(15,2),sum(r.Rulaj_debit)) as rulajdebit
		, convert(decimal(15,2),sum(r.Rulaj_credit)) as rulajcredit
		, (case when r.Data>DateADD(day,1,@dataImplementare) then 1 else 0 end) as _nemodificabil

from rulaje r
	inner join conturi c on c.Subunitate=r.Subunitate and c.Cont=r.Cont 
	left outer join lm on lm.Cod=r.Loc_de_munca
	left outer join lmfiltrare l on l.utilizator=@utilizator and l.cod=r.loc_de_munca
where r.Subunitate=@subunitate
	and r.Data between @datajos and @datasus 
	and (@tiprulaj<>'Sold initial' and (r.data= dbo.eom(@f_perioada)  or r.data= dbo.bom(@f_perioada) or @f_perioada='') 
		or @tiprulaj='Sold initial' and r.Data=@dataSoldInitial)
	and (r.Loc_de_munca = @f_Lm or @f_Lm= '') 
	and (@areLM=0 or l.cod is not null) 
	and	(isnull(lm.Denumire,'') like @f_denLm+'%' or @f_denlm='') 
	and	((case when month(r.data)='1' and day(r.data)=1 then 'Sold initial' else 'Rulaj' end) like @f_tipRulaj+'%' or @f_tipRulaj='')
--	tratat sa ia in calcul pentru total rulaj/sold initial doar conturile de nivel 1
	and c.Nivel=1
--	and (r.data= convert(datetime,@f_perioada,103) or @f_perioada='') 
group by r.data
order by data asc
for xml raw
