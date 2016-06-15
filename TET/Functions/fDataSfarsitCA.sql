--***
/**	functie pentru stabilirea datei de sfarsit a unui tip de informatie din concedii\alte aflat in continuare */
Create 
function fDataSfarsitCA
	(@pData datetime, @pMarca char(6), @pData_sfarsit datetime, @Tip_concediu char(1)) 
returns datetime
as
begin
	declare @rData_sfarsit datetime, @Data datetime, @Marca char(6), 
	@Data_inceput datetime, @Data_sfarsit datetime, @GasitCAUrmator int

	declare DataSfarsitCA cursor for 
	select data, marca, data_inceput, data_sfarsit, 
	isnull((select count(1) from conalte b where b.Data>=@pData and b.marca=@pMarca 
		and b.Data_inceput=DateAdd(day,1,a.Data_sfarsit)),0)
	from conalte a
	where a.marca=@pMarca and a.data_inceput>=DateAdd(day,1,@pData_sfarsit)
		and (@Tip_concediu='' or Tip_concediu=@Tip_concediu)
		and exists (select marca from conalte b where b.Data>=@pData and b.marca=@pMarca 
		and b.Data_inceput=DateAdd(day,1,@pData_sfarsit))

	order by a.data_inceput asc

	open DataSfarsitCA
	fetch next from DataSfarsitCA into @Data, @Marca, @Data_inceput, @Data_sfarsit, @GasitCAUrmator
	While @@fetch_status = 0 
	Begin
		Set @rData_sfarsit = @Data_sfarsit
		if @GasitCAUrmator=0
			break

		fetch next from DataSfarsitCA into @Data, @Marca, @Data_inceput, @Data_sfarsit, @GasitCAUrmator
	End
	close DataSfarsitCA
	Deallocate DataSfarsitCA
	if isnull(@rData_sfarsit,'01/01/1901')='01/01/1901'
		Set @rData_sfarsit = @pData_sfarsit

	return (@rData_sfarsit)
end
