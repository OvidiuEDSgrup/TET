drop procedure [wACNomenclatorPvSP]
GO

-- procedura apelata din PVria - la calcularea stocului, tine cont de lista de gestiuni PV, nu de proprietatea 'GESTIUNE'.
CREATE procedure [dbo].[wACNomenclatorPvSP] @sesiune varchar(50),@parXML XML      
as
set transaction isolation level read uncommitted
declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @gestiune varchar(20), @categoriePret int
declare @aplicatie varchar(100), @subtip varchar(2), @utilizator varchar(10), @GESTPV varchar(20), @listaGestiuni varchar(1000)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
if @utilizator is null
	return -1

exec luare_date_par 'GE', 'FNOMPRED', @FltStocPred output, 0, ''
exec luare_date_par 'GE', 'SUBPRO', @subunitate output, 0, ''

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
	rtrim(nomencl.Cod), rtrim(max(nomencl.Denumire)), max(nomencl.Pret_cu_amanuntul), max(nomencl.Pret_vanzare), rtrim(max(nomencl.UM)),
	sum(convert(decimal(15, 2), isnull(stocuri.stoc, 0))) stocCalculat
from nomencl
left join 
	(select cod, SUM(stoc) stoc 
		from stocuri inner join @gestuniUtiliz on Cod_gestiune=gestiune
		where Subunitate=@subunitate
		group by cod) stocuri on stocuri.cod=nomencl.cod

where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
and nomencl.Tip in ('A', 'M', 'P', 'S')
and stocuri.stoc>0

group by nomencl.cod --, nomencl.Denumire,nomencl.tip, nomencl.Cont, nomencl.Pret_cu_amanuntul, nomencl.Pret_vanzare, nomencl.UM
order by patindex('%'+@searchText+'%',max(nomencl.denumire)),1

-- selectul
select rtrim(nomencl.cod) as cod, 
	'('+ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(isnull(pretGest.Pret_cu_amanuntul,pretCat1.Pret_cu_amanuntul), nomencl.Pret_cu_amanuntul))))+' lei) '
			+ltrim(CONVERT(varchar(20), nomencl.stocCalculat))+ ' ' + rtrim(nomencl.um) as info,  
	rtrim(nomencl.denumire) as denumire 
from @nomencl nomencl
left join preturi pretGest on pretGest.Cod_produs=nomencl.Cod and pretGest.um=@categoriePret and pretGest.Tip_pret=1 and pretGest.Data_superioara='2999-01-01' 
left join preturi pretCat1 on pretCat1.Cod_produs=nomencl.Cod and pretCat1.um=1 and pretCat1.Tip_pret=1 and pretCat1.Data_superioara='2999-01-01' 
order by patindex('%'+@searchText+'%',nomencl.denumire),1
for xml raw 

GO


