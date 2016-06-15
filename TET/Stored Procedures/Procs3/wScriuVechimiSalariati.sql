--***

Create procedure wScriuVechimiSalariati (@sesiune varchar(250), @parXML xml)
as

-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuVechimiSalariatiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wScriuVechimiSalariatiSP @sesiune, @parXML output
	return @returnValue
end

declare @tip varchar(2), @tipAntet varchar(2), @subtip varchar(2), @utilizator char(10), @mesaj varchar(200), @update bit, 
	@marca varchar(6), @data_inceput datetime, @data_sfarsit datetime, @unitate varchar(30), @loc_de_munca varchar(30), 
	@functie varchar(30), @tipv varchar(1), @nrcrt int, @calcul int, @old_tipv varchar(1), @numar_pozitie int, 
	@zilesuspendare int, @regim int, @tipvPoz2 varchar(1) 
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return -1
	
	select  @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@tipAntet = isnull(@parXML.value('(/row/row/@tip)[1]', 'varchar(2)'), ''),
			@subtip = isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),
			@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@data_inceput=isnull(@parXML.value('(/row/row/@data_inceput)[1]','datetime'),''),
			@data_sfarsit=isnull(@parXML.value('(/row/row/@data_sfarsit)[1]','datetime'),''),
			@unitate=isnull(@parXML.value('(/row/row/@unitate)[1]','varchar(30)'),''),
			@loc_de_munca=isnull(@parXML.value('(/row/row/@loc_de_munca)[1]','varchar(30)'),''),
			@functie=isnull(@parXML.value('(/row/row/@functie)[1]','varchar(30)'),''),
			@zilesuspendare=isnull(@parXML.value('(/row/row/@zilesuspend)[1]','int'),''),
			@regim=isnull(@parXML.value('(/row/row/@regim)[1]','int'),''),
			@tipv=isnull(@parXML.value('(/row/row/@tipv)[1]','varchar(1)'),''),
			@old_tipv=isnull(@parXML.value('(/row/row/@o_tipv)[1]','varchar(1)'),''),
			@update=ISNULL(@parXML.value('(/row/row/@update)[1]','bit'),0),
			@calcul=ISNULL(@parXML.value('(/row/row/@calcul)[1]','int'),0),
			@numar_pozitie=ISNULL(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0)

	if ISNULL(@tipv,'')='' 
	begin
		raiserror('Tip vechime necompletat!', 16, 1)
		return -1
	end

	if ISNULL(@data_inceput,'')='' 
	begin
		raiserror('Data inceput necompletata!', 16, 1)
		return -1
	end
	if ISNULL(@data_sfarsit,'')=''
	begin
		raiserror('Data sfarsit necompletata!', 16, 1)	
		return -1
	end
	
	if @data_inceput>=@data_sfarsit
	begin
		raiserror('Data sfarsit trebuie sa fie cronologic dupa data inceput!', 16, 1)	
		return -1
	end
	
	if ISNULL(@unitate,'')=''
	begin
		raiserror('Unitate necompletata!', 16, 1)	
		return -1
	end
	
	if ISNULL(@loc_de_munca,'')=''
	begin
		raiserror('Loc de munca necompletat!', 16, 1)
		return -1
	end
	
	if ISNULL(@functie,'')=''
	begin
		raiserror('Functie necompletata!', 16, 1)
		return -1
	end

	set @tipvPoz2=(case when @tipv='T' then '1' when @tipv='I' then '2' when @tipv='M' then '3' else '0' end)
	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(numar_pozitie,0)) from Vechimi where Marca=@marca and tip=@tipv
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		
		insert into vechimi (Marca,Tip,Numar_pozitie,Data_inceput,Data_sfarsit,Unitate,Loc_de_munca,Functie)
		values (@marca,@tipv,@nrcrt,convert(char(10),@data_inceput,101),convert(char(10),@data_sfarsit,101),@unitate,@loc_de_munca,@functie)
		
		if isnull(@regim,0)<>0 or isnull(@zilesuspendare,0)<>0
			insert into vechimi (Marca,Tip,Numar_pozitie,Data_inceput,Data_sfarsit,Unitate,Loc_de_munca,Functie)
			values (@marca,@tipvPoz2,@nrcrt,'','','',@zilesuspendare,@regim)
	end
	else --modificare
	begin 
		update vechimi set Tip = @tipv, Data_inceput=convert(char(10),@data_inceput,101), Data_sfarsit=convert(char(10),@data_sfarsit,101),
			Unitate=@unitate, Functie=@functie, Loc_de_munca=@loc_de_munca
		where Marca=@marca and tip=@old_tipv and Numar_pozitie=@numar_pozitie

		if isnull(@regim,0)<>0 or isnull(@zilesuspendare,0)<>0
			if not exists (select Marca from vechimi where Marca=@marca and tip=(case when @tipv='T' then '1' when @tipv='I' then '2' when @tipv='M' then '3' else '0' end) and Numar_pozitie=@numar_pozitie)
				insert into vechimi (Marca,Tip,Numar_pozitie,Data_inceput,Data_sfarsit,Unitate,Loc_de_munca,Functie)
				values (@marca,@tipvPoz2,@numar_pozitie,'','','',@zilesuspendare,@regim)
			else
				update vechimi set Loc_de_munca=@zilesuspendare, Functie=@regim
				where Marca=@marca and tip=@tipvPoz2 and Numar_pozitie=@numar_pozitie
		else
			delete from Vechimi 
			where Marca=@marca and tip=@tipvPoz2 and Numar_pozitie=@numar_pozitie
	end
	
	if @calcul=1 --daca se bifeaza calcul vechime, se pune vechimea in personal sau infopers
	Begin
		declare @Vechime char(10)
		set @Vechime=dbo.fCalculVechimi(@marca,@tipv)
		if @tipv='T' --	vechime totala
			update personal set Vechime_totala=convert(datetime,@Vechime,111) where Marca=@marca
		if @tipv='I' --	vechime la intrare
			update infoPers set Vechime_la_intrare=rtrim(@Vechime) where Marca=@marca
		if @tipv='M' --	vechime in meserie
			update infoPers set Vechime_in_meserie=rtrim(@Vechime) where Marca=@marca
	End

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLVechimi xml
		set @docXMLVechimi='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaVechimiSalariati @sesiune=@sesiune, @parXML=@docXMLVechimi
	end

end try

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wScriuVechimiSalariati)'
	raiserror(@mesaj,11,1)
end catch
--sp_help vechimi
--select * from vechimi
