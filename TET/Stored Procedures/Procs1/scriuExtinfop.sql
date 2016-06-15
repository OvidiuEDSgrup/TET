--***
Create
procedure scriuExtinfop @Marca varchar(6), @Cod_inf varchar(20), @Val_inf varchar(80), @Data_inf datetime, @Procent decimal(10,2), @Stergere int
as
Begin
--	stergere
	if @stergere<>0 
		delete from extinfop where Marca=@marca and Cod_inf=@cod_inf 
		and (@Stergere=2 or Val_inf=@Val_inf and Data_inf=@Data_inf)
--	scriere
	if exists (select 1 from extinfop where Marca=@marca and Cod_inf=@Cod_inf and Val_inf=@Val_inf and Data_inf=@Data_inf)
		update extinfop set Procent=@Procent where Marca=@marca and Cod_inf=@Cod_inf and Val_inf=@Val_inf and Data_inf=@Data_inf
	else
		insert into extinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
		select @Marca, @Cod_inf, @Val_inf, @Data_inf, @Procent
end
