--***
Create procedure wScriuSalariatiInlocuitori (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuSalariatiInlocuitoriSP')
begin
	declare @returnValue int
	exec @returnValue=wScriuSalariatiInlocuitoriSP @sesiune, @parXML output
	return @returnValue
end

declare @tip varchar(2), @tipAntet varchar(2), @subtip varchar(2), @utilizator char(10), @mesajEroare varchar(1000), @mesaj varchar(1000), @update bit, 
	@marca varchar(6), @nume varchar(100), @marcainloc varchar(6), @numeInloc varchar(100), @datainceput datetime, @datasfarsit datetime, @motiv varchar(80), @nrcrt int
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
			@tipAntet = isnull(@parXML.value('(/row/row/@tip)[1]','varchar(2)'),''),
			@subtip = isnull(@parXML.value('(/row/@subtip)[1]','varchar(2)'),''),
			@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@marcainloc=isnull(@parXML.value('(/row/row/@marcainloc)[1]','varchar(6)'),''),
			@datainceput=isnull(@parXML.value('(/row/row/@datainceput)[1]','datetime'),''),
			@datasfarsit=isnull(@parXML.value('(/row/row/@datasfarsit)[1]','datetime'),''),
			@motiv=isnull(@parXML.value('(/row/row/@motiv)[1]','varchar(80)'),''),
			@nrcrt=isnull(@parXML.value('(/row/row/@nrcrt)[1]','int'),0),
			@update=ISNULL(@parXML.value('(/row/row/@update)[1]','bit'),0)
	
	if ISNULL(@datainceput,'')=''
	begin
		raiserror('Data inceput necompletata!', 16, 1)
		return -1
	end
	if ISNULL(@datasfarsit,'')=''
	begin
		raiserror('Data sfarsit necompletata!', 16, 1)	
		return -1
	end
	if @datainceput>=@datasfarsit
	begin
		raiserror('Data sfarsit trebuie sa fie cronologic dupa data inceput!', 16, 1)	
		return -1
	end
	if ISNULL(@marcainloc,'')='' or not exists (select 1 from personal where marca=@marca)
	begin
		raiserror('Marca neintrodusa sau inexistenta in catalogul de personal!', 16, 1)	
		return -1
	end

	select @nume=nume from personal where marca=@marca
	select @numeInloc=nume from personal where marca=@marcainloc
	/*	cazul in care pentru acelasi salariat se incearca adaugarea a doua persoane inlocuitoare, pentru o perioada comuna */
	if exists (select 1 from extinfop e1 
		left join extinfop e2 on e2.Marca=e1.marca and e2.Procent=e1.procent
		where e1.Cod_inf='SALINLOCSF' and e2.Cod_inf='SALINLOCIN' and e1.Marca=@marca 
			and ((@datainceput<e1.Data_inf and @datainceput>=e2.Data_inf) or (@datasfarsit>e2.Data_inf and @datasfarsit<=e1.Data_inf) 
				or (@datainceput <=e2.data_inf and @datasfarsit>=e1.data_inf)) and e1.Procent!=@nrcrt)
	begin
		set @mesaj='Salariatul ('+rtrim(@nume)+'-'+rtrim(@marca)+') are precizat de catre cine este inlocuit in perioada specificata!'
		raiserror(@mesaj, 16, 1)
		return -1
	end
	/*	cazul in care se incearca adaugarea aceleiasi persoane ca si inlocuitor la 2 salariati, pentru o perioada comuna */
	if exists (select 1 from extinfop e1 
		left join extinfop e2 on e2.Marca=e1.marca and e2.Procent=e1.procent
		where e1.Cod_inf='SALINLOCIN' and e2.Cod_inf='SALINLOCSF' and e1.Val_inf=@marcaInloc 
			and ((@datainceput>=e1.Data_inf and @datainceput<e2.Data_inf) or (@datasfarsit>e1.Data_inf and @datasfarsit<=e2.Data_inf) 
				or (@datainceput<=e1.data_inf and @datasfarsit>=e2.data_inf)) and e1.Procent!=@nrcrt)
	begin
		set @mesaj='Salariatul ('+rtrim(@numeInloc)+'-'+rtrim(@marcaInloc)+') este deja pus ca si inlocuitor in perioada specificata!'
		raiserror(@mesaj, 16, 1)
		return -1
	end

	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(procent,0)) from extinfop where Marca=@marca and Cod_inf = 'SCDATAINC'
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'SALINLOCIN',@marcainloc,convert(char(10),@datainceput,101),@nrcrt)
		
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'SALINLOCSF',@motiv,convert(char(10),@datasfarsit,101),@nrcrt)
	end

	else --modificare
	begin 
		update extinfop set Val_inf = @marcainloc, Data_inf=convert(char(10),@datainceput,101)
		where Marca=@marca and Cod_inf='SALINLOCIN' and Procent=@nrcrt
		
		update extinfop set Val_inf=@motiv, Data_inf=convert(char(10),@datasfarsit,101)
		where Marca=@marca and Cod_inf='SALINLOCSF' and Procent=@nrcrt
	end

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLInloc xml
		set @docXMLInloc='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaSalariatiInlocuitori @sesiune=@sesiune, @parXML=@docXMLInloc
	end

end try

begin catch
	set @mesajEroare='(wScriuSalariatiInlocuitori) '+ERROR_MESSAGE()
	raiserror(@mesajEroare,11,1)
end catch
