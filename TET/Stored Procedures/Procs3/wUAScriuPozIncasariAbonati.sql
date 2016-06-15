/****** Object:  StoredProcedure [dbo].[wUAScriuPozIncasariAbonati]    Script Date: 01/05/2011 23:58:06 ******/
--***
create PROCEDURE  [dbo].[wUAScriuPozIncasariAbonati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
	set transaction isolation level READ UNCOMMITTED
	
begin try	
	Declare  @abonat varchar(13),@data_inc datetime,@doc varchar(10),@new_suma float,@new_id_factura int,@update bit,@subtip varchar(2),
	         @utilizator varchar(13),@mesajeroare varchar(200),@nr_fact_avans varchar(13),@id_fact_avans int,@o_new_suma float,
	         @tip_inc varchar(2),@lm varchar(13),@cHostid varchar(10),@i int,@cTextSelect varchar(max),@nrtemp int ,@contract_avans int,
	         @userAsiS varchar(10)

	select 
		@doc=ISNULL(@parXML.value('(/row/@document)[1]', 'varchar(10)'),'')  ,
		@abonat = isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),''),		
		@data_inc=ISNULL(@parXML.value('(/row/@data_inc)[1]', 'datetime'), '01-01-1901'),
		@tip_inc = isnull(@parXML.value('(/row/@tip_inc)[1]','varchar(2)'),'0'),		
		
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
		@new_id_factura = isnull(@parXML.value('(/row/row/@id_factura)[1]','int'),0),
		@new_suma=ISNULL(@parXML.value('(/row/row/@suma)[1]', 'float'), 0),	
		@o_new_suma=ISNULL(@parXML.value('(/row/row/@o_suma)[1]','float'), 0),
		@contract_avans = isnull(@parXML.value('(/row/@contrat_avans)[1]','int'),0)	
		
		
	if not exists (select abonat from Abonati where abonat=@abonat)
			begin
				set @mesajeroare='Abonatul introdus nu exista in baza de date!!!'
				raiserror(@mesajeroare,11,1)
			end		
			
	
	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lm=(select Loc_de_munca from abonati where abonat=@abonat )
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	if @new_id_factura=0
		begin
			set @mesajeroare='Factura necompletata'
			raiserror(@mesajeroare,11,1)
		end	
		
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	
	if not exists (select id from Tipuri_de_incasare where id=@tip_inc)
			begin
				set @mesajeroare='Tipul de incasare introdus nu exista in baza de date!!!'
				raiserror(@mesajeroare,11,1)
			end				
	
	if  @data_inc='01-01-1901' 
		set @data_inc=CONVERT(char(10),getdate(),101)
	
	if @new_suma=0 and @subtip='IF'
		set  @new_suma=(select sold from FactAbon where id_factura=@new_id_factura and abonat=@abonat) 
	else
		begin
			declare @new_suma1 float
			set  @new_suma1=(select sold from FactAbon where id_factura=@new_id_factura and abonat=@abonat)
			if @new_suma1>@new_suma
			begin
				set @mesajeroare='Suma introdusa nu poate sa fie mai mare ca soldul facturii!!!'
				raiserror(@mesajeroare,11,1)
			end	
		end
	if @new_suma<=0
			begin
				set @mesajeroare='Suma introdusa trebuie sa fie mai mare de 0!!!'
				raiserror(@mesajeroare,11,1)
			end	
		
	if 	@subtip='IF' and @update=0
	    begin
	    	set @lm=(select isnull(loc_de_munca,'') from FactAbon where id_factura=@new_id_factura  )
			exec UAScriuIncasare 'IF',@tip_inc,@doc output,@data_inc,@abonat,@lm,@new_id_factura,
								 @new_suma,0,0,@utilizator,0,@utilizator,0,''
		end        
		      
	if 	@subtip='IA' and @update=0
			begin
				exec UAScriuAvans @abonat,@new_suma,@data_inc,@contract_avans ,@utilizator,@utilizator,'',@tip_inc,'AV',@doc output,@nr_fact_avans output,@id_fact_avans output,0
	        end
	
	if 	@subtip='MI' and @update=1
		begin
			if (select tip from IncasariFactAbon where Abonat=@abonat and Document=@doc and id_factura=@new_id_factura)='IA'
				begin
				update IncasariFactAbon set Suma=@new_suma
						where Abonat=@abonat and Document=@doc and id_factura=@new_id_factura
				update PozitiiFactAbon set Tarif=@new_suma
						where id_factura=@new_id_factura
				end
			else
			if (select ISNULL(sold ,0)+@o_new_suma from FactAbon where id_factura=@new_id_factura)<@new_suma
				begin
				set @mesajeroare='Suma introdusa este mai mare decat soldul facturii!!!'
				raiserror(@mesajeroare,11,1)
				end
			update IncasariFactAbon set Suma=@new_suma
					where Abonat=@abonat and Document=@doc and id_factura=@new_id_factura		
		end
	
		declare @docXML1 xml
	set @docXML1='<row document="'+rtrim(@doc)+'"/>'
	exec wUAIaPozIncasariAbonati @sesiune=@sesiune, @parXML=@docXML1

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch   
end
--select * from incasarifactabon 
--select * from uafactabon
