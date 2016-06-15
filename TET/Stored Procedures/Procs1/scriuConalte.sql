--***
Create
procedure  scriuConalte 
(@Data datetime, @Marca char(6), @Tip_concediu char(1), @Data_inceput datetime, @Data_sfarsit datetime, @Zile int, 
@Introd_manual int, @Indemnizatie float, @Utilizator varchar(10), @Data_operarii datetime, @Ora_operarii char(6))
as
Begin 
	If isnull((select count(1) from Conalte where Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput and Tip_concediu=@Tip_concediu),0)=1
		update Conalte set Data_sfarsit=@Data_sfarsit, Zile=@Zile, Introd_manual=@Introd_manual, Indemnizatie=@Indemnizatie, 
		Utilizator=@Utilizator, Data_operarii=@Data_operarii, Ora_operarii=@Ora_operarii
		where Marca=@Marca and Data=@Data and Data_inceput=@Data_inceput and Tip_concediu=@Tip_concediu
	Else 
		insert into Conalte
		(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)
		Select @Data, @Marca, @Tip_concediu, @Data_inceput, @Data_sfarsit, @Zile, @Introd_manual, @Indemnizatie, @Utilizator, @Data_operarii, @Ora_operarii
End
