create procedure wIaPozRulaje @parXML xml, @sesiune varchar(50)
as
declare @tipRulaj varchar(30), @lm varchar(30), @perioada datetime, @_search varchar(30), @areLM INT, @tip varchar(2), @cont varchar(40), @an int,
	@utilizator varchar(20)

exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output

select	@tipRulaj = isnull(@parXML.value('(/row/@tiprulaj)[1]','varchar(15)'),''),
		@lm = isnull(@parXML.value('(/row/@lm)[1]','varchar(30)'),''),
		@perioada = isnull(@parXML.value('(/row/@perioada)[1]','datetime'),'1900-01-01'),
		@_search = isnull(@parXML.value('(/row/@_cautare)[1]','varchar(30)'),''),
		@areLM=dbo.f_areLMFiltru(@utilizator),
		@tip = ISNULL(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@cont = ISNULL(@parXML.value('(/row/@cont)[1]','varchar(40)'),''),
		@an = ISNULL(@parXML.value('(/row/@anrulaje)[1]','int'),'')

--daca se apeleaza dinspre macheta de conturi @_search -> filtru pe loc de munca
if isnull(@_search,'')<>'' and @tip='RL'
		set @lm=@_search
--daca se apeleaza dinspre macheta de conturi si nu se primeste @an -> anul va fi anul curent
if isnull(@an,0)=0  and @tip='RL' 		
	set @an=year(GETDATE())

declare @doc xml
set @doc=(
select	 rtrim(r.cont) as cont
		, rtrim(r.cont)+' - '+ rtrim(max(c.Denumire_cont)) as contden
		, rtrim(max(c.Denumire_cont)) as denCont	
		, rtrim(convert(decimal(15,2),sum(r.Rulaj_credit))) as rulajCredit
		, rtrim(convert(decimal(15,2),sum(r.rulaj_debit))) as rulajDebit
		, CONVERT(char(10),r.data,101) as data
		, RTRIM(case when max(convert(int,c.Are_analitice))=1 then 'gray' else 'blue' end) as culoare
		, rtrim(max(convert(int,c.Are_analitice))) as areAnalitice
		, /*(case when RTRIM(r.Valuta)<>'' then r.valuta else 'RON' end)*/ RTRIM(r.Valuta) as valuta
		, rtrim(max(lm.Cod)) as lm, rtrim(max(lm.Cod))+'-'+rtrim(max(lm.Denumire)) as denLm
		, (case when max(convert(int,c.Are_analitice))=1 then '' else  'MC' end) as subtip--,
		--CONVERT(xml, dbo.wfIaArboreConturi(rtrim(r.cont), @f_perioada))
from rulaje r 
	inner join conturi c on c.subunitate=r.subunitate and c.Cont=r.Cont --and c.Nivel=1
	left outer join lm on lm.Cod=r.Loc_de_munca
	left outer join lmfiltrare fp ON fp.cod=r.Loc_de_munca and fp.utilizator=@utilizator
where (r.Data=@perioada  or (year(r.data)=@an) and @tip='RL'/*daca se apeleaza din detaliere conturi, sa filtreze pe an*/)  --and c.Nivel=1
		and	(@areLM=0 or fp.cod is not null) 
		and (r.Cont like replace(@_search,' ','%')+'%' or @tip='RL'/*in detaliere conturi, @_search se foloseste pentru filtrare an*/)
		and (r.Cont like @cont+'%' or isnull(@cont,'')='')
		and (r.Loc_de_munca like @lm+'%' or lm.denumire like @lm+'%' or isnull(@lm,'')='')
group by r.cont, data, r.Loc_de_munca, c.cont, r.Valuta
order by r.Cont asc
for xml raw--,root('Ierarhie')
)
if @tip<>'RL'--daca nu este apelata din detaliere de pe macheta de conturi
set @doc = (select @doc for xml path('Ierarhie'))
select @doc for xml path('Date')
