CREATE procedure [dbo].[wOPFinalizare] @sesiune varchar(50), @parXML XML  
as
	declare @datainchiderii datetime, @coddeviz varchar(20), @bundefacturat int
	
	set @datainchiderii = @parXML.value('(/parametri/@datafinalizare)[1]', 'datetime')
	set @coddeviz = isnull(@parXML.value('(/parametri/@coddeviz)[1]','varchar(100)'),'')
	set @bundefacturat = ISNULL(@parXML.value('(/parametri/@bundefacturat)[1]', 'int'), 0)
	
	begin
			
		if @datainchiderii is null 
		begin
			raiserror('Sunt campuri necompletate!',11,1)
			return -1				
		end
            if @bundefacturat=1 
         	    update devauto set Data_inchiderii=@datainchiderii, Stare='2'
			where Cod_deviz=@coddeviz			   
			
		print @datainchiderii
			
	end
