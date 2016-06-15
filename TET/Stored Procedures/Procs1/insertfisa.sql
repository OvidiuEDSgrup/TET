--***
create procedure insertfisa @pLm char(20),@pCom char(20),@pNivel int,@pNivelMax int,@pCantPond float,@pArtSup char(20),@pExceptArtSup char(20),@pExcArtNeincl char(20),@pArtInf char(20),@pDetalDOC int,@pSub char(20),@pDinf datetime,@pDsup datetime,@pGrCom 
int,@pComenziNedet char(100),@pArtCalcNedet char(100),@pNrOrd int,@PeConturi int          
as             
declare @nLungime int,@lSLM int          
begin            
if @PeConturi=1    
begin    
 truncate table fisacmdtmp            
    
 select *           
 into #ctt     
 from FisaPeCont where tip='D' and data between @pDinf and @pDsup and comanda=@pCom    
 set @lSLM=(select val_logica from par where tip_parametru='PC' and parametru='StrictLM')          
 if @lSLM=0           
 begin      
  set @nLungime=len(rtrim(@pLm))          
  if @pCom=''      
  begin      
   delete #ctt from #ctt,costsql tt1       
   where #ctt.lm like rtrim(@plm)+'%' and month(#ctt.data)=month(tt1.data) and year(#ctt.data)=year(tt1.data)      
   and #ctt.lm=tt1.lm_inf and #ctt.comanda='' and tt1.lm_sup='' and tt1.comanda_sup='' and tt1.comanda_inf='' and tt1.art_sup='T' and tt1.art_inf='T'  
  end  
 end      
 else          
  set @nLungime=20          
     
 update #ctt set lm=left(lm,@nLungime)    

 
 CREATE TABLE #f1([Numar_de_ordine] int identity,[Nivel] [smallint],[Descriere] [char](100),[Cantitate] [float],[Pret] [float],[Valoare] [float],
	[Tip] [char](1),[Cod] [char](20),[Locm] [char](9),[Comanda_sup] [char](20),[Art_sup] [char](9),[NrOrdP] [int])  
 insert into #f1(Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP)  
 select 0,#ctt.cont+isnull((select denumire_cont from conturi where conturi.subunitate=@pSub and conturi.cont=#ctt.cont),''),1,sum(suma),sum(suma),'C','','','',0,0    
 from #ctt where lm=@pLM  
 group by cont  

 insert into fisacmdtmp select Numar_de_ordine,Nivel,Descriere,Cantitate,Pret,Valoare,Tip,Cod,Locm,Comanda_sup,Art_sup,NrOrdP from #f1
 drop table #f1
 drop table #ctt          
end    
else    
begin    
 if @pNivel=0           
  begin          
   select *           
   into #tt          
   from costsql where data between @pDinf and @pDsup          
   set @lSLM=(select val_logica from par where tip_parametru='PC' and parametru='StrictLM')          
   if @lSLM=0           
    begin      
     set @nLungime=len(rtrim(@pLm))          
 if @pCom=''      
     begin      
      delete #tt from #tt,#tt tt1       
      where #tt.lm_sup like rtrim(@plm)+'%' and month(#tt.data)=month(tt1.data) and year(#tt.data)=year(tt1.data)      
      and #tt.lm_sup=tt1.lm_inf and #tt.comanda_sup='' and tt1.lm_sup='' and tt1.comanda_sup='' and tt1.comanda_inf='' and tt1.art_sup='T' and tt1.art_inf='T'      
     end      
    end      
   else          
    set @nLungime=20          
       
  update #tt set lm_inf=left(lm_inf,@nLungime),lm_sup=left(lm_sup,@nLungime)          
            
  select data,left(lm,@nLungime) as lm,comanda,sum(costuri) as costuri, sum(cantitate) as cantitate,sum(costuri)/(case when sum(cantitate)=0 then 1 else sum(cantitate) end) as pret          
  into #ty          
  from costurisql where data between @pDinf and @pDsup          
  group by data,left(lm,@nLungime),comanda          
 end          
    
 if @pNivel % 2=0            
  execute insertfisa1 @pLm, @pCom, @pNivel, @pNivelMax, @pCantPond, @pArtSup, @pExceptArtSup, @pExcArtNeincl, @pArtInf, @pDetalDOC, @pSub, @pDinf, @pDsup, @pGrCom, @pComenziNedet, @pArtCalcNedet, @pNrOrd          
 else            
  execute insertfisa2 @pLm, @pCom, @pNivel, @pNivelMax, @pCantPond, @pArtSup, @pExceptArtSup, @pExcArtNeincl, @pArtInf, @pDetalDOC, @pSub, @pDinf, @pDsup, @pGrCom, @pComenziNedet, @pArtCalcNedet, @pNrOrd          
            
 if @pNivel=0     
  begin            
   declare @NrOrdP int, @nrOrd int, @nrrand int, @nrrandprec int
	set @nrrand=0	set @nrrandprec=1
   select Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, Comanda_sup, Art_sup, NrOrdP into #fisa from fisacmdtmp            
   truncate table fisacmdtmp            
   while (@nrrand<>@nrrandprec)
   begin            
	set @nrrandprec=@nrrand
    set @NrOrdP = isnull((select max(numar_de_ordine) from fisacmdtmp where numar_de_ordine in (select nrordp from #fisa)),0)            
    set @NrOrd = (select min(numar_de_ordine) from #fisa where NrOrdP=@NrOrdP)            
    insert into fisacmdtmp select * from #fisa where numar_de_ordine=@NrOrd            
    delete from #fisa where numar_de_ordine=@NrOrd
	select @nrrand=count(1) from #fisa
   end            
  drop table #fisa            
  drop table #tt          
  drop table #ty          
  end          
 end      
end
