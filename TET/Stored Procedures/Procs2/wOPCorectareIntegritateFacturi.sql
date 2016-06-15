--***
create procedure wOPCorectareIntegritateFacturi(@sesiune varchar(50), @parXML xml)   
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPCorectareIntegritateFacturiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPCorectareIntegritateFacturiSP @sesiune, @parXML output
	return @returnValue
end  

declare @utilizator varchar(8),@mesaj varchar(200)
          
begin try  
	exec wIaUtilizator @sesiune, @utilizator output 
	declare @tip_necorelatii varchar(2) ,@data_jos datetime,@data_sus datetime
			
	  
	select	@tip_necorelatii=isnull(@parXML.value('(/parametri/@tip)[1]','char(2)'),''),
			@data_jos = isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'1901-01-01'),
			@data_sus = isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'2099-01-01')
	
	
	exec VerificareIntegritateFacturi @dataJ=@data_jos,@dataS=@data_sus,@cuModificare=1
		
	select 'Operatia de corectare necorelatii cont fact<->doc a fost finalizata.' as textMesaj, 'Finalizare operatie' as titluMesaj   
	for xml raw, root('Mesaje')  
end try  
begin catch  
	set @mesaj = '(wOPCorectareIntegritateFacturi)'+ERROR_MESSAGE()  
end catch		
 if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
