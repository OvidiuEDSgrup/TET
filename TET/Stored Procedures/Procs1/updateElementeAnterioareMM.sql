--***
create procedure updateElementeAnterioareMM (@bordDif decimal(15,2), @element varchar(20),
	@masina varchar(20), @data datetime, @data_plecarii datetime=null,
	@ora_plecarii varchar(20)=null)
	--(@tip varchar(2), @fisa varchar)
as
begin
declare @eroare varchar(2000)
begin try
	/*select	@KmBord=valoare
			from elemactivitati ea
			where ea.Tip=@tip and fisa=@fisa and ea.data=@data and ea.numar_pozitie=@numar_pozitie
				and ea.Element='KmBord'*/
	declare @ln int
	select @data_plecarii=isnull(@data_plecarii,'1901-1-1'),
			@ora_plecarii=isnull(@ora_plecarii,'000000'),
			@ln=len(@data_plecarii)

	update ea set ea.valoare=ea.valoare+@bordDif
	from elemactivitati ea
		inner join pozactivitati pa on ea.tip=pa.tip and ea.data=pa.data and ea.Numar_pozitie=pa.Numar_pozitie and ea.fisa=pa.fisa	--> se va inlocui cu:
			--ea.idpozactivitati=pa.idpozactivitati
		inner join activitati a on pa.Fisa=a.fisa and pa.Tip=a.Tip and a.data=pa.data	--> se va inlocui cu:
								--	pa.idactivitati=a.idactivitati	
	where ea.Element=@element and a.Masina=@masina and 
		(pa.data>@data or pa.data=@data and (pa.Data_plecarii>@data_plecarii
		or pa.Data_plecarii=@data_plecarii and
		left(pa.Ora_plecarii,@ln)>left(@ora_plecarii,len(pa.Ora_plecarii))))
end try
begin catch
	select @eroare=error_line()+' (updateElementeAnterioareMM '+convert(varchar(20),error_line())+')'
end catch
if len(@eroare)>0 raiserror(@eroare,16,1)
end
