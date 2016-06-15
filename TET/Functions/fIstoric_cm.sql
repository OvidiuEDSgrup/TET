--***
/**	functie fistoric CM	*/
Create function fIstoric_cm 
	(@Data datetime, @Marca char(6), @Tip_diagnostic char(2), @Data_inceput datetime, @Continuare int, @Suma int, @Luni_istoric int) 
returns @istoric_cm table
	(Data datetime, Marca char(6), Total_Ore_lucrate int, ore_suplimentare_1 int, ore_suplimentare_2 int, ore_suplimentare_3 int, ore_suplimentare_4 int, ore_spor_100 int, 
	ore_lucrate_regim_normal int, ore_concediu_de_odihna int, ore_concediu_medical int, ore_nemotivate int, ore_invoiri int, ore_obligatii_cetatenesti int, ore_intrerupere_tehnologica int, 
	ore_concediu_fara_salar int,cm_unitate float, cm_cas float, regim_lucru float, baza_cci float, baza_cci_plaf float, baza_casi float, zile_asig float, 
	Ore_somaj_tehnic float, Baza_somaj_tehnic float)
as
begin
	if @Data is null and @Marca is null and @Tip_diagnostic is null and @Data_inceput is null
	Begin
		declare @Term char(8), @utilizator varchar(10) 
		Set @Term=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
		set @utilizator=dbo.fIaUtilizator('')
	
		Select @Data=Data, @Marca=Numar, @Tip_diagnostic=Factura, @Data_inceput=Data_facturii, @Luni_istoric=6 
		from avnefac where (Terminal=@utilizator or Terminal=@Term) and Tip='AD'
		Select @Continuare=(case when c.Zile_luna_anterioara<>0 or i.Nr_certificat_CM_initial<>'' then 1 else 0 end)
		from conmed c
			left outer join infoconmed i on i.Data=c.Data and i.Marca=c.Marca and i.Data_inceput=c.Data_inceput
		where c.Data=@Data and c.Marca=@Marca and c.Data_inceput=@Data_inceput
	End	
	if isnull((select count(1) from sysobjects where name='istoric_cmsp' and type in ('FN','IF','TF')),0)=1
		insert @istoric_cm
		select * from istoric_cmsp (@Data, @Marca, @Tip_diagnostic, @Data_inceput, @Continuare, @Suma, @Luni_istoric) 
	Else
		insert @istoric_cm
		select * from istoric_cm (@Data, @Marca, @Tip_diagnostic, @Data_inceput, @Continuare, @Suma, @Luni_istoric) 

	return
End
