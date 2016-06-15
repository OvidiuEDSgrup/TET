--***
create procedure wACNomenclator @sesiune varchar(50),@parXML XML      
as
set transaction isolation level read uncommitted
if exists(select * from sysobjects where name='wACNomenclatorSP' and type='P')      
begin
	exec wACNomenclatorSP @sesiune,@parXML
	return 0
end
declare @FltStocPred int, @faraU bit, @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int,
		@aplicatie varchar(100), @subtip varchar(2), @tert varchar(20), @codspecific varchar(20), @utilizator varchar(10), @tipNomencl varchar(50), @listatipuri varchar(100), @grupa varchar(13), 
		@tipnom_tipgest int, @tipgest char(1)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
if @utilizator is null
	return -1

exec luare_date_par 'GE', 'FNOMPRED', @FltStocPred output, 0, ''
exec luare_date_par 'GE', 'FARATIPU',  @faraU output,0,''

-- citesc lista gestiuni atasate utilizatorului
declare @lista_gestiuni int
declare @gestuniUtiliz table(gestiune varchar(13) primary key)
insert @gestuniUtiliz
select RTRIM(valoare) from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>''

set @lista_gestiuni=(case when exists (select 1 from @gestuniUtiliz) then 1 else 0 end)

select 
	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@subunitate=@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'),
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''), 
	@tipNomencl=@parXML.value('(/row/@tipNomencl)[1]', 'varchar(20)'),
	@listatipuri=@parXML.value('(/row/@listatipuri)[1]', 'varchar(100)'),
	@tipnom_tipgest=isnull(@parXML.value('(/row/@tipnom_tipgest)[1]', 'int'),0),
	@gestiune=ISNULL(nullif(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'),''), ISNULL(@parXML.value('(/row/linie/@gestiune)[1]', 'varchar(20)'), '')),
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),
	@codspecific=@parXML.value('(/row/@codspecific)[1]', 'varchar(20)'), -- este codul specific - deocamdata la CL
	@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(13)'), '')
/** Daca subunitate nu este trimisa de prin machetele de unde se apeleaza (legacy) o luam din PAR **/
if @subunitate IS NULL
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	
if @aplicatie<>''
	set @tip=@aplicatie
set @gestutiliz=isnull((select rtrim(max(valoare)) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
set @categoriePret=isnull((select rtrim(max(valoare)) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

set @searchText=REPLACE(@searchText, ' ', '%')

if @tipnom_tipgest=1 and @gestiune<>''
	select @tipgest=tip_gestiune from gestiuni where subunitate=@subunitate and Cod_gestiune=@gestiune	

-- folosim tabela temporara pentru a face join pe tabelele de preturi doar cu liniile filtrate.
declare @nomencl table (cod varchar(20) primary key, denumire varchar(200), Cont varchar(20), Pret_cu_amanuntul float, Pret_vanzare float, UM varchar(50), stocCalculat decimal(15,3), tip char(1))
insert @nomencl(cod, denumire, Cont, Pret_cu_amanuntul, Pret_vanzare, UM, stocCalculat, tip)
select top 100 
	rtrim(nomencl.Cod), rtrim(nomencl.Denumire), rtrim(isnull(max(stocuri.cont),nomencl.Cont)), nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, rtrim(nomencl.UM),
	sum(convert(decimal(15, 3), isnull(stocuri.stoc, 0))) stocCalculat, rtrim(nomencl.tip) 
from nomencl
left join conturi c on c.Subunitate=@subunitate and c.Cont=nomencl.Cont
left join stocuri on stocuri.Subunitate=@subunitate 
	and (@tip in ('PF','CI','AF') and stocuri.Tip_gestiune='F' or @tip not in ('PF','CI','AF') and stocuri.Tip_gestiune not in ('F', 'T'))
		and stocuri.Cod=nomencl.cod and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
	and (@gestiune!='' or @lista_gestiuni=0 or exists (select 1 from @gestuniUtiliz gu where gu.gestiune=stocuri.cod_gestiune))  --Se filtreaza pe gestiunile provenite din proprietati
where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
and (@tipnomencl is null or nomencl.tip=@tipnomencl)
and (@listatipuri is null or charindex(nomencl.tip,@listatipuri)<>0)
and not (@tip in ('RM','AI') and nomencl.tip='S') 
and not (@tip in ('AP','AE') and nomencl.tip='R') 
and (@tip not in ('RS') or nomencl.tip='R') 
and (@tip not in ('AS') or nomencl.tip='S') 
and (@tip not in ('PF','CI','AF') or nomencl.tip in ('M','O')) 
and (@tip not in ('DF') or nomencl.Tip in ('A', 'M', 'P', 'O'))
--and (@tip not in ('CM') or nomencl.tip<>'O') 
and (@tip not in ('PV') or nomencl.Tip in ('A', 'M', 'P', 'S'))
and (@subtip <> 'AA' or c.Sold_credit in (1,2)--left(nomencl.Cont,3) in ('167','408','409','418','419','461','462') 
	and nomencl.Tip in ('S','R'))--pe subtip de avans sa aduca numai codurile cu conturi compatibile
-- Ghita: adaugat filtrare dupa cod specific
and (isnull(@codspecific,'') = '' or exists (select 1 from nomspec where tert=@tert and cod=nomencl.cod and Cod_special=@codspecific)) -- daca se face filtrare pe cod specif.
and (@grupa ='' or nomencl.Grupa=@grupa) 
and (@tipgest is null or tip=@tipgest) 
and (@faraU=0 or nomencl.Tip<>'U') 
group by nomencl.cod,nomencl.Denumire,nomencl.tip, nomencl.Cont, nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, nomencl.UM
-- Cristy: linia de mai jos cred ca trebuie cu nomencl.tip='S' - servicii prestate nu servicii receptionate
having (@FltStocPred=0 or nomencl.tip in ('R','S') or @tip not in ('PV','AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') or sum(ISNULL(stocuri.stoc, 0))>=0.001)
order by patindex('%'+@searchText+'%',nomencl.denumire),1

create table #preturi(cod varchar(20),nestlevel int)
insert into #preturi
select cod,@@NESTLEVEL
from @nomencl 

exec CreazaDiezPreturi
exec wIaPreturi @sesiune=@sesiune,@parXML=@parXML

-- selectul
select rtrim(nomencl.cod) as cod, 
	tip+' '+(case 
		when @tip in ('RS') then 'Cont '+rtrim(nomencl.cont) 
		when @tip in ('AS') then 'Cont '+rtrim(nomencl.cont+',Pret '+convert(varchar,convert(decimal(15, 2),isnull(p.Pret_amanunt_discountat,nomencl.Pret_vanzare)))) 
		else (case when @tip='PV' then '('+ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(p.Pret_amanunt_discountat, nomencl.Pret_cu_amanuntul))))+' lei) ' else '' end)
			+ltrim(CONVERT(varchar(20), nomencl.stocCalculat))+ ' ' + rtrim(nomencl.um)
			+(case when 1=1 or @tip in ('RM','PP','AI') then ' (cont '+rtrim(nomencl.cont)+')' else '' end)
			end) as info,  
	rtrim(nomencl.denumire) as denumire 
from @nomencl nomencl
	left outer join #preturi p on nomencl.cod=p.cod
order by patindex('%'+@searchText+'%',nomencl.denumire),1
for xml raw 
