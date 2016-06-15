--***
Create procedure wRUiauNrFisa @Tip char(2), @Numar char(8) output, @Data datetime output
as

if isnull(@Tip, '') = ''
	return
if isnull(@Data, '01/01/1901')<='01/01/1901'
	set @Data = convert(datetime, convert(char(10), getdate(), 101), 101)
if isnull(@Numar, '') = ''
begin
	declare @TipParametru char(2), @Parametru char(9), @UltNrFol int, @PerUnicFisa int, 
		@PerioadaJos datetime, @PerioadaSus datetime
	set @TipParametru = 'RU'
	set @Parametru = (case @Tip 
		when 'OB' then 'OBIECTIVE' when 'CO' then 'COMPETENT' 
		else '' end)
	set @PerUnicFisa=1
	set @PerioadaJos=(case @PerUnicFisa when 0 then dbo.BOY(@Data) else '01/01/1901' end)
	set @PerioadaSus=(case @PerUnicFisa when 0 then dbo.EOY(@Data) else '12/31/2999' end)
	exec luare_date_par @tip=@TipParametru, @par=@Parametru, @val_l=0, @val_n=@UltNrFol output, @val_a=''
	set @UltNrFol = @UltNrFol + 1
	while exists (select 1 from RU_evaluari where Tip=@Tip and Numar_fisa=ltrim(convert(char(12), @UltNrFol)) and data between @PerioadaJos and @PerioadaSus)
	begin
		set @UltNrFol = @UltNrFol + 1
		if @UltNrFol > 99999999
			set @UltNrFol = 1
	end
	set @Numar = ltrim(convert(char(12), @UltNrFol))
	exec setare_par @tip=@TipParametru, @par=@Parametru, @denp=null, @val_l=null, @val_n=@UltNrFol, @val_a=null
end
