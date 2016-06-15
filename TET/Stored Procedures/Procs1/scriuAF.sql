--***
create procedure scriuAF @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @Cantitate float, 
	@CodIntrare char(13) output, @CtStoc char(13) output, @PretStoc float, @CtCoresp char(13), @CtInterm char(13), 
	@Locatie char(30), @LM char(9), @Comanda char(40), @Jurnal char(3), @DataExp datetime, 
	@Stare int, @Utilizator char(10), @NrPozitie int=0 output, @PozitieNoua int=0
as

declare @Sb char(9), @CtUzura char(13), @AnUzura int, @PStocNom float, @StersPozitie int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output

exec iauNrDataDoc 'AF', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @PStocNom=0
select @PStocNom=pret_stoc 
from nomencl
where cod=@Cod

if isnull(@PretStoc, 0)=0
	set @PretStoc=isnull(@PStocNom, 0)
if @CtStoc is null 
	set @CtStoc=dbo.formezContStocFol(@Cod)

if @Locatie is null
	set @Locatie=''
if @DataExp is null
	set @DataExp=@Data

if isnull(@CtCoresp, '')=''
	set @CtCoresp=(case when left(@CtStoc, 1)='8' then '' else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
if @CtInterm is null 
	set @CtInterm=''

set @StersPozitie=0
if isnull(@NrPozitie, 0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='AF' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie, @CodIntrare=(case when isnull(@CodIntrare, '')='' then cod_intrare else @CodIntrare end)
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='AF' and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod 
	and (isnull(@CodIntrare, '')='' or cod_intrare=@CodIntrare) 
	and cont_de_stoc=@CtStoc and pret_de_stoc=@PretStoc and cont_corespondent=@CtCoresp and cont_intermediar=@CtInterm
	and loc_de_munca=@LM and comanda=@Comanda 

if isnull(@NrPozitie, 0)=0 or @StersPozitie=1
begin
	if isnull(@CodIntrare, '')=''
		set @CodIntrare=dbo.formezCodIntrare('AF', @Numar, @Data, @Cod, @Gestiune, @CtStoc, @PretStoc)
	if @StersPozitie=0
	begin
		exec luare_date_par 'DO', 'POZITIE', 0, @NrPozitie output, ''
		set @NrPozitie=@NrPozitie+1
	end
	
	insert pozdoc
	(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
	Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
	Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
	Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
	Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
	Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
	Accize_cumparare, Accize_datorate, Contract, Jurnal) 
	values
	(@Sb, 'AF', @Numar, @Cod, @Data, @Gestiune, 0, 0, @PretStoc, 0, 
	0, 0, 0, 0, isnull(@Utilizator,''), '01/01/1901', '', 
	@CodIntrare, @CtStoc, @CtCoresp, 0, 0, 'I', 
	@Locatie, @DataExp, @NrPozitie, @LM, @Comanda, '', 
	@CtInterm, '', 0, '', '', '', '', 
	@Stare, '', '', '', 0, @Data, @Data, 0, 0, 
	0, 0, '', @Jurnal)
	
	if @StersPozitie=0
		exec setare_par 'DO', 'POZITIE', null, null, @NrPozitie, null
end

if @Utilizator is null
	set @Utilizator=dbo.fIauUtilizatorCurent()

update pozdoc
set cantitate=cantitate+@Cantitate, 
	utilizator=@Utilizator, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
where subunitate=@Sb and tip='AF' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
