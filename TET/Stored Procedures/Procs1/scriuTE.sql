--***
create procedure scriuTE @Numar char(8) output,@Data datetime output,@GestPred char(9),@GestPrim char(9),@GestDest char(9),
	@Cod char(20),@CodIntrare char(13),@CodIPrim char(13) output,@CodIPrimNou int,@Cantitate float,@LocatiePrim char(30),
	@PretAmPrim float,@CategPret int,@Valuta char(3),@Curs float,@LM char(9),@Comanda char(40),@ComLivr char(20),@Jurnal char(3),@Stare int,
	@Barcod char(30),@Schimb int,@Serie char(20),@Utilizator char(10),@PastrCtSt int,
	@Valoare float output,@TotCant float output,@NrPozitie int=0 output,@PozitieNoua int=0,@CtCoresp char(13)='',@TVAnx float=null
as

declare @Sb char(9),@TabPreturi int,
	@TLitR int,@Accize int,@CtAccCR char(13),@FaraTVAnx int,@Ct348 char(13),@DifPProd int,@CtIntTE char(13),
	@Ct378 char(13),@AnGest378 int,@AnGr378 int,@Ct4428 char(13),@AnGest4428 int,
	@TipNom char(1),@CtNom char(13),@PStocNom float,@PAmNom float,@GrNom char(13),@CoefConv2Nom float,@CategNom int,@GreutSpecNom float,@TVANom float,
	@TipGestPred char(1),@TipGestPrim char(1),@CtGestPrim char(13),
	@PretSt float,@CtStoc char(13),@PretAmPred float,@LocatieStoc char(30),@DataExpStoc datetime,@DinCust int,@PVanzSt float,
	@PAmPreturi float,@PVanzPreturi float,
	@PretVanz float,@CtInterm char(13),@CtAdPred char(13),@CtAdPrim char(13),@CtTVAnxPred char(13),@CtTVAnxPrim char(13),
	@AccCump float,@AccDat float,@StersPozitie int,@Serii int

exec luare_date_par 'GE','SUBPRO',0,0,@Sb output
exec luare_date_par 'GE','PRETURI',@TabPreturi output,0,''
exec luare_date_par 'GE','TIMBRULT2',@TLitR output,0,''
exec luare_date_par 'GE','ACCIZE',@Accize output,0,''
exec luare_date_par 'GE','CACCIZE',0,0,@CtAccCR output
exec luare_date_par 'GE','CADAOS',@AnGest378 output,@AnGr378 output,@Ct378 output
exec luare_date_par 'GE','CNTVA',@AnGest4428 output,0,@Ct4428 output
exec luare_date_par 'GE','FARATVANE',@FaraTVAnx output,0,''
exec luare_date_par 'GE','CONT348',@DifPProd output,0,@Ct348 output
exec luare_date_par 'GE','CALTE',0,0,@CtIntTE output
exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''

exec iauNrDataDoc 'TE',@Numar output,@Data output,0
if @Stare is null set @Stare=3
if @CodIPrimNou is null set @CodIPrimNou=0

set @TipNom=''
set @CtNom=''
set @PStocNom=0
set @PAmNom=0
set @GrNom=''
set @CoefConv2Nom=0
set @CategNom=0
set @GreutSpecNom=0
set @TVANom=0
select @TipNom=tip,@CtNom=cont,@PStocNom=pret_stoc,@PAmNom=pret_cu_amanuntul,@GrNom=grupa,
	@CoefConv2Nom=Coeficient_conversie_1,@CategNom=categorie,@GreutSpecNom=greutate_specifica,@TVANom=Cota_TVA
from nomencl
where cod=@Cod

set @TipGestPred=''
select @TipGestPred=tip_gestiune
from gestiuni 
where subunitate=@Sb and cod_gestiune=@GestPred

set @TipGestPrim=''
set @CtGestPrim=''
select @TipGestPrim=tip_gestiune,@CtGestPrim=cont_contabil_specific
from gestiuni 
where subunitate=@Sb and cod_gestiune=@GestPrim

select @PretSt=pret,@CtStoc=cont,@TVAnx=(case when @TVAnx is null and tip_gestiune='A' then tva_neexigibil else @TVAnx end),@PretAmPred=pret_cu_amanuntul,@LocatieStoc=locatie,@DataExpStoc=data_expirarii,
	@DinCust=are_documente_in_perioada,@PVanzSt=pret_vanzare
from stocuri
where @TipGestPred<>'V' and subunitate=@Sb and tip_gestiune=@TipGestPred and cod_gestiune=@GestPred and cod=@Cod and cod_intrare=@CodIntrare

if @PretSt is null set @PretSt=isnull(@PStocNom,0)
if @CtStoc is null set @CtStoc=dbo.formezContStoc(@GestPred,@Cod,@LM)
if @DinCust is null set @DinCust=0

select top 1 @PAmPreturi=pret_cu_amanuntul,@PVanzPreturi=pret_vanzare
from preturi where @TabPreturi=1 and cod_produs=@Cod and UM=(case when @CategPret<>0 then @CategPret else 1 end) 
and tip_pret='1' and @Data between data_inferioara and data_superioara 
order by data_inferioara desc

if /*@TVAnx is null and */@TipGestPrim='A' and left(@CtGestPrim,2)='35' and @DifPProd=1 and left(@CtStoc,2) in ('33','34') or @FaraTVAnx=1
	set @TVAnx=0
if @TVAnx is null 
	set @TVAnx=@TVANom
if @TipGestPred<>'A' and @DifPProd=1 and left(@CtStoc,2) in ('33','34')
	set @PretAmPred=(case when @TipGestPrim='A' and left(@CtGestPrim,3)='371' then (case when @DinCust=1 then @PVanzSt else @PVanzPreturi end) else 0 /*??? aici ar trebui pret amanunt primitor...*/end)
if @PretAmPred is null 
	set @PretAmPred=0

if isnull(@PretAmPrim,0)=0
begin
	if @TipGestPrim in ('A','C') or @TipGestPrim='V' and @TipGestPred<>'A'
		set @PretAmPrim=isnull(@PAmPreturi,@PAmNom)
	if @PretAmPrim is null and @TipGestPrim='V' and @TipGestPred='A'
		set @PretAmPrim=@PretAmPred
	if @PretAmPrim is null
		set @PretAmPrim=@PAmNom
end
if isnull(@CtCoresp,'')='' and left(@CtStoc,1)='8'
	set @CtCoresp=@CtStoc
if isnull(@CtCoresp,'')='' and left(@CtGestPrim,3)='357' and @TipNom='P'
	set @CtCoresp='354'

if isnull(@CodIPrim,'')=''
	-- mai jos, unde a fost trimis parametrul @Data am pus '1901-01-01' (in 2 locuri), pentru a verifica intreg stocul la primitor, nu doar cel cu data egala cu data documentului
	set @CodIPrim=dbo.cautareCodIntrare(@Cod,@GestPrim,@TipGestPrim,@CodIntrare,@PretSt,@PretAmPrim,@CtCoresp,@CodIPrimNou,0,'1901-01-01','1901-01-01','','','','','','')

select @CtCoresp=(case when isnull(@CtCoresp,'')='' then (case when cont in ('0','371.') then '' else cont end) else @CtCoresp end),
	@PretAmPrim=(case when isnull(@PretAmPrim,0)=0 then pret_cu_amanuntul else @PretAmPrim end),
	@LocatiePrim=(case when isnull(@LocatiePrim,'')='' then locatie else @LocatiePrim end),@DataExpStoc=data_expirarii
from stocuri
where @TipGestPrim<>'V' and subunitate=@Sb and tip_gestiune=@TipGestPrim and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim

set @PretVanz=convert(decimal(17, 5), @PretAmPrim/(1.00+@TVAnx/100))

if isnull(@LocatiePrim,'')='' 
	set @LocatiePrim=isnull(@LocatieStoc,'')
if @DataExpStoc is null
	set @DataExpStoc=@Data
if isnull(@CtCoresp,'')='' and @PastrCtSt=1 and @CtGestPrim=''
	set @CtCoresp=@CtStoc
if isnull(@CtCoresp,'')=''
	set @CtCoresp=dbo.formezContStoc(@GestPrim,@Cod,@LM)

if @Accize=1 and @TipGestPred='P'
begin
	declare @AccCategProd int,@AccUnitVanz float
	exec luare_date_par 'GE','CATEGPRO',@AccCategProd output,0,''
	if @AccCategProd=1
	begin
		set @AccUnitVanz=isnull((select max(acciza_vanzare) from categprod where categoria=@CategNom),0)
		set @AccDat=round(convert(decimal(17,4),@CoefConv2Nom*@AccUnitVanz*@Cantitate),3)
	end
end
if @AccDat is null set @AccDat=0

set @Valoare=isnull(@Valoare,0)+round(convert(decimal(17,3),@Cantitate*@PretSt),2)
set @TotCant=isnull(@TotCant,0)+@Cantitate

set @StersPozitie=0
if isnull(@NrPozitie,0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='TE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='TE' and numar=@Numar and data=@Data and gestiune=@GestPred and gestiune_primitoare=@GestPrim 
	and cod=@Cod and cod_intrare=@CodIntrare and grupa=@CodIPrim and loc_de_munca=@LM and comanda=@Comanda

if isnull(@NrPozitie,0)=0 or @StersPozitie=1
begin
	set @CtInterm=(case when @TipGestPred='V' then @CtIntTE when @TLitR=1 then @CtAccCR else '' end)

	if @DifPProd=1 and left(@CtCoresp,1)<>'6' and left(@CtStoc,2) in ('33','34')
		set @CtAdPred=@Ct348
	if @CtAdPred is null 
		set @CtAdPred=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@GestPred) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)
	set @CtTVAnxPred=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@GestPred) else '' end)
	set @CtAdPrim=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@GestPrim) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)
	set @CtTVAnxPrim=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@GestPrim) else '' end)

	set @AccCump=(case when @TLitR=1 then @GreutSpecNom when @TabPreturi=1 then @CategPret else 0 end)
	
	if @StersPozitie=0
	begin
		exec luare_date_par 'DO','POZITIE',0,@NrPozitie output,''
		set @NrPozitie=@NrPozitie+1
	end
	
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
	(@Sb,'TE',@Numar,@Cod,@Data,@GestPred,0,0,@PretSt,0,
	@PretVanz,@PretAmPrim,0,0,isnull(@Utilizator,''),'01/01/1901','',
	@CodIntrare,@CtStoc,@CtCoresp,@TVAnx,@PretAmPred,'E',
	@LocatiePrim,@DataExpStoc,@NrPozitie,@LM,@Comanda,@Barcod,
	@CtInterm,@CtAdPrim,@DinCust,@CtAdPred,@ComLivr,@GestPrim,@CtTVAnxPred,
	@Stare,@CodIPrim,@CtTVAnxPrim,@Valuta,@Curs,@Data,@Data,@Schimb,0,
	@AccCump,0,@GestDest,@Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null
end

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()
	
	
---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 
	begin
	   exec scriuPDserii 'TE', @Numar, @Data, @GestPred, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, @GestPrim
	   set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='TE' and Numar=@Numar and data=@Data and Gestiune=@GestPred and cod=@Cod 
															  and Gestiune_primitoare=@GestPrim and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)
	end
----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------
	

update pozdoc
set cantitate=cantitate+@Cantitate,
	utilizator=@Utilizator,data_operarii=convert(datetime,convert(char(10),getdate(),104),104),ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':','')),
	accize_datorate=accize_datorate+@AccDat
where subunitate=@Sb and tip='TE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
