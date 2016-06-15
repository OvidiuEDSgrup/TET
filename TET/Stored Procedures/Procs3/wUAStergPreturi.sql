--***
/****** Object:  StoredProcedure [dbo].[wUAStergPreturi]    Script Date: 01/05/2011 23:51:25 ******/

Create PROCEDURE  [dbo].[wUAStergPreturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @cod varchar(20),@categorie int,@datainferioara datetime       
        
     select
         @cod = @parXML.value('(/row/@cod)[1]','varchar(20)'),      
		 @categorie = @parXML.value('(/row/row/@categorie)[1]','int'),
		 @datainferioara = @parXML.value('(/row/row/@datainferioara)[1]','datetime')


declare @mesajeroare varchar(500)
set @mesajeroare=''

if @mesajeroare=''
	begin
	delete from uapreturi where cod=@cod and Categorie=@categorie and Data_inferioara=@datainferioara
	update UAPreturi set Data_superioara ='2099-01-01' where Data_superioara=( select MAX(Data_superioara) from UAPreturi where cod=@cod and Categorie=@categorie)
		and cod=@cod and Categorie=@categorie
	end
else 
	raiserror(@mesajeroare, 11, 1)
