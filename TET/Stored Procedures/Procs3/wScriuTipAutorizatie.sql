--***
Create procedure wScriuTipAutorizatie (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuTipAutorizatieSP')
begin
	declare @returnValue int
	exec @returnValue=wScriuTipAutorizatieSP @sesiune, @parXML output
	return @returnValue
end

declare @tip varchar(2), @utilizator char(10), @mesaj varchar(200), @update bit,
@marca varchar(6), @datainceput datetime, @datasf datetime, @tipautorizatie varchar(30), @nrcrt int
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
			@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@datainceput=isnull(@parXML.value('(/row/row/@datainceput)[1]','datetime'),''),
			@datasf=isnull(@parXML.value('(/row/row/@datasf)[1]','datetime'),''),
			@tipautorizatie=isnull(@parXML.value('(/row/row/@tipautorizatie)[1]','varchar(30)'),''),
			@nrcrt=isnull(@parXML.value('(/row/row/@nrcrt)[1]','int'),0),
			@update=ISNULL(@parXML.value('(/row/row/@update)[1]','bit'),0)

	if ISNULL(@datainceput,'')='' 
	begin
		raiserror('Data inceput necompletata!', 16, 1)
		return -1
	end
	if ISNULL(@datasf,'')=''
	begin
		raiserror('Data sfarsit necompletata!', 16, 1)	
		return -1
	end
	if @datainceput>=@datasf
	begin
		raiserror('Data sfarsit trebuie sa fie cronologic dupa data inceput!', 16, 1)	
		return -1
	end
	if ISNULL(@tipautorizatie,'')=''
	begin
		raiserror('Tip autorizatie necompletata!', 16, 1)	
		return -1
	end
	if not exists (select 1 from CatalogRevisal where TipCatalog='TipAutorizatie' and (cod = @tipautorizatie or descriere=@tipautorizatie))
	begin
		raiserror('Tip autorizatie inexistenta!', 16, 1)
		return -1
	end
	if exists (select 1 from extinfop l1 
		left join extinfop l2 on l2.Marca=l1.marca and l2.Procent=l1.procent
		where l1.Cod_inf='AUTDATASF' and l2.Cod_inf='AUTDATAINC' and l2.Val_inf=@tipautorizatie and l1.Marca=@marca and ((l1.Data_inf>@datainceput and l2.Data_inf<=@datainceput) or (@datasf>l2.Data_inf and @datasf<=l1.Data_inf)or (@datainceput <=l2.data_inf and @datasf>=l1.data_inf)) and l1.Procent!=@nrcrt)		
	begin
		raiserror('Salariatul are deja autorizatie pe perioada specificata!', 16, 1)
		return -1
	end
	if exists (select 1 from extinfop where Cod_inf='AUTDATASF' and Marca=@marca and Procent!=@nrcrt and Data_inf=@datasf)
		begin
		raiserror('Data de sfarsit a autorizatiei nu trebuie sa fie identica cu o alta data de sfarsit deja introdusa pentru acest salariat!', 16, 1)
		return -1
	end
	
	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(procent,0)) from extinfop where Marca=@marca and Cod_inf='AUTDATAINC'
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'AUTDATAINC',@tipautorizatie,convert(char(10),@datainceput,101),@nrcrt)
		
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'AUTDATASF','',convert(char(10),@datasf,101),@nrcrt)
	end
	else --modificare
	begin 
		update extinfop set Val_inf = @tipautorizatie, Data_inf=convert(char(10),@datainceput,101)
		where Marca=@marca and Cod_inf='AUTDATAINC' and Procent=@nrcrt
		
		update extinfop set Data_inf=convert(char(10),@datasf,101)
		where Marca=@marca and Cod_inf='AUTDATASF' and Procent=@nrcrt
	end

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tip in ('S')
	begin
		declare @docXMLAutoriz xml
		set @docXMLAutoriz='<row marca="'+rtrim(@marca)+ '" tip="'+@tip +'"/>'
		exec wIaTipAutorizatie @sesiune=@sesiune, @parXML=@docXMLAutoriz
	end

end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
