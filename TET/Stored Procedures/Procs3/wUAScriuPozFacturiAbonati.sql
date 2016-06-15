/****** Object:  StoredProcedure [dbo].[wUAScriuPozFacturiAbonati]    Script Date: 01/05/2011 22:59:01 ******/

--***
create procedure [dbo].[wUAScriuPozFacturiAbonati]  @sesiune varchar(50), @parXML xml
as
declare @iDoc int, @Sub char(9),@mesaj varchar(200),@update int, @id int ,@factura char(8),@tip char(2),@abonat char(13),@id_contract int, 
		@data datetime,@datascadentei datetime,@tip_tva smallint,@perioada_inceput datetime,@perioada_sfarsit datetime,@stare char(1),@valoare float, 
		@sold float,@sold_pen float,@penalizari float,@utilizator varchar(13),@serie varchar(10),@userAsis varchar(10),		
		@nr_pozitie int,@cod char(13),@cantitate float,@tarif float,@loc_de_munca char(8), @comanda char(40)		

begin try	
	select
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id= isnull(@parXML.value('(/row/@id)[1]','int'),0),
		@factura = isnull(@parXML.value('(/row/@factura)[1]','varchar(8)'),''),	
		@abonat = isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),''),	
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@id_contract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),''),
		@serie = isnull(@parXML.value('(/row/@serie)[1]','varchar(10)'),''),			
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01'),
		@datascadentei=ISNULL(@parXML.value('(/row/@datascadentei)[1]', 'datetime'), '1901-01-01'),
		@tip_tva= isnull(@parXML.value('(/row/@tip_TVA)[1]','smallint'),0),
		@perioada_inceput=ISNULL(@parXML.value('(/row/@per_fact_jos)[1]', 'datetime'), '1901-01-01'),
		@perioada_sfarsit=ISNULL(@parXML.value('(/row/@per_fact_sus)[1]', 'datetime'), '1901-01-01'),
		
		@cod=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(13)'), '')  ,
		@nr_pozitie = isnull(@parXML.value('(/row/row/@nr_pozitie)[1]','int'),0),
		@cantitate=ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0),
		@tarif=ISNULL(@parXML.value('(/row/row/@tarif)[1]', 'float'), 0),
		@loc_de_munca=ISNULL(@parXML.value('(/row/row/@lm)[1]', 'varchar(13)'), '')  ,
		@comanda=ISNULL(@parXML.value('(/row/row/@comanda)[1]', 'varchar(40)'),'')  ,
		
		@utilizator=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	--select @tip_tva
	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	
	if (@lista_lm=1 and @loc_de_munca='') or (@lista_lm=1 and not exists (select cod from lm where Cod=@loc_de_munca))
		begin     
			set @mesaj='Intorduceti un loc de munca valid!!'  
			raiserror(@mesaj,11,1)  
		end
	
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@loc_de_munca and utilizator=@utilizator))
		begin     
			set @mesaj='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesaj,11,1)  
		end
	
	
	declare @result int
	set @result=0
	if @id=0 and @update=0
		 exec UAScriuAntetfacturi 'FM',@serie,@id_contract,@data,@datascadentei,@tip_tva,@perioada_inceput,@perioada_sfarsit,@utilizator,
             @loc_de_munca,@id output,@factura output,0

	 exec UAScriuPozitiifacturi @id,@nr_pozitie ,@cod,@cantitate,@tarif,@loc_de_munca,@comanda,@utilizator
    	
	declare @docXML xml
	set @docXML='<row id="'+rtrim(@id)+'" tip="'+@tip+ '" factura="'+rtrim(@factura)+'"/>'
	exec wUAIaPozFacturiAbonati @sesiune=@sesiune, @parXML=@docXML
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
