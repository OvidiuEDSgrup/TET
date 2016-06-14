--***
--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'yso_pdocTVACump') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP procedure yso_pdocTVACump
GO
--***
create procedure yso_pdocTVACump
(@DataJ datetime,@DataS datetime,@ContF char(200),@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor char(13),@TVAnx int,@RecalcBaza int,@nTVAex int,@FFFBTVA0 char(1),@SFTVA0 char(1),@IAFTVA0 int,
@TipCump int, -- 1=toate, 2=intern si import, 3=intracom. si taxare inversa, 9=declaratia 394
@TVAAlteCont int, -- 0=doar cu cont de TVA setat, 1=doar cele cu cont TVA diferit de setare, 2=nu conteaza contul de TVA
@DVITertExt int,@OrdDataDoc int,@Tert char(13),@Factura char(20),@UnifFact int,@FaraVanz int,@nTVAned int, @parXML xml)
as
declare @dtva table
(subunitate char(9),numar char(10),numarD varchar(13),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,explicatii varchar(50),tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(30),drept_ded varchar(1),cont_TVA varchar(13),cont_coresp char(13),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf char(13))
begin
declare @Sb char(9),@CotaTVA int,@RotRM int,@Ct4426 char(13),@Ct4428 char(13),@AccImpDVI int,@ContFactVama int,@Bugetari int,@AgrArad int,@IFN int,@ListaContF int,@ContFFlt char(13), @PrimTM int, @Fara44 int,
	@marcaj int

select @marcaj=isnull(@parXML.value('(row/@marcaj)[1]','int'),0)
set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')
set @CotaTVA=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='COTATVA'),0)
set @RotRM=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ROTUNJR'),2)
set @IFN=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='IFN'),0)
set @Ct4426=left(isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CDTVA'),''),@IFN+4)
set @Ct4428=left(isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CNEEXREC'),''),@IFN+4)
set @AccImpDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='ACCIMP'),0)
set @ContFactVama=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CONTFV'),0)
set @Bugetari=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='BUGETARI'),0)
set @AgrArad=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='AGRIRARAD'),0)
set @PrimTM=isnull((select max(cast(val_logica as int)) from par where tip_parametru='SP' and parametru='PRIMTIM'),0)
set @ListaContF=(case when charindex(';',@ContF)>0 then 1 else 0 end)
set @ContFFlt=(case when @ListaContF=0 then @ContF else '' end)
set @Fara44=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='FARA44'),0)
if @TVAAlteCont is null
	set @TVAAlteCont=0
	/**	Pregatire filtrare pe lm configurate pe utilizatori*/
declare @utilizator varchar(20), @eLmUtiliz int
select @utilizator=dbo.fIaUtilizator('')
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
select --* from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
	cod from lmfiltrare where utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	
insert @dtva
select a.subunitate,a.numar+'  ',a.numar+space(5),case when a.tip='RP' then 'RM' else a.tip end,
	case when @OrdDataDoc=1 then a.data else isNull(a.data_facturii,a.data) end,a.factura,a.tert,
	(CASE WHEN a.tip='RS' and a.pret_valuta<0.01 
	THEN round(convert(decimal(17,2),a.TVA_deductibil*100/@CotaTVA),2) 
	ELSE round(convert(decimal(17,5),a.cantitate*(case when a.tip='RM' and a.jurnal='RC' 
	then round(a.pret_valuta*(1-convert(decimal(12,0),a.cota_TVA)/convert(decimal(12,0),100+a.cota_TVA)),5) 
	when a.valuta='' or a.tip='RP' then round(a.pret_valuta*round(convert(decimal(15,4),1+a.discount/100),4),5) 
	else round(a.pret_valuta*a.curs*round(1+a.discount/100,4),5) end)),@RotRM) END) as valoare_factura,
	(case when a.cota_tva<>0 then (case when @RecalcBaza=0 then (case when a.tip='RS' 
	and a.pret_valuta<0.01 then round(convert(decimal(17,2),a.TVA_deductibil*100/@CotaTVA),2) 
	else round(convert(decimal(17,5),a.cantitate*(case when a.tip='RM' and a.jurnal='RC' 
	then round(a.pret_valuta*(1-convert(decimal(12,0),a.cota_TVA)/convert(decimal(12,0),100+a.cota_TVA)),5) 
	when a.valuta='' or a.tip='RP' then round(a.pret_valuta*round(convert(decimal(15,4),1+a.discount/100),4),5) 
	else round(a.pret_valuta*a.curs*(1+convert(decimal(17,5),a.discount/100)),5) end)),@RotRM) end) 
	ELSE round((case when a.cota_tva<>0 then convert(decimal(17,3),a.tva_deductibil*100/a.cota_tva) 
	else 0 end),@RotRM) END) else 0 end) as baza_22,a.tva_deductibil as tva_22,space(50),'',
	(case when a.tip='RS' and a.pret_valuta<0.01 then @CotaTVA else a.cota_tva end),0,0,a.data,'','',
	a.cont_venituri,a.cont_de_stoc,(case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') 
	and a.procent_vama=1 then 1 else 0 end),'C',a.numar_pozitie,(case when a.tip='RM' and a.jurnal='RC' 
	then 'RC' else a.tip end),a.cod,'',a.cont_factura
from pozdoc a
	left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
--	tabela facturi nu pare a fi folosita justificat:
		--left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
where a.subunitate=@Sb and a.tip in ('RM','RP','RS','RQ') 
	and @nTVAex in (0,(case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') 
		and a.procent_vama=1 then 1 else 2 end)) 
	and ((@TipCump<>9  or a.data_facturii='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_facturii between @DataJ and @DataS)
	and a.cont_factura like rtrim(@ContFFlt)+'%' and a.cont_factura<>'' 
	and @nTVAned in (2, (case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') 
		and a.procent_vama in (2,3) then 1 else 0 end)) 
	and (/*@Bugetari=1 or */@TVAnx=0 and left(a.cont_factura,3)<>'408' 
	and (@TVAAlteCont=0 and (left(a.cont_venituri,4)='    ' or a.cont_venituri like RTrim(@Ct4426)+'%' 
							or @PrimTM=0 and @Bugetari=1 and left(a.cont_venituri, 1)='6') 
		or @TVAAlteCont=1 and left(a.cont_venituri,4)<>'    ' and a.cont_venituri not like RTrim(@Ct4426)+'%' 
							and not (@PrimTM=0 and @Bugetari=1 and left(a.cont_venituri, 1)='6')
		or @TVAAlteCont=2) 
	or @TVAnx=1 and (a.cont_factura like '408%' /*or a.cont_venituri like RTrim(@Ct4428)+'%'*/)) 
	and a.cont_de_stoc like rtrim(@ContCor)+'%' 
	and (@TipCump in (1,9) or @TipCump=2 and left((case when a.tip='RP' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tip='RM' and a.numar=b.numar and a.data=b.data) else a.cont_de_stoc end),3)<>'371'
					or @TipCump=3 and left((case when a.tip='RP' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tip='RM' and a.numar=b.numar and a.data=b.data) else a.cont_de_stoc end),3)='371') 
	and (@Gest='' or a.gestiune=@Gest) 
	and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') 
	and not (a.tip='RM' and a.tip_miscare<>'V' and a.numar_DVI<>'' and a.numar_DVI in (select numar_DVI from DVI where subunitate=a.subunitate and numar_receptie=a.numar)) 
	and left(a.cont_de_stoc,1)<>'8' and (@Fara44=0 or left(a.cont_de_stoc,2)<>'44') 
	and (@Jurnal='' or a.jurnal=@Jurnal) 
	and not (a.tip='RQ' and (a.valuta<>'' or abs(a.tva_deductibil)<0.01)) 
	and not (a.tip='RM' and left(a.cont_factura,3)='167' and a.jurnal='MFX' and @IAFTVA0=0 and abs(a.tva_deductibil)<0.01) 
	and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura) 
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
	and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
union all 
select a.subunitate,a.numar,a.numar,a.tip,a.data,a.numar,'',round(a.pret_de_stoc*a.cantitate,@RotRM),round((case when a.cota_tva<>0 then convert(decimal(17,2),a.tva_deductibil*100/a.cota_tva) else 0 end),@RotRM),a.tva_deductibil,left(a.factura, 8)+left(a.contract, 8),'',a.cota_tva,0,0,a.data,'','',@Ct4426,a.cont_de_stoc,0,'C',a.numar_pozitie,a.tip,a.cod,'',a.cont_intermediar
from pozdoc a
	left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
where @nTVAex in (0,2) and @nTVAned in (0,2) and a.subunitate=@Sb and a.tip='AI' and a.tva_deductibil<>0 and @TVAAlteCont<>1 and 
		((@TipCump<>9  or a.Data_facturii='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_facturii between @DataJ and @DataS) and a.cont_intermediar like rtrim(@ContFFlt)+'%' and (@TVAnx=0 and left(a.cont_intermediar,3)<>'408' or @TVAnx=1 and a.cont_intermediar like '408%') and a.cont_de_stoc like rtrim(@ContCor)+'%' and 
		(@TipCump in (1,9) or @TipCump=2 and left(a.cont_de_stoc,3)<>'371' or @TipCump=3 and a.cont_de_stoc like '371%')
		and (@Gest='' or a.gestiune=@Gest) 
	and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and @Tert='' and (@Factura='' or a.numar=@Factura)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
	and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
select * from @dtva
if @marcaj in (0,2)
begin
	--if @TipCump<>9
	--	insert @dtva select * from dbo.yso_pdocTVACumpDVI(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,@CotaTVA,@AccImpDVI,@ContFactVama,@AgrArad,@nTVAned)
	insert @dtva select * from dbo.yso_pdocTVACumpAdoc(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@Tert,@Factura,@CotaTVA,@Ct4426,@Ct4428,@nTVAned)
	--print 'dd'
end

if @nTVAex in (0, 1) and @FaraVanz=0 and @nTVAned<>1
	insert @dtva -- pentru vanzari cu TVA exonerat
	select * from dbo.docTVAVanz(@DataJ,@DataS,@ContFFlt,0,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,'','',1,@FFFBTVA0,0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,0,@Tert,@Factura,0,1, @parXML)
	where exonerat=1 /*ca 2 e TVA neinregistrat)*/
if @ListaContF=1 begin
	declare @lc table (cont char(13))
	insert @lc 
	select left([Item],13) from dbo.Split(@ContF, ';')
	
	delete @dtva 
	from @dtva d 
	where not exists (select 1 from @lc l where d.contf like RTrim(l.cont)+'%')
end
if @FaraVanz=1 and exists (select 1 from sysobjects where [type]='TF' and [name]='yso_pdocTVACumpSP')
	insert @dtva select * from dbo.yso_pdocTVACumpSP(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@Tert,@Factura,@CotaTVA,@Ct4426,@Ct4428,@nTVAned)

if @UnifFact=1
	update @dtva
	set factura=left(factura,PATINDEX('%[ .,/A-Z]%',right(rtrim(factura),len(factura)-1)))
	where len(factura)>1 and PATINDEX('%[ .,/A-Z]%',right(rtrim(factura),len(factura)-1))>0
select * from @dtva
end
