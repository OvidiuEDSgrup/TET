--***
/**	procedura pentru scriere in realizari pe comenzi (Realcom)	*/
Create 
procedure scriuRealcom 
(@Marca char(6), @Loc_de_munca char(9), @Numar_document char(20), @Data datetime, @Comanda char(20), 
@Cod_reper char(20), @Cod_operatie char(20), @Cantitate float, @Categoria_salarizare char(4), @Norma_de_timp float, @Tarif_unitar float)
As
Begin 
	If isnull((select count(1) from Realcom where Data=@Data and Marca=@Marca and Loc_de_munca=@Loc_de_munca 
	and Comanda=@Comanda and Numar_document=@Numar_document),0)=1
		update Realcom set Cod_reper=@Cod_reper, Cod=@Cod_operatie, Cantitate=@Cantitate,
		Categoria_salarizare=@Categoria_salarizare, Norma_de_timp=@Norma_de_timp, Tarif_unitar=@Tarif_unitar
		where Data=@Data and Marca=@Marca and Loc_de_munca=@Loc_de_munca and Comanda=@Comanda 
		and Numar_document=@Numar_document
	Else 
		insert into Realcom (Marca, Loc_de_munca, Numar_document, Data, Comanda, Cod_reper, Cod, Cantitate, Categoria_salarizare, Norma_de_timp, Tarif_unitar)
		Select @Marca, @Loc_de_munca, @Numar_document, @Data, @Comanda, @Cod_reper, @Cod_operatie, @Cantitate, @Categoria_salarizare, @Norma_de_timp, @Tarif_unitar
End
