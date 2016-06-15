--***
create function yso_pdocTVACumpDVI
(@Sb char(9),@DataJ datetime,@DataS datetime,@ContF char(13),@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor char(13),@TVAnx int,@RecalcBaza int,@nTVAex int,
@TipCump int,	-- 1=toate, 2=intern si import, 3=intracom. si taxare inversa, 9=declaratia 394
@TVAAlteCont int,@DVITertExt int,@OrdDataDoc int,@Tert char(13),@Factura char(20),@CotaTVA int,@AccImpDVI int,@ContFactVama int,@AgrArad int,@nTVAned int)
returns @dtva table
(subunitate char(9),numar char(10),numarD varchar(13),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,explicatii varchar(50),tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(30),drept_ded varchar(1),cont_TVA varchar(13),cont_coresp char(13),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf char(13))
begin
	/**	Pregatire filtrare pe lm configurate pe utilizatori*/
declare @utilizator varchar(20), @eLmUtiliz int
select @utilizator=dbo.fIaUtilizator('')

declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
select cod from lmfiltrare l where l.utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

insert @dtva
select b.subunitate,b.numar_receptie,b.numar_receptie,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),(case when @OrdDataDoc=1 then b.data_DVI else isNull(e.Data_facturii,b.data_DVI) end),b.factura_CIF,b.tert_CIF,b.valoare_CIF,round(convert(decimal(17,2),b.tva_CIF *100/@CotaTVA),2),b.tva_CIF,'','',@CotaTVA,0,0,(case when e.tip in ('RM','RS') then e.data else b.data_receptiei end),'','','',isnull((select max(p.cont_de_stoc) from pozdoc p where p.subunitate=e.subunitate and p.tip=e.tip and p.numar=e.numar and p.data=e.data), ''),0,'C',0,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),'','',b.cont_CIF
from DVI b
--	tabela facturi nu pare a fi folosita justificat:
		--left outer join facturi c on c.tip=0x54 and b.subunitate=c.subunitate and b.factura_CIF=c.factura and b.tert_CIF=c.tert
left outer join doc e on b.subunitate=e.subunitate and e.tip in ('RM','RS') and b.numar_receptie=e.numar and b.data_DVI=e.data 
where @nTVAex in (0,2) and @nTVAned in (0,2) and b.subunitate=@Sb and 
	((@TipCump<>9  or e.Data_facturii='1901-1-1') and b.data_DVI between @DataJ and @DataS or @TipCump=9 and e.Data_facturii between @DataJ and @DataS)
	and b.cont_CIF like rtrim(@ContF)+'%' and b.tert_CIF<>'' and b.cont_CIF<>'' and (@TVAnx=0 and left(b.cont_CIF,3)<>'408' and left(e.gestiune_primitoare,4)<>'4428' or @TVAnx=1 and (b.cont_CIF like '408%' or e.gestiune_primitoare like '4428%')) and b.valuta_CIF='' and @TipCump in (1,3,9) and (@Gest='' or e.cod_gestiune=@Gest)
	and (@LMExcep=0 and e.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and e.loc_munca not like rtrim(@LM)+'%') and @TVAAlteCont<>1 and (@Jurnal='' or e.jurnal=@Jurnal) and (@Tert='' or b.tert_CIF=@Tert) and (@Factura='' or b.factura_CIF=@Factura)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=e.Loc_munca))
UNION ALL 
select b.subunitate,b.numar_receptie,b.numar_receptie,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),(case when @OrdDataDoc=1 then b.data_receptiei else isNull(e.Data_facturii,b.data_receptiei) end),(case when @DVITertExt=0 then b.factura_vama when @AgrArad=1 then b.numar_DVI else e.factura end),(case when @DVITertExt=0 then b.tert_vama else isnull(e.cod_tert,b.tert_receptie) end),b.val_fara_comis+b.dif_vama+b.dif_com_vam +(case when @AccImpDVI=1 then b.TVA_11 else 0 end) -(case when b.valuta_CIF='' then b.valoare_CIF else 0 end),(case when @RecalcBaza=0 then b.val_fara_comis+b.dif_vama+b.dif_com_vam +(case when @AccImpDVI=1 then b.TVA_11 else 0 end) else round(convert(decimal(17,2),(b.valoare_tva-b.tva_CIF) *100/@CotaTVA),2) end),b.valoare_tva-b.tva_CIF,'','',@CotaTVA,0,0,(case when e.tip in ('RM','RS') then e.data else b.data_receptiei end),'','','',isnull((select max(p.cont_de_stoc) from pozdoc p where p.subunitate=e.subunitate and p.tip=e.tip and p.numar=e.numar and p.data=e.data), ''),(case when b.total_vama=1 then 1 else 0 end),'C',0,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),'','',b.cont_tert_vama
from DVI b
left outer join doc e on b.subunitate=e.subunitate and e.tip in ('RM','RS') and b.numar_receptie=e.numar and b.data_DVI=e.data 
--	tabela facturi nu pare a fi folosita justificat:
			--left outer join facturi c on c.tip=0x54 and b.subunitate=c.subunitate and b.factura_vama=c.factura and (case when @DVITertExt=0 then b.tert_vama else isnull(e.cod_tert,b.tert_receptie) end)=c.tert
where @nTVAex in (0,(case when b.total_vama=1 then 1 else 2 end)) and @nTVAned in (2,(case when b.total_vama=2 then 1 else 0 end)) and b.factura_comis in ('','D') and b.subunitate=@Sb and 
	((@TipCump<>9  or e.Data_facturii='1901-1-1') and b.data_DVI between @DataJ and @DataS or @TipCump=9 and e.Data_facturii between @DataJ and @DataS)
	and b.cont_tert_vama like rtrim(@ContF)+'%' and (@TVAnx=0 and (@ContFactVama=0 or left(b.cont_tert_vama,3)<>'408' and isnull(left(e.cont_factura,3),'')<>'408' and isnull(left(e.gestiune_primitoare,4),'')<>'4428') or @TVAnx=1 and @ContFactVama=1 and (b.cont_tert_vama like '408%' or e.cont_factura like '408%' or e.gestiune_primitoare like '4428%')) and b.cont_vama like rtrim(@ContCor)+'%' and @TipCump in (1,3,9) and (@Gest='' or e.cod_gestiune=@Gest) 
	and (@LMExcep=0 and isnull(e.loc_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(e.loc_munca,'') not like rtrim(@LM)+'%') and @TVAAlteCont<>1 and (@Jurnal='' or e.jurnal=@Jurnal) and (@Tert='' or (case when @DVITertExt=0 then b.tert_vama else isnull(e.cod_tert,b.tert_receptie) end)=@Tert) and (@Factura='' or (case when @DVITertExt=0 then b.factura_vama when @AgrArad=1 then b.numar_DVI else e.factura end)=@Factura)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=e.Loc_munca))
return
end
