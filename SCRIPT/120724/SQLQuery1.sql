--***  
create procedure wIaSoldTert @sesiune varchar(50), @parXML xml output  
as   
begin try   
 if exists (select 1 from sysobjects where type='P' and name='wIaSoldTertSP')  
 begin  
  exec wIaSoldTertSP @sesiune=@sesiune, @parXML=@parXML output  
  return 0  
 end  
 declare @mesajeroare varchar(500), @soldmaxim float, @tert varchar(50), @subunitate varchar(200),  
   @totalIncasari float, @sold float, @blocSold bit, @blocScad bit, @zileScadBlocate int,  
   @zileScadDepasite char(1)  
  
 exec luare_date_par 'GE', 'SUBPRO', 0,0, @subunitate output  
 exec luare_date_par 'GE', 'BLOCSOLD', @blocSold output, 0,''  
 exec luare_date_par 'GE', 'BLOCSCAD', @blocScad output, @zileScadBlocate output,''  
   
 if @blocScad=0 and @blocSold=0  
 begin  
  set @parXML=null  
  return  
 end  
   
 select @tert=ISNULL(@parXML.value('(/row/@tert)[1]','varchar(100)'), '')  
   
 select @soldmaxim=0, @sold=0, @zileScadDepasite='0'  
   
 select @sold=@sold + f.sold,   
  @zileScadDepasite = (case when DATEADD(DAY, @zileScadBlocate, f.Data_scadentei)<GETDATE()   
         then '1' else '0' end)  
 from facturi f  
 where f.subunitate=@subunitate and f.tip=0x46 and f.tert=@Tert and sold>0.001  
   
 if @blocSold=1  
 begin   
  select @soldmaxim= t.Sold_maxim_ca_beneficiar  
   from terti t where t.Tert=@tert and t.Subunitate=@subunitate  
  if @soldmaxim=0  
   set @soldmaxim=999999999.00 -- Ghita, 28.06.2012: daca nu se completeaza se considera neblocat  
    
  if @parXML.value('(/row/@sold)[1]','varchar(50)') is null  
   set @parXML.modify ('insert attribute sold {sql:variable("@sold")} into (/row)[1]')  
  else  
   set @parXML.modify('replace value of (/row/@sold)[1] with sql:variable("@sold")')  
    
  if @parXML.value('(/row/@soldmaxim)[1]','varchar(50)') is null  
   set @parXML.modify ('insert attribute soldmaxim {sql:variable("@soldmaxim")} into (/row)[1]')  
  else  
   set @parXML.modify('replace value of (/row/@soldmaxim)[1] with sql:variable("@soldmaxim")')  
 end  
   
 if @blocScad=1 and @zileScadDepasite='1'  
  if @parXML.value('(/row/@zilescadentadepasite)[1]','varchar(50)') is null  
   set @parXML.modify ('insert attribute zilescadentadepasite {sql:variable("@zileScadDepasite")} into (/row)[1]')  
  else  
   set @parXML.modify('replace value of (/row/@zilescadentadepasite)[1] with sql:variable("@zileScadDepasite")')  
   
end try  
begin catch  
 set @mesajeroare=ERROR_MESSAGE()+'(wIaSoldTert)'  
 raiserror(@mesajeroare,11,1)  
end catch  
  