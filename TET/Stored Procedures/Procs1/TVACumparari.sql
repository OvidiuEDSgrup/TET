--***
create procedure TVACumparari
(@DataJ datetime,@DataS datetime,@ContF char(200),@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor varchar(40),@TVAnx int,@RecalcBaza int,@nTVAex int,@FFFBTVA0 char(1),@SFTVA0 char(1),@IAFTVA0 int,
@TipCump int, -- 1=toate, 2=intern si import, 3=intracom. si taxare inversa, 9=declaratia 394
@TVAAlteCont int, -- 0=doar cu cont de TVA setat, 1=doar cele cu cont TVA diferit de setare, 2=nu conteaza contul de TVA
@DVITertExt int,@OrdDataDoc int,@Tert char(13),@Factura char(20),@UnifFact int,@FaraVanz int,@nTVAned int, @parXML xml)
as
begin
declare @Sb char(9),@CotaTVA int,@RotRM int,@Ct4426 varchar(40),@Ct4428 varchar(40),@CtTvaNeexPlati varchar(40),@AccImpDVI int,@ContFactVama int,@Bugetari int,
	@AgrArad int,@IFN int,@ListaContF int,@ContFFlt varchar(40), @PrimTM int, @Fara44 int,@marcaj int, @RPTVACompPeRM int, @faraReturnareDate int, @parXMLSP xml
	,@tipuridocument varchar(2000)	--> filtru pe tipuri de documente; insiruire de tipuri, separate prin virgule

select @marcaj=isnull(@parXML.value('(row/@marcaj)[1]','int'),0), @RPTVACompPeRM=isnull(@parXML.value('(row/@RPTVACompPeRM)[1]','int'),0)
	,@tipuridocument=rtrim(isnull(@parXML.value('(/*/@tipuridocument)[1]', 'varchar(2000)'),''))

if @tipuridocument<>''
begin
	--> filtrare pe grupe de tipuri documente:
	if @tipuridocument like '%pozadoc%' or @tipuridocument like '%altedoc%' select @tipuridocument=tip+','+@tipuridocument from pozadoc p group by p.tip
	if @tipuridocument like '%pozdoc%' or @tipuridocument like '%documente%' select @tipuridocument=p.tip+','+@tipuridocument from pozdoc p group by p.tip
	if @tipuridocument like '%compensari%' set @tipuridocument='CO,C3,CB,CF,'+@tipuridocument
	if @tipuridocument like '%fix%' set @tipuridocument='MA,ME,MI,MM,'+@tipuridocument
	if @tipuridocument like '%note%' set @tipuridocument='NC,MA,IC,PS,'+@tipuridocument

	set @tipuridocument=isnull(','+@tipuridocument+',','')
end

set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')
set @CotaTVA=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='COTATVA'),0)
set @RotRM=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ROTUNJR'),2)
set @IFN=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='IFN'),0)
set @Ct4426=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CDTVA'),'4426')
set @Ct4428=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CNEEXREC'),'4428')
set @CtTvaNeexPlati= isnull(nullif((select max(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIFURN'),''),'4428')
if @IFN=1
begin
	set @Ct4426=left(@Ct4426,@IFN+4)
	set @Ct4428=left(@Ct4428,@IFN+4)
end
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

-- creare tabela ce va returna datele, se creeaza tabela cu un singur camp si se adauga celelalte coloana prin procedura CreazaDiezTVA
/*
create table #tvacump 
	(subunitate char(9),numar char(10),numarD varchar(13),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,explicatii varchar(50),tip varchar(1),
	cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(30),drept_ded varchar(1),cont_TVA varchar(40),cont_coresp varchar(40),exonerat int,vanzcump char(1),numar_pozitie int,tipDoc char(2),
	cod char(20),factadoc char(20),contf varchar(40), detalii xml, tip_tva int)
*/
set @faraReturnareDate=0
if object_id('tempdb..#tvacump') is not null 
	set @faraReturnareDate=1
if object_id('tempdb..#tvacump') is null 
begin
	create table #tvacump (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvacump'
end

insert #tvacump
select a.subunitate,a.numar+'  ',a.numar+space(5),case when a.tip='RP' then 'RM' else a.tip end,
	case when @OrdDataDoc=1 then a.data else isNull(a.data_facturii,a.data) end,
	(case when @RPTVACompPeRM=1 and a.tip='RP' and a.Procent_vama=1 then d1.factura else a.factura end) as factura,
	(case when @RPTVACompPeRM=1 and a.tip='RP' and a.Procent_vama=1 then d1.Cod_tert else a.tert end) as tert,

	/*(CASE WHEN a.tip='RS' and a.pret_valuta<0.01 THEN round(convert(decimal(17,2),a.TVA_deductibil*100/@CotaTVA),2) 
		ELSE*/ round(convert(decimal(17,5),a.cantitate*(case when a.tip='RM' and a.jurnal='RC' then round(a.pret_valuta*(1-convert(decimal(12,0),a.cota_TVA)/convert(decimal(12,0),100+a.cota_TVA)),5) 
			when a.valuta='' or a.tip='RP' then round(a.pret_valuta*round(convert(decimal(15,4),1+a.discount/100),4),5) 
			else round(a.pret_valuta*a.curs*round(1+a.discount/100,4),5) end)),@RotRM) /*END)*/ as valoare_factura,
	
	(CASE WHEN a.cota_tva<>0 then (case when @RecalcBaza=0 then /*(case when a.tip='RS' and a.pret_valuta<0.01 then round(convert(decimal(17,2),a.TVA_deductibil*100/@CotaTVA),2) 
		else*/ round(convert(decimal(17,5),a.cantitate*(case when a.tip='RM' and a.jurnal='RC' then round(a.pret_valuta*(1-convert(decimal(12,0),a.cota_TVA)/convert(decimal(12,0),100+a.cota_TVA)),5) 
			when a.valuta='' or a.tip='RP' then round(a.pret_valuta*round(convert(decimal(15,4),1+a.discount/100),4),5) else round(a.pret_valuta*a.curs*(1+convert(decimal(17,5),a.discount/100)),5) end)),@RotRM) /*end)*/ 
		else round((case when a.cota_tva<>0 then convert(decimal(17,3),a.tva_deductibil*100/a.cota_tva) else 0 end),@RotRM) end) 
	ELSE 0 end) as baza_22,
	
	a.tva_deductibil as tva_22,space(50),'',/*(case when 1=0 and a.tip='RS' and a.pret_valuta<0.01 then @CotaTVA else*/ a.cota_tva /*end)*/,
	
	0,0,a.data,'','',
	/*a.cont_venituri*/isnull(a.detalii.value('/row[1]/@cont_tva','varchar(50)'),''),a.cont_de_stoc,(case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') 
	and a.procent_vama=1 then 1 else 0 end),'C',a.numar_pozitie,(case when a.tip='RM' and a.jurnal='RC' then 'RC' else a.tip end),a.cod,'',a.cont_factura, a.detalii, a.procent_vama, a.data_facturii,
	a.Cont_de_stoc, a.idPozDoc
from pozdoc a
	left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
	left join doc d1 on d1.subunitate=a.subunitate and d1.tip=(case when a.Tip='RP' then 'RM' else a.tip end) and d1.data=a.data and d1.numar=a.numar
--	tabela facturi nu pare a fi folosita justificat:
		--left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
where a.subunitate=@Sb and a.tip in ('RM','RP','RS','RQ') 
	and @nTVAex in (0,(case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') and a.procent_vama=1 then 1 else 2 end)) 
	and ((@TipCump<>9  or a.data_facturii='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_facturii between @DataJ and @DataS)
	and a.cont_factura like rtrim(@ContFFlt)+'%' and a.cont_factura<>'' 
	and @nTVAned in (2, (case when (a.tip in ('RS','RP') or a.tip='RM' and a.numar_DVI='') and a.procent_vama in (2,3) then 1 else 0 end)) 
--	Lucian: Am eliminat filtrarea dupa alte conturi de TVA, ramine de mutat in procedura rapJurnalTvaCumparari
	and (@TVAAlteCont=0 /*and (left(a.cont_venituri,4)='    ' or a.cont_venituri like RTrim(@Ct4426)+'%' or @PrimTM=0 and @Bugetari=1 and left(a.cont_venituri, 1)='6') 
		or @TVAAlteCont=1 and left(a.cont_venituri,4)<>'    ' and a.cont_venituri not like RTrim(@Ct4426)+'%' and not (@PrimTM=0 and @Bugetari=1 and left(a.cont_venituri, 1)='6')*/
		or @TVAAlteCont=2) 
	and (/*@Bugetari=1 or */@TVAnx=0 and left(a.cont_factura,3)<>'408' 
		or @TVAnx=1 and (a.cont_factura like '408%' /*or a.cont_venituri like RTrim(@Ct4428)+'%'*/)) 
	and a.cont_de_stoc like rtrim(@ContCor)+'%' 
	and (@TipCump in (1,9) or @TipCump=2 and left((case when a.tip='RP' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tip='RM' and a.numar=b.numar and a.data=b.data) else a.cont_de_stoc end),3)<>'371'
		or @TipCump=3 and left((case when a.tip='RP' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tip='RM' and a.numar=b.numar and a.data=b.data) else a.cont_de_stoc end),3)='371') 
	and (@Gest='' or a.gestiune=@Gest) 
	and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') 
	and not (a.tip='RM' /*and a.tip_miscare<>'V'*/ and a.numar_DVI<>'' and a.numar_DVI in (select numar_DVI from DVI where subunitate=a.subunitate and numar_receptie=a.numar)) 
	and left(a.cont_de_stoc,1)<>'8' and (@Fara44=0 or left(a.cont_de_stoc,2)<>'44') 
	and (@Jurnal='' or a.jurnal=@Jurnal) 
	and not (a.tip='RQ' and (a.valuta<>'' or abs(a.tva_deductibil)<0.01)) 
	and not (a.tip='RM' and left(a.cont_factura,3)='167' and a.jurnal='MFX' and @IAFTVA0=0 and abs(a.tva_deductibil)<0.01) 
	and (@Tert='' or a.tert=@Tert) 
	and (@Factura='' or a.factura=@Factura) 
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
	and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
	and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
union all 
select a.subunitate,a.numar,a.numar,a.tip,a.data,a.numar,'',round(a.pret_de_stoc*a.cantitate,@RotRM),round((case when a.cota_tva<>0 then convert(decimal(17,2),a.tva_deductibil*100/a.cota_tva) else 0 end),@RotRM),
	a.tva_deductibil,left(a.factura, 8)+left(a.contract, 8),'',a.cota_tva,0,0,a.data,'','',@Ct4426,a.cont_de_stoc,0,'C',a.numar_pozitie,a.tip,a.cod,'',a.cont_intermediar,a.detalii,0,a.data,
	a.Cont_de_stoc, a.idPozDoc
from pozdoc a
	left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
where @nTVAex in (0,2) and @nTVAned in (0,2) and a.subunitate=@Sb and a.tip='AI' and a.tva_deductibil<>0 and @TVAAlteCont<>1 
	and ((@TipCump<>9  or a.Data_facturii='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_facturii between @DataJ and @DataS) and a.cont_intermediar like rtrim(@ContFFlt)+'%' 
	and (@TVAnx=0 and left(a.cont_intermediar,3)<>'408' or @TVAnx=1 and a.cont_intermediar like '408%') and a.cont_de_stoc like rtrim(@ContCor)+'%' 
	and (@TipCump in (1,9) or @TipCump=2 and left(a.cont_de_stoc,3)<>'371' or @TipCump=3 and a.cont_de_stoc like '371%')
	and (@Gest='' or a.gestiune=@Gest) 
	and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and @Tert='' and (@Factura='' or a.numar=@Factura)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
	and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
	and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)

/*	Completez contul de TVA='' pe pozitiile care au cont de TVA in detalii=unul din conturile de TVA din parametrii. 
	Sunt cazuri in care care in pozdoc.detalii se completeaza cont de TVA exceptie unul din conturile de TVA setabile */
update #tvacump set cont_tva=''
where cont_tva<>'' and (cont_tva=@ct4426 or cont_tva=@Ct4428 or cont_tva=@CtTvaNeexPlati) and not (tip='AI' and @TVAAlteCont<>1)

if @marcaj in (0,2)
begin
	if @TipCump<>9
	begin
		--insert #tvacump select *,null,0 from dbo.docTVACumpDVI(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,@CotaTVA,@AccImpDVI,@ContFactVama,@AgrArad,@nTVAned)
--	s-a inlocuit apelul functiei docTVACumpDVI cu continutul ei
		insert #tvacump
		/*	Se pare ca factura CIF nu trebuie sa apara separat in jurnal. Ea reprezinta baza pentru TVA in vama. Nu trebuie sa apara nici in D394 (prestari servicii efectuate pe teritoriu national).
		select b.subunitate,b.numar_receptie,b.numar_receptie,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),(case when @OrdDataDoc=1 then b.data_DVI else isNull(e.Data_facturii,b.data_DVI) end),
			b.factura_CIF,b.tert_CIF,b.valoare_CIF,round(convert(decimal(17,2),b.tva_CIF *100/@CotaTVA),2),b.tva_CIF,'','',(case when b.tva_CIF=0 then 0 else @CotaTVA end),0,0,
			(case when e.tip in ('RM','RS') then e.data else b.data_receptiei end),
			'','','',isnull((select max(p.cont_de_stoc) from pozdoc p where p.subunitate=e.subunitate and p.tip=e.tip and p.numar=e.numar and p.data=e.data), ''),0,'C',0,
			(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),'','',b.cont_CIF,null,0,e.Data_facturii
		from DVI b
			left outer join doc e on b.subunitate=e.subunitate and e.tip in ('RM','RS') and b.numar_receptie=e.numar and b.data_DVI=e.data 
		where @nTVAex in (0,2) and @nTVAned in (0,2) and b.subunitate=@Sb and ((@TipCump<>9  or e.Data_facturii='1901-1-1') 
			and b.data_DVI between @DataJ and @DataS or @TipCump=9 and e.Data_facturii between @DataJ and @DataS) and b.cont_CIF like rtrim(@ContFFlt)+'%' and b.tert_CIF<>'' and b.cont_CIF<>'' 
			and (@TVAnx=0 and left(b.cont_CIF,3)<>'408' and left(e.gestiune_primitoare,4)<>'4428' or @TVAnx=1 and (b.cont_CIF like '408%' or e.gestiune_primitoare like '4428%')) and b.valuta_CIF='' 
			and @TipCump in (1,3,9) and (@Gest='' or e.cod_gestiune=@Gest) and (@LMExcep=0 and e.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and e.loc_munca not like rtrim(@LM)+'%') and @TVAAlteCont<>1 
			and (@Jurnal='' or e.jurnal=@Jurnal) and (@Tert='' or b.tert_CIF=@Tert) and (@Factura='' or b.factura_CIF=@Factura)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=e.Loc_munca))
			and (@tipuridocument='' or @tipuridocument like '%dvi%' or charindex(','+(case when e.tip in ('RM','RS') then 'RM' else 'MI' end)+',',@tipuridocument)>0)
		UNION ALL */
		select b.subunitate,b.numar_receptie,b.numar_receptie,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),(case when @OrdDataDoc=1 then b.data_receptiei else isNull(e.Data_facturii,b.data_receptiei) end),
			(case when @DVITertExt=0 then b.factura_vama when @AgrArad=1 then b.numar_DVI else e.factura end),(case when @DVITertExt=0 then b.tert_vama else isnull(e.cod_tert,b.tert_receptie) end),
			b.val_fara_comis+b.dif_vama/*+b.suma_vama*/+b.dif_com_vam +(case when @AccImpDVI=1 then b.TVA_11 else 0 end) -(case when b.valuta_CIF='' then b.valoare_CIF else 0 end),
			(case when @RecalcBaza=0 then b.val_fara_comis/*+b.suma_vama*/+b.dif_vama+b.dif_com_vam +(case when @AccImpDVI=1 then b.TVA_11 else 0 end) 
				else round(convert(decimal(17,2),(b.valoare_tva-b.tva_CIF) *100/@CotaTVA),2) end),
			b.valoare_tva-b.tva_CIF,'','',(case when b.valoare_tva-b.tva_CIF=0 then 0 else @CotaTVA end),0,0,(case when e.tip in ('RM','RS') then e.data else b.data_receptiei end),'','','',
			isnull((select max(p.cont_de_stoc) from pozdoc p where p.subunitate=e.subunitate and p.tip=e.tip and p.numar=e.numar and p.data=e.data), ''),
			(case when b.total_vama=1 then 1 else 0 end),'C',0,(case when e.tip in ('RM','RS') then 'RM' else 'MI' end),'','',b.cont_tert_vama,null,0,e.Data_facturii,null,null
		from DVI b
			left outer join doc e on b.subunitate=e.subunitate and e.tip in ('RM','RS') and b.numar_receptie=e.numar and b.data_DVI=e.data 
		where @nTVAex in (0,(case when b.total_vama=1 then 1 else 2 end)) and @nTVAned in (2,(case when b.total_vama=2 then 1 else 0 end)) and b.factura_comis in ('','D') and b.subunitate=@Sb 
			and ((@TipCump<>9  or e.Data_facturii='1901-1-1') and b.data_DVI between @DataJ and @DataS or @TipCump=9 and e.Data_facturii between @DataJ and @DataS)	and b.cont_tert_vama like rtrim(@ContFFlt)+'%' 
			and (@TVAnx=0 and (@ContFactVama=0 or left(b.cont_tert_vama,3)<>'408' and isnull(left(e.cont_factura,3),'')<>'408' and isnull(left(e.gestiune_primitoare,4),'')<>'4428') 
				or @TVAnx=1 and @ContFactVama=1 and (b.cont_tert_vama like '408%' or e.cont_factura like '408%' or e.gestiune_primitoare like '4428%')) 
			and b.cont_vama like rtrim(@ContCor)+'%' and @TipCump in (1,3,9) and (@Gest='' or e.cod_gestiune=@Gest) 
			and (@LMExcep=0 and isnull(e.loc_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(e.loc_munca,'') not like rtrim(@LM)+'%') 
			and @TVAAlteCont<>1 and (@Jurnal='' or e.jurnal=@Jurnal) and (@Tert='' or (case when @DVITertExt=0 then b.tert_vama else isnull(e.cod_tert,b.tert_receptie) end)=@Tert) 
			and (@Factura='' or (case when @DVITertExt=0 then b.factura_vama when @AgrArad=1 then b.numar_DVI else e.factura end)=@Factura)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=e.Loc_munca))
			and (@tipuridocument='' or @tipuridocument like '%dvi%' or charindex(','+(case when e.tip in ('RM','RS') then 'RM' else 'MI' end)+',',@tipuridocument)>0)
	end
--	insert #tvacump select * from dbo.docTVACumpAdoc(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@Tert,@Factura,@CotaTVA,@Ct4426,@Ct4428,@nTVAned)
--	s-a inlocuit apelul functiei docTVACumpAdoc cu continutul ei
	insert #tvacump 
	select a.subunitate,a.numar,a.cont,'PI',(case when a.plata_incasare='PC' then isnull(a.detalii.value('(/row/@datafact)[1]','datetime'),isnull(c.data,a.data)) else a.Data end),a.factura,a.tert,
		(case when a.Plata_incasare in ('PC','PR') and a.suma=a.TVA22 and a.TVA11<>0 
			--then (case when abs(c.Valoare-round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) )<0.05 then c.Valoare else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end)
			then (case when left(a.numar,4)='ITVA' and isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)>=0.01 
				then isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)-a.TVA22 when a.tip_tva>0 then 0 else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end)
			else a.Suma-a.TVA22 end),
		(case when a.TVA11=0 then 0 
			else (case when @RecalcBaza=1 or a.Plata_incasare in ('PC','PR') and a.suma=a.TVA22 and a.TVA11<>0 
			--then (case when abs(c.Valoare-round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) )<0.05 then c.Valoare else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end) 
			then (case when left(a.numar,4)='ITVA' and isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)>=0.01 
				then isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)-a.TVA22 when a.tip_tva>0 then 0 else round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) end)
			else a.suma-a.TVA22 end) end),
		a.TVA22,a.explicatii,'',a.TVA11,0,0,a.data,'','',@Ct4426,a.cont_corespondent,(case when a.plata_incasare='PC' and a.tip_tva=1 then 1 else 0 end),'C',a.numar_pozitie,a.plata_incasare,'','',
		a.cont, a.detalii, a.tip_tva, (case when a.plata_incasare='PC' then isnull(a.detalii.value('(/row/@datafact)[1]','datetime'),isnull(c.data,a.data)) else a.Data end),
		null,a.idPozplin
	from pozplin a
		left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert and a.cont like '442%'
	where @nTVAex in (0,(case when a.plata_incasare='PC' and a.tip_tva=1 then 1 else 2 end)) and @nTVAned in (2,(case when a.plata_incasare='PC' and a.tip_tva in (2,3) then 1 else 0 end)) 
		and a.subunitate=@Sb 
		and --(@TipCump<>9 and	--> care e data facturii? are sens?
			a.data between @DataJ and @DataS --or @TipCump=9 and a.data between @DataJ and @DataS)
		and (a.plata_incasare='PC' or a.plata_incasare='PR' and @TipCump<>9 or a.plata_incasare='PF' and TVA22<>0) 
		and a.cont like rtrim(@ContFFlt)+'%' and @TVAnx=0 
		and (a.cont_corespondent like rtrim(@ContCor)+'%' or a.cont like '442%' and exists (select 1 from pozdoc p where p.subunitate=a.subunitate and p.tip in ('RM','RS') and p.tert=a.tert and p.factura=a.factura and p.cont_de_stoc like rtrim(@ContCor)+'%')) 
		and @TipCump in (1,2,9) and @Gest='' 
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') 
		and @TVAAlteCont<>1 and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and (@tipuridocument='' or charindex(',PI,',@tipuridocument)>0 or charindex(','+a.plata_incasare+',',@tipuridocument)>0)
	UNION ALL 
	select a.Subunitate,a.Numar_document,a.Numar_document,a.Tip,a.Data_fact,a.factura_dreapta,a.Tert,
		(case when a.tip='FF' and (a.cont_deb like RTrim(@Ct4426)+'%' and a.suma=0 or a.TVA22<0 and a.TVA22=-a.suma) and a.TVA11<>0 then round(convert(decimal(17,2),a.TVA22*100/a.TVA11),2) else a.suma end),
		(case when a.TVA11=0 or a.TVA22=0 then 0 else (case when @RecalcBaza=0 then a.suma else round(a.TVA22 *100/a.TVA11,2) end) end),a.TVA22,'','',(case when a.TVA22=0 then 0 else a.TVA11 end),
		0,0,a.data,'','',(case when a.tip='FF' and a.tert_beneficiar<>'' then a.tert_beneficiar else @Ct4426 end),a.cont_deb,(case when a.stare=1 then 1 else 0 end),'C',a.numar_pozitie,a.tip,'',
		(case a.tip when 'SF' then a.factura_stinga else '' end),a.cont_cred, null, a.stare, a.Data_fact,null,a.idPozadoc
	from pozadoc a
	where a.subunitate=@Sb 
		and ((@TipCump<>9 or a.Data_fact='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_fact between @DataJ and @DataS)
		and @nTVAex in (0,(case when a.stare=1 then 1 else 2 end)) and @nTVAned in (2,(case when a.stare in (2,3) then 1 else 0 end)) and a.cont_cred like rtrim(@ContFFlt)+'%' 
--	mai jos am inlocuit a.tert_beneficiar like RTrim(@Ct4426)+'%' cu (a.tert_beneficiar like RTrim(@Ct4426)+'%' or @TipCump=9). Sa apara si in D394 FF-urile cu cont de TVA neexigibil.
		and (@TVAnx=0 and a.cont_cred not like '408%' and (/*left(a.tert_beneficiar,4) in ('    ',@Ct4426)*/1=1 or @TipCump=9 or a.valuta<>'' or @TVAAlteCont=1) 
--	Lucian: Am eliminat filtrarea dupa alte conturi de TVA, ramine de mutat in procedura rapJurnalTvaCumparari
		and (@TVAAlteCont<>1 and (left(a.tert_beneficiar,4)='    ' or (a.tert_beneficiar like RTrim(@Ct4426)+'%' or @TipCump=9) or a.tip='SF' and a.valuta<>'') 
			or @TVAAlteCont=1 and left(a.tert_beneficiar,4)<>'    ' and a.tert_beneficiar not like RTrim(@Ct4426)+'%' and not (a.tip='SF' and a.valuta<>'')) 
			or @TVAnx=1 and (a.cont_cred like '408%' /*and a.tert_beneficiar='' or left(a.tert_beneficiar,4)=@Ct4428*/)) 
		and (a.tip='FF' and (@FFFBTVA0='0' and a.TVA22<>0 or @FFFBTVA0='1' and a.TVA11<>0 or @FFFBTVA0='2') or a.tip='SF' and (@SFTVA0='0' and a.TVA22<>0 or @SFTVA0='1' and a.TVA11<>0 or @SFTVA0='2')) 
		and a.cont_deb like rtrim(@ContCor)+'%' 
		and (@TipCump in (1,9) 
			or @TipCump=2 and left((case when a.tip='SF' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tert=a.tert and b.factura=a.factura_stinga) else a.cont_deb end),3)<>'371' 
			or @TipCump=3 and (case when a.tip='SF' then (select max(b.cont_de_stoc) from pozdoc b where a.subunitate=b.subunitate and b.tert=a.tert and b.factura=a.factura_stinga) else a.cont_deb end) like '371%') 
		and @Gest=''
		and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) 
		and (@Factura='' or a.factura_dreapta=@Factura) and not ((a.explicatii like '%CONV%DIF.%CURS%' or isnull(a.detalii.value('(/row/@difconv)[1]', 'int'),0)=1) and tip='FF')--and ltrim(numar_document) like 'DIF%')
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	UNION ALL 
	select a.Subunitate,a.Numar_document,a.Numar_document,a.Tip,a.Data_fact,a.Factura_dreapta,a.Tert,-a.Suma+(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22,
		-(case when @RecalcBaza=0 then a.suma-(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22 else round(convert(decimal(17,2),(case when 1=0 and a.TVA22<0 then -1 else 1 end)*a.TVA22*100/@CotaTVA),2) end),
		(case when 1=0 and a.TVA22<0 then 1 else -1 end)*a.TVA22,'','',@CotaTVA,0,0,a.data,'','',@Ct4426,a.cont_deb,0,'C',a.numar_pozitie,a.tip,'','',a.cont_cred, null, 0, null, null, a.idPozadoc
	from pozadoc a
	where @nTVAex in (0,2) and @nTVAned in (0,2) and a.subunitate=@Sb 
		and ((@TipCump<>9 or a.Data_fact='1901-1-1') and a.data between @DataJ and @DataS or @TipCump=9 and a.Data_fact between @DataJ and @DataS)
		and a.tip='CF' and a.TVA22<>0 and a.cont_cred like rtrim(@ContFFlt)+'%' and (@TVAnx=0 and left(a.cont_cred,3)<>'408' or @TVAnx=1 and a.cont_cred like '408%') 
		and a.cont_deb like rtrim(@ContCor)+'%' and @TipCump in (1,2,9) and @Gest='' 
		and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and @TVAAlteCont<>1 and (@Jurnal='' or a.jurnal=@Jurnal) 
		and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura_dreapta=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	UNION ALL 
	select a.subunitate,a.numar_document,a.numar_document,(case when a.tip_miscare='IAF' then 'MI' else 'MM' end),a.data_miscarii,a.factura,a.tert,
		(case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end),
		(case when a.tva=0 then 0 when abs((case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end)-round(convert(decimal(17,2),a.tva*100/@CotaTVA),2))>1 and @RecalcBaza=1 
			then round(convert(decimal(17,2),a.tva*100/@CotaTVA),2) 
			else (case when a.tip_miscare='IAF' then a.pret else a.diferenta_de_valoare end) end),
		a.TVA,'','',(case when a.tva<>0 then @CotaTVA else 0 end),0,0,a.data_miscarii,'','',@Ct4426,
		(case when 1=1 or a.tip_miscare='MFF' then isnull((select max(cont_mijloc_fix) from fisaMF where subunitate=@Sb and numar_de_inventar=a.numar_de_inventar and felul_operatiei='3'),'212') 
			else a.subunitate_primitoare end),0,'C',0,(case when a.tip_miscare='IAF' then 'MI' else 'MM' end),'','',a.cont_corespondent, null, 0, null, null, null
	from misMF a 
		left outer join facturi c on c.tip=0x54 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
	where @nTVAex in (0,2) and @nTVAned in (0,2) and a.procent_inchiriere not in (1, 6, 9) 
		and isnull((select max(cont_mijloc_fix) from fisaMF where subunitate=@Sb and numar_de_inventar=a.numar_de_inventar and felul_operatiei='3'),'212') like rtrim(@ContCor)+'%' 
		and a.subunitate=@Sb and a.data_miscarii between @DataJ and @DataS and a.tip_miscare in ('IAF','MFF') and not (a.tip_miscare='IAF' and @IAFTVA0=0 and abs(a.tva)<0.01) 
		and a.cont_corespondent like rtrim(@ContFFlt)+'%' and (@TVAnx=0 and left(a.cont_corespondent,3)<>'408' or @TVAnx=1 and a.cont_corespondent like '408%') and @TipCump in (1,2,9) and @Gest='' 
		and (@LMExcep=0 and isnull(c.loc_de_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(c.loc_de_munca,'') not like rtrim(@LM)+'%') 
		and not (a.loc_de_munca_primitor<>'' and a.loc_de_munca_primitor in (select numar_DVI from DVI where subunitate=a.subunitate and numar_receptie=a.numar_document)) 
		and @TVAAlteCont<>1 and @Jurnal='' and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=c.Loc_de_munca))
		and (@tipuridocument='' or charindex(','+(case when a.tip_miscare='IAF' then 'MI' else 'MM' end)+',',@tipuridocument)>0)
end

if @nTVAex in (0, 1) and @FaraVanz=0 and @nTVAned<>1
begin
/*	insert #tvacump -- pentru vanzari cu TVA exonerat
	select * from dbo.docTVAVanz(@DataJ,@DataS,@ContFFlt,0,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,'','',1,@FFFBTVA0,0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,0,@Tert,@Factura,0,1, @parXML)
	where exonerat=1 /*ca 2 e TVA neinregistrat)*/
*/
	insert #tvacump  -- pentru vanzari cu TVA exonerat
	exec dbo.TVAVanzari @DataJ,@DataS,@ContFFlt,0,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,'','',1,@FFFBTVA0,0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,0,@Tert,@Factura,0,1, @parXML
end

if @ListaContF=1 begin
	declare @lc table (cont varchar(40))
	insert @lc 
	select left([Item],13) from dbo.Split(@ContF, ';')
	
	delete #tvacump 
	from #tvacump d 
	where not exists (select 1 from @lc l where d.contf like RTrim(l.cont)+'%')
end
if @FaraVanz=1 and exists (select 1 from sysobjects where [type]='TF' and [name]='docTVACumpSP')
	insert #tvacump select *,null,0,null,null,null from dbo.docTVACumpSP(@Sb,@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@Tert,@Factura,@CotaTVA,@Ct4426,@Ct4428,@nTVAned)

if @UnifFact=1
	update #tvacump
	set factura=left(factura,PATINDEX('%[ .,/A-Z]%',right(rtrim(factura),len(factura)-1)))
	where len(factura)>1 and PATINDEX('%[ .,/A-Z]%',right(rtrim(factura),len(factura)-1))>0

--	apel procedura specifica ce va putea modifica datele din tabela #tvacump
set @parXMLSP=(select @DataJ as datajos, @DataS as datasus, @TipCump as tipCump for xml raw)
if exists (select 1 from sysobjects where [type]='P' and [name]='TVACumparariSP')  
	exec TVACumparariSP @parXML=@parXMLSP

--	selectul final
if @faraReturnareDate=0
	select 
		subunitate, numar, numarD, tipD, data, factura, tert, valoare_factura, baza_22, tva_22, explicatii, tip, cota_tva, discFaraTVA, discTVA, data_doc, 
		ordonare, drept_ded, cont_TVA, cont_coresp, exonerat, vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, detalii, tip_tva, dataf, cont_de_stoc, idpozitie
	from #tvacump 
end
