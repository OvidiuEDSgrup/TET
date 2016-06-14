CREATE procedure [dbo].[yso_wScriuPreturiNomenclator] @sesiune varchar(50), @parXML xml  
as  
  
Declare @update bit, @cod varchar(20),@data datetime,@pret_cu_amanuntul decimal(12,3),@pvanzare decimal(12,3),@catpret varchar(20)  
 ,@tippret varchar(1),@utilizator varchar(50),@cota_tva decimal(12,2)  
  
Set @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)  
Set @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))  
Set @catpret= @parXML.value('(/row/row/@catpret)[1]','varchar(20)')  
Set @tippret = @parXML.value('(/row/row/@tippret)[1]','varchar(1)')  
Set @data= @parXML.value('(/row/row/@data_inferioara)[1]','datetime')  
Set @pret_cu_amanuntul= isnull(@parXML.value('(/row/row/@pret_cu_amanuntul)[1]','decimal(12,3)'),0)  
set @cota_tva=isnull((select top 1 Cota_TVA from nomencl where cod=@cod),24)  
set @pvanzare=isnull(@parXML.value('(/row/row/@pret_vanzare)[1]','decimal(12,3)'),round(@pret_cu_amanuntul/(100+@cota_tva)*100,3))  
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null  
 return  
  
--se calculeaza pretul de vanzare prin extragerea tva-ului din pretul cu amanuntul  
--declare @pvanzare decimal(12,3)  
--set @pvanzare=round(@pret_cu_amanuntul/(100+@cota_tva)*100,3)  
  
  
begin try  
declare @tip varchar(1)  
  
 --if @update=1  --se va sterge linia cu pretul respectiv deoarece se poate schimba data, adica cheia  
 --begin    
  declare @o_cod varchar(20),@o_data datetime,@o_categpret varchar(10),@o_tippret varchar(10)  
  Set @o_cod= @parXML.value('(/row/row/@o_cod)[1]','varchar(20)')  
  Set @o_data= @parXML.value('(/row/row/@o_data_inferioara)[1]','datetime')  
  Set @o_categpret= @parXML.value('(/row/row/@o_categorie)[1]','varchar(10)')  
  Set @o_tippret= @parXML.value('(/row/row/@o_tippret)[1]','varchar(10)')  
    
  delete from preturi where Cod_produs= @o_cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret  
 --end    
  
 --se cauta ultimul pret pana la mine si se pune update cu o zi inainte  
 declare @lastdate datetime  
 set @lastdate=(select top 1 data_superioara from preturi where  
 Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara<@data  
 order by Data_superioara desc)  
 print @lastdate  
 /*if @lastdate is not null  
 begin  
  update preturi set Data_superioara=DATEADD(DAY,-1,@data)  
  where Cod_produs= @cod and preturi.Data_superioara=@lastdate and preturi.UM=@catpret and preturi.Tip_pret=@tippret  
 end*/  
 --se cauta daca exista pret dupa data ceruta si se pune data superioara data inferioara a pretului de dupa -1 zi  
 set @lastdate=(select top 1 data_inferioara from preturi where  
 Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara>@data  
 order by Data_superioara desc)  
 declare @datasup datetime  
 if @lastdate is not null  
  set @datasup=DATEADD(DAY,-1,@lastdate)  
 else  
  set @datasup='01/01/2999'  
  
 insert into preturi (Cod_produs,UM,Tip_pret,Data_inferioara,Ora_inferioara,Data_superioara,Ora_superioara,Pret_vanzare,Pret_cu_amanuntul,Utilizator,Data_operarii,Ora_operarii)  
 values (@cod,@catpret,@tippret,@data,'',@datasup,'',@pvanzare,@pret_cu_amanuntul,@utilizator,GETDATE(),'')  
end try  
  
begin catch  
 declare @mesaj varchar(254)  
 set @mesaj = ERROR_MESSAGE()   
 --set @mesaj = RTRIM(@mesaj)+': '+isnull(@cod,'')+','+isnull(@catpret,'')+','+isnull(@tippret,'')  
 -- +','+convert(varchar,isnull(@data,''))+','+CONVERT(varchar,isnull(@update,''))  
 raiserror(@mesaj, 11, 1)   
end catch  