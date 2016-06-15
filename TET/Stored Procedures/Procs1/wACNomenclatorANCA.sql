

CREATE procedure [dbo].[wACNomenclatorANCA] @sesiune varchar(50),@parXML XML      
as
set transaction isolation level read uncommitted
/*if exists(select * from sysobjects where name='wACNomenclatorSP' and type='P')      
begin
	exec wACNomenclatorSP @sesiune,@parXML
	return 0
end
*/
declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int
declare @aplicatie varchar(100), @subtip varchar(2)
declare @utilizator varchar(10)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
if @utilizator is null
	return -1

exec luare_date_par 'GE', 'FNOMPRED', @FltStocPred output, 0, ''

-- citesc lista gestiuni atasate utilizatorului
declare @lista_gestiuni int
declare @gestuniUtiliz table(gestiune varchar(13) primary key)
insert @gestuniUtiliz
select RTRIM(valoare) from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>''

set @lista_gestiuni=(case when exists (select 1 from @gestuniUtiliz) then 1 else 0 end)

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''), 
	@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), '')
	
    
if @aplicatie<>''
	set @tip=@aplicatie
set @gestutiliz=isnull((select rtrim(max(valoare)) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
set @categoriePret=isnull((select rtrim(max(valoare)) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

set @searchText=REPLACE(@searchText, ' ', '%')

-- folosim tabela temporara pentru a face join pe tabelele de preturi doar cu liniile filtrate.
declare @nomencl table (cod varchar(20) primary key, denumire varchar(200), Cont varchar(20), Pret_cu_amanuntul float, Pret_vanzare float, UM varchar(50), stocCalculat decimal(15,2))
insert @nomencl(cod, denumire, Cont, Pret_cu_amanuntul, Pret_vanzare, UM, stocCalculat)
select 
	rtrim(nomencl.Cod), rtrim(nomencl.Denumire), rtrim(nomencl.Cont), nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, rtrim(nomencl.UM),
	sum(convert(decimal(15, 2), isnull(stocuri.stoc, 0))) stocCalculat
from nomencl
left join stocuri on stocuri.Subunitate=@subunitate 
	and (@tip in ('PF','CI') and stocuri.Tip_gestiune='F' or @tip not in ('PF','CI') and stocuri.Tip_gestiune not in ('F', 'T'))
		and stocuri.Cod=nomencl.cod and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
	and (@gestiune!='' or @lista_gestiuni=0 or exists (select 1 from @gestuniUtiliz gu where gu.gestiune=stocuri.cod_gestiune))  --Se filtreaza pe gestiunile provenite din proprietati
where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
and not (@tip in ('RM','AI') and nomencl.tip='S') 
and not (@tip in ('AP','AE') and nomencl.tip='R') 
and (@tip not in ('RS') or nomencl.tip='R') 
and (@tip not in ('AS') or nomencl.tip='S') 
and (@tip not in ('DF','PF','CI') or nomencl.tip='O') 
and (@tip not in ('CM') or nomencl.tip<>'O') 
and (@tip not in ('PV') or nomencl.Tip in ('A', 'M', 'P', 'S'))
and (@subtip <> 'AA' or (nomencl.Cont in ('419','4092') and nomencl.Tip in ('S','R')) )--daca suntem pe subtip de avans sa aduca numai codurile de servicii pe cont 419
group by nomencl.cod,nomencl.Denumire,nomencl.tip, nomencl.Cont, nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, nomencl.UM
having (@FltStocPred=0 or nomencl.tip = 'R' or @tip not in ('AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') or sum(ISNULL(stocuri.stoc, 0))>=0.001)
order by patindex('%'+@searchText+'%',nomencl.denumire),1

-- selectul
select rtrim(nomencl.cod) as cod, 
	/*(case 
		when @tip in ('RS') then rtrim(nomencl.cont) 
		when @tip in ('AS') then 'Cont:'+rtrim(nomencl.cont+'Pret: '+convert(varchar,convert(decimal(15, 2),nomencl.Pret_vanzare))) 
		else (case when @tip='PV' then '('+ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(isnull(pretGest.Pret_cu_amanuntul,pretCat1.Pret_cu_amanuntul), nomencl.Pret_cu_amanuntul))))+' lei) ' else '' end)
			+ltrim(CONVERT(varchar(20), nomencl.stocCalculat))+ ' ' + rtrim(nomencl.um)
			+(case when @tip in ('RM','PP') then ' (cont '+rtrim(nomencl.cont)+')' else '' end)
			--+(case when @tip in ('AP') then '  Pret: '+convert(varchar,convert(decimal(15, 2),isnull(pretGest.Pret_vanzare,0)))  else '' end)
			end)--+(case when @tip in ('AP') then '  Pret: '+convert(varchar,convert(decimal(15, 2),isnull(pretGest.Pret_vanzare,0)))  else '' end) 
			*/
			'  Pret: '+convert(varchar,convert(decimal(15, 2),isnull(pretGest.Pret_vanzare,0))) as info,  
	rtrim(nomencl.denumire) as denumire
from @nomencl nomencl
left join preturi pretGest on pretGest.Cod_produs=nomencl.Cod and pretGest.um=@categoriePret and pretGest.Tip_pret=1 and pretGest.Data_superioara='2999-01-01' 
left join preturi pretCat1 on pretCat1.Cod_produs=nomencl.Cod and pretCat1.um=1 and pretCat1.Tip_pret=1 and pretCat1.Data_superioara='2999-01-01' 
--and (@gestiune='' --or @tip not in ('BK', 'AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') 
--	or nomencl.tip not in ('A','M','P') or stocuri.Cod_gestiune=@gestiune) --Se filtreaza pe gestiunea primita ca si parametru
--and (@lista_gestiuni=0 or gu.valoare is not null 
	--or @tip not in ('BK', 'AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') or @FltStocPred=0
	--or nomencl.tip not in ('A','M','P'))  --Se filtreaza pe gestiunile provenite din proprietati
order by patindex('%'+@searchText+'%',nomencl.denumire),1
for xml raw 


