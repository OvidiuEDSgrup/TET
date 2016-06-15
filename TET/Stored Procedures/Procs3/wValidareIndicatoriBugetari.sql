create proc  [dbo].[wValidareIndicatoriBugetari] (@parXML xml)
as begin
	declare @mesajeroare varchar(600),@indbug varchar (20),@capitol varchar(5),@subcapitol varchar(5),@paragraf varchar(5),@titlu varchar(5),
	        @articol varchar(5),@aliniat varchar(5),@rand varchar(5),@denumire varchar(30),@grupa varchar(10),@update bit,@indbug_cu_puncte varchar (30),
	        @o_indbug varchar (20), @utilizator varchar(100)
	Select
	     @denumire=isnull( @parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
         @grupa=isnull( @parXML.value('(/row/@grupa)[1]','varchar(30)'),''),
         @indbug_cu_puncte=isnull(@parXML.value('(/row/@indbug_cu_puncte)[1]','varchar(30)'),''),
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),	
         @o_indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),'')
    select
	     @indbug=replace(@indbug_cu_puncte,'.',''),
         @capitol=substring(@indbug,1,4),
         @subcapitol=substring(@indbug,5,2),
         @paragraf=substring(@indbug,7,2),
         @titlu=substring(@indbug,9,2),
         @articol=substring(@indbug,11,2),
         @aliniat=substring(@indbug,13,2),
         @rand=substring(@indbug,15,2)    
	
	set @utilizator=dbo.fIaUtilizator(null)
	/* if @capitol<>'' and @indbug_cu_puncte=''
	 begin 	
	 set @capitol=replace(@capitol,'.','')
	 set @indbug=rtrim(ltrim(@capitol))+rtrim(ltrim(@subcapitol))+rtrim(ltrim(@paragraf))+rtrim(ltrim(@titlu))+
                 rtrim(ltrim(@articol))+rtrim(ltrim(@aliniat))+rtrim(ltrim(@rand))	
	 end*/

	--select @capitol,@subcapitol,@paragraf,@titlu,@articol,@rand,@indbug
	
	if @update=1 and exists (select 1 from pozncon where substring(comanda,21,20)=@indbug and tip='AO')
	begin
		set @mesajeroare='Un indicator care are alocat plan bugetar si/sau angajari nu poate fi modificat'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if @indbug = ''
	begin
		set @mesajeroare='Introduceti indicatorul bugetar!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
		
	if isnumeric(replace(@indbug,' ',''))=0
	begin
		set @mesajeroare='Toate campurile care formeaza indicatorul bugetar trebuie sa fie formate exclusiv din cifre!'
		raiserror(@mesajeroare,11,1)
		return -1
	end		
	
	if len(@indbug)<4
	begin
		set @mesajeroare='Lungimea minima a unui indicator bugetar trebuie sa fie 4!'
		raiserror(@mesajeroare,11,1)
		return -1
	end	

	if exists (select indbug from indbug where indbug=@indbug )and @update=0
	begin
		set @mesajeroare='Indicatorul bugetar exista deja!!'
		raiserror(@mesajeroare,11,1)
		return -1
	end	
	
	if not exists (select indbug from indbug where indbug=substring(@indbug,1,len(@indbug)-2)) and len(@indbug)>4
	begin
		set @mesajeroare='Nu exista idicator de nivel superior!'
		raiserror(@mesajeroare,11,1)
		return -1
	end		
	
	if not exists (select indbug from indbug where indbug=substring(@indbug,1,len(@indbug)-2) and indbug<>@o_indbug) and len(@indbug)>4 and @update=1
	begin
	   set @mesajeroare='Nu exista idicator de nivel superior!'
		raiserror(@mesajeroare,11,1)
		return -1
	end		
	
	if len(@indbug)>16
	begin
		set @mesajeroare='Acest indicator are o lungime mai mare decat lungimea maxima permisa de lege!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if @denumire=''
	begin
	    set @mesajeroare='Denumirea indicatorului bugetar nu a fost completata!'
		raiserror(@mesajeroare,11,1)
		return -1
	end	
	
	if (not exists (select grupa from indbuggr where grupa=@grupa ))and  @grupa<>''
		begin
		set @mesajeroare='Grupa inexistenta!!'
		raiserror(@mesajeroare,11,1)
		return -1
		end	  
			
	return 0
end
