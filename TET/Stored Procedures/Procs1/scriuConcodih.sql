--***
/**	procedura scriuConcodih	*/
Create 
procedure scriuConcodih 
(@Data datetime, @Marca char(6), @Tip_concediu char(1), @Data_inceput datetime, @Data_sfarsit datetime, 
@Zile_CO int, @Indemnizatie_CO float, @Data_inreg float, @lData_inregistrarii int, @nData_inregistrarii float, 
@lSterg int, @Introd_manual int=0)
as
Begin 
	delete from concodih 
	where @lSterg=1 and Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput 
		and Tip_concediu=@Tip_concediu 
		and (@lData_inregistrarii=0 or Prima_vacanta=@nData_inregistrarii)
	If @lSterg=0 and isnull((select count(1) from Concodih where Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput and Tip_concediu=@Tip_concediu),0)=1
		update Concodih set Data_sfarsit=@Data_sfarsit, Zile_CO=@Zile_CO, 
			Indemnizatie_CO=(case when @Tip_concediu='9' or @Introd_manual=1 then @Indemnizatie_CO else Indemnizatie_CO end),
			Introd_manual=@Introd_manual
		where Marca=@Marca and Data=@Data and Data_inceput=@Data_inceput and Tip_concediu=@Tip_concediu
	Else 
		insert into ConcOdih
		(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile_CO, Introd_manual, Indemnizatie_CO, Zile_prima_vacanta, Prima_vacanta)
		Select @Data, @Marca, @Tip_concediu, @Data_inceput, @Data_sfarsit, @Zile_CO, @Introd_manual, @Indemnizatie_CO, 0, @Data_inreg
End
