--***
/**	procedura scriuCorectii	*/
Create 
procedure scriuCorectii 
(@Data datetime, @Marca char(6), @Loc_de_munca char(9), @Tip_corectie_venit char(2), @Suma_corectie float, @Procent_corectie float, @Suma_neta float)
As
Begin 
	If isnull((select count(1) from corectii where Data=@Data and Marca=@Marca and Loc_de_munca=@Loc_de_munca and Tip_corectie_venit=@Tip_corectie_venit),0)=1
		update corectii set Suma_corectie=@Suma_corectie, Suma_neta=@Suma_neta, Procent_corectie=@Procent_corectie
		where Data=@Data and Marca=@Marca and Loc_de_munca=@Loc_de_munca 
		and Tip_corectie_venit=@Tip_corectie_venit
	Else 
		insert into Corectii
		(Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
		Select @Data, @Marca, @Loc_de_munca, @Tip_corectie_venit, @Suma_corectie, @Procent_corectie, @Suma_neta
End
