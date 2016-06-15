--***
create function yso_pdocTVACumpAdoc
-- vezi explicatii la parametrii functiei in rapJurnalTVACumparari!
(@Sb char(9),@DataJ datetime,@DataS datetime,@ContF char(13),@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor char(13),@TVAnx int,@RecalcBaza int,
@nTVAex int, -- 0=toate tipurile de TVA, 1=doar TVA taxare inversa, 2=doar TVA taxare normala 
@FFFBTVA0 char(1),@SFTVA0 char(1),@IAFTVA0 int,@TipCump int,@TVAAlteCont int,@Tert char(13),@Factura char(20),@CotaTVA int,@Ct4426 char(13),@Ct4428 char(13),@nTVAned int)
returns @dtva table
(subunitate char(9),numar char(10),numarD varchar(13),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,explicatii varchar(50),tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(30),drept_ded varchar(1),cont_TVA varchar(13),cont_coresp char(13),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf char(13))
begin
	/**	Pregatire filtrare pe lm configurate pe utilizatori*/
declare @eLmUtiliz int, @utilizator varchar(20)
select @utilizator=dbo.fIaUtilizator('')
set @eLmUtiliz=dbo.f_arelmfiltru(@utilizator)
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
select l.cod from lmfiltrare l where l.utilizator=@utilizator

insert @dtva
select a.subunitate,a.numar,a.cont,'PI',(case when a.plata_incasare='PC' then isnull(e.data_document,isnull(c.data,a.data)) else a.Data end),a.factura,a.tert,
	(case when a.Plata_incasare in ('PC','PR') and a.suma=a.TVA22 and a.TVA11<>0 
		then (case when abs(c.Valoare-round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) )<0.05 then c.Valoare else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end)
		else a.Suma-a.TVA22 end),
	(case when a.TVA11=0 then 0 
		else (case when @RecalcBaza=1 or a.Plata_incasare in ('PC','PR') and a.suma=a.TVA22 and a.TVA11<>0 
			then (case when abs(c.Valoare-round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) )<0.05 then c.Valoare else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end) else a.suma-a.TVA22 end) end),
		a.TVA22,a.explicatii,'',a.TVA11,0,0,a.data,'','',@Ct4426,a.cont_corespondent,(case when a.plata_incasare='PC' and a.curs_la_valuta_facturii=1 then 1 else 0 end),'C',a.numar_pozitie,a.plata_incasare,'','',a.cont
from pozplin a
left outer join extpozplin e on e.data_document>'01/01/1901' and a.plata_incasare='PC' and a.subunitate=e.subunitate and a.cont=e.cont and a.data=e.data and a.numar=e.numar and a.numar_pozitie=e.numar_pozitie
left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
where @nTVAex in (0,(case when a.plata_incasare='PC' and a.curs_la_valuta_facturii=1 then 1 else 2 end)) and @nTVAned in (2,(case when a.plata_incasare='PC' and a.curs_la_valuta_facturii in (2,3) then 1 else 0 end)) 
	and a.subunitate=@Sb 
	and --(@TipCump<>9 and	--> care e data facturii? are sens?
		a.data between @DataJ and @DataS --or @TipCump=9 and a.data between @DataJ and @DataS)
	and (a.plata_incasare in ('PC','PR') and @TipCump<>9 or a.plata_incasare='PF' and TVA22<>0) 
	and a.cont like rtrim(@ContF)+'%' and @TVAnx=0 and a.cont_corespondent like rtrim(@ContCor)+'%' and @TipCump in (1,2,9) and @Gest='' 
	and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') 
	and @TVAAlteCont<>1 and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
--UNION ALL 
--select a.Subunitate,a.Numar_document,a.Numar_document,a.Tip,a.Data_fact,a.factura_dreapta,a.Tert,(case when a.tip='FF' and (a.cont_deb like RTrim(@Ct4426)+'%' and a.suma=0 or a.TVA22<0 and a.TVA22=-a.suma) and a.TVA11<>0 then round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) else a.suma end),(case when a.TVA11=0 or a.TVA22=0 then 0 else (case when @RecalcBaza=0 then a.suma else round(a.TVA22 *100/a.TVA11,2) end) end),a.TVA22,'','',(case when a.TVA22=0 then 0 else a.TVA11 end),0,0,a.data,'','',(case when a.tip='FF' and a.tert_beneficiar<>'' then a.tert_beneficiar else @Ct4426 end),a.cont_deb,(case when a.stare=1 then 1 else 0 end),'C',a.numar_pozitie,a.tip,'',(case a.tip when 'SF' then a.factura_stinga else '' end),a.cont_cred
--from pozadoc a
--where a.subunitate=@Sb 
--	and ((@TipCump<>9 or a.Data_fact='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_fact between @DataJ and @DataS)
--	and @nTVAex in (0,(case when a.stare=1 then 1 else 2 end)) and @nTVAned in (2,(case when a.stare in (2,3) then 1 else 0 end)) and a.cont_cred like rtrim(@ContF)+'%' 
----	mai jos am inlocuit a.tert_beneficiar like RTrim(@Ct4426)+'%' cu (a.tert_beneficiar like RTrim(@Ct4426)+'%' or @TipCump=9). Sa apara si D394 FF-urile cu cont de TVA neexigibil.
--	and (@TVAnx=0 and a.cont_cred not like '408%' and (left(a.tert_beneficiar,4) in ('    ',@Ct4426) or @TipCump=9 or a.valuta<>'') 
--		and (@TVAAlteCont<>1 and (left(a.tert_beneficiar,4)='    ' or (a.tert_beneficiar like RTrim(@Ct4426)+'%' or @TipCump=9) or a.tip='SF') 
--			or @TVAAlteCont=1 and left(a.tert_beneficiar,4)<>'    ' and a.tert_beneficiar not like RTrim(@Ct4426)+'%' and a.tip<>'SF') 
--		or @TVAnx=1 and (a.cont_cred like '408%' and a.tert_beneficiar='' or left(a.tert_beneficiar,4)=@Ct4428)) 
--	and (a.tip='FF' and (@FFFBTVA0='0' and a.TVA22<>0 or @FFFBTVA0='1' and a.TVA11<>0 or @FFFBTVA0='2') or a.tip='SF' and (@SFTVA0='0' and a.TVA22<>0 or @SFTVA0='1' and a.TVA11<>0 or @SFTVA0='2')) 
--	and a.cont_deb like rtrim(@ContCor)+'%' and (@TipCump in (1,9) or @TipCump=2 and left((case when a.tip='SF' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tert=a.tert and b.factura=a.factura_stinga) else a.cont_deb end),3)<>'371' 
--		or @TipCump=3 and (case when a.tip='SF' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tert=a.tert and b.factura=a.factura_stinga) else a.cont_deb end) like '371%') 
--	and @Gest=''
--	and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) 
--	and (@Factura='' or a.factura_dreapta=@Factura) and not (a.explicatii like  '%CONV%DIF.%' and tip='FF' and numar_document like 'DIF%')
--	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
--UNION ALL 
--select a.Subunitate,a.Numar_document,a.Numar_document,a.Tip,a.Data_fact,a.Factura_dreapta,a.Tert,-a.Suma+(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22,-(case when @RecalcBaza=0 then a.suma-(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22 else round(convert(decimal(17,2),(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22*100/@CotaTVA),2) end),(case when 1=0 and a.TVA22<0 then 1 else -1 end)*a.TVA22,'','',@CotaTVA,0,0,a.data,'','',@Ct4426,a.cont_deb,0,'C',a.numar_pozitie,a.tip,'','',a.cont_cred
--from pozadoc a
--where @nTVAex in (0,2) and @nTVAned in (0,2) and a.subunitate=@Sb 
--	and ((@TipCump<>9 or a.Data_fact='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_fact between @DataJ and @DataS)
--	and a.tip='CF' and a.TVA22<>0 and a.cont_cred like rtrim(@ContF)+'%' and (@TVAnx=0 and left(a.cont_cred,3)<>'408' or @TVAnx=1 and a.cont_cred like '408%') 
--	and a.cont_deb like rtrim(@ContCor)+'%' and @TipCump in (1,2,9) and @Gest='' 
--	and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and @TVAAlteCont<>1 and (@Jurnal='' or a.jurnal=@Jurnal) 
--	and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura_dreapta=@Factura)
--	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
--UNION ALL 
--select a.subunitate,a.numar_document,a.numar_document,(case when a.tip_miscare='IAF' then 'MI' else 'MM' end),a.data_miscarii,a.factura,a.tert,(case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end),(case when a.tva=0 then 0 when abs((case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end)-round(convert(decimal(17,2),a.tva*100/@CotaTVA),2))>1 and @RecalcBaza=1 then round(convert(decimal(17,2),a.tva*100/@CotaTVA),2) else (case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end) end),a.TVA,'','',(case when a.tva<>0 then @CotaTVA else 0 end),0,0,a.data_miscarii,'','',@Ct4426,(case when 1=1 or a.tip_miscare='MFF' then isnull((select max(cont_mijloc_fix) from fisaMF where subunitate=@Sb and numar_de_inventar=a.numar_de_inventar and felul_operatiei='3'),'212') else a.subunitate_primitoare end),0,'C',0,(case when a.tip_miscare='IAF' then 'MI' else 'MM' end),'','',a.cont_corespondent
--from misMF a 
--left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
--where @nTVAex in (0,2) and @nTVAned in (0,2) and a.procent_inchiriere not in (1, 6, 9) 
--	and isnull((select max(cont_mijloc_fix) from fisaMF where subunitate=@Sb and numar_de_inventar=a.numar_de_inventar and felul_operatiei='3'),'212') like rtrim(@ContCor)+'%' and a.subunitate=@Sb and a.data_miscarii between @DataJ and @DataS and a.tip_miscare in ('IAF','MFF') and not (a.tip_miscare='IAF' and @IAFTVA0=0 and abs(a.tva)<0.01) 
--	and a.cont_corespondent like rtrim(@ContF)+'%' and (@TVAnx=0 and left(a.cont_corespondent,3)<>'408' or @TVAnx=1 and a.cont_corespondent like '408%') and @TipCump in (1,2,9) and @Gest='' 
--	and (@LMExcep=0 and isnull(c.loc_de_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(c.loc_de_munca,'') not like rtrim(@LM)+'%') 
--	and not (a.loc_de_munca_primitor<>'' and a.loc_de_munca_primitor in (select numar_DVI from DVI where subunitate=a.subunitate and numar_receptie=a.numar_document)) 
--	and @TVAAlteCont<>1 and @Jurnal='' and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
--	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=c.Loc_de_munca))
return
end
