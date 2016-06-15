create procedure  [dbo].[wScriuIndicatoriBugetari] @sesiune varchar(50), @parXML xml  
as
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20),@denumire varchar(80),@descr varchar(200),
	        @grupa varchar(13),@alfa1 varchar(20),@alfa2 varchar(20),@val1 float,@val2 float,@data_operarii datetime,
	        @ora_operarii varchar(6),@grup bit,@update int
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','int'),0),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(80)'),''),
         @grup = isnull(@parXML.value('(/row/@grup)[1]','bit'),0),
         @descr =isnull( @parXML.value('(/row/@descriere)[1]','varchar(200)'),''),
         @grupa = isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(13)'),''),
         @indbug_cu_puncte=isnull(@parXML.value('(/row/@indbug_cu_puncte)[1]','varchar(30)'),''),
         @o_indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),'')
         
     --select isnull(@grupa,'')    	 
	/* if @capitol<>'' and @indbug_cu_puncte='' and @update=
	 begin 
	 set @capitol=replace(@capitol,'.','') 
	 set @indbug_cu_puncte=isnull(rtrim(ltrim(@capitol)),'  ')+'.'+isnull(rtrim(ltrim(@subcapitol)),'  ')+'.'+
	                       isnull(rtrim(ltrim(@paragraf)),'  ')+'.'+isnull(rtrim(ltrim(@titlu)),'  ')+'.'+
	                       isnull(rtrim(ltrim(@articol)),'  ')+'.'+isnull(rtrim(ltrim(@aliniat)),'  ')+'.'+
	                       isnull(rtrim(ltrim(@rand)),'  ')
     set @indbug=rtrim(ltrim(@capitol))+rtrim(ltrim(@subcapitol))+rtrim(ltrim(@paragraf))+rtrim(ltrim(@titlu))+
                 rtrim(ltrim(@articol))+rtrim(ltrim(@aliniat))+rtrim(ltrim(@rand))
     end
     */
    set @indbug=replace(@indbug_cu_puncte,'.','')   
    --select @indbug 
		
	if exists (select 1 from sys.objects where name='wScriuIndicatoriBugetariSP' and type='P')  
		exec wScriuIndicatoriBugetariSP @sesiune, @parXML
	else  
		begin
			exec wValidareIndicatoriBugetari  @parXML 
				
			if @update=1  
				update indbug set indbug=@indbug,denumire=@denumire,grup=@grup,descr=@descr,grupa=@grupa,alfa1='',alfa2='',val1=0,val2=0,utilizator=@utilizator,
							  data_operarii=convert(datetime, convert(char(10), getdate(), 101), 101),
							  ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 
				where indbug = @o_indbug
			 
			else 
				insert into indbug(indbug,denumire,grup,descr,grupa,alfa1,alfa2,val1,val2,utilizator,data_operarii,ora_operarii) 
						 select @indbug,@denumire,@grup,@descr,@grupa,'','',0,0,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),
						 RTrim(replace(convert(char(8), getdate(), 108), ':', '')) 				
		end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
