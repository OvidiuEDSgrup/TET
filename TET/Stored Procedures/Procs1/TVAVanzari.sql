--***
create procedure TVAVanzari
(@DataJ datetime,@DataS datetime,@ContF char(200),@ContFExcep int,@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),
@ContCor varchar(40),
@TVAnx int, -- 0=TVA normal, 1=TVA neexigibil
@RecalcBaza int,@CtVenScDed char(200),@CtPIScDed char(200),
@nTVAex int, -- 0=toate documentele, 1=doar documentele cu TVA compensat, 2=doar documentele fara TVA compensat, 3=facturi aferente bonurilor de PV (BFF), 8=fara facturi UA, 9=doar facturi UA
@FFFBTVA0 char(1),@SiFactAnul int,@TipCump int,@TVAAlteCont int,@DVITertExt int,@OrdDataDoc int,@OrdDenTert int,
@Tert char(13),@Factura char(20),@D394 int,@FaraCump int, @parXML xml)
as
begin
--@nTVAex int=0	-->ordinul unitatilor 0=Toate documentele, 1=Cu TVA exonerat, 2=Fara TVA exonerat,3=Facturi casa de marcat, 8=Fara facturi UA, 9=Doar facturi UA
--				   ordinul zecilor 0-toti 1-platitor tva, 2-neplatitor tva
declare @nTVAexUA int,@o_nTVAex int
set @o_nTVAex=@nTVAex
set @nTVAex=@o_nTVAex%10 -- exprima ordinul unitatilor - de aici in jos va avea aceasta functie (primele 3 valori)
--declare @TipTvaTert int -- se va folosi doar in jurnalTVAVanzari
--set @TipTvaTert=@o_nTVAex/10	--> @TipTvaTert:0=nefiltrat,1=platitor,2=neplatitor

declare @Sb char(9),@CotaTVA int,@RotAP int,@DocSch int,@Ct4427 varchar(40),@Ct4428 varchar(40),@AccImpDVI int,@ContFactVama int,@STOEHR int,@DrumOR int,@Bugetari int,
	@GenisaUnicarm int,@Metrou int,@Pragmatic int,@Autoliv int,@AgrArad int/*,@Arobs int*/,@IFN int,@ListaContF int,@ContFFlt varchar(40),@ExpandareDiminuari int, @marcaj int, @faraReturnareDate int, @parXMLSP xml
	,@tipuridocument varchar(2000)	--> filtru pe tipuri de documente; insiruire de tipuri, separate prin virgule
--	variabile utilizate in docTVAVanzBFF
declare @AplPV int, @DetBon int, @TertBP int, @PVria int, @GenICAC int
	,@nTVAex_0238 bit	--> conditie de filtrare tva exonerat: 0=toate documentele, 2=doar documentele fara TVA compensat, 3=facturi aferente bonurilor de PV (BFF), 8=fara facturi UA
select @nTVAex_0238=(case when @nTVAex in (0, 2, 3, 8) then 1 else 0 end)
select @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),''),
	@CotaTVA=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='COTATVA'),0),
	@RotAP=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ROTUNJ'),2),
	@DocSch=isnull((select max(case when val_logica=1 and val_numerica=0 then 1 else 0 end) from par where tip_parametru='GE' and parametru='DOCPESCH'),0),
	@IFN=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='IFN'),0),
	@Ct4427=left(isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CCTVA'),''),@IFN+4),
	@Ct4428=left(isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CNEEXREC'),''),@IFN+4),
	@AccImpDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='ACCIMP'),0),
	@ContFactVama=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CONTFV'),0),
	@STOEHR=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='STOEHR'),0),
	@DrumOR=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DRUMOR'),0),
	@Bugetari=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='BUGETARI'),0),
	@GenisaUnicarm=isnull((select max(cast(val_logica as int)) from par where tip_parametru='SP' and parametru in ('GENISA','UNICARM')),0),
	@Metrou=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='METROUL'),0),
	@Pragmatic=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='PRAGMATIC'),0),
	@Autoliv=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='AUTOLIV'),0),
	@AgrArad=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='AGRIRARAD'),0),
	--@Arobs=isnull((select max(cast(val_logica as int)) from par where tip_parametru='SP' and parametru='AROBS'),0),
	@ListaContF=(case when charindex(';',@ContF)>0 then 1 else 0 end),
	@ContFFlt=(case when @ListaContF=0 then @ContF else '' end),
	@ExpandareDiminuari=isnull((select val_logica from par where tip_parametru='GE' and parametru='TVAEXPDIM'),0),
	@marcaj=isnull(@parXML.value('(row/@marcaj)[1]','int'),0)
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

select @AplPV=isnull((select val_logica from par where tip_parametru='GE' and parametru='POS'),0)
	,@DetBon=isnull((select val_logica from par where tip_parametru='PO' and parametru='DETBON'),0)
	,@TertBP=isnull((select val_logica from par where tip_parametru='PO' and parametru='TERTFAC'),0)
	,@PVria=isnull((select val_logica from par where tip_parametru='AR' and parametru='PV'),0)
	,@GenICAC=isnull((select val_logica from par where tip_parametru='GE' and parametru='GENICAC'),0)

if @PVria=1
	set @AplPV=1 -- lucreaza cu PV, dar mai nou 

declare @sesiune varchar(20)
Set @sesiune = @parXML.value('(/row/@sesiune)[1]','varchar(20)')

if @DetBon=0 set @TertBP=0

	/**	Pregatire filtrare pe lm configurate pe utilizatori*/
declare @eLmUtiliz int, @utilizator varchar(20)
select @utilizator=dbo.fIaUtilizator('')
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
--select valoare from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
select cod from lmfiltrare where utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	
/** Pregatire parametri pentru facturi UA*/
declare @D394UA int
select	@nTVAexUA=(case when @nTVAex=9 then 0 else @nTVAex end), 
		--@D394UA=(case when @nTVAex<8 then @D394 else 9 end)
		@D394UA=@D394
if @nTVAex=8 set @nTVAex=0
/**	Luci Maier: Am "impartit" parametru @nTVAex pentru UA pentru a rezolva problema luarii datelor de UA; nTVAex ramane 0 pentru
				filtrare daca inainte era 8 sau 9; 8 = excludere date UA, 9 = doar date UA;
				@nTVAexUA este 0 pentru @nTVAex=9 ca sa aduca datele de UA (procedurile UA aduc datele doar pentru 0 sau 2)
			Aceasta impartire s-a facut pentru a nu mai modifica toate functiile apelate cascadat din functia curenta (ar trebui 
				tratat peste tot parametri @nTVAex si @D394)*/
-- creare tabela ce va returna datele, se creeaza tabela cu un singur camp si se adauga celelalte coloana prin procedura CreazaDiezTVA
/*create table #tvavanz 
(subunitate char(9),numar char(10),numarD varchar(13),tipD char(2),data datetime,factura char(20),tert varchar(13),valoare_factura float,baza_22 float,tva_22 float,explicatii varchar(50),
	tip varchar(1),cota_tva smallint,discFaraTVA float,discTVA float,data_doc datetime,ordonare char(100),drept_ded varchar(1),cont_TVA varchar(40),cont_coresp varchar(40),exonerat int,
	vanzcump char(1),numar_pozitie int,tipDoc char(2),cod char(20),factadoc char(20),contf varchar(40), detalii xml, tip_tva int)
*/

set @faraReturnareDate=0
if object_id('tempdb..#tvavanz') is not null 
	set @faraReturnareDate=1
if object_id('tempdb..#tvavanz') is null 
begin
	create table #tvavanz (subunitate char(9))
	exec CreazaDiezTVA @numeTabela='#tvavanz'
end

if @nTVAex<3 -- fara casa de marcat, facturi UA
begin
	insert #tvavanz
	select a.subunitate,a.numar,a.numar+space(5),a.tip,(case when @OrdDataDoc=0 then isnull(a.Data_facturii,a.data) else a.data end),a.factura,
			a.tert,round(convert(decimal(20,5),pret_vanzare*cantitate),@RotAP) as valoare_factura,
			(case when a.cota_tva<>0 then (case when @RecalcBaza=0 then round(convert(decimal(20,5),pret_vanzare*cantitate),@RotAP) else round(a.tva_deductibil,2)*100/a.cota_tva end) else 0 end) as baza_22,
			round(a.tva_deductibil,2) as tva_22,space(50),'A',a.cota_tva,round((pret_valuta-pret_vanzare)*cantitate,2) as discFaraTVA,round((pret_valuta-pret_vanzare)*cantitate*(case when a.Procent_vama=2 then 0 else a.cota_tva/100 end),2) as discTVA,
			a.data,(case when @OrdDenTert=1 then t.denumire else '' end) as ordonare,(case when charindex(rtrim(a.cont_venituri),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),a.grupa,a.cont_venituri,
			(case when @GenisaUnicarm=0 and (@DocSch=0 or a.tip='AS') and a.procent_vama in (1,2) then /*1*/ a.procent_vama else 0 end),'V',numar_pozitie,a.tip,a.cod,'',a.cont_factura,a.detalii,a.procent_vama,
			a.Data_facturii,a.cont_de_stoc,a.idpozdoc
	from pozdoc a 
		left outer join terti t on a.subunitate=t.subunitate and a.tert=t.tert 
		left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
	--	tabela facturi nu pare a fi folosita justificat:
			--left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
	where a.subunitate=@Sb and a.tip in ('AP','AS') 
		and @nTVAex in (0,(case when @GenisaUnicarm=0 and (@DocSch=0 or a.tip='AS') and a.procent_vama in (1,2) then 1 else 2 end)) 
		and ((@D394=0 or a.Data_facturii='1901-1-1') and a.data between @DataJ and @DataS or 
				@D394=1 and a.Data_facturii between @DataJ and @DataS)
		and (@ContFExcep=0 and a.cont_factura like rtrim(@ContFFlt)+'%' or @ContFExcep=1 
		and a.cont_factura not like rtrim(@ContFFlt)+'%') 
		and (@TVAnx=0 and left(a.cont_factura,3)<>'418' /*and a.grupa not like RTrim(@Ct4428)+'%'*/ or @TVAnx=1 and (a.cont_factura like '418%' /*or a.grupa like RTrim(@Ct4428)+'%'*/)) 
		and (@IFN=1 or left(a.cont_corespondent,2)<>'35') and (@Gest='' or a.gestiune=@Gest)
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') 
--	Lucian: am scos filtrarea dupa campul grupa (=cont de TVA). Vom vedea daca va trebui mutata conditia in procedura rapJurnalTvaVanzari. 
--	Conditiile ciudate de mai jos tin de momentul initial, cand campul grupa a fost utilizat ca si cont de TVA
--		and (/*@Bugetari=1 or */@D394=1 or a.grupa like RTrim(@Ct4427)+'%' or charindex('.',a.grupa)=2 or len(a.grupa)<3 or left (a.grupa,3)='***' or @STOEHR=1 and a.grupa like 'N%') 
		and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and a.cont_venituri like rtrim(@ContCor)+'%' 
		and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	union all 
	select a.subunitate,a.numar,a.numar,a.tip,a.data,a.numar,'',pret_de_stoc*cantitate,pret_de_stoc*cantitate,a.tva_deductibil,
		isnull(a.detalii.value('/row[1]/@explicatii','varchar(1000)'),a.factura+a.contract),'A',a.cota_tva,0,0,a.data,
		(case when @OrdDenTert=1 then isnull(a.detalii.value('/row[1]/@explicatii','varchar(1000)'),a.factura+a.contract) else '' end),
		(case when charindex(rtrim(a.cont_venituri),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),@Ct4427,a.cont_corespondent,0,'V',numar_pozitie,a.tip,a.cod,'',a.cont_factura,a.detalii,0,a.Data,
		a.cont_de_stoc,a.idpozdoc
	from pozdoc a 
		left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
	where @nTVAex in (0,2) and a.subunitate=@Sb and a.tip='AE' and a.tva_deductibil<>0 
		and a.data between @DataJ and @DataS 
		and (@ContFExcep=0 and a.cont_factura like rtrim(@ContFFlt)+'%' or @ContFExcep=1 and a.cont_factura not like rtrim(@ContFFlt)+'%') and (a.cota_tva=@CotaTVA or a.cota_tva>0) 
		and (@TVAnx=0 and a.cont_factura<>'418' or @TVAnx=1 and a.cont_factura='418') and (@Gest='' or a.gestiune=@Gest)
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and @Tert='' and (@Factura='' or a.numar=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and a.cont_corespondent like rtrim(@ContCor)+'%' 
		and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	union all 
	select a.subunitate,a.numar,a.numar,a.tip,(case when @OrdDataDoc=0 then isnull(a.Data_facturii,a.data) else a.data end),a.numar,'',round(convert(decimal(17,5),pret_de_stoc*cantitate*a.procent_vama/100),2),
		round(convert(decimal(17,5),pret_de_stoc*cantitate*a.procent_vama/100),2),round(convert(decimal(17,5),pret_de_stoc*cantitate*a.procent_vama/100*a.cota_tva/100),2),
		(select nume from personal where marca=a.gestiune_primitoare),'A',a.cota_tva,0,0,a.data,(case when @OrdDenTert=1 then t.denumire else '' end),
		(case when charindex(rtrim(a.cont_venituri),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),@Ct4427,a.cont_venituri,0,'V',numar_pozitie,a.tip,a.cod,'',a.cont_factura,a.detalii,0,a.Data_facturii,
		a.cont_de_stoc,a.idpozdoc
	from pozdoc a 
		left outer join terti t on a.subunitate=t.subunitate and a.tert=t.tert 
		left join doc d on @marcaj<>0 and a.subunitate=d.subunitate and a.tip=d.tip and a.data=d.data and a.numar=d.numar and d.detalii.value('(row/@marcaj)[1]','int')=1
	--	tabela facturi nu pare a fi folosita justificat:
			--	left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
	where @nTVAex in (0,2) and a.subunitate=@Sb and a.tip='DF' and a.cota_tva>0 and a.procent_vama>0 
		and ((@D394=0 or a.Data_facturii='1901-1-1') and a.data between @DataJ and @DataS or @D394=1 and a.Data_facturii between @DataJ and @DataS)
		and (@ContFExcep=0 and a.cont_factura like rtrim(@ContFFlt)+'%' or @ContFExcep=1 and a.cont_factura not like rtrim(@ContFFlt)+'%') and (@TVAnx=0 and a.cont_factura<>'418' or @TVAnx=1 and a.cont_factura='418') and (@Gest='' or a.gestiune=@Gest)
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and @Tert='' and (@Factura='' or a.numar=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and a.cont_venituri like rtrim(@ContCor)+'%' 
		and (@marcaj=0 or @marcaj=1 and d.numar is not null or @marcaj=2 and d.numar is null)
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
		
	--insert #tvavanz select * from dbo.docTVAVanzAdoc(@Sb,@DataJ,@DataS,@ContFFlt,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,@TVAnx,@RecalcBaza,@CtVenScDed,@CtPIScDed,@o_nTVAex,@FFFBTVA0,@SiFactAnul,@OrdDataDoc,
	--	@OrdDenTert,@Tert,@Factura,@CotaTVA,@Ct4427,@Ct4428,@DrumOR,@Metrou,@D394)
	--	where not (@D394=1 and (tipD='PI' and cont_coresp like '419%' or tipD='CB' and contf like '419%'))

	--set @o_nTVAex=@nTVAex -- nu mai este necesar, s-a facut sus
	if @marcaj in (0,2)
	insert #tvavanz
	select a.Subunitate,a.Numar,a.Cont as numarD,'PI',(case when @OrdDataDoc=0 then isnull(c.Data,a.Data) else a.Data end),a.Factura,a.Tert,
		(case when a.Plata_incasare in ('IC','IR') and a.suma=a.TVA22 and a.TVA11<>0 then 
			(case when left(a.Numar,4)='ITVA' and isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)>=0.01 
				then isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)-a.TVA22 else round(a.TVA22*100/a.TVA11,2) end) 
			else a.Suma-a.TVA22 end) as valoare_factura,
		(case when a.TVA11=0 then 0 else (case when @RecalcBaza=1 or a.Plata_incasare in ('IC','IR') and a.suma=a.TVA22 and a.TVA11<>0 then 
			(case when left(a.Numar,4)='ITVA' and isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)>=0.01 
				then isnull(nullif(a.detalii.value('(/row/@valachitat)[1]','decimal(12,3)'),0),a.Curs)-a.TVA22 else round(a.TVA22*100/a.TVA11,2) end) 
			else a.suma-a.TVA22 end) end) as baza_22,
		a.TVA22 as tva_22,a.explicatii,'B',a.TVA11,0,0,a.data,(case when @OrdDenTert=1 then left(d.denumire,30) else '' end),
		(case when charindex(rtrim(a.cont_corespondent),@CtVenScDed)>0 or charindex(rtrim(left(a.cont,3)),@CtPIScDed)>0 or @DrumOR=1 then 'C' else 'F' end),@Ct4427,a.cont_corespondent,
		(case when a.plata_incasare='IC' and a.tip_tva in (1, 2) then a.tip_tva else 0 end),'V',a.numar_pozitie,a.plata_incasare,'',a.loc_de_munca,a.cont,
		a.detalii,a.tip_tva,isnull(c.Data,a.Data),null,a.idpozplin
	from pozplin a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
		left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert
		left join infotert inf on inf.subunitate=d.Subunitate and d.tert=inf.tert and Identificator=''
	where @nTVAex in (0,(case when a.plata_incasare='IC' and a.tip_tva in (1, 2) then 1 else 2 end)) and a.subunitate=@Sb and a.data between @DataJ and @DataS and a.plata_incasare in ('IC','IR') 
		and (@ContFExcep=0 and a.cont like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont not like rtrim(@ContF)+'%') and (@TVAnx=0 and left(a.cont,3)<>'418' or @TVAnx=1 and a.cont like '418%') and @Gest=''
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) 
		and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and not (@D394=1 and a.cont_corespondent like '419%')
		and (@ContCor='' or a.cont_corespondent like rtrim(@ContCor)+'%')
		and (@tipuridocument='' or charindex(',PI,',@tipuridocument)>0)
		-- deoarece filtrarea se face in jurnalTVAVanzari, am eliminat-o de aici
		/*and (a.plata_incasare<>'IC' -- pe liniile urmatoare se trateaza IB in functie de tip terti (platitor, neplatitor)
			--or @TipTvaTert=0 or @TipTvaTert=1 and LEFT(isnull(grupa13,''),1)<>'1' and d.Tert is not null or @TipTvaTert=2 and LEFT(isnull(grupa13,'1'),1)='1')
			--left join infotert inf on inf.subunitate=t.Subunitate and t.tert=inf.tert and Identificator=''
			or @TipTvaTert=0 --or @TipTvaTert=1 and LEFT(isnull(grupa13,''),1)<>'1' or @TipTvaTert=2 and LEFT(isnull(grupa13,''),1)='1'
				or isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=a.Tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')=(case @TipTvaTert when 1 then 'P' when 2 then 'N' else 'I' end))*/
	union all 
	select a.Subunitate,a.Numar,a.Cont as numarD,'PI' as tipD,(case when @OrdDataDoc=0 then isnull(c.data,a.data) else a.Data end),a.Factura,a.Tert,a.suma-a.TVA22,
		(case when a.TVA11=0 then 0 else (case when @RecalcBaza=0 then a.suma-a.TVA22 else round(a.TVA22*100/a.TVA11,2) end) end),a.TVA22,a.explicatii,'C',a.TVA11,0,0,a.data,
		(case when @OrdDenTert=1 then left(d.denumire,30) else '' end),(case when charindex(rtrim(a.cont_corespondent),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),@Ct4427,a.cont_corespondent,0,'V',
		a.numar_pozitie,a.plata_incasare,'','',a.cont,a.detalii,0,c.data,null,a.idpozplin
	from pozplin a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
		left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
	where @nTVAex in (0,2) and a.subunitate=@Sb and a.data between @DataJ and @DataS and a.plata_incasare='IB' 
		and (@ContFExcep=0 and a.cont like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont not like rtrim(@ContF)+'%') and @TVAnx=0 and left(a.cont_corespondent,3) in ('419','267','472') and a.TVA22<>0 and @Gest=''
		and (@LMExcep=0 and a.loc_de_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_de_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) 
		and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and (@ContCor='' or a.cont_corespondent like rtrim(@ContCor)+'%')
		and (@tipuridocument='' or charindex(',PI,',@tipuridocument)>0)
	union all 
	select a.subunitate,a.numar_document,a.numar_document,a.tip,(case when @OrdDataDoc=0 then isnull(c.data,a.data) else a.data end),a.factura_stinga,a.tert,
		(case when @IFN=0 and a.tip='FB' and a.cont_cred like RTrim(@Ct4427)+'%' and a.suma=0 then round(a.TVA22*100/@CotaTVA,2) else a.suma end),
		(case when a.TVA11=0 or a.tip='FB' and (/*@IFN=0 or */a.TVA11=0) and a.TVA22=0 then 0 else (case when @RecalcBaza=0 then a.suma else round(a.TVA22*100/a.TVA11,2) end) end),a.TVA22, '','D',
		(case when a.tip='FB' and (/*@IFN=0 or */a.TVA11=0) and a.TVA22=0 then 0 else a.TVA11 end),0,0,a.data,(case when @OrdDenTert=1 then left(d.denumire,30) else '' end),
		(case when charindex(rtrim(left(a.cont_cred,3)),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),(case when a.tip='FB' and a.tert_beneficiar<>'' then a.tert_beneficiar else @Ct4427 end),a.cont_cred,
		(case when a.stare in (1,2) then a.stare else 0 end),'V',a.numar_pozitie,a.tip,'',(case a.tip when 'IF' then a.factura_dreapta else '' end),a.cont_deb,null,a.stare,a.Data_fact,null,a.idpozadoc
	from pozadoc a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
		left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura_stinga=c.factura and a.tert=c.tert 
	where a.subunitate=@Sb and a.data between @DataJ and @DataS 
		and (a.tip='FB' and (@FFFBTVA0='0' and a.TVA22<>0 or @FFFBTVA0='1' and a.TVA11<>0 or @FFFBTVA0='2') 
			or a.tip='IF' and not (@IFN=1 and len(rtrim(a.factura_stinga))>1 and left(a.factura_stinga, len(rtrim(a.factura_stinga))-1)=a.factura_dreapta)) 
		and @nTVAex in (0,(case when a.stare in (1,2) then 1 else 2 end)) and (@ContFExcep=0 and a.cont_deb like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont_deb not like rtrim(@ContF)+'%') 
		and (@TVAnx=0 and left(a.cont_deb,3)<>'418' and (a.tip='IF' and a.valuta<>'' or a.tert_beneficiar='' or a.tert_beneficiar like rtrim(@Ct4427)+'%' or @D394=1) 
			or @TVAnx=1 and (a.cont_deb like '418%' and a.tert_beneficiar='' or left(a.tert_beneficiar,4)=@Ct4428)) and not (a.cont_cred like '89%' and a.TVA22=0) and @Gest=''
		and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) 
		and (@Factura='' or a.factura_stinga like RTrim(@Factura)+(case when @IFN=1 then '%' else '' end)) 
		and not ((a.explicatii like '%CONV%DIF.%CURS%' or isnull(a.detalii.value('(/row/@difconv)[1]', 'int'),0)=1) and a.tip='FB')--and a.numar_document like 'DIFC%') 
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
		and (@ContCor='' or a.Cont_cred like rtrim(@ContCor)+'%')
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	union all 
	select a.subunitate,a.numar_document as numar,a.numar_document as numarD,a.tip as tipD,(case when @OrdDataDoc=0 then isnull(c.data,a.data) else a.data end),/*a.factura_dreapta*/a.Factura_stinga,a.tert,
		-a.suma+a.TVA22,(case when a.TVA11=0 then 0 else -(case when @RecalcBaza=0 then a.suma-a.TVA22 else round(a.TVA22*100/a.TVA11,2) end) end),-a.TVA22,'','D',a.TVA11,0,0,a.data,
		(case when @OrdDenTert=1 then left(d.denumire,30) else '' end),(case when @DrumOR=1 then 'C' else 'F' end),@Ct4427,a.Cont_deb,0,'V',a.numar_pozitie,a.tip,'','',a.cont_cred,null,0,null,null,a.idpozadoc
	from pozadoc a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
		left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and /*a.factura_dreapta*/a.Factura_stinga=c.factura and a.tert=c.tert 
	where @nTVAex in (0,2) and a.subunitate=@Sb 
--	am lasat sa nu aduca pentru Arobs CB-urile in valuta. Pe caz general trebuie sa aduca CB-urile in valuta pentru a diminua valoarea facturii finale (altfel se dubleaza sumele, ar aparea si factura de avans si factura finala)
		and a.data between @DataJ and @DataS and a.tip='CB' and (a.TVA22<>0) --or @Arobs=0 and a.cont_deb like '419%' and a.valuta<>'')
		and (@ContFExcep=0 and a.Cont_cred like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont_cred not like rtrim(@ContF)+'%') 
		and (@TVAnx=0 and left(a.Cont_cred,3)<>'418' or @TVAnx=1 and (a.cont_cred like '418%' or @Metrou=1 and a.cont_cred like '267%')) and @Gest=''
		and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') and (@Jurnal='' or a.jurnal=@Jurnal) 
		and (@Tert='' or a.tert=@Tert) and (@Factura='' or /*a.factura_dreapta*/a.Factura_stinga=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
		and not (@D394=1 and a.cont_deb like '419%')
		and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)

	if @IFN=1
		update #tvavanz
		set factura=left(factura,len(rtrim(factura))-(case when upper(substring(reverse(rtrim(factura)),2,1)) between 'A' and 'Z' then 2 when upper(right(rtrim(factura),1)) between 'A' and 'Z' then 1 else 0 end))
		where tipD in ('FB', 'IF') and upper(right(rtrim(factura),1)) between 'A' and 'Z'

	if @nTVAex in (0, 2)
	begin
		--insert #tvavanz select * from dbo.docTVAVanzMisMf(@Sb,@DataJ,@DataS,@ContF,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,@TVAnx,@RecalcBaza,@CtVenScDed,@nTVAex,@SiFactAnul,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,@CotaTVA,@DrumOR,@Ct4427)
		if @marcaj in (0,2)
		insert #tvavanz
		select a.subunitate,a.numar_document,a.numar_document as numarD,'ME' as tipD,(case when @OrdDataDoc=0 then isnull(c.data,a.data_miscarii) else a.data_miscarii end),
			(case when a.tip_miscare='ECS' then a.numar_document else a.factura end),a.tert,a.pret,(case when abs(a.pret-round(a.tva*100/@CotaTVA,2))>10 and @RecalcBaza=1 then round(a.tva*100/@CotaTVA,2) else a.pret end),
			a.TVA,'','M',@CotaTVA,0,0,a.data_miscarii,(case when @OrdDenTert=1 then d.denumire else '' end),(case when charindex(rtrim(a.cont_corespondent),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),
			(case when a.tip_miscare='ECS' then a.loc_de_munca_primitor else @Ct4427 end),a.gestiune_primitoare,0,'V',0,'ME','','',a.cont_corespondent,null,0,null,null,null
		from misMF a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
		left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.tert=c.tert 
		where a.procent_inchiriere not in (1, 6, 9) and a.subunitate=@Sb 
			and a.data_miscarii between @DataJ and @DataS and (a.tip_miscare='EVI' or a.tip_miscare='ECS' and abs(a.tva)>=0.01 and a.loc_de_munca_primitor like RTrim(@Ct4427)+'%') 
			and (@ContFExcep=0 and a.cont_corespondent like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont_corespondent not like rtrim(@ContF)+'%') 
			and (@TVAnx=0 and left(a.cont_corespondent,3)<>'418' or @TVAnx=1 and a.cont_corespondent like '418%') 
			and @Gest=''
			and (@LMExcep=0 and isnull(c.loc_de_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(c.loc_de_munca,'') not like rtrim(@LM)+'%') and @Jurnal='' 
			and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=c.Loc_de_munca))
			and (@tipuridocument='' or charindex(',ME,',@tipuridocument)>0)
		
		if @SiFactAnul=1 -- facturi anulate: trebuie sa apara in jurnal daca @SiFactAnul=1!
			insert #tvavanz
			select a.subunitate,a.numar,a.numar,a.tip,(case when @OrdDataDoc=0 then isnull(c.data,a.data) else a.data end),a.factura,a.cod_tert,0,0,0,'','A',0,0,0,a.data,(case when @OrdDenTert=1 then d.denumire else '' end),
				(case when charindex(rtrim(a.cont_factura),@CtVenScDed)>0 or @DrumOR=1 then 'C' else 'F' end),@Ct4427,'',0,'V',-1,a.tip,'','',a.cont_factura,null,0,a.Data_facturii,null,null
			from doc a 
			left outer join terti d on a.subunitate=d.subunitate and a.cod_tert=d.tert 
				left outer join facturi c on c.tip=0x46 and a.subunitate=c.subunitate and a.factura=c.factura and a.cod_tert=c.tert 
			where a.subunitate=@Sb and a.tip in ('AP','AS') and a.stare=1
				and a.data between @DataJ and @DataS and (@ContFExcep=0 and a.cont_factura like rtrim(@ContF)+'%' or @ContFExcep=1 and a.cont_factura not like rtrim(@ContF)+'%') 
				and (@TVAnx=0 and left(a.cont_factura,3)<>'418' /*and a.tip_miscare<>'8'*/ or @TVAnx=1 and (a.cont_factura like '418%' /*or a.tip_miscare='8'*/)) and (@Gest='' or a.cod_gestiune=@Gest)
				and (@LMExcep=0 and a.loc_munca like rtrim(@LM)+'%' or @LMExcep=1 and a.loc_munca not like rtrim(@LM)+'%') 
				and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.cod_tert=@Tert) and (@Factura='' or a.factura=@Factura)
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_munca))
				and (@marcaj=0 or @marcaj=1 and a.detalii.value('(row/@marcaj)[1]','int')=1 or @marcaj=2 and a.detalii.value('(row/@marcaj)[1]','int') is null)
				and (@tipuridocument='' or charindex(','+a.tip+',',@tipuridocument)>0)
	end
end
-- facturi din bonuri (PV) plus o linie de "diminuare bonuri":
if (@marcaj=0 or @marcaj=2)
begin
--insert #tvavanz select *,null,0 from dbo.docTVAVanzBFF(@Sb,@RotAP,@DataJ,@DataS,@ContF,@Gest,@LM,@LMExcep,@Jurnal,@TVAnx,@RecalcBaza,@o_nTVAex,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,@D394)
--	s-a inlocuit apelul functiei docTVAVanzBFF cu continutul ei
/* PV 9.4 si PVria.POS (v1) - VERSIUNI VECHI! */
if exists (select 1 from sysobjects o where o.type='U' and o.name='factposleg')
	and exists (select 1 from sysobjects o where o.type='U' and o.name='factpos')
	insert #tvavanz
	select @Sb, rtrim(convert(char(10), bp.numar_bon)), rtrim(convert(char(10), bp.numar_bon)), 'BP', bp.data, fpl.factura, 
		(case when @TertBP=1 then left(fpl.cod_fiscal,13) else '' end), round(convert(decimal(20, 5), bp.total-bp.tva), 2) as valoare_factura, 
		(case when bp.cota_tva<>0 then (case when @RecalcBaza=0 then round(convert(decimal(20, 5), bp.total-bp.tva), 2) else round(bp.tva, 2)*100/bp.cota_tva end) else 0 end) as baza_22,
		round(bp.tva, 2) as tva_22, left(isnull(t.denumire, isnull(fp.denumire, '')),50) as explicatii, (case when @TertBP=0 then 'F' /*tert din factpos*/else '' end), bp.cota_TVA,
		0 as discFaraTVA, 0 as discTVA, bp.data, (case when @OrdDenTert=1 then isnull(t.denumire, isnull(fp.denumire, '')) else '' end) as ordonare, 'C',
		(case when @TertBP=0 then fpl.cod_fiscal else '' end), '', 0, 'V', bp.numar_linie, 'BP', bp.cod_produs, '', '', null, 0, null, null, null
	from bp 
		inner join factposleg fpl on fpl.nr_bon=bp.numar_bon and fpl.casa_de_marcat=bp.casa_de_marcat and fpl.data=bp.data
		left outer join terti t on @TertBP=1 and t.subunitate=@Sb and t.tert=fpl.cod_fiscal
		left outer join factpos fp on @TertBP=0 and fp.cod_fiscal=fpl.cod_fiscal
	where (@AplPV=1 and @DetBon=0 or @PVria=1) and bp.factura_chitanta=1 and bp.tip='21' 
		and fpl.factura<>'' and @nTVAex_0238=1 and bp.data between @DataJ and @DataS and @ContF='' 
		and @TVAnx=0 and @Gest='' and @Lm='' and @Jurnal='' and (@Tert='' or @TertBP=1 
		and fpl.cod_fiscal=@Tert) and (@Factura='' or fpl.factura=@Factura)
		and fpl.cod_fiscal<>'' and len(rtrim(fpl.cod_fiscal))<13 
		and (isnull(@D394,0)=0 or exists --(select 1 from infotert inf where inf.subunitate=@Sb and fpl.cod_fiscal=inf.tert and Identificator='' and LEFT(grupa13,1)<>'1')
			(select top 1 1/*tt.tip_tva*/ from tvapeterti tt where tt.tert=fpl.cod_fiscal and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' and tt.tip_tva<>'N' order by tt.dela desc))
	union all 
	select a.subunitate, numar, numar+space(5), 'BP', a.data, a.factura, a.tert, round(convert(decimal(20, 5), pret_vanzare*cantitate), @RotAP) as valoare_factura,
		(case when a.cota_tva<>0 then (case when @RecalcBaza=0 then round(convert(decimal(20, 5), pret_vanzare*cantitate), @RotAP) else round(a.tva_deductibil, 2)*100/a.cota_tva end) else 0 end) as baza_22,
		round(a.tva_deductibil, 2) as tva_22, space(50), '', a.cota_tva, round((pret_valuta-pret_vanzare)*cantitate, 2) as discFaraTVA, round((pret_valuta-pret_vanzare)*cantitate*a.cota_tva/100, 2) as discTVA,
		a.data, (case when @OrdDenTert=1 then d.denumire else '' end) as ordonare, 'C', '', '', 0, 'V', numar_pozitie, a.tip, a.cod, '', '', null, 0, a.Data_facturii, a.Cont_de_stoc, a.idPozdoc
	from pozdoc a 
		left outer join terti d on a.subunitate=d.subunitate and a.tert=d.tert 
	where (@AplPV=1 and @DetBon=1 and @PVria=0 or @AplPV=0 and @GenICAC=0 and a.stare<>5) 
		and a.factura<>'' and a.tert<>'' and a.subunitate=@Sb and a.tip='AC' and @nTVAex_0238=1
		and a.data between @DataJ and @DataS and @ContF='' and @TVAnx=0 and (@Gest='' or a.gestiune=@Gest) 
		and (@LMExcep=0 and isnull(a.loc_de_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(a.loc_de_munca,'') not like rtrim(@LM)+'%') 
		and (@Jurnal='' or a.jurnal=@Jurnal) and (@Tert='' or a.tert=@Tert) and (@Factura='' or a.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare u where u.utilizator=@utilizator and u.cod=a.Loc_de_munca))

/* PVria v2 - VERSIUNE CURENTA */
	if exists (select * from sysobjects where name='antetBonuri')
	insert #tvavanz
	select @Sb, rtrim(convert(char(10), bp.numar_bon)), 
		rtrim(convert(char(10), bp.numar_bon)), 'BP', /*bp.data*/ant.data_facturii, ant.factura, 
		ant.tert, round(convert(decimal(20, 5), bp.total-bp.tva), 2) as valoare_factura, 
		(case when bp.cota_tva<>0 then (case when @RecalcBaza=0 then round(convert(decimal(20, 5), bp.total-bp.tva), 2) 
			else round(bp.tva, 2)*100/bp.cota_tva end) else 0 end) as baza_22, round(bp.tva, 2) as tva_22, 
		isnull(rtrim(substring(t.denumire,1,30)),'') as explicatii, '', bp.cota_TVA, 0 as discFaraTVA, 0 as discTVA, bp.data, 
		(case when @OrdDenTert=1 then isnull(t.denumire, '') else '' end) as ordonare, 'C', 
		'', '', 0, 'V', bp.numar_linie, 'BP', bp.cod_produs, (case when @ExpandareDiminuari=1 then ant.loc_de_munca else '' end), '', null, 0, ant.data_facturii, null, null
	from bp 
		inner join antetBonuri ant on ant.numar_bon = bp.numar_bon and ant.casa_de_marcat=bp.casa_de_marcat and ant.vinzator=bp.Vinzator and ant.data_bon=bp.data
		left outer join terti t on t.subunitate=@Sb and t.tert=ant.tert
	where bp.factura_chitanta=1 and bp.tip='21' and isnull(ant.factura,'')<>'' 
		and @nTVAex_0238=1 and /*bp.data*/ant.data_facturii between @DataJ and @DataS and @ContF='' 
		and @TVAnx=0 and (@Gest='' or ant.gestiune=@Gest) 
		and (@LMExcep=0 and isnull(ant.loc_de_munca,'') like rtrim(@LM)+'%' or @LMExcep=1 and isnull(ant.loc_de_munca,'') not like rtrim(@LM)+'%') --and @Gest='' and @Lm='' 
		and @Jurnal='' and (@Tert='' or ant.tert=@Tert) and (@Factura='' or ant.factura=@Factura)
		and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare u where u.utilizator=@utilizator and u.cod=ant.Loc_de_munca))
end

-- facturi din UAPlus:
if exists (select 1 from sysobjects o where o.type='TF' and o.name='docTVAVanzUA') and @nTVAexUA<>8 and (@marcaj=0 or @marcaj=2) 
	and exists (select 1 from sysobjects o where o.type='U' and o.name='incfactabon')
begin
	set @nTVAexUA=@nTVAexUA+(@o_nTVAex/10)*10
	insert #tvavanz(subunitate,numar,numarD,tipD,data,factura,tert,valoare_factura,baza_22,tva_22,explicatii,tip,cota_tva,discFaraTVA,discTVA,data_doc,ordonare,drept_ded,
	cont_TVA,cont_coresp,exonerat,vanzcump,numar_pozitie,tipDoc,cod,factadoc,contf,detalii,tip_tva,dataf)
	select subunitate,numar,numarD,tipD,data,factura,tert,valoare_factura,baza_22,tva_22,explicatii,tip,cota_tva,discFaraTVA,discTVA,data_doc,ordonare,drept_ded,
	cont_TVA,cont_coresp,exonerat,vanzcump,numar_pozitie,tipDoc,cod,factadoc,contf,null,0,dataf
	from dbo.docTVAVanzUA(@Sb,@DataJ,@DataS,@ContFFlt,@LM,@Jurnal,@TVAnx, @nTVAexUA, @TVAAlteCont,@Tert,@Factura,@CotaTVA,@D394UA)
end
-- facturi din UARIA:
if exists (select 1 from sysobjects o where o.type='P' and o.name='TVAVanzariUA') and @nTVAexUA<>8 and (@marcaj=0 or @marcaj=2) 
	and exists (select 1 from sysobjects o where o.type='U' and o.name='Antetfactabon')
begin
	set @nTVAexUA=@nTVAexUA+(@o_nTVAex/10)*10
	exec TVAVanzariUA @Sb,@DataJ,@DataS,@ContF,@LM,@Jurnal,@TVAnx,@nTVAexUA,@TVAAlteCont,@Tert,@Factura,@CotaTVA,@D394,@sesiune
end

-- facturi daca exista procedura specifica:
if exists (select 1 from sysobjects o where o.type='TF' and o.name='docTVAVanzSP') --and @nTVAex<>8
	insert #tvavanz select *,null,0,null,null,null from dbo.docTVAVanzSP(@Sb,@DataJ,@DataS,@ContF,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,
		@ContCor,@TVAnx,@RecalcBaza,@CtVenScDed,@CtPIScDed,@nTVAex,@FFFBTVA0,@SiFactAnul,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,@CotaTVA,@D394,@FaraCump)

if @nTVAex in (0,1) and @FaraCump=0 
begin
/*
	insert #tvavanz -- pentru cumparari cu TVA exonerat
	select * from dbo.docTVACump(@DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,1,@FFFBTVA0,1,0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,0,1,0, @parXML)
*/
	insert #tvavanz -- pentru cumparari cu TVA exonerat
	exec dbo.TVACumparari @DataJ,@DataS,@ContFFlt,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,1,@FFFBTVA0,1,0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,0,1,0, @parXML
end

if @ListaContF=1 begin
	declare @lc table (cont varchar(40))
	insert @lc 
	select left([Item],13) from dbo.Split(@ContF,';')
	
	delete #tvavanz 
	from #tvavanz d 
	where (@ContFExcep=0 and not exists (select 1 from @lc l where d.contf like RTrim(l.cont)+'%')
		or @ContFExcep=1 and exists (select 1 from @lc l where d.contf like RTrim(l.cont)+'%'))
end
if @ExpandareDiminuari=1	--> pentru eliminare diminuare bonuri din PV - nu e gata inca (pentru Unisem, facut de Cristy)
begin
	declare @randuriupd float,@randuridel float
	select @randuriupd=sum(d2.baza_22)
		from #tvavanz d1,#tvavanz d2 where d1.data=d2.data and d1.tert='' and d2.factadoc=d1.factadoc and d2.tert='<Dim BF>' and d1.explicatii='Vanzari PVria'
	select @randuridel=sum(d2.baza_22)
		from #tvavanz d2 where d2.tert='<Dim BF>'

	if @randuriupd=@randuridel --Doar daca nu afectam deloc jurnalul TVA adica cate updateuri facem tot atatea deleturi. Daca datele nu sunt OK mai bine nu facem nimic.
	begin
		update d1 set d1.baza_22=d1.baza_22+d2.baza_22,d1.tva_22=d1.tva_22+d2.tva_22,d1.valoare_factura=d1.valoare_factura+d2.valoare_factura
			from #tvavanz d1,#tvavanz d2 where d1.data=d2.data and d1.tert='' and d2.factadoc=d1.factadoc and d2.tert='<Dim BF>' and d1.explicatii='Vanzari PVria'

		delete d2
			from #tvavanz d1,#tvavanz d2 where d1.data=d2.data and d1.tert='' and d2.factadoc=d1.factadoc and d2.tert='<Dim BF>' and d1.explicatii='Vanzari PVria'
	end
end

--	apel procedura specifica ce va putea modifica datele din tabela #tvavanz 
set @parXMLSP=(select @DataJ as datajos, @DataS as datasus for xml raw)
if exists (select 1 from sysobjects where [type]='P' and [name]='TVAVanzariSP')  
	exec TVAVanzariSP @parXML=@parXMLSP

--	selectul final
if @faraReturnareDate=0
	select subunitate, numar, numarD, tipD, data, factura, tert, valoare_factura, baza_22, tva_22, explicatii, 
		tip, cota_tva, discFaraTVA, discTVA, data_doc, ordonare, drept_ded, cont_TVA, cont_coresp, exonerat,
		vanzcump, numar_pozitie, tipDoc, cod, factadoc, contf, detalii, tip_tva, dataf, cont_de_stoc, idpozitie
	from #tvavanz 
	where (@FaraCump=0 or exonerat=1)
end
