--***
create procedure scriuPDserii @Tip char(2), @Numar char(8), @Data datetime, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), @NumarPozitie int, @Serie char(20), @Cantitate float, @GestiunePrimitoare char(9)
as

declare @Serii int, @Sb char(9), @TipMiscare char(1)
exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''
if @Serii=0 
	return
if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')<>'Y'
	return
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output

if @Serie is null set @Serie=''
 
if not exists (select 1 from pdserii where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod and cod_intrare=@CodIntrare and numar_pozitie=@NumarPozitie and serie=@Serie)
begin
	set @TipMiscare=(case when @Tip in ('RM', 'PP', 'AI') then 'I' else 'E' end)
	insert pdserii
	(Subunitate, Tip, Numar, Data, Gestiune, Cod, Cod_intrare, Serie, Cantitate, Tip_miscare, Numar_pozitie, Gestiune_primitoare)
	values
	(@Sb, @Tip, @Numar, @Data, @Gestiune, @Cod, @CodIntrare, @Serie, 0, @TipMiscare, @NumarPozitie, @GestiunePrimitoare)
end

update pdserii
set cantitate=@Cantitate
where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data and gestiune=@Gestiune and cod=@Cod and cod_intrare=@CodIntrare and numar_pozitie=@NumarPozitie and serie=@Serie
