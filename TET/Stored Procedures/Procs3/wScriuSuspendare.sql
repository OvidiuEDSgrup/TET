--***
Create procedure wScriuSuspendare (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuSuspendareSP')
begin
	declare @returnValue int
	exec @returnValue=wScriuSuspendareSP @sesiune, @parXML output
	return @returnValue
end

declare @tip varchar(2), @tipAntet varchar(2), @subtip varchar(2), @utilizator char(10), @mesaj varchar(200), @update bit,
@marca varchar(6), @datainceput datetime, @datasf datetime, @temeisusp varchar(60), @dentemeisusp varchar(200), 
@dataincetarii datetime, @nrcrt int, @incetare int
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@tipAntet = isnull(@parXML.value('(/row/row/@tip)[1]', 'varchar(2)'), ''),
			@subtip = isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),
			@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@datainceput=isnull(@parXML.value('(/row/row/@datainceput)[1]','datetime'),'01/01/1901'),
			@datasf=isnull(@parXML.value('(/row/row/@datasf)[1]','datetime'),'01/01/1901'),
			@temeisusp=isnull(@parXML.value('(/row/row/@temeisusp)[1]','varchar(60)'),''),
			@dentemeisusp=isnull(@parXML.value('(/row/row/@temeilegal)[1]','varchar(200)'),''),
			@dataincetarii=isnull(@parXML.value('(/row/row/@dataincetare)[1]','datetime'),''),
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
	if @datainceput>@datasf
	begin
		raiserror('Data sfarsit trebuie sa fie cronologic dupa data inceput!', 16, 1)	
		return -1
	end
	if ISNULL(@temeisusp,'')=''
	begin
		raiserror('Temeiul legal necompletat!', 16, 1)	
		return -1
	end
	if not exists(select 1 from CatalogRevisal where TipCatalog='TemeiSuspendare' and (cod=@temeisusp or descriere=@dentemeisusp))
	begin
		raiserror('Temei legal inexistent!', 16, 1)	
		return -1
	end
	if exists (select 1 from extinfop l1 
		left join extinfop l2 on l2.Marca=l1.marca and l2.Procent=l1.procent and l2.Cod_inf='SCDATAINC'
		left join extinfop l3 on l3.Marca=l1.marca and l3.Procent=l1.procent and l3.Cod_inf='SCDATAINCET'
		where l1.Cod_inf='SCDATASF' and l1.Marca=@marca 
			and (((case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end)>@datainceput and l2.Data_inf<=@datainceput) 
				or (@datasf>l2.Data_inf and @datasf<=(case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end)) 
				or (@datainceput <=l2.data_inf and @datasf>=(case when isnull(l3.Data_inf,'')<='01/01/1901' then l1.Data_inf else l3.Data_inf end))) and l1.Procent!=@nrcrt)
	begin
		raiserror('Contractul salariatului este deja suspendat pe perioada specificata!', 16, 1)
		return -1
	end
	if @incetare=1 and exists(select 1 from extinfop where Marca=@marca and Cod_inf='SCDATAINCET' and Data_inf=@dataincetarii and procent!=@nrcrt)
	begin
		raiserror('Aceasta data de incetare a suspendarii a fost deja inregistrata pe o alta suspendare!', 16, 1)
		return -1
	end
	if @incetare=1 and @dataincetarii<@datainceput 
	begin
		raiserror('Data incetarii suspendarii trebuie sa fie mai mare sau egala cu data de inceput a suspendarii!', 16, 1)
		return -1
	end
	if @temeisusp='Art52Alin1LiteraD' and not exists (select 1 from fRevisalDetasari ('01/01/1901', '12/31/2999', @marca, null) d where d.DataInceput=@datainceput and d.DataSfarsit=@datasf)
	Begin
		raiserror('Nu s-a operat detasarea! Inregistrati mai intai detasarea si apoi reveniti pentru a inregistra suspendarea pe perioada detasarii!', 16, 1)
		return -1
	End		


	if @update=0 -- adaugare
	begin
		set @nrcrt=0
		select @nrcrt=MAX(isnull(procent,0)) from extinfop where Marca=@marca and Cod_inf = 'SCDATAINC'
		set @nrcrt=ISNULL(@nrcrt,0)
		set @nrcrt=@nrcrt+1
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'SCDATAINC',@temeisusp,convert(char(10),@datainceput,101),@nrcrt)
		
		insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
		values (@marca,'SCDATASF','',convert(char(10),@datasf,101),@nrcrt)
		
		if @incetare=1 
			insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
			values (@marca,'SCDATAINCET','',convert(char(10),@dataincetarii,101),@nrcrt)
	end

	else --modificare
	begin 
		update extinfop set Val_inf = @temeisusp, Data_inf=convert(char(10),@datainceput,101)
		where Marca=@marca and Cod_inf='SCDATAINC' and Procent=@nrcrt
		
		update extinfop set Data_inf=convert(char(10),@datasf,101)
		where Marca=@marca and Cod_inf='SCDATASF' and Procent=@nrcrt
		
		if @incetare=1
			if not exists(select 1 from extinfop where Marca=@marca and Cod_inf='SCDATAINCET' and Procent=@nrcrt)
				insert into extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
				values (@marca,'SCDATAINCET',convert(char(10),@dataincetarii,101),convert(char(10),@dataincetarii,101),@nrcrt)	
			else
				update extinfop set Data_inf=convert(char(10),@dataincetarii,101)
				where Marca=@marca and Cod_inf='SCDATAINCET' and Procent=@nrcrt
		else 
			delete from extinfop where Marca=@marca and Cod_inf='SCDATAINCET' and Procent=@nrcrt
	end

	--refresh pozitii in cazul in care meniu este 'S'-> tab de tip pozdoc
	if @tipAntet in ('','S')
	begin
		declare @docXMLSusp xml
		set @docXMLSusp='<row marca="'+rtrim(@marca)+ '" tip="'+(case when @tipAntet='' then 'S' else @tipAntet end)+'"/>'
		exec wIaSuspendare @sesiune=@sesiune, @parXML=@docXMLSusp
	end

end try

begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj,11,1)
end catch
