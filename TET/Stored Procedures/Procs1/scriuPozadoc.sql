--***
create procedure scriuPozadoc @Numar char(8) output, @Data datetime, @Tip char(2), 
	@Tert char(13), @FacturaStinga char(20), @ContDeb char(13), @FacturaDreapta char(20), @ContCred char(13), 
	@Suma float, @Valuta char(3), @Curs float, @Suma_valuta float, 
	@TVA11 float, @TVA22 float, @Explicatii char(50), @Numar_pozitie int output, 
	@TertBenef char(13), @LM char(9), @Comanda char(40), @Utilizator char(10), @Jurnal char(3), 
	@DataFact datetime, @DataScad datetime, @SumaDif float, @ContDif char(13), @AchitFact float, @DifTVA float, @Stare int
as 

if abs(@Suma)<0.01 and abs(@Suma_valuta)<0.01
	return

declare @Sb char(9), @CuDifCurs int, @CtCheltDifcF char(13), @CtVenDifcF char(13), @CtCheltDifcB char(13), @CtVenDifcB char(13), 
	@TipFactSt char(1), @TipFactDr char(1), @TertFactDr char(13), @DenTert char(80)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
exec luare_date_par 'GE', 'DIFINR', @CuDifCurs output, 0, ''
exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output
exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output
exec luare_date_par 'GE', 'DIFCHB', 0, 0, @CtCheltDifcB output
exec luare_date_par 'GE', 'DIFVEB', 0, 0, @CtVenDifcB output

if @Data is null set @Data=CONVERT(datetime, convert(char(10), getdate(), 101), 101)

if ISNULL(@Numar, '')=''
begin
	declare @UltNrFol int, @PerUnicDoc int, @NuModiUltNr int, @PerioadaJos datetime, @PerioadaSus datetime
	exec luare_date_par 'DO', 'NRUNIC', 0, @PerUnicDoc output, ''
	exec luare_date_par 'GE', 'MODIULTNR', @NuModiUltNr output, 0, ''
	set @PerioadaJos=(case @PerUnicDoc when 0 then dbo.BOY(@Data) when 1 then dbo.BOM(@Data) when 2 then @Data else '01/01/1901' end)
	set @PerioadaSus=(case @PerUnicDoc when 0 then dbo.EOY(@Data) when 1 then dbo.EOM(@Data) when 2 then @Data else '12/31/2999' end)
	exec luare_date_par 'DO', 'ALTEDOC', 0, @UltNrFol output, ''
	if @NuModiUltNr = 0 
		set @UltNrFol = @UltNrFol + 1
	while exists (select 1 from adoc where subunitate=@Sb and tip=@Tip and numar_document=ltrim(convert(char(12), @UltNrFol)) and data between @PerioadaJos and @PerioadaSus)
	begin
		set @UltNrFol = @UltNrFol + 1
		if @UltNrFol > 99999999
			set @UltNrFol = 1
	end
	set @Numar = ltrim(convert(char(12), @UltNrFol))
	if @NuModiUltNr = 0
		exec setare_par 'DO', 'ALTEDOC', null, null, @UltNrFol, null
end

select @TipFactSt=(case when @Tip in ('CO', 'SF', 'CF', 'C3') then 'F' else 'B' end), 
	@TipFactDr=(case when @Tip in ('FF', 'SF', 'CF') then 'F' else 'B' end), 
	@TertFactDr=isnull((case when @Tip='C3' then @TertBenef else @Tert end), '')

if @Tip<>'FF' and isnull(@ContDeb, '')=''
begin
	select @ContDeb=Cont_de_tert from facturi where Subunitate=@Sb and tip=(case @TipFactSt when 'F' then 0x54 else 0x46 end) and tert=@Tert and Factura=@FacturaStinga
	select @ContDeb=(case when @TipFactSt='F' then cont_ca_furnizor else cont_ca_beneficiar end) from terti where isnull(@ContDeb, '')='' and Subunitate=@Sb and Tert=@Tert
	set @ContDeb=isnull(@ContDeb, '')
end
if @Tip<>'FB' and isnull(@ContCred, '')=''
begin
	select @ContCred=Cont_de_tert from facturi where Subunitate=@Sb and tip=(case @TipFactDr when 'F' then 0x54 else 0x46 end) and tert=@TertFactDr and Factura=@FacturaDreapta
	select @ContCred=(case when @TipFactDr='F' then cont_ca_furnizor else cont_ca_beneficiar end) from terti where isnull(@ContCred, '')='' and Subunitate=@Sb and Tert=@TertFactDr
	set @ContCred=isnull(@ContCred, '')
end

if abs(isnull(@Suma, 0))<0.01 and @Valuta<>'' and abs(@Curs)>=0.0001
	set @Suma=round(convert(decimal(18, 5), @Suma_valuta*@Curs), 2)
if ABS(@Suma)>=0.01 and ABS(@TVA11)>=0.01 and ABS(ISNULL(@TVA22, 0))<0.01
	set @TVA22=ROUND(convert(decimal(18, 5), @Suma*@TVA11/100), 2)


if ISNULL(@TertBenef, '')=''
begin
	if @Tip in ('FF', 'FB')
	begin
		declare @ParTVA char(9), @CtTVA char(13)
		set @ParTVA=(case when @Tip='FF' and LEFT(@ContCred, 3)='408' or @Tip='FB' and LEFT(@ContDeb, 3)='418' then 'CNEEXREC' when @Tip='FF' then 'CDTVA' else 'CCTVA' end)
		exec luare_date_par 'GE', @ParTVA, 0, 0, @CtTVA output
	end
	else if @Tip<>'C3' and @Valuta<>'' and @Suma_valuta<>''
		set @TertBenef=ltrim(convert(char(13), convert(decimal(12, 2), @Suma_valuta*@TVA11/(100+(case when @Tip not in ('FF', 'SF', 'FB', 'IF') then @TVA11 else 0 end)))))
end

if ISNULL(@Explicatii, '')=''
begin
	select @Explicatii=@Tip + ' ' + Denumire from terti where Subunitate=@Sb and tert=@Tert
	set @Explicatii=ISNULL(@Explicatii, '')
end

select @DataFact=(case when ISNULL(@DataFact, '01/01/1901')<='01/01/1901' then Data else @DataFact end), 
	@DataScad=(case when ISNULL(@DataScad, '01/01/1901')<='01/01/1901' then Data_scadentei else @DataScad end)
from facturi 
where @Tip in ('SF', 'FF', 'IF', 'FB') and Subunitate=@Sb and tert=Tert and tip=(case when @Tip in ('SF', 'FF') then 0x54 else 0x46 end)
and Factura=(case when @Tip in ('SF', 'FF') then @FacturaDreapta else @FacturaStinga end)

if ISNULL(@DataFact, '01/01/1901')<='01/01/1901'
	set @DataFact=@Data
if ISNULL(@DataScad, '01/01/1901')<='01/01/1901'
begin
	declare @ZileScad int
	select @ZileScad=0
	select @ZileScad=discount from infotert where Subunitate=@Sb and tert=@Tert and Identificator=''
	if @ZileScad<=0 and @Tip in ('IF', 'FB')
		exec luare_date_par 'GE', 'SCADENTA', 0, @ZileScad output, ''
	set @DataScad=DATEADD(d, @ZileScad, @DataFact)
end

select @SumaDif=ISNULL(@SumaDif, 0), @ContDif=ISNULL(@ContDif, ''), 
	@AchitFact=ISNULL(@AchitFact, 0), @DifTVA=ISNULL(@DifTVA, 0), 
	@Stare=ISNULL(@Stare, 0)

if isnull(@Numar_pozitie, 0)<>0
begin
	delete pozadoc where subunitate=@Sb and tip=@Tip and Numar_document=@Numar and data=@Data and numar_pozitie=@Numar_pozitie
end
else
begin
	exec luare_date_par 'DO', 'POZITIE', 0, @Numar_pozitie output, ''
	set @Numar_pozitie=@Numar_pozitie+1
	
	while exists (select 1 from pozadoc where subunitate=@Sb and tip=@Tip and Numar_document=@Numar and data=@Data and numar_pozitie=@Numar_pozitie)
		set @Numar_pozitie=@Numar_pozitie + 1 
	
	exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Numar_pozitie, ''
end

declare @Data_operarii datetime, @Ora_operarii char(6) 
set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')
if isnull(@Utilizator, '')='' set @Utilizator=dbo.fIauUtilizatorCurent()

insert pozadoc
(Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, 
Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif, 
Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal)
values 
(@Sb, @Numar, @Data, @Tert, @Tip, @FacturaStinga, @FacturaDreapta, @ContDeb, @ContCred, @Suma, @TVA11, @TVA22, 
@Utilizator, @Data_operarii, @Ora_operarii, @Numar_pozitie, @TertBenef, @Explicatii, @Valuta, @Curs, @Suma_valuta, @ContDif, @SumaDif, 
@LM, @Comanda, @DataFact, @DataScad, @Stare, @AchitFact, @DifTVA, @Jurnal)
