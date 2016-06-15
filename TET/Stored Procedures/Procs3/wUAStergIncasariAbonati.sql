create procedure [dbo].[wUAStergIncasariAbonati]  @sesiune varchar(50), @parXML xml  
as  
begin try  
DECLARE @id_fact int,@nr_pozitie int ,@doc varchar(10),@subtip varchar(2) ,@tip varchar(2),@data datetime,@abonat varchar(13),
	@mesaj varchar(100)       
   select  
   @doc = isnull(@parXML.value('(/row/@document)[1]','varchar(10)'),''),          
   @abonat = rtrim(isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),'')),  
   @data = isnull(@parXML.value('(/row/@data)[1]','datetime'),''),  
   @tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')  
  
declare @mesajeroare varchar(100)  
begin  
  
 set @id_fact=isnull((select id_Factura from incasarifactabon where document=@doc and abonat=@abonat and data=@data and tip='IA'),'000')  
 if @id_fact in (select id_Factura from incasarifactabon where tip='CP')
 begin  
    set @mesaj='Incasarea nu se poate anula! Exista deja compesare pe aceasta incasare in avans !'  
    raiserror(@mesaj,11,1)  
 end  
 
 delete from AntetFactAbon where Id_factura in (select id_Factura from incasarifactabon where document=@doc and abonat=@abonat and data=@data and tip='IA')--Id_factura=@id_fact  
 delete from PozitiiFactAbon where Id_factura in (select id_Factura from incasarifactabon where document=@doc and abonat=@abonat and data=@data and tip='IA')--Id_factura=@id_fact    
 --delete from IncasariFactAbon where Id_factura=@id_fact    
  
 delete from IncasariFactAbon where document=@doc and abonat=@abonat and data=@data  
  
end   
  
end try  
begin catch  
 set @mesajeroare = ERROR_MESSAGE()  
 raiserror(@mesajeroare, 11, 1)   
end catch
