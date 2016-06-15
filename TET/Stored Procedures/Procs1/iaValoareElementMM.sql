--***
create procedure iaValoareElementMM (@element varchar(20),
	@masina varchar(20), @data datetime, @data_plecarii datetime=null,
	@ora_plecarii varchar(20)=null, @valoare decimal(15,4) output)
as
begin
declare @eroare varchar(2000)
begin try
	declare @ln int	
	select @data_plecarii=isnull(@data_plecarii,'2999-1-1'),
			@ora_plecarii=isnull(@ora_plecarii,'300000'),
			@ln=len(@data_plecarii)

	set @valoare=isnull(
		(select top 1 ea.valoare from elemactivitati ea
			inner join pozactivitati pa on pa.idPozActivitati=ea.idPozActivitati
			inner join activitati a on pa.idActivitati=a.idActivitati
					and ea.element=@element and a.masina=@masina and
			(pa.data<@data or pa.data=@data and (pa.Data_plecarii<@data_plecarii
						or pa.Data_plecarii=@data_plecarii and left(pa.Ora_plecarii,@ln)<=left(@ora_plecarii,len(pa.Ora_plecarii))))
		order by ea.data desc, data_plecarii desc, ora_plecarii desc
		),0)
	return
end try
begin catch
	select @eroare=error_message()+' (iaValoareElementMM '+convert(varchar(20),error_line())+')'
end catch
if len(@eroare)>0 raiserror(@eroare,16,1)
end
