--***
create procedure scriuAE @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), 
	@Cantitate float, @CtCoresp char(13), @LM char(9), @Comanda char(40), @ComLivr char(20), 
	@Explicatii char(16), @Serie char(20), @Utilizator char(10), @Schimb int, @Jurnal char(3), @Stare int, @NrPozitie int=0 output, @PozitieNoua int=0, @PretStoc float=null
as

declare @Sb char(9), @Ct378 char(13), @AnGest378 int, @AnGr378 int, @Ct4428 char(13), @AnGest4428 int, 
	@CtCorespAE char(13), @CuCtFactAE int, @CtFactAE char(13), 
	@TipNom char(1), @PStocNom float, @PretVanzNom float, @GrNom char(13), @TipGest char(1), 
	@CtStoc char(13), @TVAnx float, @PretAmPred float, @LocatieStoc char(30), @DataExpStoc datetime, 
	@CtFact char(13), @CtAdaos char(13), @CtTVANx char(13), @StersPozitie int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CADAOS', @AnGest378 output, @AnGr378 output, @Ct378 output
exec luare_date_par 'GE', 'CNTVA', @AnGest4428 output, 0, @Ct4428 output
exec luare_date_par 'GE', 'CCORAE', 0, 0, @CtCorespAE output
exec luare_date_par 'GE', 'CONT_AE?', @CuCtFactAE output, 0, ''
exec luare_date_par 'GE', 'CONT_AE', 0, 0, @CtFactAE output

exec iauNrDataDoc 'AE', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @TipNom=''
set @PStocNom=0
set @PretVanzNom=0
set @GrNom=''
select @TipNom=tip, @PStocNom=pret_stoc, @PretVanzNom=pret_vanzare, @GrNom=grupa
from nomencl
where cod=@Cod

set @TipGest=''
set @LocatieStoc=''
set @DataExpStoc=@Data
select @TipGest=tip_gestiune
from gestiuni 
where subunitate=@Sb and cod_gestiune=@Gestiune

select @PretStoc=(case when @PretStoc is null then pret else @PretStoc end), @CtStoc=cont, @TVAnx=tva_neexigibil, @PretAmPred=pret_cu_amanuntul, @LocatieStoc=locatie, @DataExpStoc=data_expirarii
from stocuri
where subunitate=@Sb and tip_gestiune=@TipGest and cod_gestiune=@Gestiune and cod=@Cod and cod_intrare=@CodIntrare

if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
if @CtStoc is null 
	set @CtStoc=dbo.formezContStoc(@Gestiune, @Cod, @LM)
if @TVAnx is null
	set @TVAnx=0
if @PretAmPred is null
	set @PretAmPred=@PretVanzNom
if @LocatieStoc is null
	set @LocatieStoc=''
if @DataExpStoc is null
	set @DataExpStoc=@Data

if isnull(@CtCoresp, '')=''
	set @CtCoresp=(case when @CtCorespAE<>'' then @CtCorespAE else '6588' end)
set @CtTVAnx=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(@Gestiune) else '' end)
set @CtAdaos=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)
set @CtFact=(case when @CuCtFactAE=1 then @CtFactAE else @CtCoresp end)

set @StersPozitie=0
if isnull(@NrPozitie, 0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='AE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='AE' and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod 
	and cod_intrare=@CodIntrare and cont_de_stoc=@CtStoc and cont_corespondent=@CtCoresp and loc_de_munca=@LM and comanda=@Comanda

if isnull(@NrPozitie, 0)=0 or @StersPozitie=1
begin
	if @StersPozitie=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
		set @NrPozitie=@NrPozitie+1
	end
	
	insert pozdoc
	(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
	Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
	Cod_intrare, Cont_de_stoc, Cont_corespondent, 
	TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
	Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
	Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
	Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
	Accize_cumparare, Accize_datorate, Contract, Jurnal) 
	values
	(@Sb, 'AE', @Numar, @Cod, @Data, @Gestiune, 0, 0, @PretStoc, 0, 
	0, 0, 0, 0, isnull(@Utilizator,''), '01/01/1901', '', 
	@CodIntrare, @CtStoc, @CtCoresp, @TVAnx, @PretAmPred, 'E', 
	@LocatieStoc, @DataExpStoc, @NrPozitie, @LM, @Comanda, '', 
	'', '', 0, @CtTVAnx, left(@Explicatii, 8), @CtAdaos, '', 
	@Stare, @ComLivr, @CtFact, '', 0, @Data, @Data, @Schimb, 0, 
	0, 0, substring(@Explicatii, 9, 8), @Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null
end

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()
	

-->>>>>>>>>start cod pentru lucrul cu serii<<<<<<<<<<<<<<--
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>''
	begin
	exec scriuPDserii 'AE',@Numar,@Data,@Gestiune,@Cod,@CodIntrare,@NrPozitie,@Serie,@Cantitate,''
	set @Cantitate =(select SUM(cantitate) from pdserii where tip='AE' and Numar=@Numar and data=@Data and Gestiune=@Gestiune and cod=@Cod 
														  and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie)
	end														  														  
-->>>>>>>>>	stop cod pentru lucrul cu serii<<<<<<<<<<<<<<<--

update pozdoc
set cantitate=cantitate+@Cantitate, 
	utilizator=@Utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
where subunitate=@Sb and tip='AE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
