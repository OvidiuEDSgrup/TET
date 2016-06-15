--***
create procedure scriuCM @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), 
	@Cantitate float, @LM char(9), @Comanda char(40), @Barcod char(30), @Factura char(20), @Schimb int, 
	@Serie char(20), @Utilizator char(10), @Jurnal char(3), @Stare int, @NrPozitie int=0 output, @PozitieNoua int=0, 
	@CtCoresp char(13)='' 
as

declare @Sb char(9), 
	@TipNom char(1), @PStocNom float, @PretVanzNom float, @TipGest char(1), 
	@PretStoc float, @CtStoc char(13), @TVAnx float, @PretAmPred float, @LocatieStoc char(30), @DataExpStoc datetime, 
	@Discount float, @CtInterm char(13), @CtVenit char(13), @CtAdaos char(13), @CtTVANx char(13),
	@StersPozitie int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output

exec iauNrDataDoc 'CM', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @TipNom=''
set @PStocNom=0
set @PretVanzNom=0
select @TipNom=tip, @PStocNom=pret_stoc, @PretVanzNom=pret_vanzare
from nomencl
where cod=@Cod

set @TipGest=''
set @LocatieStoc=''
set @DataExpStoc=@Data
select @TipGest=tip_gestiune
from gestiuni 
where subunitate=@Sb and cod_gestiune=@Gestiune

select @PretStoc=pret, @CtStoc=cont, @TVAnx=tva_neexigibil, @PretAmPred=pret_cu_amanuntul, @LocatieStoc=locatie, @DataExpStoc=data_expirarii
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
if @CodIntrare is null
	set @CodIntrare=dbo.formezCodIntrare('CM', @Numar, @Data, @Cod, @Gestiune, @CtStoc, @PretStoc)

set @Discount=0
exec formezConturiCM @Cod, @CtStoc, @Gestiune, '', @LM, @Discount, @CtCoresp output, @CtInterm output, @CtVenit output, @CtAdaos output, @CtTVANx output 

set @StersPozitie=0
if isnull(@NrPozitie, 0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='CM' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else --if isnull(@PozitieNoua,0)=0
	select @NrPozitie=numar_pozitie
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='CM' and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod 
	and cod_intrare=@CodIntrare and cont_de_stoc=@CtStoc and cont_corespondent=@CtCoresp and loc_de_munca=@LM and comanda=@Comanda

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()

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
	(@Sb, 'CM', @Numar, @Cod, @Data, @Gestiune, @Cantitate, 0, @PretStoc, 0, 
	0, 0, 0, 0, -- '', '01/01/1901', '', 
	@Utilizator, convert(datetime, convert(char(10), getdate(), 104), 104), 
	RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
	@CodIntrare, @CtStoc, @CtCoresp, @TVAnx, @PretAmPred, 'E', 
	@LocatieStoc, @DataExpStoc, @NrPozitie, @LM, @Comanda, @Barcod, 
	@CtInterm, @CtVenit, @Discount, @CtAdaos, @Factura, '', @CtTVAnx, 
	@Stare, '', '', '', 0, @Data, @Data, @Schimb, 0, 
	0, 0, '', @Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null
end

if isnull(@PozitieNoua,0)=0
update pozdoc
set cantitate=cantitate+@Cantitate, 
	utilizator=@Utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
	ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
where subunitate=@Sb and tip='CM' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie

exec scriuPDserii 'CM', @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, ''
