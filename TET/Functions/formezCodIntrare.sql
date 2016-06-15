--***
create function formezCodIntrare (@Tip char(2), @Numar char(20), @Data datetime, @Cod char(20), @Gestiune char(9), @ContStoc char(20), @PretStoc float) returns char(13)
as begin
declare @CodIntrare char(13), @Sb char(9), @TipNomencl char(1), @ContNomencl char(20), @AtribCtNom int, @TipGest char(1), 
	@Serii int, @PretMediu int, @nExcepPM int, @cGestExcepPM char(202), @CodICtStoc int, @CodIPretStoc int

set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')
set @Serii=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='SERII'), 0)
set @CodICtStoc=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CODCS'), 0)
set @CodIPretStoc=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CODPS'), 0)

set @PretMediu=0
set @nExcepPM=0
set @cGestExcepPM=''
select @PretMediu=max(cast(val_logica as int)), 
	@nExcepPM=max(val_numerica),
	@cGestExcepPM=','+LTrim(RTrim(max(val_alfanumerica)))+','
from par where tip_parametru='GE' and parametru='MEDIUP'

set @TipNomencl=''
set @ContNomencl=''
set @AtribCtNom=0
set @TipGest=''

select @TipNomencl=tip, @ContNomencl=cont
from nomencl 
where cod=@Cod
select @TipGest=tip_gestiune from gestiuni

select @AtribCtNom=sold_credit
from conturi
where subunitate=@Sb and cont=@ContNomencl

select @TipGest=tip_gestiune
from gestiuni
where subunitate=@Sb and cod_gestiune=@Gestiune

if (@Tip in ('RM', 'RS') and @AtribCtNom=1 or @Tip in ('AP', 'AS') and @AtribCtNom=2)
	set @CodIntrare='AV'+RTrim(replace(convert(char(8), @Data, 4), '.', ''))

if @CodIntrare is null and @Serii=0 and @PretMediu=1 and sign(charindex(','+rtrim(@Gestiune)+',',@cGestExcepPM))=sign(@nExcepPM) and @TipGest not in ('A', 'V')
	set @CodIntrare=(case when @CodICtStoc=1 then @ContStoc else @Cod end)

if @CodIntrare is null and @CodIPretStoc=1 and abs(isnull(@PretStoc, 0))>=0.00001 and @Serii=0 and @Tip in ('RM', 'PP', 'AI', 'TI') 
	set @CodIntrare=LTrim(RTrim(convert(char(15), convert(decimal(13,3), @PretStoc))))
if @CodIntrare is null and @Tip in ('RM', 'PP', 'AI','AF') 
begin
	if isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='CODIVECH'), 0)=0 
	/* Aici e noua varianta implicita*/
	begin 
		declare @maxIdPozDoc int
		set @maxIdPozDoc=IDENT_CURRENT('pozdoc')
		set @CodIntrare=@Tip+ltrim(str(@maxidPozDoc+1))
	end
	else -- se poate pune setarea ascuns pt. compatibilitate in urma
	begin
		declare @NrPozitii int
		set @NrPozitii=1+isnull((select count(1) from pozdoc where subunitate=@Sb and tip=@Tip and numar=@Numar and data=@Data), 0)
		set @CodIntrare=RTrim(@Numar)+replace(right(str(@NrPozitii), 3), ' ', '0')
	end
end

if @CodIntrare is null
	set @CodIntrare=''

return @CodIntrare

end
