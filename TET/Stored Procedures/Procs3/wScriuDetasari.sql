--***

Create procedure wScriuDetasari (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDetasariSP')
begin
	declare @returnValue int
	exec @returnValue=wScriuDetasariSP @sesiune, @parXML output
	return @returnValue
end

declare @tip varchar(2), @tipAntet varchar(2), @subtip varchar(2), @utilizator char(10), @mesaj varchar(80),@update bit, 
@marca varchar(6), @datainceput datetime, @datasf datetime, @cuiang varchar(30), @nume_ang varchar(30), 
@nationalitate varchar(30), @dataincetarii datetime, @nrcrt int, @incetare int, @vmesaj varchar(100)
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@tipAntet = isnull(@parXML.value('(/row/row/@tip)[1]', 'varchar(2)'), ''),
			@subtip = isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),
			@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@datainceput=isnull(@parXML.value('(/row/row/@datainceput)[1]','datetime'),''),
			@datasf=isnull(@parXML.value('(/row/row/@datasf)[1]','datetime'),''),
			@cuiang=isnull(@parXML.value('(/row/row/@cuiang)[1]','varchar(30)'),''),
			@nume_ang=isnull(@parXML.value('(/row/row/@nume_ang)[1]','varchar(30)'),''),
			@nationalitate=isnull(@parXML.value('(/row/row/@nationalitate)[1]','varchar(30)'),''),
			@dataincetarii=isnull(@parXML.value('(/row/row/@dataincetare)[1]','datetime'),'01/01/1901'),
			@nrcrt=isnull(@parXML.value('(/row/row/@nrcrt)[1]','int'),0),
			@incetare=ISNULL(@parXML.value('(/row/row/@incetare)[1]','bit'),0),
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
	if ISNULL(@cuiang,'')=''
	begin
		raiserror('CUI angajator necompletat!', 16, 1)	
		return -1
	end
	if ISNULL(@nume_ang,'')=''
	begin
		raiserror('Nume angajator necompletat!', 16, 1)
		return -1
	end
	if ISNULL(@nationalitate,'')=''
	begin
		raiserror('Nationalitatea necompletata!', 16, 1)
		return -1
	end
	if not exists (select 1 from CatalogRevisal where TipCatalog='Nationalitate' and (cod = @nationalitate  or descriere=@nationalitate))
	begin
		raiserror('Nationalitatea inexistenta!', 16, 1)
		return -1
	end
	if exists (select 1 from extinfop l1 
		left join extinfop l2 on l2.Marca=l1.marca and l2.Procent=l1.procent and l2.Cod_inf='DETDATAINC'
		left join extinfop l3 on l3.Marca=l1.marca and l3.Procent=l1.procent and l3.Cod_inf='DETNATIONAL'
		where l1.Cod_inf='DETDATASF' and l1.Marca=@marca 
			and (((case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end)>@datainceput and l2.Data_inf<=@datainceput) 
				or (@datasf>l2.Data_inf and @datasf<=(case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end)) 
				or (@datainceput<=l2.Data_inf and @datasf>=(case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end))) and l1.Procent!=@nrcrt)		
	begin
		raiserror('Salariatul este deja detasat pe perioada specificata!', 16, 1)
		return -1
	end
	
	if @incetare=1 and exists(select 1 from extinfop where Marca=@marca and Cod_inf='DETNATIONAL' and Data_inf=@dataincetarii and Procent!=@nrcrt)
	begin
		raiserror('Aceasta data de incetare a detasarii a fost deja inregistrata pe o alta detasare!', 16, 1)
		return -1
	end
	
	if @incetare=1 and @dataincetarii<@datainceput 
	begin
		raiserror('Data incetarii detasarii trebuie sa fie mai mare sau egala cu data de inceput a detasarii!', 16, 1)
		return -1
	end
	
	if @incetare=0 and exists (select 1 from extinfop where Marca=@marca and Cod_inf='DETNATIONAL' and Val_inf=@nationalitate and (isnull(convert(char(10),Data_inf,101),'')='' or isnull(convert(char(10),Data_inf,101),'')='01/01/1900') and Procent!=@nrcrt)
	begin
		set @vmesaj='Salariatul este deja detasat in ' + rtrim(@nationalitate) + ' !'
		raiserror(@vmesaj, 16, 1)
		return -1
	end
	
	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(procent,0)) from extinfop where Marca=@marca and Cod_inf='DETDATAINC'
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'DETDATAINC',@cuiang,convert(char(10),@datainceput,101),@nrcrt)
		
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'DETDATASF',@nume_ang,convert(char(10),@datasf,101),@nrcrt)
		
		if @incetare=1 --problema e ca aici oricum am nevoie de nationalitate.. deci daca nu bifez incetare suspendare (detasare) cum fac cu dataincetarii?  chestiunea e ca nu ma lasa sa trec 2 dataincetarii in tabela :(
			insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
			values (@marca,'DETNATIONAL',@nationalitate,convert(char(10),@dataincetarii,101),@nrcrt)
		else
			insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
			values (@marca,'DETNATIONAL',@nationalitate,'01/01/1901',@nrcrt)
	end
	else --modificare
	begin 
		update extinfop set Val_inf = @cuiang, Data_inf=convert(char(10),@datainceput,101)
		where Marca=@marca and Cod_inf='DETDATAINC' and Procent=@nrcrt
		
		update extinfop set Val_inf =@nume_ang, Data_inf=convert(char(10),@datasf,101)
		where Marca=@marca and Cod_inf='DETDATASF' and Procent=@nrcrt
		
		if @incetare=1 
			update extinfop set Val_inf =@nationalitate, Data_inf=convert(char(10),@dataincetarii,101)
			where Marca=@marca and Cod_inf='DETNATIONAL' and Procent=@nrcrt	
		else
			update extinfop set Val_inf =@nationalitate, Data_inf='01/01/1901'
			where Marca=@marca and Cod_inf='DETNATIONAL' and Procent=@nrcrt	
	end

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLDet xml
		set @docXMLDet='<row marca="'+rtrim(@marca)+ '" tip="'++(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaDetasari @sesiune=@sesiune, @parXML=@docXMLDet
	end

end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
