--***
/**	procedura pt. scriere in Totlocm + tabela utilizata la totaluri pe locuri de munca in lista avans/liste de plata lichidare*/
Create
procedure scriuTotlocm 
(@Loc_de_munca char(9), @Avans decimal(10,2), @Retinere decimal(10,2), @Total decimal(10,2), 
@Premiu decimal(10,2), @TotalCardSalubris decimal(10,2), @NumarAngajati int)
As
Begin 
	declare @CodParinte char(9)
	Select @CodParinte=Cod_parinte from lm where Cod=@Loc_de_munca

	If isnull((select count(1) from Totlocm where Cod=@Loc_de_munca),0)=1
		update Totlocm set Avans=Avans+@Avans, Retinere=Retinere+@Retinere, Total=Total+@Total, 
		Premiu=Premiu+@Premiu, Ore_pontaj_t=Ore_pontaj_t+@NumarAngajati, Salar_pontaj_t=Salar_pontaj_t+@TotalCardSalubris
		where Cod=@Loc_de_munca 
	Else 
		insert into Totlocm
		(Cod, Avans, Retinere, Total, Premiu, Ore_pontaj_t, Salar_pontaj_t, Ore_acord_t, Salar_acord_t)
		Select @Loc_de_munca, @Avans, @Retinere, @Total, @Premiu, @NumarAngajati, @TotalCardSalubris, 0, 0
	if @CodParinte<>''
		exec scriuTotlocm @CodParinte, @Avans, @Retinere, @Total, @Premiu, @TotalCardSalubris, @NumarAngajati
End
