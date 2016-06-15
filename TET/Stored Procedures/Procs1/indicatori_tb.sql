--***
create procedure [dbo].[indicatori_tb]    
 --@Data datetime ,    
@grupul varchar(20) ,  
 @calculat int ,    
 @luna int,    
 @anul int ,    
 @BDr varchar(20) 
  
AS    
    
--set @grupul = ''    
--set @calculat = 0    
--set @luna = 11    
--set @anul = 2007 
--set @BDr = 'ReportServer'   
--as    
--declare @Data datetime 
--set @Data = getdate()    
declare @cAdrSrv char(1000)    
declare @cInd varchar(20), @DataJ datetime, @DataS datetime    
set @DataJ =  convert(datetime, convert(char(2),@luna) + '/01/'+ convert(char(4), @anul))    
set @DataS = dbo.eom(@DataJ) 
set @cAdrSrv=(select val_alfanumerica from par where tip_parametru='GE' and parametru='REPSRVADR') 
if right(rtrim(@cAdrSrv),1)<>'/'    
set @cAdrSrv=rtrim(@cAdrSrv)   +'/'    
set @cAdrSrv=rtrim(@cAdrSrv)+'ReportServer/Pages/ReportViewer.aspx?/'   
  
--select @cAdrSrv   
    
create table #tmpraptb    
(cInd varchar(20),    
denumire varchar(150),    
valoare float default 0,    
expandare varchar(2) default '',    
cale_raport varchar(1000) default '' ,  
culoare int default 0 ,    
semnificatie varchar(30) default ''   
)    
    
declare @culoare int , @semnificatie varchar(30)  
--select * from indicatori where ordine_in_raport <> 0    
if (@calculat = 1)    
  begin    
   declare @cCodInd varchar(20), @denumire varchar(150), @valoare float, @expd varchar(2), @cale_ind varchar(200)  
   declare indicator cursor dynamic  
   for select distinct cod_indicator, denumire_indicator  
   from indicatori  
   where ordine_in_raport <> 0 and (unitate_de_masura = @grupul or @grupul = '')  
   open indicator  
   fetch next from indicator into @cCodInd, @denumire  
   while @@fetch_status = 0   
   begin   
    exec calculind @cCodInd, @DataJ, @DataS  
    if (@cCodInd ='SITPERSONAL' or @cCodInd = 'NRPERSC')    
  begin 
--   set @valoare = (select valoare from expval where cod_indicator = @cCodInd and 
--   data = dateadd(d,-datepart(d,getdate()),convert(datetime,convert(char(10),getdate(),104),104))) 
   set @valoare = (select valoare from expval where cod_indicator = @cCodInd and 
  data between  @DataJ and @DataS )  
  end    
    else   
 begin    
   set @valoare = (select sum(valoare) from expval where cod_indicator = @cCodInd and data between   
   @DataJ and @DataS)  
    end    
    set @expd = (select tip_detaliere from detalind where cod_indicator = @cCodInd and tip_detaliere = 'R')  
    set @cale_ind = (select expresie from detalind where cod_indicator = @cCodInd and tip_detaliere = 'R')   
    set @culoare = (select top 1 culoare from semnific where indicator = @cCodInd and @valoare between val_min and val_max)  
 set @semnificatie = (select top 1 semnificatie from semnific where indicator = @cCodInd and @valoare between val_min and val_max)  
    
    declare  @output varchar(1000)  
   --print @cale_ind  
 set @cale_ind=RTrim(@cale_ind)  
    exec returneaza_pardata @DataJ,@DataS,@cale_ind, @BDr, @output output  
 
    --print @output  
    
    insert into #tmpraptb  
    select @cCodInd,  
   @denumire,  
   @valoare,  
   @expd,  
   rtrim(@cAdrSrv)+replace(@cale_ind,'<F>', ''), --+ @output,  
   @culoare,    
   @semnificatie   
   
   
   fetch next from indicator into @cCodInd, @denumire   end  
   close indicator  
   deallocate indicator  
 
   select * from #tmpraptb   
  end    
else    
  begin    
   declare indicator cursor dynamic  
   for select distinct cod_indicator, denumire_indicator  
   from indicatori   
   where ordine_in_raport <> 0 and (unitate_de_masura = @grupul or @grupul = '')  
   open indicator  
   fetch next from indicator into @cCodInd, @denumire  
   while @@fetch_status = 0   
   begin   
    --exec calculind @cCodInd, @DataJ, @DataS  
    if (@cCodInd ='SITPERSONAL' or @cCodInd = 'NRPERSC')    
   begin    
--    set @valoare = (select valoare from expval where cod_indicator = @cCodInd and 
--    data = dateadd(d,-datepart(d,getdate()),convert(datetime,convert(char(10),getdate(),104),104))) 
  set @valoare = (select valoare from expval where cod_indicator = @cCodInd and 
    data between  @DataJ and @DataS) --dateadd(d,-datepart(d,getdate()),convert(datetime,convert(char(10),getdate(),104),104)))    
    end    
    else   
 begin    
 set @valoare = (select sum(valoare) from expval where cod_indicator = @cCodInd and data between   
 @DataJ and @DataS)  
    end    
    set @expd = (select tip_detaliere from detalind where cod_indicator = @cCodInd and tip_detaliere = 'R')  
    set @cale_ind = (select expresie from detalind where cod_indicator = @cCodInd and tip_detaliere = 'R')   
  
    set @culoare = (select top 1 culoare from semnific where indicator = @cCodInd and @valoare between val_min and val_max)    
 set @semnificatie = (select top 1 semnificatie from semnific where indicator = @cCodInd and @valoare between val_min and val_max) 
 
    --print @cale_ind    
 set @cale_ind=RTrim(@cale_ind)    
    exec returneaza_pardata @DataJ,@DataS,@cale_ind, @BDr, @output output  
   --print @output  
  
    insert into #tmpraptb  
    select @cCodInd,  
   @denumire,  
   @valoare,   
   @expd,  
   ltrim(rtrim(@cAdrSrv))+replace(rtrim(@cale_ind),'<F>', '')+rtrim(@output) ,  
   @culoare ,    
   @semnificatie    
   
   --select * from #tmpraptb 
   fetch next from indicator into @cCodInd, @denumire  
  end  
   close indicator  
   deallocate indicator  
 
   select * from #tmpraptb   
  
  end   
drop table #tmpraptb
