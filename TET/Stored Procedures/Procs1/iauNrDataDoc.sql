--***
create procedure iauNrDataDoc @Tip char(2), @Numar varchar(20) output, @Data datetime output, @ModiUltNr int = 0
as

if isnull(@Tip, '') = ''
	return
if isnull(@Data, '01/01/1901')<='01/01/1901'
	set @Data = convert(datetime, convert(char(10), getdate(), 101), 101)
if isnull(@Numar, '') = ''
begin
	declare @TipParametru char(2), @Parametru char(9), @UltNrFol int, @Sb char(9), @PerUnicDoc int, @NuModiUltNr int, 
		@PerioadaJos datetime, @PerioadaSus datetime
	set @TipParametru = (case when @Tip in ('CM') then 'GE' else 'DO' end)
	set @Parametru = (case @Tip 
		when 'RM' then 'RECEPTII' when 'RS' then 'RECSERVI' 
		when 'AP' then 'AVIZE' when 'AS' then 'AVIZE' when 'AC' then 'AVIZE'
		when 'PP' then 'PREDARI'
		when 'CM' then 'ULTIMBONC'
		when 'TE' then 'TRANSFER'
		when 'AI' then 'ALTEINTR'
		when 'AE' then 'ALTEIES'
		when 'DF' then 'DAREFOL'
		when 'PF' then 'PREDFOL'
		when 'CI' then 'CASARE'
		when 'AF' then 'CASARE'
		else '' end)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	exec luare_date_par 'DO', 'NRUNIC', 0, @PerUnicDoc output, ''
	exec luare_date_par 'GE', 'MODIULTNR', @NuModiUltNr output, 0, ''
	set @PerioadaJos=(case @PerUnicDoc when 0 then dbo.BOY(@Data) when 1 then dbo.BOM(@Data) when 2 then @Data else '01/01/1901' end)
	set @PerioadaSus=(case @PerUnicDoc when 0 then dbo.EOY(@Data) when 1 then dbo.EOM(@Data) when 2 then @Data else '12/31/2999' end)
	exec luare_date_par @TipParametru, @Parametru, 0, @UltNrFol output, ''
	if @NuModiUltNr = 0 /*and @ModiUltNr = 1*/
		set @UltNrFol = @UltNrFol + 1
	while exists (select 1 from doc where subunitate=@Sb and tip=@Tip and numar=ltrim(convert(char(12), @UltNrFol)) and data between @PerioadaJos and @PerioadaSus)
	begin
		set @UltNrFol = @UltNrFol + 1
		if @UltNrFol > 99999999
			set @UltNrFol = 1
	end
	set @Numar = ltrim(convert(char(12), @UltNrFol))
	if @ModiUltNr = 1 and @NuModiUltNr = 0
		exec setare_par @TipParametru, @Parametru, null, null, @UltNrFol, null
end
