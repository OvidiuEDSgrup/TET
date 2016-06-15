--***
--***    
CREATE procedure wOPCorectareIntegritateStocuri(@sesiune varchar(50), @parXML xml)       
as         
-- apelare procedura specifica daca aceasta exista.    
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPCorectareIntegritateStocuriSP')    
begin     
 declare @returnValue int -- variabila salveaza return value de la procedura specifica    
 exec @returnValue = wOPCorectareIntegritateStocuriSP @sesiune, @parXML output    
 return @returnValue    
end      
    
declare @utilizator varchar(10),@mesaj varchar(200)    
              
begin try      
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output     
 declare @tip_necorelatii varchar(2) ,@data_jos datetime,@data_sus datetime,@filtrucod varchar(20),@filtrugestiune varchar(13),@input xml,    
   @necorelatiicont int, @necorelatiipret_intrare int,@necorelatiipret_amanunt int, @refacereStocuri int, @liniaCurenta int    
 select @tip_necorelatii=isnull(@parXML.value('(/parametri/@tip)[1]','char(2)'),''),    
   @data_jos = isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'1901-01-01'),    
   @data_sus = isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'2099-01-01'),    
   @filtrucod = ISNULL(@parXML.value('(/parametri/@filtrucod)[1]', 'varchar(20)'), ''),    
   @filtrugestiune = ISNULL(@parXML.value('(/parametri/@filtrugestiune)[1]', 'varchar(13)'), ''),    
   @liniaCurenta = ISNULL(@parXML.value('(/parametri/@liniaCurenta)[1]', 'int'), 0)    
   
  declare @numar varchar(20), @tipdoc varchar(2), @data datetime, @cod varchar(20), @codi varchar(13), @new_codi varchar(13), @gestiune varchar(30),    
    @fstocuri int    
  select @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]','varchar(30)'),''),    
    @tipdoc = ISNULL(@parXML.value('(/parametri/@tipdoc)[1]','varchar(2)'),''),    
    @gestiune = ISNULL(@parXML.value('(/parametri/@gestiune)[1]','varchar(30)'),''),    
    @data = ISNULL(@parXML.value('(/parametri/@data)[1]','datetime'),''),    
    @cod = ISNULL(@parXML.value('(/parametri/@cod)[1]','varchar(20)'),''),    
    @codi = ISNULL(@parXML.value('(/parametri/@codi)[1]','varchar(13)'),''),    
    @new_codi = ISNULL(@parXML.value('(/parametri/@new_codi)[1]','varchar(13)'),''),    
    @fstocuri = ISNULL(@parXML.value('(/parametri/@fstocuri)[1]','int'),0)    
   
 set @input=    
  (select @filtrucod as '@filtrucod', @filtrugestiune as '@filtrugestiune', @liniaCurenta as '@liniaCurenta',     
    @numar as '@numar', @tipdoc as '@tipdoc', @gestiune as '@gestiune', @data as '@data', @cod as '@cod',    
    @codi as '@codi', @new_codi as '@new_codi', @fstocuri as '@fstocuri'    
  for xml Path,type)    
     
 set @necorelatiipret_intrare=(case when @tip_necorelatii='PD' then 1 else 0 end)     
 set @necorelatiipret_amanunt=(case when @tip_necorelatii='PA' then 1 else 0 end)     
 set @necorelatiicont=(case when @tip_necorelatii='CD' then 1 else 0 end)          
     
 exec VerificareIntegritateStocuri @dataJ=@data_jos,@dataS=@data_sus,@cuModificare=1,@necorelatiipret_intrare=@necorelatiipret_intrare,    
  @necorelatiipret_amanunt=@necorelatiipret_amanunt,@necorelatiicont=@necorelatiicont,@parXML=@input    
      
 select 'Operatia de corectare necorelatii cont stoc <-> documente a fost finalizata.' as textMesaj, 'Finalizare operatie' as titluMesaj       
 for xml raw, root('Mesaje')      
end try      
begin catch      
 set @mesaj = '(wOPCorectareIntegritateStocuri)'+ERROR_MESSAGE()      
end catch      
 if LEN(@mesaj)>0    
 raiserror(@mesaj, 11, 1)
