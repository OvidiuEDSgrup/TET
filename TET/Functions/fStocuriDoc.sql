--***
create function  fStocuriDoc(@DIst datetime,@DJPdoc datetime,@DSus datetime,
	@Cod char(20),@Gest char(20),@Codi char(20),@Grupa char(13),@TipStoc char(1),@Cont char(13),@Corel int,
	@Loc char(30),@LM char(9),@Com char(40),@Cntr char(20),@Furn char(13),@Lot char(20))
	
returns @docstoc table
(subunitate char(9),gestiune char(20),cont char(20),cod char(20),data datetime,cod_intrare char(20),
	pret float,tip_document char(2),numar_document char(9),cantitate float,cantitate_UM2 float,
	tip_miscare char(1),in_out char(1),predator char(20),
	codi_pred char(20), jurnal char(3),tert char(13),serie char(20),pret_cu_amanuntul float,
	tip_gestiune char(1),locatie char(30),data_expirarii datetime,TVA_neexigibil int,
	pret_vanzare float,accize_cump float,loc_de_munca char(9),comanda char(40),
	[contract] char(20),furnizor char(13),lot char(20),numar_pozitie int,cont_corespondent char(13),
	schimb int, contractdinpozdoc_pebune varchar(20))
as
begin
declare @Sb char(13),@C35 int,@C8 int,@UM2 int,@PrestTE int,@SFL int
select	@Sb=max(case when p.parametru='SUBPRO' then p.val_alfanumerica else '' end),
		@C35=max(case when p.parametru='STCUST35' then p.val_logica else 0 end),
		@C8=max(case when p.parametru='STCUST8' then p.val_logica else 0 end),
		@PrestTE=max(case when p.parametru='PRESTTE' then p.val_logica else 0 end),
		@UM2=max(case when p.parametru='URMCANT2' then p.val_logica else 0 end),
		@SFL=max(case when p.parametru='SUBGLMFOL' then p.val_logica else 0 end)
from par p where tip_parametru='GE' and parametru in ('SUBPRO','STCUST35','STCUST8','PRESTTE','URMCANT2','SUBGLMFOL')
--/*
select @cont=rtrim(isnull(@cont,''))
declare @conturi table (cont varchar(50))
insert into @conturi(cont)
select cont from arbconturi(@cont)
--*/
	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @utilizator varchar(20), @fltGstUt int, @eLmUtiliz int
select @utilizator=dbo.fIaUtilizator('')
declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
insert into @GestUtiliz (valoare,cod)
select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'' and @TipStoc<>'F'
set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
declare @LmUtiliz table(valoare varchar(200), marca varchar(20))
insert into @LmUtiliz(valoare, marca)
select l.cod valoare, p.marca
	from lmfiltrare l 
	left join personal p on (@sfl=1 or rtrim(l.cod)=rtrim(p.loc_de_munca))
	where l.utilizator=@utilizator and l.cod<>'' and @TipStoc='F'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

insert @docstoc (subunitate, gestiune, cont, cod, data, cod_intrare, pret, tip_document,
	numar_document,	cantitate, cantitate_UM2, tip_miscare, in_out, predator, codi_pred, jurnal,
	tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, data_expirarii, TVA_neexigibil,
	pret_vanzare, accize_cump, loc_de_munca, comanda,	contract, furnizor, lot, numar_pozitie,
	cont_corespondent, schimb, contractdinpozdoc_pebune)
select subunitate,cod_gestiune,i.cont,i.cod,data,cod_intrare,pret,'SI',
	'',i.stoc,(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),i.stoc/n.coeficient_conversie_1),3)
		when @UM2=0 or left(isnull(n.UM_2,''),1)<>'Y' then 0 else i.stoc_UM2 end),'I','1','','','','','',i.pret_cu_amanuntul,tip_gestiune,locatie,data_expirarii,
		TVA_neexigibil,i.pret_vanzare,0,i.loc_de_munca,comanda,i.contract,i.furnizor,lot,0,'',0,
	'' Contract
from istoricstocuri i
	left outer join nomencl n on i.cod=n.cod
	left join @conturi c on c.cont=i.cont
where @Corel<>1 and data_lunii=@DIst and subunitate=@Sb and tip_gestiune not in ('V','I') and (@Cod is null or i.cod=rtrim(@Cod))
	and (@Gest is null or cod_gestiune=@Gest) and (@Codi is null or cod_intrare=rtrim(@Codi)) and isnull(n.grupa,'') like RTrim(@Grupa)
	and (@TipStoc='' or @TipStoc='D' and i.tip_gestiune not in ('F','T') or i.tip_gestiune=@TipStoc)	
	and (@cont='' or c.cont is not null) --and i.cont like RTrim(@Cont)+'%'
	and (@Loc='' or locatie in ('',@Loc)) and (@LM='' or i.loc_de_munca in ('',@LM)) and (@Com='' or comanda in('',@Com))
	and (@Cntr='' or i.contract in ('',@Cntr)) and (@Furn='' or i.furnizor in ('',@Furn)) and (@Lot='' or lot in ('',@Lot))
	and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=i.cod_gestiune))
	and (@eLmUtiliz=0 or 
		exists(select 1from @LMUtiliz pr
		where rtrim(pr.valoare) like rtrim(i.loc_de_munca)+'%' and (@sfl=1 or rtrim(pr.marca)=rtrim(i.cod_gestiune))))

union all
select a.subunitate,a.gestiune,a.cont_de_stoc,a.cod,a.data,a.cod_intrare,a.pret_de_stoc,a.tip,a.numar,a.cantitate,
	(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),
		a.cantitate/n.coeficient_conversie_1),3) when a.tip in ('PF','CI','AF') or @UM2=0 or left(isnull(n.UM_2,''),1)<>'Y'
		then 0 when a.tip='RM' and a.numar_DVI<>'' then a.accize_datorate else a.suprataxe_vama end), a.tip_miscare,
	(case when a.tip_miscare='I' then '2' else '3' end),a.gestiune_primitoare,
	(case when a.tip not in ('TE','DF','PF') then '' when a.grupa='' then a.cod_intrare else a.grupa end),a.jurnal,
	(case when a.tip in ('RM','AP') then a.tert when a.tip in ('AI','AE') then left(a.factura,13) else a.loc_de_munca end),'',
	(case when a.tip_miscare='I' then a.pret_cu_amanuntul else a.pret_amanunt_predator end),
	(case when a.tip in ('PF','CI','AF') then 'F' else isnull(b.tip_gestiune,'') end),
	(case when a.tip in ('TE','DF','PF') then isnull(s.locatie,a.locatie) else a.locatie end),
	(case when a.tip in ('TE','DF','PF') then isnull(s.data_expirarii,a.data_expirarii) else a.data_expirarii end),
	a.TVA_neexigibil,(case when a.tip_miscare='I' then a.pret_amanunt_predator when a.tip in ('AP','AC') then a.pret_vanzare else a.pret_cu_amanuntul end),
	a.accize_cumparare,(case when @SFL=1 and a.tip in ('PF','CI') then isnull(s.loc_de_munca,'') else a.loc_de_munca end),
	a.comanda,(case when a.tip='TE' then a.factura when a.tip in ('AP','AC','PP') then a.contract else '' end),
	(case a.tip when 'RM' then a.tert when 'AI' then a.cont_venituri else '' end),
	(case when a.tip='RM' then a.cont_corespondent when a.tip in ('PP','AI') then a.grupa else '' end),a.numar_pozitie,
	(case when a.tip in ('RM','RS') then a.cont_factura else a.cont_corespondent end),a.procent_vama, a.contract
from pozdoc a
	left join @conturi c on a.cont_de_stoc=c.cont
	left outer join gestiuni b on a.tip not in ('PF','CI','AF') and b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune
	left outer join nomencl n on a.cod=n.cod
	left outer join stocuri s on a.tip in ('TE','DF','PF','CI') and s.subunitate=a.subunitate and s.cod_gestiune=a.gestiune and
		s.tip_gestiune=(case when a.tip in ('DF','PF','CI') then 'F' else b.tip_gestiune end) and s.cod=a.cod and s.cod_intrare=a.cod_intrare
where a.subunitate=@Sb and a.tip_miscare between 'E' and 'I' and (a.tip in ('PF','CI','AF') or isnull(b.tip_gestiune,'')<>'I'
	and (@Corel=1 or isnull(b.tip_gestiune,'')<>'V')) and isnull(n.tip,'') not in ('R','S') and a.data between @DJPdoc and @DSus
	and (@Cod is null or a.cod=@Cod) and (@Gest is null or a.gestiune=@Gest) and (@Codi is null or a.cod_intrare=rtrim(@Codi))
	and isnull(n.grupa,'') like RTrim(@Grupa)
	and (@cont='' or c.cont is not null)
	and (@TipStoc='' or @TipStoc='D' and a.tip not in ('PF','CI','AF') or @TipStoc='F' and a.tip in ('PF','CI','AF'))
	and (@Loc='' or (case when a.tip in ('TE','DF','PF') then isnull(s.locatie,a.locatie) else a.locatie end) in ('',@Loc))
	and (@LM='' or (case when @SFL=1 and a.tip in ('PF','CI') then isnull(s.loc_de_munca,'') else a.loc_de_munca end) like rtrim(@LM)+'%')
	and (@Com='' or a.comanda in('',@Com))
	and (@Cntr='' or (case when a.tip='TE' then a.factura when a.tip in ('AP','AC','PP') then a.contract else '' end) in ('',@Cntr))
	and (@Furn='' or (case a.tip when 'RM' then a.tert when 'AI' then a.cont_venituri else '' end) in ('',@Furn))
	and (@Lot='' or (case when a.tip='RM' then a.cont_corespondent when a.tip in ('PP','AI') then a.grupa else '' end) in ('',@Lot))
	and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=a.gestiune))
	and (@eLmUtiliz=0 or 
		exists(select 1from @LMUtiliz pr --inner join personal p on (@sfl=1 or pr.valoare=p.loc_de_munca and p.marca=a.gestiune)
			where rtrim(pr.valoare) like rtrim(case when @SFL=1 and a.tip in ('PF','CI') then isnull(s.loc_de_munca,'') else a.loc_de_munca end)+'%'
					and (@sfl=1 or rtrim(pr.marca)=rtrim(a.gestiune))))
union all
select a.subunitate,a.gestiune_primitoare,a.cont_corespondent,a.cod,a.data,(case when a.grupa='' then a.cod_intrare else a.grupa end),
		(case when a.tip='TE' and @PrestTE=1 and a.accize_datorate<>0 then accize_datorate else a.pret_de_stoc end)*
			(case when a.tip='DF' and a.procent_vama>0 then (1-convert(decimal(12,3),a.procent_vama/100)) else 1 end),
		(case a.tip when 'DF' then 'DI' when 'PF' then 'PI' else 'TI' end),a.numar,a.cantitate,
		(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),a.cantitate/n.coeficient_conversie_1),3)
			when a.tip in ('DF','PF') or @UM2=0 or left(isnull(n.UM_2,''),1)<>'Y' then 0 else a.suprataxe_vama end),'I','2',a.gestiune,a.cod_intrare,
		a.jurnal,'','',a.pret_cu_amanuntul,(case when a.tip in ('DF','PF') then 'F' else isnull(tip_gestiune,'') end),a.locatie,a.data_expirarii,
		a.TVA_neexigibil,a.pret_amanunt_predator,a.accize_cumparare,a.loc_de_munca,a.comanda,(case when a.tip='TE' then a.factura else '' end),'','',
		a.numar_pozitie,a.cont_de_stoc,a.procent_vama, a.contract
from pozdoc a
	left outer join gestiuni b on a.tip not in ('DF','PF') and b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune_primitoare
	left outer join nomencl n on a.cod=n.cod
	left join @conturi c on a.cont_corespondent=c.cont
where a.subunitate=@Sb and (a.tip in ('DF','PF') or a.tip='TE' and isnull(tip_gestiune,'') not in ('V','I'))
	and isnull(n.tip,'') not in ('R','S') and (@Cod is null or a.cod=@Cod) and (@Gest is null or gestiune_primitoare=@Gest)
	and (@Codi is null or (case when a.grupa='' then a.cod_intrare else a.grupa end)=rtrim(@Codi)) and a.data between @DJPdoc and @DSus
	and isnull(n.grupa,'') like RTrim(@Grupa) and (@TipStoc='' or @TipStoc='D' and a.tip='TE' or @TipStoc='F' and a.tip in ('DF','PF'))
	and (@cont='' or c.cont is not null) --and a.cont_corespondent like RTrim(@Cont)+'%'
	and (@Loc='' or a.locatie in ('',@Loc)) and (@LM='' or a.loc_de_munca in ('',@LM)) and (@Com='' or a.comanda in('',@Com))
	and (@Cntr='' or (case when a.tip='TE' then a.factura else '' end) in ('',@Cntr))
	and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=a.gestiune_primitoare))
	and (@eLmUtiliz=0 or 
		exists(select 1from @LMUtiliz pr
			where rtrim(pr.valoare) like rtrim(a.loc_de_munca)+'%' and (@sfl=1 or rtrim(pr.marca)=rtrim(a.gestiune_primitoare))))
union all
select a.subunitate,a.tert,cont_corespondent,a.cod,a.data,cod_intrare,a.pret_de_stoc,a.tip,numar,a.cantitate,
	(case when @UM2=0 and isnull(n.UM_1,'')<>'' and isnull(n.coeficient_conversie_1,0)<>0 then round(convert(decimal(17,5),a.cantitate/n.coeficient_conversie_1),3) else 0 end),
	(case when tip_miscare='E' then 'I' else 'E' end),(case when tip_miscare='E' then '1' else '2' end),a.gestiune,a.cod_intrare,jurnal,'','',0,'T',
	locatie,data_expirarii,TVA_neexigibil,a.pret_vanzare,0,a.loc_de_munca,a.comanda,(case when a.tip='AP' then a.contract else '' end),'',
	(case when a.tip='AI' then a.grupa else '' end),numar_pozitie,a.cont_de_stoc,a.procent_vama, a.Contract
from pozdoc a 
	left outer join gestiuni b on b.subunitate=a.subunitate and b.cod_gestiune=a.gestiune
	left outer join nomencl n on a.cod=n.cod
	left join @conturi c on a.cont_corespondent=c.cont
where a.subunitate=@Sb and a.tip in ('AI','AP') and (@C35=1 and left(cont_corespondent,2)='35' or @C8=1 and left(cont_corespondent,1)='8')
	and isnull(n.tip,'') not in ('R','S') and isnull(tip_gestiune,'') not in ('V','I') and (@Cod is null or a.cod=@Cod)
	and (@Gest is null or a.tert=@Gest) and (@Codi is null or cod_intrare=rtrim(@Codi)) and a.data between @DJPdoc and @DSus
	and isnull(n.grupa,'') like RTrim(@Grupa) and (@TipStoc='' or @TipStoc='T')
	and (@cont='' or c.cont is not null) -- and a.cont_corespondent like RTrim(@Cont)+'%'
	and (@Loc='' or locatie in ('',@Loc)) and (@LM='' or a.loc_de_munca in ('',@LM)) and (@Com='' or a.comanda in('',@Com))
	and (@Cntr='' or (case when a.tip='AP' then a.contract else '' end) in ('',@Cntr))
	and (@Lot='' or (case when a.tip='AI' then a.grupa else '' end) in ('',@Lot))
	and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=a.tert))
	and (@eLmUtiliz=0 or 
		exists(select 1from @LMUtiliz pr --inner join personal p on (@sfl=1 or pr.valoare=p.loc_de_munca and p.marca=a.tert)
			where rtrim(pr.valoare) like rtrim(a.loc_de_munca)+'%' and (@sfl=1 or rtrim(pr.marca)=rtrim(a.tert))))
return
end