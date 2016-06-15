--***  
create procedure wOPCorectareIntegritateStocuri_p(@sesiune varchar(50), @parXML xml)     
as   

  
declare @numar varchar(20), @tipdoc varchar(2), @data datetime, @cod varchar(20), @codi varchar(13), @new_codi varchar(13), @gestiune varchar(30)  
 select @numar = ISNULL(@parXML.value('(/row/@numar)[1]','varchar(30)'),''),  
   @tipdoc = ISNULL(@parXML.value('(/row/@tip_doc)[1]','varchar(2)'),''),  
   @gestiune = ISNULL(@parXML.value('(/row/@gestiune)[1]','varchar(30)'),''),  
   @data = ISNULL(@parXML.value('(/row/@data)[1]','datetime'),''),  
   @cod = ISNULL(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),  
   @codi = ISNULL(@parXML.value('(/row/@cod_intrare)[1]','varchar(13)'),'')  

select 'Acest gen de operatie se ruleaza in afara orelor de program deoarece se lucreaza cu triggere dezactivate! Atentie daca operatia dureaza prea mult iar ASiSRia returneaza mesaj de time-out posibil ca triggerele sa fi ramas dezactivate!' as textMesaj ,'Atentie!' as titluMesaj for xml raw, root('Mesaje')
  
select @numar numar, @tipdoc tipdoc, @gestiune gestiune, convert(varchar(20),@data,101) data, rtrim(@cod) cod, @codi codi  
for xml raw  
  
  
