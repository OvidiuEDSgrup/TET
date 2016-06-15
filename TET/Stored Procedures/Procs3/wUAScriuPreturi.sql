/****** Object:  StoredProcedure [dbo].[wUAScriuPreturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuPreturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @cod varchar(20),@o_cod varchar(20),@cotatva float,@categorie int, 
				@datainferioara datetime,@datasuperioara datetime,
				@pretvanzare float,@pretamanunt float,@update bit
				
 begin try       
    select 
         
         @cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
         @o_cod= isnull(@parXML.value('(/row/row/@o_cod)[1]','varchar(20)'),''),
         @cotatva =isnull( @parXML.value('(/row/@cotatva)[1]','float'),''),
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @categorie =isnull(@parXML.value('(/row/row/@categorie)[1]','int'),1),
         @datainferioara=isnull(@parXML.value('(/row/row/@datainferioara)[1]','datetime'),''),
         @datasuperioara=isnull(@parXML.value('(/row/row/@datasuperioara)[1]','datetime'),''),
         @pretvanzare = isnull(@parXML.value('(/row/row/@pretvanzare)[1]','float'),0),
         @pretamanunt = isnull(@parXML.value('(/row/row/@pretamanunt)[1]','float'),0)
         
	
	if exists (select 1 from sys.objects where name='wUAScriuPreturiSP' and type='P')  
	exec wUAScriuPreturiSP @sesiune, @parXML
else  

begin
exec wUAValidarePreturi  @parXML 
 
 
 if @update=1 
   begin

   update uapreturi set categorie=@categorie,Pret_vanzare=@pretvanzare,Pret_cu_amanuntul=round(@pretvanzare+round(@cotatva/100*@pretvanzare,2),2) 
   where cod = @cod and Categorie=@categorie and Data_inferioara=@datainferioara
   end

else 	
begin
	declare @dataupdate datetime
	set @dataupdate=(select MAX(Data_inferioara) from uapreturi where cod=@cod and Categorie=@categorie )
	if @dataupdate<@datainferioara
		begin
			update UApreturi
			set Data_superioara=dateadd(day,-1,@datainferioara) where cod=@cod and Categorie=@categorie  and Data_inferioara=@dataupdate
	    end		 
    
   insert into uapreturi(cod,categorie,data_inferioara,data_superioara,pret_vanzare,pret_cu_amanuntul) 
   select @cod,@categorie,@datainferioara,'01-01-2999',@pretvanzare,round(@pretvanzare+round(@cotatva/100*@pretvanzare,2),2) 				
end
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
