--***
/**	procedura scriuTichete	*/
Create 
procedure scriuTichete 
	(@Marca char(6), @Data datetime, @Tip_operatie char(1), @Serie_inceput char(13), @Serie_sfarsit char(13), 
	@Nr_tichete int, @Valoare_tichet float, @Valoare_imprimat float, @TVA_imprimat float)
As
Begin 
	If isnull((select count(1) from Tichete where Data_lunii=@Data and Marca=@Marca and Tip_operatie=@Tip_operatie and Serie_inceput=@Serie_inceput),0)=1
		update Tichete set Serie_sfarsit=@Serie_sfarsit, Nr_tichete=@Nr_tichete, Valoare_tichet=@Valoare_tichet,
		Valoare_imprimat=@Valoare_imprimat, TVA_imprimat=@TVA_imprimat
		where Marca=@Marca and Data_lunii=@Data and Tip_operatie=@Tip_operatie and Serie_inceput=@Serie_inceput
	Else 
		insert into Tichete (Marca, Data_lunii, Tip_operatie, Serie_inceput, Serie_sfarsit, Nr_tichete, Valoare_tichet, Valoare_imprimat, TVA_imprimat)
		Select @Marca, @Data, @Tip_operatie, @Serie_inceput, @Serie_sfarsit, @Nr_tichete, @Valoare_tichet, @Valoare_imprimat, @TVA_imprimat
End
