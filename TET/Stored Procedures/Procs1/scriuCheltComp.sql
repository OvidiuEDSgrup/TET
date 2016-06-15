--***
/**	procedura scriuCheltComp */
Create 
procedure scriuCheltComp (@Data datetime, @Lm char(9), @Comanda char(20), @Cont char(13), 
@Componenta char(30), @Suma float)
As
Begin 
	if exists (select data from cheltcomp where data=@Data and loc_de_munca=@Lm and comanda=@Comanda and cont=@Cont and componenta=@Componenta)
		update cheltcomp set suma = suma + @Suma where data=@Data and loc_de_munca=@Lm and comanda=@Comanda and cont=@Cont and componenta=@Componenta 
	else 
		insert into cheltcomp select @Data, @Lm, @Comanda, @Cont, @Componenta, @Suma
End
