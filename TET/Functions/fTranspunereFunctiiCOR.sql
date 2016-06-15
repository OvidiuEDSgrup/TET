--***
Create 
function fTranspunereFunctiiCOR (@IDCOR_vechi char(6)) returns char(6)
as
begin
	declare @result char(6), @IDCOR_nou char(6), @tip char(2)
	if @IDCOR_vechi=''
		set @result='EROARE'
	else
	begin
		select @IDCOR_nou=isnull(Numar_curent,''), @tip=ISNULL(Tip_corespondenta,'0') 
		from Coresp_Functii_COR where Numar_curent_vechi=@IDCOR_vechi
		select @IDCOR_nou=isnull(@IDCOR_nou,''),@tip=ISNULL(@tip,'0')
		if @IDCOR_nou='' 
			set @result=(case when @tip='3' then 'STERS' when @tip='0' then @IDCOR_vechi else 'EROARE' end)
		if @IDCOR_nou<>'' and @IDCOR_vechi not in ('EROARE','STERS') and @IDCOR_nou<>@IDCOR_vechi
			set @result=dbo.fTranspunereFunctiiCor(@IDCOR_nou)
	end
	return isnull(@result,'')
end
