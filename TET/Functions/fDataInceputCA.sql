--***
/**	functie pentru stabilirea datei de inceput a unui tip de informatie din concedii\alte */
Create 
function fDataInceputCA
	(@pData datetime, @pMarca char(6), @pData_inceput datetime, @Tip_concediu char(1)) 
returns datetime
as
begin
	declare @rData_inceput datetime, @Data datetime, @Marca char(6), @Data_inceput datetime, @Data_sfarsit datetime, @GasitCAAnterior int

	declare DataInceputCA cursor for 
	select data, marca, data_inceput, data_sfarsit, 
	isnull((select count(1) from conalte b where b.Data<=@pData and b.marca=@pMarca 
		and (b.Data_sfarsit=DateAdd(day,-1,a.Data_inceput) or b.Data_sfarsit>=a.Data_inceput and b.Data_inceput<a.Data_inceput)),0)
	from conalte a
	where a.marca=@pMarca and (@Tip_concediu='' or Tip_concediu=@Tip_concediu) and a.Data_inceput<@pData_inceput
		and (a.data_sfarsit=DateAdd(day,-1,@pData_inceput) or a.Data_sfarsit>=@pData_inceput and a.Data_inceput<@pData_Inceput)
/*		or exists (select marca from conalte b where b.Data<=@pData and b.marca=@pMarca 
		and (b.Data_sfarsit=DateAdd(day,-1,a.Data_inceput) or b.Data<@pData and b.Data_sfarsit>=a.Data_inceput and b.Data_inceput<=a.Data_inceput)))*/
	order by a.data_inceput desc

	open DataInceputCA
	fetch next from DataInceputCA into @Data, @Marca, @Data_inceput, @Data_sfarsit, @GasitCAAnterior
	While @@fetch_status = 0 
	Begin
--		apelez recursiv functia 
		Set @rData_inceput=dbo.fDataInceputCA(@Data, @Marca, @Data_inceput, @Tip_concediu) 

		if @GasitCAAnterior=0
			break

		fetch next from DataInceputCA into @Data, @Marca, @Data_inceput, @Data_sfarsit, @GasitCAAnterior
	End
	close DataInceputCA
	Deallocate DataInceputCA
	if isnull(@rData_inceput,'01/01/1901')='01/01/1901'
		Set @rData_inceput = @pData_inceput

	return (@rData_inceput)
end
