--***
create procedure scriuCI @Numar char(8) output, @Data datetime output, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), 
	@Cantitate float, @Locatie char(30), @LM char(9), @Comanda char(40), @Jurnal char(3), 
	@CtInterm char(13), @Stare int, @Utilizator char(10), @NrPozitie int=0 output, @PozitieNoua int=0
as

declare @Sb char(9), @Ct602 char(13), @AnLM602 int, @AnCtSt602 int, @CtUzura char(13), @AnUzura int, 
	@PStocNom float, @PretStoc float, @CtStoc char(13), @LocatieStoc char(30), @DataExpStoc datetime, 
	@CtCoresp char(13), @StersPozitie int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'CONTCINV', @AnLM602 output, @AnCtSt602 output, @Ct602 output
exec luare_date_par 'GE', 'CONTUZ', @AnUzura output, 0, @CtUzura output

exec iauNrDataDoc 'CI', @Numar output, @Data output, 0
if @Stare is null set @Stare=3

set @PStocNom=0
select @PStocNom=pret_stoc 
from nomencl
where cod=@Cod

select @PretStoc=pret, @CtStoc=cont, @LocatieStoc=locatie, @DataExpStoc=data_expirarii 
from stocuri
where subunitate=@Sb and tip_gestiune='F' and cod_gestiune=@Gestiune and cod=@Cod and cod_intrare=@CodIntrare

--pret de stoc
if @PretStoc is null set @PretStoc=isnull(@PStocNom, 0)
--cont de stoc
if @CtStoc is null set @CtStoc=dbo.formezContStocFol(@Cod)

if isnull(@Locatie, '')='' 
	set @Locatie=isnull(@LocatieStoc, '')
if isnull(@DataExpStoc, '01/01/1901')<='01/01/1901'
	set @DataExpStoc=@Data

set @CtCoresp=(case when left(@CtStoc, 1)='8' then '' when 1=1 then RTrim(@Ct602)+(case when @AnLM602=1 then '.'+RTrim(@LM) else '' end)+(case when @AnCtSt602=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) else RTrim(@CtUzura)+(case when @AnUzura=1 then RTrim(substring(@CtStoc, 4, 9)) else '' end) end)
if @CtInterm is null 
	set @CtInterm=''

set @StersPozitie=0
if isnull(@NrPozitie, 0)<>0
begin
	delete pozdoc
	where subunitate=@Sb and tip='CI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
	set @StersPozitie=1
end
else
	select @NrPozitie=numar_pozitie
	from pozdoc
	where isnull(@PozitieNoua,0)=0 and subunitate=@Sb and tip='CI' and numar=@Numar and data=@Data and gestiune=@Gestiune 
	and cod=@Cod and cod_intrare=@CodIntrare and loc_de_munca=@LM and comanda=@Comanda 
	and cont_de_stoc=@CtStoc and cont_corespondent=@CtCoresp and cont_intermediar=@CtInterm

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
	Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
	Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
	Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
	Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
	Accize_cumparare, Accize_datorate, Contract, Jurnal) 
	values
	(@Sb, 'CI', @Numar, @Cod, @Data, @Gestiune, 0, 0, @PretStoc, 0, 
	0, 0, 0, 0, isnull(@Utilizator,''), '01/01/1901', '', 
	@CodIntrare, @CtStoc, @CtCoresp, 0, 0, 'E', 
	@Locatie, @DataExpStoc, @NrPozitie, @LM, @Comanda, '', 
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
where subunitate=@Sb and tip='CI' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie
