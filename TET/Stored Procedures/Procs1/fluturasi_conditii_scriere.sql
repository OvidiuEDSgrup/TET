--***
/**	conditii scriere fluturasi	*/
Create procedure fluturasi_conditii_scriere
	@contor_marci int output, @contor_impar int output, @nloc_de_munca char(9), @glocm char(9), @psupervisor varchar(50), @gsupervisor varchar(50), 
	@Ordonare char(50), @conditie1 bit output, @conditie2 bit output, @conditie3 bit output
as
Begin
	declare @flut3col bit, @saltpag bit, @flut1col bit, @supervisorPeMarca int, @saltpagLM bit, @saltpagsupervisor bit
--	Variabila @flut1col pusa pe True din procedura din formularul SQL, pt. a putea scrie din formularul sql pt. Colas in tabela flutur datele pe o singura col
	Exec Luare_date_par 'PS', 'FLUT_1CL', @flut1col output , 0, 0
	Exec Luare_date_par 'PS', 'SALT_LIST', @saltpag output , 0, 0
	Exec Luare_date_par 'PS', 'FLUT_3CL', @flut3col output , 0, 0
	Exec Luare_date_par 'PS', 'SUPERVISO', @supervisorPeMarca output , 0, 0

	set @saltpagLM=(case when @saltpag=1 and @nloc_de_munca<>@glocm and @Ordonare<>'Nume' and @supervisorPeMarca=0 then 1 else 0 end)
	set @saltpagsupervisor=(case when @supervisorPeMarca=1 and @psupervisor<>@gsupervisor then 1 else 0 end)

	if @contor_marci>1 and (@saltpagLM=1 or @saltpagsupervisor=1)
		Set @contor_marci=@contor_marci+(case when @flut3col=1 then 3 else 2 end)-dbo.modulo(@contor_marci,(case when @flut3col=1 then 3 else 2 end))

	Set @contor_marci=@contor_marci+1
	if dbo.modulo(@contor_marci, (case when @flut3col=1 then 3 else 2 end))=1 or @saltpagLM=1 or @saltpagsupervisor=1 or @flut1col=1
		Set @contor_impar= isnull((select max(numar_pozitie) from flutur),0)
	if (select count(1) from #contor_marca)=0
		insert into #contor_marca select @contor_impar
	else 
		update #contor_marca set contor_marca=@contor_impar

--Set @contor_marca=@contor_impar
	Set @conditie1=(case when dbo.modulo(@contor_marci, (case when @flut3col=1 then 3 else 2 end))=1 or 
		(@saltpagLM=1 or @saltpagsupervisor=1) then 1 else 0 end)
	Set @conditie2=(case when @flut3col=1 and dbo.modulo(@contor_marci,3)=2 and 
		not(@saltpagLM=1 or @saltpagsupervisor=1) then 1 else 0 end)
	Set @conditie3=(case when dbo.modulo(@contor_marci, (case when @flut3col=1 then 3 else 2 end))=0 and 
		not(@saltpagLM=1 or @saltpagsupervisor=1) then 1 else 0 end)
End
