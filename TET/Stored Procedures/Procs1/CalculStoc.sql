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

	if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 declare @p xml
		 select @p=(select @dData dDataSus, @cCod cCod, @GestFiltru cGestiune, @cCodi cCodi, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc, @cGrupa cGrupa, @cLocatie Locatie, '' Contract for xml raw)
		exec pstoc @sesiune='', @parxml=@p
--apel anterior:	dbo.fStocuriCen(@dData, @cCod, @GestFiltru, @cCodi, 1, 1, 1, @TipStoc, '', @cGrupa, @cLocatie, '', '', '', '', '') a
--			@dDataSus, @cCod, @cGestiune, @cCodi, @GrCod, @GrGest, @GrCodi, @TipStoc, @cCont, @cGrupa, @Locatie, @LM, @Comanda, @Contract, @Furnizor, @Lot

update stocuri
set 
stoc_ce_se_calculeaza = a.stoc, 
stoc2_ce_se_calculeaza= a.stoc_UM2, 
pret_vanzare=(case when isnull(@PretMed, 0)=1 then (case when a.stoc<>0 then round(convert(decimal(17,5), a.valoare_stoc/a.stoc),5) else 0 end) else a.pret_vanzare end)
from #docstoc a
where stocuri.subunitate=a.subunitate and stocuri.tip_gestiune=a.tip_gestiune and stocuri.cod_gestiune=a.gestiune and stocuri.cod=a.cod and stocuri.cod_intrare=a.cod_intrare
and (isnull(@cLocatie, '')='' or stocuri.locatie=@cLocatie)

select * from #docstoc
