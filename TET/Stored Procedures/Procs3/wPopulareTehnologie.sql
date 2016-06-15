
CREATE procedure wPopulareTehnologie @sesiune varchar(50), @parXML XML      
as    
 declare @id int    
 set @id=ISNULL(@parXML.value('(/row/@id)[1]', 'int'), '')    
    
 select     
 @id as 'Id_tehn'    
 for xml raw,root('Date')
 
 
 