--***
create function  fSerii(@dDataJos datetime, @dDataSus datetime, @cCod char(20), @cGestiune char(20), @cCodi char(20), @cSerie char(20), @cGrupa char(13), @cCont varchar(40)) 
returns @docserii table
(
subunitate char(9), 
gestiune char(20), 
cont varchar(40), 
cod char(20), 
data datetime, 
cod_intrare char(20), 
serie char(20), 
pret float, 
tip_document char(2), 
numar_document varchar(20), 
cantitate float, 
tip_miscare char(1), 
in_out char(1), 
predator char(20), 
jurnal char(3), 
tert char(13), 
pret_cu_amanuntul float, 
tip_gestiune char(1), 
locatie char(30), 
data_expirarii datetime, 
TVA_neexigibil int, 
pret_vanzare float, 
accize_cump float, 
loc_de_munca char(13), 
comanda char(40), 
numar_pozitie int, 
cont_corespondent varchar(40)
)
as
begin
declare @cSub char(13), @dDataIstoric datetime, @dDataStartPozdoc datetime, @nAnInc int, @nLunaInc int, @nAnImpl int, @nLunaImpl int

set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')

set @nAnInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
set @nLunaInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)
set @dDataIstoric=dbo.eom(dateadd(year, @nAnInc-1901, dateadd(month, @nLunaInc-1, '01/01/1901')))
set @dDataStartPozdoc=dateadd(day, 1, @dDataIstoric)
if @dDataSus is null set @dDataSus='12/31/2999'
if @dDataJos is null set @dDataJos=(case when @dDataSus>=@dDataIstoric then @dDataStartPozdoc else @dDataSus end)
if @dDataJos<@dDataStartPozdoc
begin
 set @dDataIstoric=(select max(data_lunii) from istoricserii where data_lunii<@dDataJos
  or data_lunii=@dDataJos and @dDataJos=@dDataSus)
 if @dDataIstoric is null
 begin
  set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
  set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
  set @dDataIstoric=dbo.eom(dateadd(year, @nAnImpl-1901, dateadd(month, @nLunaImpl-1, '01/01/1901')))
 end
 set @dDataStartPozdoc=dateadd(day, 1, @dDataIstoric)
end 

if isnull(@cGrupa, '')='' set @cGrupa='%'
if @cCont is null set @cCont = ''

insert @docserii
select a.subunitate, a.gestiune, isnull(b.cont, ''), a.cod, isnull(b.data, a.data_lunii), a.cod_intrare, a.serie, isnull(b.pret, 0), 'SI' as tip_document, '' as numar_document, a.stoc as cantitate, 'I' as tip_miscare, '1' as in_out, '' as predator, '' as jurnal, '' as tert, isnull(b.pret_cu_amanuntul, 0), a.tip_gestiune, isnull(b.locatie, ''), isnull(b.data_expirarii, a.data_lunii), isnull(b.TVA_neexigibil, 0), isnull(b.pret_vanzare, 0), 0 as accize_cump, '' as loc_de_munca, '' as comanda, 0 as numar_pozitie, '' as cont_corespondent
from istoricserii a
left outer join istoricstocuri b on a.subunitate=b.subunitate and a.data_lunii=b.data_lunii and a.tip_gestiune=b.tip_gestiune and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
left outer join nomencl n on a.cod=n.cod 
where a.data_lunii=@dDataIstoric and a.subunitate=@cSub and a.tip_gestiune not in ('F', 'T') and (@cCod is null or a.cod=rtrim(@cCod)) and (@cGestiune is null or a.gestiune=@cGestiune) and (@cCodi is null or a.cod_intrare=rtrim(@cCodi)) and (@cSerie is null or a.serie=rtrim(@cSerie)) and isnull(b.cont, '') like RTrim(@cCont)+'%' and isnull(n.grupa, '') like RTrim(@cGrupa) 
union all 
select a.subunitate, a.gestiune, isnull(b.cont_de_stoc, ''), a.cod, a.data, a.cod_intrare, a.serie, isnull(b.pret_de_stoc, 0), a.tip, a.numar, a.cantitate, a.tip_miscare, (case when a.tip_miscare='I' then '2' else '3' end), a.gestiune_primitoare, isnull(b.jurnal, ''), (case when a.tip in ('RM', 'AP') then isnull(b.tert, '') when a.tip in ('AI', 'AE') then isnull(b.factura, '') else isnull(b.loc_de_munca, '') end), (case when isnull(b.tip_miscare, '')='I' then isnull(b.pret_cu_amanuntul, 0) else isnull(b.pret_amanunt_predator, 0) end), isnull(g.tip_gestiune, ''), isnull(b.locatie, ''), isnull(b.data_expirarii, a.data), isnull(b.TVA_neexigibil, 0), (case when isnull(b.tip_miscare, '')='I' then isnull(b.pret_amanunt_predator, 0) else isnull(b.pret_cu_amanuntul, 0) end), isnull(b.accize_cumparare, 0), isnull(b.loc_de_munca, ''), isnull(b.comanda, ''), a.numar_pozitie, isnull(b.cont_corespondent, '')
from pdserii a
left outer join pozdoc b on a.subunitate=b.subunitate and a.data=b.data and a.tip=b.tip and a.numar=b.numar and a.gestiune=b.gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare and a.numar_pozitie=b.numar_pozitie 
left outer join gestiuni g on g.subunitate=a.subunitate and g.cod_gestiune=a.gestiune
left outer join nomencl n on a.cod=n.cod
where a.subunitate=@cSub and a.tip not in ('PF', 'CI', 'AF') and isnull(b.tip_miscare, 'E') between 'E' and 'I' and a.data between @dDataStartPozdoc and @dDataSus and (@cCod is null or a.cod=rtrim(@cCod)) and (@cGestiune is null or a.gestiune=@cGestiune) and (@cCodi is null or a.cod_intrare=rtrim(@cCodi)) and (@cSerie is null or a.serie=rtrim(@cSerie)) and isnull(b.cont_de_stoc, '') like RTrim(@cCont)+'%' and isnull(n.grupa, '') like RTrim(@cGrupa) 
union all 
select a.subunitate, a.gestiune_primitoare, isnull(b.cont_corespondent, ''), a.cod, a.data, (case when isnull(b.grupa, '')<>'' then b.grupa else a.cod_intrare end), a.serie, isnull(b.pret_de_stoc, 0), 'TI', a.numar, a.cantitate, 'I', '2', a.gestiune, isnull(b.jurnal, ''), '', isnull(b.pret_cu_amanuntul, 0), isnull(g.tip_gestiune, ''), isnull(b.locatie, ''), isnull(b.data_expirarii, a.data), isnull(b.TVA_neexigibil, 0), isnull(b.pret_amanunt_predator, 0), isnull(b.accize_cumparare, 0), isnull(b.loc_de_munca, ''), isnull(b.comanda, ''), a.numar_pozitie, isnull(b.cont_de_stoc, '')
from pdserii a
left outer join pozdoc b on a.subunitate=b.subunitate and a.data=b.data and a.tip=b.tip and a.numar=b.numar and a.gestiune_primitoare=b.gestiune_primitoare and a.cod=b.cod and a.cod_intrare=b.cod_intrare and a.numar_pozitie=b.numar_pozitie 
left outer join gestiuni g on g.subunitate=a.subunitate and g.cod_gestiune=a.gestiune_primitoare
left outer join nomencl n on a.cod=n.cod
where a.subunitate=@cSub and a.tip='TE' and a.data between @dDataStartPozdoc and @dDataSus and (@cCod is null or a.cod=rtrim(@cCod)) and (@cGestiune is null or a.gestiune_primitoare=@cGestiune) and (@cCodi is null or (case when isnull(b.grupa, '')<>'' then b.grupa else a.cod_intrare end)=rtrim(@cCodi)) and (@cSerie is null or a.serie=rtrim(@cSerie)) and isnull(b.cont_corespondent, '') like RTrim(@cCont)+'%' and isnull(n.grupa, '') like RTrim(@cGrupa) 

return
end
