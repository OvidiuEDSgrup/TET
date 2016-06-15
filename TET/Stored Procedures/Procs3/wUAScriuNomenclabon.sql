/****** Object:  StoredProcedure [dbo].wUAScriuNomenclabon]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuNomenclabon] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @cod varchar(20),@o_cod varchar(20),@denumire varchar(50), 
				@um varchar(3),@tarif float,
				@cotatva float,@tipserviciu varchar(2),@contvenituri varchar(13),
				@comanda varchar(13),@lm varchar(13),@update bit
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(50)'),''),
         @um =isnull(@parXML.value('(/row/@um)[1]','varchar(80)'),''),
         @tarif = isnull(@parXML.value('(/row/@tarif)[1]','float'),0),
         @cotatva =isnull( @parXML.value('(/row/@cotatva)[1]','float'),''),
         @tipserviciu = isnull(@parXML.value('(/row/@tipserviciu)[1]', 'varchar(2)'),''),
         @contvenituri=isnull(@parXML.value('(/row/@contvenituri)[1]','varchar(13)'),''),
         @comanda= isnull(@parXML.value('(/row/@comanda)[1]','varchar(13)'),''),
         @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
         @o_cod= isnull(@parXML.value('(/row/@o_cod)[1]','varchar(20)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuNomenclabonSP' and type='P')  
	exec wUAScriuNomenclabonSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	
	if (@lista_lm=1 and @lm='') or (@lista_lm=1 and not exists (select cod from lm where Cod=@lm))
		begin     
			set @mesajeroare='Intorduceti un loc de munca valid!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	if @contvenituri=''
		begin     
			set @mesajeroare='Nu ati completat contul de venituri !!'  
			raiserror(@mesajeroare,11,1)  
		end

 exec wUAValidareNomenclabon  @parXML 
	
 if @update=1
   begin
   update nomenclabon set cod=@cod,denumire=@denumire,um=@um,tarif=@tarif,cota_tva=@cotatva,
	tip_serviciu=@tipserviciu,cont_venituri=@contvenituri,comanda=@comanda,Loc_de_munca=@lm

    where cod = @o_cod
   update UAPreturi set Cod=@cod where cod=@o_cod
   end
else 
   insert into nomenclabon(cod,denumire,um,tarif,cota_tva,tip_serviciu,cont_venituri,comanda,loc_de_munca) 
             select @cod,@denumire,@um,@tarif,@cotatva,@tipserviciu,@contvenituri,@comanda,@lm 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
