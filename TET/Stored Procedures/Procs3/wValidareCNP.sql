--***
Create procedure wValidareCNP 
	@cnp char(13), @Eroare int output, @Mesaj varchar(100) output, @DataCNP datetime output, @Sex int output, @detalii xml=null 
as
if exists (select 1 from sys.objects where name='wValidareCNPSP' and type='P')  
	exec wValidareCNPSP @cnp, @Eroare output, @Mesaj output, @DataCNP output, @Sex output, @detalii

Declare @DataValida int, @RezultatConversie decimal(8), @IndexCifra int, @CheieControl char(12), 
@SecventaCNP char(12), @suma decimal(8), @BitControl int, @CheckSum int
	
if @eroare=1 -- daca a fost incadrat ca eronat in ...SP nu mai participa la validarea standard - MESAJELE AU FOST DATE ACOLO
	SET @Eroare=0
ELSE
begin
	Select @DataCNP='01/01/1901', @CheieControl='279146358279', @SecventaCNP=left(@cnp,12), @IndexCifra=1, 
	@suma=0, @RezultatConversie=0, @eroare=1, @Mesaj='Cod numeric personal incorect!' , @Sex=1

	if @cnp='' 
		select @eroare=2, @Mesaj='Cod numeric personal necompletat!'
--	verific checksum
	while @IndexCifra<=12 and isnumeric(@cnp)=1
	Begin
		Select @Suma=@Suma+convert(int, substring(@CheieControl,@IndexCifra,1))*
		convert(int,substring(@SecventaCNP,@IndexCifra,1)), 
		@IndexCifra=@IndexCifra+1
	End
	Set @BitControl=@suma % 11
	Select @BitControl=1 where @BitControl=10 
	Select @CheckSum=1 where rtrim(convert(char(1),@BitControl))=substring(@cnp,13,1)
--	verific data nasterii
--	am mutat aici verificare data nasterii (initial a fost inainte de verificare checksum) intrucat daca era invalida data dadea mesaj de SQL.
--	am conditionat validarea datei si de @CheckSum=1
	if @cnp<>'' and len(rtrim(@cnp))>6 and substring(@cnp,2,6)<>'000000' and @CheckSum=1
	Begin
		Set @DataCNP=dbo.fDataNasterii(@cnp)
		Set @Sex=(case when left(@cnp,1) in ('1','3','5','7','9') then 1 else 0 end)
		Select @RezultatConversie=datediff(day,convert(datetime,'01/01/1901'),@DataCNP)+693961
	End
	if @RezultatConversie>693961
	Begin 
		Set @DataValida=1
		Set @DataCNP=dbo.fDataNasterii(@cnp)
	End
end
if (@DataValida=1 or substring(@cnp,2,6)='000000') and @CheckSum=1
	Select @eroare=0, @Mesaj='Cod numeric personal valid!'
return

/*
	declare @cnp char(13), @eroare int, @Mesaj varchar(100), @DataCNP datetime, @Sex int  
	set @cnp='savnnv'
	exec wValidareCNP @cnp, @Eroare output, @Mesaj output, @DataCNP output, @Sex output
	select @Mesaj
*/
