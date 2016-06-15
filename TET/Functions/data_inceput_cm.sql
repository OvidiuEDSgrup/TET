--***
/**	functie data_inceput_CM	*/
Create function data_inceput_cm 
	(@pData datetime, @pMarca char(6), @pData_inceput datetime, @pContinuare int) 
returns datetime
as
begin
	declare @rData_inceput datetime, @Data_inceput_1 datetime, @Data datetime, @cMarca char(6), @Data_inceput datetime, @Data_sfarsit datetime, @Zile_luna_anterioara int, 
	@Nr_certificat_CM_initial varchar(10), @Gasit_cm_ant int
	Set @Data_inceput_1 = @pData_inceput-1

	declare data_inceput_cm cursor for 
	select a.data, a.marca, a.data_inceput, a.data_sfarsit, a.zile_luna_anterioara, i.Nr_certificat_CM_initial, 
	isnull((select count(1) from conmed b where b.Data<=@pData and b.marca=@pMarca and b.Data_sfarsit=a.Data_inceput-1),0)
	from conmed a
		left outer join infoconmed i on i.Data=a.Data and i.Marca=a.Marca and a.Data_inceput=i.Data_inceput
	where a.marca=@pMarca and a.data_sfarsit<=@Data_inceput_1 --and zile_luna_anterioara<>0
	order by a.data_inceput desc

	open data_inceput_cm
	fetch next from data_inceput_cm into @Data, @cMarca, @Data_inceput, @Data_sfarsit, @Zile_luna_anterioara, @Nr_certificat_CM_initial, @Gasit_cm_ant
	While @@fetch_status = 0 and @pContinuare=1
	Begin
		Set @rData_inceput = @Data_inceput
		if (@Gasit_cm_ant=0 or @Zile_luna_anterioara=0 and @Nr_certificat_CM_initial='') --or @Nr_certificat_CM_initial=''*
			break

		fetch next from data_inceput_cm into @Data, @cMarca, @Data_inceput, @Data_sfarsit, @Zile_luna_anterioara, @Nr_certificat_CM_initial, @Gasit_cm_ant
	End
	close data_inceput_cm
	Deallocate data_inceput_cm
	if isnull(@rData_inceput,'01/01/1901')='01/01/1901'
		Set @rData_inceput = @pData_inceput

	return (@rData_inceput)
end
