/****** Object:  StoredProcedure [dbo].[wUAScriuPozDateLunare]    Script Date: 01/05/2011 22:59:01 ******/
--***
create procedure  [dbo].[wUAScriuPozDateLunare]  @sesiune varchar(50), @parXML xml
as
declare @update bit,@id_contract int, @utilizator varchar(13),@tip varchar(2),@document varchar(13),@datajos datetime,
		@datasus datetime,@saptamana varchar(2),@tura varchar(2),@locatar varchar(13),@cod_serviciu varchar(20),
		@realizat float,@cantitate_de_facturat float,@data datetime	,@mesaj varchar(200),@planificat float,@id int

begin try	
	select
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id_contract= isnull(@parXML.value('(/row/@id_contract)[1]','int'),0),
		@id= isnull(@parXML.value('(/row/row/@id)[1]','int'),0),
		@tip = isnull(@parXML.value('(/row/row/@tip)[1]','varchar(2)'),''),
		@document = isnull(@parXML.value('(/row/row/@document)[1]','varchar(13)'),''),
		@data = isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'1909-01-01'),
		@locatar = isnull(@parXML.value('(/row/row/@locatar)[1]','varchar(13)'),''),
		@cod_serviciu = isnull(@parXML.value('(/row/row/@cod_serviciu)[1]','varchar(20)'),''),
		@realizat= isnull(@parXML.value('(/row/row/@realizat)[1]','float'),0),
		@planificat= isnull(@parXML.value('(/row/row/@planificat)[1]','float'),0),
		@datajos = isnull(@parXML.value('(/row/row/@datajos)[1]','datetime'),'1909-01-01'),
		@datasus = isnull(@parXML.value('(/row/row/@datasus)[1]','datetime'),'2909-01-01'),
		@saptamana = isnull(@parXML.value('(/row/row/@saptamana)[1]','varchar(2)'),''),
		@tura = isnull(@parXML.value('(/row/row/@tura)[1]','varchar(2)'),''),	
		
		@utilizator=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	
	if (select stare from UAcon where Id_contract=@id_contract)=3
		begin
		set @mesaj='Nu se pot adauga cantitati pe un contract reziliat!!'
		raiserror(@mesaj,11,1)
		end
	
	if @realizat< 0 and @planificat<0
		begin
		set @mesaj='Cel putin una dintre cantitati, realizat sau planificat trebuie sa fie mai mare sau egala cu 0!!'
		raiserror(@mesaj,11,1)
		end
	if @tip='CF'
	begin
		set @datajos=@data
		set @datasus=@data
	end
	if @update=0
	begin
	  --select @cod_serviciu
	  exec   UAScriuCant @tip ,@datajos,@datasus,@id_contract,@saptamana,@tura,'',@locatar,@cod_serviciu,@planificat,@realizat,
					 @document,@data,@utilizator,0
	end		
	
	if @update=1
	begin
	 -- select @planificat
	  exec   UAScriuCant @tip ,@datajos,@datasus,@id_contract,@saptamana,@tura,'',@locatar,@cod_serviciu,@planificat,@realizat,
					 @document,@data,@utilizator,@id
	end			 
	         
	declare @docXML xml
	set @docXML='<row id_contract="'+rtrim(@id_contract)+'"/>'
	exec wUAIaPozDateLunare @sesiune=@sesiune, @parXML=@docXML
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
--sp_help uacantitati
