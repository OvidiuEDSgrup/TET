--***
create procedure docStocuri @sesiune varchar(50), @dDataJos datetime, @dDataSus datetime, @cCod char(20), @cGestiune char(20), @cCodi char(20), @cGrupa char(13), @TipStoc char(1), @cCont varchar(40), @Corelatii int, 
	@Locatie varchar(30), @LM char(9), @Comanda char(40), @Contract char(20), @Furnizor varchar(13), @Lot char(20), @Cen int, @GrCod int, @GrGest int, @GrCodi int 
	, @parXML xml=null
as
declare @StocCom int, @StocFurn int, @StocLot int, @PropDataS char(20), @AccDVI int, 
	@dDataIstoric datetime, @dDataStartPozdoc datetime, @nAnInc int, @nLunaInc int, @nAnImpl int, @nLunaImpl int,
	@grupGestiuni varchar(20),@subtipGestiune varchar(1)--> folosit doar din fisa terti pentru a obtine stocurile depozit custodie; null=nefiltrat, 'T' sau altceva = doar custodie
declare @cSub char(13),@C35 int,@C8 int,@UM2 int,@PrestTE int,@SubgestFolLM int

select @StocCom=0, @StocFurn=0, @StocLot=0, @PropDataS='', @AccDVI=0

select	@grupGestiuni=@parXML.value('(row/@grupgestiuni)[1]','varchar(50)')+'%',
		@subtipGestiune=@parXML.value('(row/@subtipgestiune)[1]','varchar(1)')
select 
	@StocCom = (case when tip_parametru='GE' and parametru='STOCPECOM' then val_logica else @StocCom end),
	@StocFurn = (case when tip_parametru='GE' and parametru='STOCFURN' then val_logica else @StocFurn end),
	@StocLot = (case when tip_parametru='GE' and parametru='STOCLOT' then val_logica else @StocLot end),
	@PropDataS=(case when tip_parametru='GE' and parametru='DATASTOCP' and val_logica=1 then val_alfanumerica else @PropDataS end),
	@StocLot = (case when tip_parametru='GE' and parametru='ACCIMP' then val_logica else @AccDVI end)
from par where tip_parametru='GE'
select	@cSub=max(case when p.parametru='SUBPRO' then p.val_alfanumerica else '' end),
		@C35=max(case when p.parametru='STCUST35' then p.val_logica else 0 end),
		@C8=max(case when p.parametru='STCUST8' then p.val_logica else 0 end),
		@PrestTE=max(case when p.parametru='PRESTTE' then p.val_logica else 0 end),
		@UM2=max(case when p.parametru='URMCANT2' then p.val_logica else 0 end),
		@SubgestFolLM=max(case when p.parametru='SUBGLMFOL' then p.val_logica else 0 end)
from par p where tip_parametru='GE' and parametru in ('SUBPRO','STCUST35','STCUST8','PRESTTE','URMCANT2','SUBGLMFOL')

if @Corelatii is null set @Corelatii=0

if @Corelatii=1 
	set @dDataStartPozdoc=@dDataJos
else
begin
	set @nAnInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
	set @nLunaInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)
	set @dDataIstoric=dbo.eom(dateadd(year, @nAnInc-1901, dateadd(month, @nLunaInc-1, '01/01/1901')))
	set @dDataStartPozdoc=dateadd(day, 1, @dDataIstoric)
	if @dDataSus is null set @dDataSus='12/31/2999'
	if @dDataJos is null set @dDataJos=(case when @dDataSus>=@dDataIstoric then @dDataStartPozdoc else @dDataSus end)
	if @dDataJos<@dDataStartPozdoc
	begin
		set @dDataIstoric=(select max(data_lunii) from istoricstocuri where data_lunii<@dDataJos )
			--or data_lunii=@dDataJos and @dDataJos=@dDataSus)
		if @dDataIstoric is null
		begin
			set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
			set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
			set @dDataIstoric=dbo.eom(dateadd(year, @nAnImpl-1901, dateadd(month, @nLunaImpl-1, '01/01/1901')))
		end
		set @dDataStartPozdoc=dateadd(day, 1, @dDataIstoric)
	end	
end

declare @LM_like varchar(200)
select @TipStoc=isnull(@TipStoc, ''), @cGrupa=(case when isnull(@cGrupa, '')='' then '%' else @cGrupa end), @cCont=isnull(@cCont, ''), 
	@Locatie=isnull(@Locatie, ''), @LM=isnull(rtrim(@LM), ''),
	@LM_like=isnull(rtrim(@LM), '')+'%', @Comanda=isnull(@Comanda, ''), 
	@Contract=isnull(@Contract, ''), @Furnizor=isnull(@Furnizor, ''), @Lot=isnull(@Lot, '')


select @cCont=rtrim(isnull(@cCont,''))
declare @cConturi table (cont varchar(50))
if @cCont<>''
	insert into @cConturi(cont)
		select cont from arbconturi(@cCont)
--*/
	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @utilizator varchar(20), @fltGstUt int, @eLmUtiliz int
select @utilizator=dbo.fIaUtilizator(@sesiune)
declare @cGestiuneUtiliz table(valoare varchar(200), cod varchar(20))
insert into @cGestiuneUtiliz (valoare,cod)
select valoare, cod_proprietate from fPropUtiliz(@sesiune) where cod_proprietate='GESTIUNE' and valoare<>'' and @TipStoc<>'F'
set	@fltGstUt=isnull((select count(1) from @cGestiuneUtiliz),0)
declare @LmUtiliz table(valoare varchar(200), marca varchar(20))
insert into @LmUtiliz(valoare, marca)
select l.cod valoare, p.marca
	from lmfiltrare l 
	left join personal p on (@SubgestFolLM=1 or rtrim(l.cod)=rtrim(p.loc_de_munca))
	where l.utilizator=@utilizator and l.cod<>'' and @TipStoc='F'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

create table #pozdoc
	(subunitate char(9),gestiune char(20),cont varchar(40),cod char(20),data datetime,cod_intrare char(20),	pret float,tip_document char(2),numar_document char(20),cantitate float,cantitate_UM2 float,
	tip_miscare char(1),in_out char(1),predator char(20), codi_pred char(20), jurnal char(20),tert char(13),serie char(20),pret_cu_amanuntul float, tip_gestiune char(1),locatie char(30),data_expirarii datetime,
	TVA_neexigibil int,	pret_vanzare float,accize_cump float,loc_de_munca char(9),comanda char(40),	[contract] char(20),furnizor char(13),lot char(20),numar_pozitie int,cont_corespondent varchar(40),
	schimb int, contractdinpozdoc_pebune varchar(20),idIntrareFirma int,idIntrare int)
	
insert #pozdoc (subunitate, gestiune, cont, cod, data, cod_intrare, pret, tip_document,	numar_document,	cantitate, cantitate_UM2, tip_miscare, in_out, predator, codi_pred, jurnal,
	tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, data_expirarii, TVA_neexigibil, pret_vanzare, accize_cump, loc_de_munca, comanda, contract, furnizor, lot, numar_pozitie,
	cont_corespondent, schimb, contractdinpozdoc_pebune,idIntrareFirma,idIntrare)
select i.subunitate, i.cod_gestiune, i.cont, i.cod, i.data, i.cod_intrare, i.pret, 'SI','',i.stoc,
		(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),i.stoc/n.coeficient_conversie_1),3) when @UM2=0 /*or left(isnull(n.UM_2,''),1)<>'Y'*/ then 0 else i.stoc_UM2 end) as cantitate_UM2,
		'I','1','','','','','',i.pret_cu_amanuntul, i.tip_gestiune, 
		isnull(nullif(si.locatie,''),i.locatie), 
		isnull(nullif(si.data_expirarii,'1901-01-01'),isnull(nullif(ip.data_expirarii,'1901-01-01'),i.data_expirarii)),
		i.TVA_neexigibil, i.pret_vanzare, 0, i.loc_de_munca, i.comanda, i.contract, 
		isnull(nullif(case when ip.tip='RM' then ip.tert else '' end,''),i.furnizor), 
		isnull(nullif(ip.lot,''),i.lot), 
		0, '', 0, '' Contract,i.idIntrareFirma,i.idIntrare
from istoricstocuri i
	left join pozdoc ip on ip.idpozdoc=i.idintrarefirma --and ip.subunitate=@cSub --and ip.tip='rm'
	left join pozdoc si on si.idpozdoc=i.idintrare 
	left outer join nomencl n on i.cod=n.cod
	left outer join personal pers on pers.marca=i.Cod_gestiune
	left join @cConturi c on c.cont=i.cont
	left outer join gestiuni b on b.subunitate=i.subunitate and b.cod_gestiune=i.cod_gestiune
where @Corelatii<>1 and i.data_lunii=@dDataIstoric and i.subunitate=@cSub and i.tip_gestiune not in ('V','I') and (@cCod is null or i.cod=rtrim(@cCod))
	and (@subtipGestiune is null or isnull(b.detalii.value('(/row/@custodie)[1]', 'int'),0)=1)
	and (@cGestiune is null or i.cod_gestiune=@cGestiune)
	and (@grupGestiuni is null or i.cod_gestiune like @grupGestiuni)
	and (@cCodi is null or i.cod_intrare=rtrim(@cCodi)) and isnull(n.grupa,'') like RTrim(@cGrupa)
	and (@TipStoc='' or @TipStoc='D' and i.tip_gestiune not in ('F','T') or i.tip_gestiune=@TipStoc)	
	and (@cCont='' or c.cont is not null) --and i.cont like RTrim(@cCont)+'%'
	and (@Locatie='' or i.locatie like @Locatie) 
	and (@LM='' or rtrim(case when @SubgestFolLM=1 then i.loc_de_munca else pers.Loc_de_munca end) like @LM_like) 
	and (@Comanda='' or i.comanda in('',@Comanda))
	and (@Contract='' or i.contract in ('',@Contract))
	and (@Furnizor='' or ip.tert=@furnizor or i.furnizor=@Furnizor)
	and (@Lot='' or isnull(ip.lot,i.lot)=@Lot) and (@fltGstUt=0 or exists(select 1from @cGestiuneUtiliz pr where pr.valoare=i.cod_gestiune))
	and (@eLmUtiliz=0 
		or @SubgestFolLM=0 and exists (select 1 from @LMUtiliz pr where rtrim(pr.marca)=rtrim(i.Cod_gestiune))
		or @SubgestFolLM=1 and exists (select 1 from @LMUtiliz pr where rtrim(pr.valoare)=rtrim(i.loc_de_munca)))
union all	--*/
select a.subunitate,a.gestiune,a.cont_de_stoc,a.cod,a.data,a.cod_intrare,a.pret_de_stoc,a.tip,a.numar,a.cantitate,
	(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),
		a.cantitate/n.coeficient_conversie_1),3) when a.tip in ('PF','CI','AF') or @UM2=0 /*or left(isnull(n.UM_2,''),1)<>'Y'*/ then 0 
		else -- "urmarire cantitate secundara": daca am in pozdoc.detalii atribut _cantitate2 acesta e mai tare, altfel las cum a fost 
		ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),(case when a.tip='RM' and a.numar_DVI<>'' then a.accize_datorate else a.suprataxe_vama end)) end), 
	a.tip_miscare,(case when a.tip_miscare='I' then '2' else '3' end),a.gestiune_primitoare,
	(case when a.tip not in ('TE','DF','PF') then '' when a.grupa='' then a.cod_intrare else a.grupa end),a.jurnal,
	(case when a.tip in ('RM','AP') then a.tert when a.tip in ('AI','AE') then left(a.factura,13) else a.loc_de_munca end),'',
	(case when a.tip_miscare='I' then a.pret_cu_amanuntul else a.pret_amanunt_predator end),
	(case when a.tip in ('PF','CI','AF') then 'F' else isnull(b.tip_gestiune,'') end),
	(case when a.tip_miscare='E' then isnull(s.locatie,a.locatie) else a.locatie end),
	(case when a.tip_miscare='E' then isnull(nullif(s.data_expirarii,'1901-01-01'),isnull(nullif(i.data_expirarii,'1901-01-01'),a.data_expirarii)) else a.data_expirarii end),
	a.TVA_neexigibil,(case when a.tip_miscare='I' then a.pret_amanunt_predator when a.tip in ('AP','AC') then a.pret_vanzare else a.pret_cu_amanuntul end),
	a.accize_cumparare,(case when @SubgestFolLM=1 and a.tip in ('PF','CI') then isnull(nullif(s.loc_de_munca,''),a.loc_de_munca) else a.loc_de_munca end),
	(case when a.tip='TE' then s.comanda else a.comanda end) comanda,--pentru transferuri, comanda predatoare este comanda de pe documentul de intrare in gestiune
	(case when a.tip='TE' then a.factura when a.tip in ('AP','AC','PP') then a.contract else '' end) as contract,
	(case when a.tip='RM' then a.tert when i.tip='RM' then i.tert else '' end) furnizor, 
	(case when (a.tip in ('RM','PP','AI') or a.idintrarefirma is null) and isnull(a.lot,'')<>'' then isnull(a.lot,'') 
		--when a.tip='RM' then a.cont_corespondent when a.tip in ('PP','AI') then a.grupa 
		else isnull(i.lot,'') end) as lot,
	a.numar_pozitie,
	(case when a.tip in ('RM','RS') then a.cont_factura else a.cont_corespondent end) as cont_corespondent,
	a.procent_vama, a.contract,isnull(a.idIntrareFirma,a.idPozDoc) as idIntrareFirma,isnull(a.idIntrare,a.idPozDoc)
from pozdoc a
	left join pozdoc i on i.idpozdoc=a.idintrarefirma --and i.subunitate=@cSub --and i.tip='rm'
	left join pozdoc s on s.idpozdoc=a.idintrare 
	left join @cConturi c on a.cont_de_stoc=c.cont
	left outer join gestiuni b on a.tip not in ('PF','CI','AF') and b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune
	left outer join nomencl n on a.cod=n.cod
	left outer join personal pers on pers.marca=a.gestiune
	--left outer join stocuri s on a.tip in ('TE','DF','PF','CI') and s.subunitate=a.subunitate and s.cod_gestiune=a.gestiune and	s.tip_gestiune=(case when a.tip in ('DF','PF','CI') then 'F' else b.tip_gestiune end) and s.cod=a.cod and s.cod_intrare=a.cod_intrare
where a.subunitate=@cSub 
	and a.tip_miscare between 'E' and 'I' 
	and (a.tip in ('PF','CI','AF') or isnull(b.tip_gestiune,'')<>'I' and (@Corelatii=1 or isnull(b.tip_gestiune,'')<>'V')) 
	and isnull(n.tip,'') not in ('R','S') 
	and a.data between @dDataStartPozdoc and @dDataSus
	and (@subtipGestiune is null or isnull(b.detalii.value('(/row/@custodie)[1]', 'int'),0)=1)
	and (@cCod is null or a.cod=@cCod)
	and (@cGestiune is null or a.gestiune=@cGestiune)
	and (@grupGestiuni is null or a.gestiune like @grupGestiuni)
	and (@cCodi is null or a.cod_intrare=rtrim(@cCodi))
	and isnull(n.grupa,'') like RTrim(@cGrupa)
	and (@cCont='' or c.cont is not null)
	and (@TipStoc='' or @TipStoc='D' and a.tip not in ('PF','CI','AF') or @TipStoc='F' and a.tip in ('PF','CI','AF'))
	and (@Locatie='' or 
		--(case when a.tip in ('TE','DF','PF') then isnull(s.locatie,a.locatie) else a.locatie end)='' or
		(case when a.tip in ('TE','DF','PF') then isnull(s.locatie,a.locatie) else a.locatie end) like @Locatie)
	and (@LM='' or rtrim(case when @SubgestFolLM=1 and a.tip in ('PF','CI') then isnull(s.loc_de_munca,'') when @SubgestFolLM=1 then a.loc_de_munca else pers.Loc_de_munca end) like @LM_like)
	and (@Comanda='' or a.comanda in('',@Comanda))
	and (@Contract='' or (case when a.tip='TE' then a.factura when a.tip in ('AP','AC','PP') then a.contract else '' end) in ('',@Contract))
	and (@Furnizor='' or --(case a.tip when 'RM' then a.tert when 'AI' then a.cont_venituri else '' end) in ('',@Furnizor)
		(case when a.tip='RM' then a.tert else i.tert end)=@furnizor)
	and (@Lot='' or isnull(i.lot,isnull(a.lot,''))=@Lot)
	and (@fltGstUt=0 or exists(select 1from @cGestiuneUtiliz pr where pr.valoare=a.gestiune))
	and (@eLmUtiliz=0 
		or @SubgestFolLM=0 and exists (select 1 from @LMUtiliz pr where rtrim(pr.marca)=rtrim(a.gestiune))
		or @SubgestFolLM=1 and exists (select 1 from @LMUtiliz pr where rtrim(pr.valoare)=rtrim(case when a.tip in ('PF','CI') then isnull(nullif(s.loc_de_munca,''),a.loc_de_munca) else a.loc_de_munca end)))
--/*
union all
-- TI, DI, PI <=> intrarile de la TE, DF, PF 
select a.subunitate,a.gestiune_primitoare,a.cont_corespondent,a.cod,a.data,(case when a.grupa='' then a.cod_intrare else a.grupa end),
	(case when a.tip='TE' and @PrestTE=1 and a.accize_datorate<>0 then a.accize_datorate else a.pret_de_stoc end)*
	(case when a.tip='DF' and a.procent_vama<>0 then (1-convert(decimal(12,3),a.procent_vama/100)) else 1 end),
	(case a.tip when 'DF' then 'DI' when 'PF' then 'PI' else 'TI' end),a.numar,a.cantitate,
	(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),a.cantitate/n.coeficient_conversie_1),3)
		when a.tip in ('DF','PF') or @UM2=0 /*or left(isnull(n.UM_2,''),1)<>'Y'*/ then 0 
		else ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),a.suprataxe_vama) end),'I','2',a.gestiune,a.cod_intrare,
	a.jurnal,'','',a.pret_cu_amanuntul,(case when a.tip in ('DF','PF') then 'F' else isnull(tip_gestiune,'') end),
	a.locatie,
	a.data_expirarii,
	a.TVA_neexigibil,a.pret_amanunt_predator,a.accize_cumparare,(case when @SubgestFolLM=1 then isnull(a.detalii.value('(/*/@lmprim)[1]','varchar(20)'),a.loc_de_munca) else pers.Loc_de_munca end),a.comanda,
	(case when a.tip='TE' then a.factura else '' end) as contract,
	ISNULL(i.tert,'') as furnizor,
	(case when a.idintrarefirma is null and isnull(a.lot,'')<>'' then isnull(a.lot,'') else isnull(i.lot,'') end) as lot,
	a.numar_pozitie,a.cont_de_stoc,a.procent_vama, a.contract,ISNULL(a.idIntrareFirma,a.idpozdoc),a.idPozdoc
from pozdoc a
	left join pozdoc i on a.idintrarefirma=i.idpozdoc --and i.subunitate=@cSub --and i.tip='rm'
	left outer join gestiuni b on a.tip not in ('DF','PF') and b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune_primitoare
	left outer join nomencl n on a.cod=n.cod
	left outer join personal pers on pers.marca=a.gestiune_primitoare
	left join @cConturi c on a.cont_corespondent=c.cont
where a.subunitate=@cSub and (a.tip in ('DF','PF') or a.tip='TE' and isnull(tip_gestiune,'') <> 'I' and (@Corelatii=1 or isnull(tip_gestiune,'')<>'V'))
	and (@subtipGestiune is null or isnull(b.detalii.value('(/row/@custodie)[1]', 'int'),0)=1)
	and isnull(n.tip,'') not in ('R','S') and (@cCod is null or a.cod=@cCod)
	and (@cGestiune is null or a.gestiune_primitoare=@cGestiune)
	and (@grupGestiuni is null or a.gestiune_primitoare like @grupGestiuni)
	and (@cCodi is null or (case when a.grupa='' then a.cod_intrare else a.grupa end)=rtrim(@cCodi)) and a.data between @dDataStartPozdoc and @dDataSus
	and isnull(n.grupa,'') like RTrim(@cGrupa) and (@TipStoc='' or @TipStoc='D' and a.tip='TE' or @TipStoc='F' and a.tip in ('DF','PF'))
	and (@cCont='' or c.cont is not null) --and a.cont_corespondent like RTrim(@cCont)+'%'
	and (@Locatie='' or a.locatie like @Locatie)
	and (@LM='' or rtrim(case when @SubgestFolLM=1 then isnull(a.detalii.value('(/*/@lmprim)[1]','varchar(20)'),a.loc_de_munca) else pers.Loc_de_munca end) like @LM_like) 
	and (@Comanda='' or a.comanda in('',@Comanda))
	and (@Contract='' or (case when a.tip='TE' then a.factura else '' end) in ('',@Contract))
	and (@fltGstUt=0 or exists(select 1from @cGestiuneUtiliz pr where pr.valoare=a.gestiune_primitoare))
	and (@Furnizor='' or i.tert =@furnizor)
	and (@Lot='' or isnull(i.lot,'')=@Lot)
	and (@eLmUtiliz=0 
		or @SubgestFolLM=0 and exists (select 1 from @LMUtiliz pr where rtrim(pr.marca)=rtrim(a.gestiune_primitoare))
		or @SubgestFolLM=1 and exists (select 1 from @LMUtiliz pr where rtrim(pr.valoare)=rtrim(isnull(a.detalii.value('(/*/@lmprim)[1]','varchar(20)'),a.loc_de_munca))))
union all
-- custodie pe vechiul stil (tip_gestiune="T")
select a.subunitate,a.tert,cont_corespondent,a.cod,a.data,cod_intrare,a.pret_de_stoc,a.tip,numar,a.cantitate,
	(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),a.cantitate/n.coeficient_conversie_1),3) else 0 end),
	(case when tip_miscare='E' then 'I' else 'E' end),(case when tip_miscare='E' then '2' else '3' end),a.gestiune,a.cod_intrare,jurnal,'','',0,'T',
	locatie,data_expirarii,TVA_neexigibil,a.pret_vanzare,0,a.loc_de_munca,a.comanda,(case when a.tip='AP' then a.contract else '' end),'',
	(case when a.tip in ('AI') and isnull(a.lot,'')<>'' then isnull(a.lot,'') when a.tip='AI' then a.grupa else '' end),numar_pozitie,a.cont_de_stoc,a.procent_vama, a.Contract,a.idIntrareFirma,a.idPozDoc
from pozdoc a 
	left outer join gestiuni b on b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune
	left outer join nomencl n on a.cod=n.cod
	left join @cConturi c on a.cont_corespondent=c.cont
where a.subunitate=@cSub and a.tip in ('AI','AP') and (@C35=1 and left(cont_corespondent,2)='35' or @C8=1 and left(cont_corespondent,1)='8')
	and (@subtipGestiune is null or isnull(b.detalii.value('(/row/@custodie)[1]', 'int'),0)=1)
	and isnull(n.tip,'') not in ('R','S') and isnull(b.tip_gestiune,'') not in ('V','I') and (@cCod is null or a.cod=@cCod)
	and (@cGestiune is null or a.tert=@cGestiune)
	and (@grupGestiuni is null or a.tert like @grupGestiuni)
	and (@cCodi is null or cod_intrare=rtrim(@cCodi)) and a.data between @dDataStartPozdoc and @dDataSus
	and isnull(n.grupa,'') like RTrim(@cGrupa) and (@TipStoc='' or @TipStoc='T')
	and (@cCont='' or c.cont is not null) -- and a.cont_corespondent like RTrim(@cCont)+'%'
	and (@Locatie='' or locatie like @Locatie) 
	and (@LM='' or a.loc_de_munca like @LM_like) 
	and (@Comanda='' or a.comanda in('',@Comanda))
	and (@Contract='' or (case when a.tip='AP' then a.contract else '' end) in ('',@Contract))
	and (@Lot='' or (case when a.tip in ('AI') and isnull(a.lot,'')<>'' then isnull(a.lot,'') when a.tip='AI' then a.grupa else '' end) in ('',@Lot))
	--and (@fltGstUt=0 or exists(select 1 from @cGestiuneUtiliz pr where pr.valoare=a.tert))
	and @furnizor=''
	and (@eLmUtiliz=0 or exists(select 1 from @LMUtiliz pr where rtrim(pr.valoare) like rtrim(a.loc_de_munca)+'%' and (@SubgestFolLM=1 or rtrim(pr.marca)=rtrim(a.tert))))


insert into #docstoc (subunitate, gestiune, cont, cod, data, data_stoc, cod_intrare, pret, tip_document, numar_document, cantitate, cantitate_UM2, tip_miscare, in_out, 
			predator, jurnal, tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, 
			data_expirarii, TVA_neexigibil, pret_vanzare, accize_cump, loc_de_munca, comanda, [contract], furnizor, lot, numar_pozitie, cont_corespondent, schimb, idIntrareFirma, idIntrare)
select subunitate, gestiune, cont, cod, data, data, cod_intrare, pret, tip_document, numar_document, cantitate, cantitate_UM2, tip_miscare, in_out,
	(case when tip_document='TE' and rtrim(isnull(contractdinpozdoc_pebune,''))<>'' then contractdinpozdoc_pebune else predator end) predator,	jurnal, tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, 
	data_expirarii, TVA_neexigibil, pret_vanzare, accize_cump, isnull(loc_de_munca,''), comanda, [contract], furnizor, lot, numar_pozitie, cont_corespondent, schimb, idIntrareFirma, idIntrare
from #pozdoc
	where (@grupGestiuni is null or isnull(gestiune,'') like @grupGestiuni)

if @TipStoc='F' and @SubgestFolLM=0 
	update d
		set loc_de_munca=isnull(p.Loc_de_munca,'')
		from #docstoc d
		inner join personal p on d.gestiune=p.marca 

delete #docstoc
	where @Locatie<>'' and locatie not like @Locatie 
		or @LM<>'' and loc_de_munca not like @LM_like 
		or @Comanda<>'' and comanda<>@Comanda 
		or @Contract<>'' and [contract]<>@Contract 
		--or @Furnizor<>'' and furnizor<>@Furnizor 
		or @Lot<>'' and lot<>@Lot


-- fostul fStocuriCen (grupare): 
if @Cen=1
begin
	if @GrCod  is null set @GrCod  = 1
	if @GrGest is null set @GrGest = 1
	if @GrCodi is null set @GrCodi = 1

	create table #docstoccen (subunitate char(9),gestiune char(20),cont varchar(40),cod char(20),data datetime,data_stoc datetime,cod_intrare char(20),pret float,tip_document char(2),
		numar_document char(20),cantitate float,cantitate_UM2 float,tip_miscare char(1),in_out char(1),predator char(20),jurnal char(20),tert char(13),serie char(20),pret_cu_amanuntul float,
		tip_gestiune char(1),locatie char(30),data_expirarii datetime,TVA_neexigibil int, pret_vanzare float,accize_cump float,loc_de_munca char(9),comanda char(40),[contract] char(20),
		furnizor char(13),lot char(20),numar_pozitie int, grp varchar(100), ordineIntrareFirma varchar(30), ordineIntrariCustodie varchar(30), ordineIntrare varchar(30),
		dataG datetime, dataStocG datetime, pretG float, contG varchar(40), dataExpG datetime, pretAmG float, 
		locatieG char(30), lmG char(9), comandaG char(40), contractG char(20), furnizorG char(13), lotG char(20), locatieCustodie char(30),idIntrareFirma int,idIntrare int, idIntrareFirmaG int, idIntrareG int)

	insert #docstoccen
	select subunitate,gestiune,cont,cod,data,data_stoc,cod_intrare,pret,tip_document,numar_document,cantitate,cantitate_UM2,tip_miscare,in_out,predator,jurnal,tert,serie,
		pret_cu_amanuntul,tip_gestiune,(case when tip_miscare='E' then '' else locatie end),data_expirarii,TVA_neexigibil,pret_vanzare,accize_cump,loc_de_munca,comanda,[contract],furnizor,lot,numar_pozitie,
		subunitate+tip_gestiune+gestiune+cod+cod_intrare grp,
		(case when tip_document = 'SI' then '0' else '1' end)+(case when tip_miscare='I' and tip_document not in ('AI','TI') 
			/*SP or tip_miscare='E' and cantitate<0 SP*/ then '0' when tip_document='AI' then '1' else '2' end)
			+(case when tip_miscare='E' and cantitate<0 then '0' else '1' end)
			+convert(char(8),data,112)+str(numar_pozitie) ordineIntrareFirma, 	-- SI, apoi intrari (exclusiv TI), apoi AI, apoi iesiri
		(case when tip_miscare='I' and tip_document<>'AI' or tip_miscare='E' and cantitate<0 then '2' when tip_document = 'SI' then '1' else '0' end)
			+convert(char(8),data,112)+str(numar_pozitie) ordineIntrariCustodie, -- iesiri, apoi SI, apoi intrari = ordinea pt. "ultima intrare"
		(case when tip_document = 'SI' then '0' else '1' end)+(case when tip_miscare='I' and tip_document not in ('AI') 
			/*or tip_miscare='E' and cantitate<0*/ then '0' when tip_document='AI' then '1' else '2' end)
			+(case when tip_miscare='E' and cantitate<0 then '0' else '1' end)
			+convert(char(8),data,112)+str(numar_pozitie) ordineIntrare ,-- SI, apoi intrari (inclusiv TI),apoi AI, apoi iesiri
		'01/01/2999', '01/01/2999', 0, '', '01/01/2999', 0, '', '', '', '', '', '', '',idIntrareFirma,idIntrare, null, null
	from #docstoc
	--> pret vanzare este pretul de pe documentul primar; nu e pret vanzare de afisat.
	
	--> se actualizeaza datele pe grupari in functie de regulile specificate pentru campul "ordineIntrareFirma":
	update d
	set 
		dataG=data, dataStocG=data_stoc, pretG=pret, contG=cont, dataExpG=data_expirarii, pretAmG=pret_cu_amanuntul, 
		locatieG=locatie, lmG=loc_de_munca, comandaG=comanda, contractG=[contract], furnizorG=furnizor, lotG=lot,
		idIntrareFirmaG=idIntrareFirma, idIntrareG=idIntrare
	from #docstoccen d, (select d2.grp, min(d2.ordineIntrareFirma) as ordine from #docstoccen d2 group by d2.grp) d1
	where d.grp=d1.grp and d.ordineIntrareFirma=d1.ordine

	--> se actualizeaza datele pe grupari in functie de regulile specificate pentru campul "ordineIntrare":
	update d
	set 
		dataG=ISNULL(d.data, dataG), dataStocG=ISNULL(d.data_stoc, dataStocG), contG=ISNULL(d.cont,contG), pretAmG=ISNULL(d.pret_cu_amanuntul,pretAmG), 
		locatieG=ISNULL(d.locatie,locatieG), lmG=ISNULL(d.loc_de_munca,lmG), comandaG=ISNULL(d.comanda,comandaG), 
		idIntrareG=ISNULL(d.idIntrare,idIntrareG)
	from #docstoccen d, (select d2.grp, min(d2.ordineIntrare) as ordine from #docstoccen d2 group by d2.grp) d1
	where d.grp=d1.grp and d.ordineIntrare=d1.ordine

	-- locatia pt. custodie e luata de pe ULTIMUL document de intrare, altfel ramane null 
	update d
	set locatieCustodie=locatie
	from #docstoccen d 
	inner join (select d2.grp, max(d2.ordineIntrariCustodie) as ordineIntrariCustodie from #docstoccen d2 group by d2.grp) d1 on d.grp=d1.grp and d.ordineIntrariCustodie=d1.ordineIntrariCustodie
	inner join gestiuni g on g.subunitate=d.subunitate and g.cod_gestiune=d.gestiune and isnull(g.detalii.value('(/row/@custodie)[1]', 'int'),0)=1
	
	truncate table #docstoc
	insert into #docstoc (subunitate, gestiune, tip_gestiune, cod, data, data_stoc, cod_intrare, pret, stoc_initial, intrari, iesiri,
			data_ultimei_iesiri, stoc, cont, data_expirarii, tva_neexigibil, pret_cu_amanuntul, locatie, loc_de_munca,
			comanda, [contract], furnizor, lot, valoare_stoc, stoc_initial_UM2, intrari_UM2, iesiri_UM2, stoc_UM2, idIntrareFirma, idIntrare)
	select
		subunitate,
		max(case when @GrGest=1 then gestiune else '' end) gestiune,
		max(case when @GrGest=1 then tip_gestiune when tip_gestiune in ('F', 'T') then tip_gestiune else '' end) tip_gestiune,
		max(case when @GrCod=1 then cod else '' end) cod,
		min(dataG) data, min(case when tip_miscare='I' then data_stoc else '2999-12-31' end) data_stoc, max(case when @GrCodi=1 then cod_intrare else '' end) cod_intrare,
		max(pretG) pret,
		sum(round(convert(decimal(15,5), case when tip_document='SI' then cantitate else 0 end), 3)) stoc_initial,
		sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='I' then cantitate else 0 end), 3)) intrari,
		sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='E' then cantitate else 0 end), 3)) iesiri,
		max(case when tip_miscare='E' then data else '01/01/1901' end) data_ultimei_iesiri,
		sum(round(convert(decimal(15,5), (case when tip_miscare='E' then -1 else 1 end)*cantitate), 3)) stoc,
		max(contG) cont, min(dataExpG) data_expirarii, max(TVA_neexigibil) tva_neexigibil,
		max(case when @AccDVI=1 and tip_miscare='I' and accize_cump<>0 and tip_document<>'AI' 
			and tip_gestiune<>'A' then accize_cump else pretAmG end) pret_cu_amanuntul,
		(case when max(locatieCustodie)='' then max(locatieG) else max(locatieCustodie) end) locatie, max(lmG) loc_de_munca, max(comandaG) comanda, max(contractG) contract, max(furnizorG) furnizor, max(lotG) lot,
		sum(round(convert(decimal(17, 5), (case when tip_miscare='E' then -1 else 1 end)*cantitate*pret), 2)) valoare_stoc,
		sum(round(convert(decimal(15,5), case when tip_document='SI' then cantitate_UM2 else 0 end), 3)) stoc_initial_UM2,
		sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='I' then cantitate_UM2 else 0 end), 3)) intrari_UM2,
		sum(round(convert(decimal(15,5), case when tip_document<>'SI' and tip_miscare='E' then cantitate_UM2 else 0 end), 3)) iesiri_UM2,
		sum(round(convert(decimal(15,5), (case when tip_miscare='E' then -1 else 1 end)*cantitate_UM2), 3)) stoc_UM2,MIN(idIntrareFirmaG),MIN(idIntrareG)
	from #docstoccen
	group by subunitate,
	(case when @GrGest=1 then gestiune else '' end),
	(case when @GrCod=1 then cod else '' end),
	(case when @GrCodi=1 then cod_intrare else '' end),
	(case when @GrGest=1 then tip_gestiune when tip_gestiune in ('F', 'T') then tip_gestiune else '' end)	
end
