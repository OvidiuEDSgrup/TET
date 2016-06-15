-- procedura apelata din PVria - la calcularea stocului, tine cont de lista de gestiuni PV, nu de proprietatea 'GESTIUNE'.
create procedure wACNomenclatorPv @sesiune varchar(50),@parXML XML      
as
set transaction isolation level read uncommitted
if exists(select * from sysobjects where name='wACNomenclatorPvSP' and type='P')      
begin
	exec wACNomenclatorPvSP @sesiune,@parXML
	return 0
end
declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @gestiune varchar(20), @categoriePret int
declare @aplicatie varchar(100), @subtip varchar(2), @utilizator varchar(10), @GESTPV varchar(20), @listaGestiuni varchar(1000)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
if @utilizator is null
	return -1

select	@FltStocPred=(case when parametru='FNOMPRED' then Val_logica else isnull(@FltStocPred,0) end),
		@subunitate=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @subunitate end)
from par 
where Tip_parametru='GE' and Parametru in ('FNOMPRED', 'SUBPRO')


select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@GESTPV = @parXML.value('(/row/@GESTPV)[1]','varchar(50)'),
		@GESTPV= (case when isnull(@GESTPV,'')<>'' then @GESTPV else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end),
		@listaGestiuni= dbo.wfListaGestiuniAtasatePV(@GESTPV)

-- citesc lista gestiuni atasate utilizatorului
declare @lista_gestiuni int
declare @gestuniUtiliz table(gestiune varchar(13) primary key)
insert @gestuniUtiliz
select distinct item from dbo.split(@listagestiuni,';')


-- TODO: categ. de pret sa tina cont de tertul ales
set @categoriePret=isnull((select rtrim(max(valoare)) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@GESTPV),'1')
set @searchText=REPLACE(@searchText, ' ', '%')

-- folosim tabela temporara pentru a face join pe tabelele de preturi doar cu liniile filtrate.
declare @nomencl table (cod varchar(20) primary key, denumire varchar(200), Pret_cu_amanuntul float, Pret_vanzare float, UM varchar(50), stocCalculat decimal(15,2))
insert @nomencl(cod, denumire, Pret_cu_amanuntul, Pret_vanzare, UM, stocCalculat)
select top 100 
	rtrim(nomencl.Cod), rtrim(nomencl.Denumire), nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, rtrim(nomencl.UM),
	convert(decimal(15, 2), isnull(stocuri.stoc, 0)) stocCalculat
from nomencl
left join 
	(select cod, SUM(stoc) stoc 
		from stocuri inner join @gestuniUtiliz on Cod_gestiune=gestiune
		where Subunitate=@subunitate and Tip_gestiune <>'F'
		group by cod) stocuri on stocuri.cod=nomencl.cod
where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
and nomencl.Tip in ('A', 'M', 'P', 'S')
and (@FltStocPred=0 or nomencl.tip='S' or ISNULL(stocuri.stoc, 0)>=0.001)
order by patindex('%'+@searchText+'%',nomencl.denumire),1

create table #preturi(cod varchar(20),nestlevel int)
insert into #preturi
select cod,@@NESTLEVEL
from @nomencl 

exec CreazaDiezPreturi
exec wIaPreturi @sesiune=@sesiune,@parXML=@parXML

-- selectul
select rtrim(nomencl.cod) as cod, 
	isnull('('+ltrim(CONVERT(varchar(20),p.Pret_amanunt_discountat))+' lei) ','')
			+ltrim(CONVERT(varchar(20), nomencl.stocCalculat))+ ' ' + rtrim(nomencl.um) as info,  
	rtrim(nomencl.denumire) as denumire 
from @nomencl nomencl
left outer join #preturi p on nomencl.cod=p.cod
order by patindex('%'+@searchText+'%',nomencl.denumire),1
for xml raw 
