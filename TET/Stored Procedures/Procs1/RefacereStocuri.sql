--***
create procedure RefacereStocuri @cGestiune char(20)=null, @cCod char(20)=null, @cMarca char(9)=null, @dData datetime=null, @PretMed int=0, @InlocPret int=0
as

declare @TipStoc char(1), @GestFiltru char(20), @ProcMed bit, @CodICtStoc bit
declare @LenGestiune int, @UrmCant2 int
select @LenGestiune = c.length from sysobjects o, syscolumns c where o.type='U' and o.name='stocuri' and o.id=c.id and c.name='cod_gestiune'
set @UrmCant2=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='URMCANT2'), 0)

set @TipStoc = (case when isnull(@cMarca,'')<>'' then 'F' when isnull(@cGestiune,'')<>'' then 'D' else '' end)
set @GestFiltru = (case when @TipStoc='F' then @cMarca else @cGestiune end)

if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
begin
	raiserror('RefacereStocuri: Accesul este restrictionat pe anumite gestiuni! Nu este permisa refacerea in aceste conditii!',16,1)
	return
end

if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
begin
	raiserror('RefacereStocuri: Accesul este restrictionat pe anumite locuri de munca! Nu este permisa refacerea in aceste conditii!',16,1)
	return
end

delete stocuri
where (@TipStoc='' or @TipStoc='D' and stocuri.tip_gestiune not in ('F','T') or stocuri.tip_gestiune=@TipStoc)
and (isnull(@GestFiltru,'')='' or stocuri.cod_gestiune=@GestFiltru)
and (isnull(@cCod,'')='' or stocuri.cod=@cCod)

	declare @p xml
	select @p=(select @dData dDataSus, @cCod cCod, @GestFiltru cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc
	for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p

insert stocuri
(Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data, Cod_intrare, Pret, 
Stoc_initial, Intrari, Iesiri, Data_ultimei_iesiri, Stoc, 
Cont, Data_expirarii, Stoc_ce_se_calculeaza, Are_documente_in_perioada, TVA_neexigibil, Pret_cu_amanuntul, Locatie, Pret_vanzare, 
Loc_de_munca, Comanda, [Contract], Furnizor, Lot, Stoc_initial_UM2, Intrari_UM2, Iesiri_UM2, Stoc_UM2, Stoc2_ce_se_calculeaza, Val1, Alfa1, Data1,idIntrareFirma,idIntrare)
select 
a.subunitate, a.tip_gestiune, left(a.gestiune, @LenGestiune), a.cod, (case when a.data_stoc='2999-12-31' then a.data else a.data_stoc end), a.cod_intrare, a.pret, 
a.stoc_initial, a.intrari, a.iesiri, a.data_ultimei_iesiri, a.stoc,
a.cont, a.data_expirarii, 0, 0, a.tva_neexigibil, a.pret_cu_amanuntul, a.locatie, 0, 
isnull(a.loc_de_munca,''), isnull(a.comanda,''), isnull(a.[contract],''), isnull(a.furnizor,''), isnull(a.lot,''), 
(case when @UrmCant2=1 then a.stoc_initial_UM2 else 0 end), 
(case when @UrmCant2=1 then a.intrari_UM2 else 0 end), 
(case when @UrmCant2=1 then a.iesiri_UM2 else 0 end), 
(case when @UrmCant2=1 then a.stoc_UM2 else 0 end), 
0, 0, '', '01/01/1901',idIntrareFirma,idIntrare
from --dbo.fStocuriCen(@dData, @cCod, @GestFiltru, null, 1, 1, 1, @TipStoc, '', '', '', '', '', '', '', '') a
	#docstoc a
where not exists (select 1 from stocuri s where s.subunitate=a.subunitate and s.tip_gestiune=a.tip_gestiune 
	and s.cod_gestiune=left(a.gestiune, @LenGestiune) and s.cod=a.cod and s.cod_intrare=a.cod_intrare)

if @PretMed = 1
begin
	exec luare_date_par 'GE', 'PROCMED', @ProcMed output, null, null
	exec luare_date_par 'GE', 'CODCS', @CodICtStoc output, null, null
	if (@ProcMed = 1 and exists (select 1 from sysobjects where type='P' and name='PROCMED'))
		exec ProcMed @dData, @cCod, @InlocPret, null, @CodICtStoc, 0
	else
		exec RefPretMediu @dData, @cCod, @InlocPret, null, @CodICtStoc, 0
end

if object_id('tempdb..#docstoc') is not null drop table #docstoc
