--***  
create procedure CalculStoc @cGestiune char(9), @cCod char(20), @dData datetime, @cCodi char(13), @cGrupa char(13), @cLocatie char(30), @cMarca char(9)  
as  
  
declare @TipStoc char(1), @GestFiltru char(9), @UM2 bit, @PretMed int  
  
set @TipStoc = (case when isnull(@cMarca,'')<>'' then 'F' when isnull(@cGestiune,'')<>'' then 'D' else '' end)  
set @GestFiltru = (case when @TipStoc='F' then @cMarca else @cGestiune end)  
  
exec luare_date_par 'GE', 'MEDIUP', @PretMed output, null, null  
  
update stocuri  
set stoc_ce_se_calculeaza=0, pret_vanzare=(case when isnull(@PretMed, 0)=1 then 0 else pret_vanzare end),   
 stoc2_ce_se_calculeaza=0  
where (@TipStoc='' or @TipStoc='D' and stocuri.tip_gestiune not in ('F','T') or stocuri.tip_gestiune=@TipStoc)  
and (isnull(@GestFiltru,'')='' or stocuri.cod_gestiune=@GestFiltru)  
and (isnull(@cCod,'')='' or stocuri.cod=@cCod)  
and (isnull(@cCodi,'')='' or stocuri.cod_intrare=@cCodi)  
and (isnull(@cLocatie, '')='' or stocuri.locatie=@cLocatie)  
and (isnull(@cGrupa,'')='' or exists (select 1 from nomencl where nomencl.cod=stocuri.cod and nomencl.grupa=@cGrupa))  
  
update stocuri  
set   
stoc_ce_se_calculeaza = a.stoc,   
stoc2_ce_se_calculeaza= a.stoc_UM2,   
pret_vanzare=(case when isnull(@PretMed, 0)=1 then (case when a.stoc<>0 then round(convert(decimal(17,5), a.valoare_stoc/a.stoc),5) else 0 end) else pret_vanzare end)  
from dbo.fStocuriCen(@dData, @cCod, @GestFiltru, @cCodi, 1, 1, 1, @TipStoc, '', @cGrupa, @cLocatie, '', '', '', '', '') a  
where stocuri.subunitate=a.subunitate and stocuri.tip_gestiune=a.tip_gestiune and stocuri.cod_gestiune=a.gestiune and stocuri.cod=a.cod and stocuri.cod_intrare=a.cod_intrare  
and (isnull(@cLocatie, '')='' or stocuri.locatie=@cLocatie)  