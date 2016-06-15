--***
/**	procedura verific pontaj	*/
Create procedure verificaPontaj 
	(@data datetime, @marca char(6), @numar_curent int, @loc_de_munca char(9), @stergere int=0)
as
delete from pontaj where 
	data=@data and marca=@marca and numar_curent=@numar_curent and loc_de_munca=@loc_de_munca 
	and ore_regie=0 and ore_acord=0 and ore_lucrate=0 and ore_suplimentare_1=0 
	and ore_suplimentare_2=0 and ore_suplimentare_3=0 and ore_suplimentare_4=0 and ore_spor_100=0 
	and ore_de_noapte=0 and ore_intrerupere_tehnologica=0 and ore_concediu_de_odihna=0 
	and ore_concediu_medical=0 and ore_invoiri=0 and ore_nemotivate=0 and ore_obligatii_cetatenesti=0 
	and	ore_concediu_fara_salar=0 and ore_donare_sange=0 and salar_categoria_lucrarii=0 
	and	coeficient_de_timp=0 and ore_realizate_acord=0  and coeficient_acord=0 and realizat=0
	/*and sistematic_peste_program=0 and ore_sistematic_peste_program=0 and spor_specific=0 
	and spor_conditii_1=0 and spor_conditii_2=0 and spor_conditii_3=0 and spor_conditii_4=0 
	and spor_conditii_5=0 and spor_conditii_6=0*/ and ore__cond_1=0 and ore__cond_2=0 and ore__cond_3=0 
	and ore__cond_4=0 and ore__cond_5=0 /*and ore__cond_6=0*/ and ore=0 and spor_cond_7=0 
	and spor_cond_8=0 and spor_cond_9=0 and spor_cond_10=0
	and (@stergere=1 or not exists (select Marca from conmed where data=dbo.EOM(@data) and Marca=@marca and Tip_diagnostic='0-'))

declare @SalariatiPeComenzi int
exec luare_date_par 'PS', 'SALCOM', @SalariatiPeComenzi output, 0, ''

if @SalariatiPeComenzi=1
	delete from realcom where data=@data and Marca=@marca and Loc_de_munca=@loc_de_munca and Numar_document='PS'+rtrim(convert(char(10),@numar_curent)) 
		and Cantitate=0
		and not exists (select 1 from pontaj where data=@data and marca=@marca and numar_curent=@numar_curent)
