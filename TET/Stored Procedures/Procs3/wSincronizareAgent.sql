create procedure wSincronizareAgent @sesiune varchar(50), @parXML xml      
as      
 declare @comenzi xml, @facturi xml , @sume xml, @rComenzi xml , @rFacturi xml, @rSume xml,@utilizator varchar(100) , @raspuns xml,
		 @date XML    
       
 --Iau utilizator      
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output      
 
 select top 1 @date=date from logSincronizare where utilizator=@utilizator order by id desc
 
 select @comenzi=@date.query('(/Date/Comenzi[1])')      
 select @facturi=@date.query('(/Date/Facturi[1])')      
 select @sume=@date.query('(/Date/Incasari[1])')      
    
 
 if @comenzi.value('count (/Comenzi/row)','INT') >0      
  begin      
    exec wSincronComenziLivrare @sesiune=@sesiune, @parXML= @comenzi          
 end       
     
 if @facturi.value('count (/Facturi/row)','INT') >0      
 begin      
  set @facturi.modify('insert attribute eIncasare {"0"} into (/Facturi)[1]')      
  exec wSincronFacturiSiSume @sesiune=@sesiune, @parXML= @facturi      
     
  end       
     
 if @sume.value('count (/Incasari/row)','INT') >0      
 begin    
  set @sume.modify('insert attribute eIncasare {"1"} into (/Incasari)[1]')      
  exec wSincronFacturiSiSume @sesiune=@sesiune, @parXML= @sume      
end    
