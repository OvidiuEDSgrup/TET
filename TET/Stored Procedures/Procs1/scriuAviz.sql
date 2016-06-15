--***
create procedure scriuAviz @Tip char(2),@Numar char(8) output,@Data datetime output,@Tert char(13),@PctLiv char(5),@CtFact char(13) output,
	@Fact char(20),@DataFact datetime,@DataScad datetime,@Gest char(9),@Cod char(20),@CodIntrare char(13),@Cantitate float,
	@PretValuta float,@Valuta char(3),@Curs float,@Discount float,@PretVanz float,@CotaTVA float,@SumaTVA float output,@PretAm float,
	@CategPret int,@LM char(9),@Comanda char(40),@ComLivr char(20),@Jurnal char(3),@Stare int,
	@Barcod char(30),@TipTVAsauSchimb int,@Suprataxe float,@Serie char(20),@Utilizator char(10), 
	@ValFact float output,@ValTVA float output,@ValValuta float output,@NrPozitie int=0 output,@PozitieNoua int=0
as

declare @Sb char(9),@TPreturi int,@DiscInv int,
	@TLit int,@Accize int,@CtAccDB char(13),@CtAccCR char(13),@DifPProd int,
	@Ct378 char(13),@AnGest378 int,@AnGr378 int,@Ct4428 char(13),@AnGest4428 int,
	@Ct4427 char(13),@Ct4428AV char(13),
	@TipNom char(1),@CtNom char(13),@PStocNom float,@GrNom char(13),@StLimNom float,@CoefC2Nom float,@CategNom int,
	@TipGest char(1),@CtGest char(13),@CategMFix int,@ValAmMFix float,@CtAmMFix char(13),
	@PretSt float,@CtStoc char(13),@TVAnx float,@PretAmPred float,@LocatieStoc char(30),@DataExpStoc datetime,
	@DiscAplic float,@CtCoresp char(13),@CtInterm char(13),@CtVenit char(13),@CtAdPred char(13),@CtTVAnxPred char(13),
	@CtTVA char(13),@AccCump float,@AccDat float, @StersPoz int, @Bugetar int

exec luare_date_par 'GE','SUBPRO',0,0,@Sb output
exec luare_date_par 'GE','PRETURI',@TPreturi output,0,''
exec luare_date_par 'GE','INVDISCAP',@DiscInv output,0,''
exec luare_date_par 'GE','TIMBRULIT',@TLit output,0,''
exec luare_date_par 'GE','ACCIZE',@Accize output,0,''
exec luare_date_par 'GE','CCHACCIZE',0,0,@CtAccDB output
exec luare_date_par 'GE','CACCIZE',0,0,@CtAccCR output
exec luare_date_par 'GE','CADAOS',@AnGest378 output,@AnGr378 output,@Ct378 output
exec luare_date_par 'GE','CNTVA',@AnGest4428 output,0,@Ct4428 output
exec luare_date_par 'GE','CCTVA',0,0,@Ct4427 output
exec luare_date_par 'GE','CNEEXREC',0,0,@Ct4428AV output
exec luare_date_par 'GE','CONT348',@DifPProd output,0,''
exec luare_date_par 'GE','BUGETARI',@Bugetar output,0,''

if isnull(@Tip,'')='' set @Tip='AP'
exec iauNrDataDoc @Tip,@Numar output,@Data output,0
if @Stare is null set @Stare=3
if @Fact is null set @Fact=@Numar

select @TipNom='',@CtNom='',@PStocNom=0,@GrNom='',@CoefC2Nom=0,@CategNom=0,@StLimNom=0
select @TipNom=tip,@CtNom=cont,@PStocNom=pret_stoc,@GrNom=grupa,
	@CoefC2Nom=Coeficient_conversie_1,@CategNom=categorie,@StLimNom=stoc_limita
from nomencl
where cod=@Cod

select @TipGest='',@LocatieStoc='',@DataExpStoc=@Data
if @TipNom not in ('S','F') begin
	select @TipGest=tip_gestiune,@CtGest=cont_contabil_specific
	from gestiuni 
	where subunitate=@Sb and cod_gestiune=@Gest

	select @PretSt=pret,@CtStoc=cont,@TVAnx=tva_neexigibil,@PretAmPred=pret_cu_amanuntul,@LocatieStoc=locatie,@DataExpStoc=data_expirarii,
		@Suprataxe=(case when @Tip='AC' and @DifPProd=1 and left(@CtGest,3)='371' then pret_vanzare else @Suprataxe end)
	from stocuri
	where subunitate=@Sb and tip_gestiune=@TipGest and cod_gestiune=@Gest and cod=@Cod and cod_intrare=@CodIntrare
end

set @DiscAplic=(case when @DiscInv=1 then (1-100/(100+@Discount))*100 else @Discount end)
if isnull(@PretVanz,0)=0
	set @PretVanz=@PretValuta*(case when @Valuta<>'' then @Curs else 1 end)*(1-@DiscAplic/100)
if isnull(@PretAm,0)=0
	set @PretAm=round(convert(decimal(17,5),@PretVanz*(1+@CotaTVA/100)),5)

if @TipNom='F'
begin
	select @CtStoc=@CtNom,@PretSt=0,@CategMFix=0,@ValAmMFix=0
	select @CtStoc=cont_mijloc_fix,@PretSt=valoare_de_inventar,@CategMFix=categoria,@ValAmMFix=valoare_amortizata
	from fisamf 
	where subunitate=@Sb and numar_de_inventar=@CodIntrare and felul_operatiei='1' and data_lunii_operatiei between (case when left(str(@StLimNom),1)<>'1' then dbo.bom(@Data) else '01/01/1901' end) and dbo.eom(@Data)
	set @CtAmMFix=isnull((select max(cod_de_clasificare) from mfix where subunitate='DENS' and numar_de_inventar=@CodIntrare),'')
end

if @PretSt is null set @PretSt=(case when @TipNom='S' then 0 when @TPreturi=1 then @PretVanz else isnull(@PStocNom,0) end)
if @CtStoc is null 
	set @CtStoc=dbo.formezContStoc(@Gest,@Cod,@LM)
if @TipNom='S' and isnull(@CodIntrare,'')='' and exists (select 1 from conturi where subunitate=@Sb and cont=@CtStoc and sold_credit=2)
	set @CodIntrare='AV'+RTrim(replace(convert(char(8),@Data,3),'/',''))
if @Tip<>'AC' 
begin
	if isnull(@CtFact,'')='' and @PctLiv<>'' 
		select @CtFact=cont_in_banca3 from infotert where subunitate=@Sb and tert=@Tert and identificator=@PctLiv
	if isnull(@CtFact,'')='' 
		select @CtFact=(case when isnull(@CtFact,'')='' then cont_ca_beneficiar else @CtFact end) from terti where subunitate=@Sb and tert=@Tert
end
if @CtFact is null
	set @CtFact=''
set @CtCoresp=(case when @TipNom='S' then @CtFact else dbo.contCorespAP(@Gest,@Cod,@CtStoc,@LM) end)
if @TipNom='F' 
	set @AccDat=@ValAmMFix
if @AccDat is null and @Accize=1
begin
	declare @AccCategProd int,@AccUnitVanz float
	exec luare_date_par 'GE','CATEGPRO',@AccCategProd output,0,''
	set @AccUnitVanz=isnull((select max(acciza_vanzare) from categprod where categoria=@CategNom),0)
	set @AccDat=round(convert(decimal(17,4),@CoefC2Nom*@AccUnitVanz*@Cantitate),3)
end
if @AccDat is null 
	set @AccDat=0

if isnull(@SumaTVA,0)=0
	set @SumaTVA=round(convert(decimal(17,4),@Cantitate*@PretVanz*@CotaTVA/100),2)

select @ValFact=isnull(@ValFact,0)+round(convert(decimal(17,3),@Cantitate*@PretVanz),2),
	@ValTVA=isnull(@ValTVA,0)+@SumaTVA,
	@ValValuta=isnull(@ValValuta,0)+(case when @Valuta<>'' then round(convert(decimal(17,3),@Cantitate*@PretValuta*(1-@DiscAplic/100)),2) else 0 end)

set @StersPoz=0
if isnull(@NrPozitie, 0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPoz=1
end
else
	select @NrPozitie=numar_pozitie
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and gestiune=@Gest and cod=@Cod 
	and cod_intrare=@CodIntrare and pret_valuta=@PretValuta and pret_vanzare=@PretVanz
	and cont_de_stoc=@CtStoc and cont_corespondent=@CtCoresp and loc_de_munca=@LM and comanda=@Comanda and factura=@Fact

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()
if isnull(@NrPozitie, 0)=0 or @StersPoz=1
begin
	if @TVAnx is null set @TVAnx=@CotaTVA
	select @PretAmPred=(case when left(@CtStoc,3)='354' then @PretSt when @PretAmPred is null then @PretAm else @PretAmPred end),
		@CtInterm=dbo.contIntermAP(@Gest,@Cod,@CtStoc,@CtCoresp),@CtVenit=dbo.contVenitAP(@Gest,@Cod,@CtStoc,@CtInterm)
	if @Bugetar=1 -- ind. bug. asociat contului de venituri 
		set @Comanda=left(@comanda,20)+(select Cont_strain from contcor where ContCG=@CtVenit)
	if @TipNom='F'
	begin
		declare @Ct681C char(13),@N681C int,@Ct681NC char(13),@N681NC int
		exec luare_date_par 'MF','CA681',0,@N681C output,@Ct681C output
		exec luare_date_par 'MF','681NECORP',0,@N681NC output,@Ct681NC output
		set @CtAdPred=(case when @CategMFix=7 
			then RTrim(@Ct681NC)+(case @N681NC when 2 then RTrim(substring(@CtStoc,3,11)) when 3 then '.'+RTrim(@LM) else '' end) 
			else RTrim(@Ct681C)+(case @N681C when 2 then RTrim(substring(@CtStoc,3,11)) when 3 then '.'+RTrim(@LM) else '' end) end)
	end
	if @CtAdPred is null and (@TLit=1 or @Accize=1)
		set @CtAdPred=@CtAccDB
	if @CtAdPred is null and (left(@CtStoc,3)='371' or left(@CtStoc,2)='35')
		set @CtAdPred=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@Gest) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)
	else
		set @CtAdPred=''
	
	if @TipNom='F'
		set @CtTVAnxPred=@CtAmMFix
	if @CtTVAnxPred is null and (@TLit=1 or @Accize=1)
		set @CtTVAnxPred=@CtAccCR
	if @CtTVAnxPred is null and (left(@CtStoc,3)='371' or left(@CtStoc,2)='35')
		set @CtTVAnxPred=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@Gest) else '' end)
	else
		set @CtTVAnxPred=''

	set @CtTVA=(case when left(@CtFact,3)='418' then @Ct4428AV else @Ct4427 end)
	set @AccCump=(case when @Accize=1 or @TipNom='F' then 0 when @TLit=1 then @PretAmPred else @CategPret end)
	
	if @StersPoz=0
	begin
		exec luare_date_par 'AP','POZITIE',0,@NrPozitie output,''
		set @NrPozitie=@NrPozitie+1
	end
	set @PozitieNoua=1
	
	insert pozdoc
	(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
	Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,
	Cod_intrare,Cont_de_stoc,Cont_corespondent,
	TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,
	Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,
	Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,
	Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,
	Accize_cumparare,Accize_datorate,Contract,Jurnal) 
	values
	(@Sb,@Tip,@Numar,@Cod,@Data,@Gest,@Cantitate,@PretValuta,@PretSt,(case when @PretSt>0 then round(convert(decimal(17,3),(@PretVanz/@PretSt-1)*100),2) else 0 end),
	@PretVanz,@PretAm,@SumaTVA,@CotaTVA,isnull(@Utilizator,''),convert(datetime,convert(char(10),getdate(),104),104), RTrim(replace(convert(char(8),getdate(),108),':','')),
	@CodIntrare,@CtStoc,@CtCoresp,@TVAnx,@PretAmPred,(case when isnull(@TipNom,'')='S' then 'V' else 'E' end),
	@LocatieStoc,@DataExpStoc,@NrPozitie,@LM,@Comanda,@Barcod,
	@CtInterm,@CtVenit,@Discount,@Tert,@Fact,@CtAdPred,left(@CtTVAnxPred,13)+@PctLiv,
	@Stare,@CtTVA,@CtFact,@Valuta,@Curs,@DataFact,@DataScad,@TipTVAsauSchimb,@Suprataxe,
	@AccCump,@AccDat,@ComLivr,@Jurnal)
	
	if @StersPoz=0
		exec setare_par 'AP','POZITIE',null,null,@NrPozitie,null
end
if isnull(@PozitieNoua,0)=0
	update pozdoc
	set cantitate=cantitate+@Cantitate,TVA_deductibil=TVA_deductibil+@SumaTVA,
		accize_datorate=accize_datorate+@AccDat,
		utilizator=@Utilizator,data_operarii=convert(datetime,convert(char(10),getdate(),104),104),ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':',''))
	where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	
	
-->>>>>>>>>start cod pentru lucrul cu serii<<<<<<<<<<<<<<--
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>''
	begin
	exec scriuPDserii @Tip,@Numar,@Data,@Gest,@Cod,@CodIntrare,@NrPozitie,@Serie,@Cantitate,''
	set @Cantitate =(select SUM(cantitate) from pdserii where tip=@Tip and Numar=@Numar and data=@Data and Gestiune=@Gest and cod=@Cod 
														  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie)
	end													  														  
-->>>>>>>>>stop cod pentru lucrul cu serii<<<<<<<<<<<<<<<--

	update pozdoc
	set cantitate=@Cantitate,utilizator=@Utilizator,
	data_operarii=convert(datetime,convert(char(10),getdate(),104),104),ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':',''))
	where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
		

