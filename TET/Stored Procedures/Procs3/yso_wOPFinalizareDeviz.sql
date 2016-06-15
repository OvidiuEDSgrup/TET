
--***
CREATE procedure [dbo].[yso_wOPFinalizareDeviz] @sesiune varchar(50), @parXML XML  
as
declare @nrdeviz varchar(8)--, @bundefacturat int, @datainchiderii datetime
	
set @nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]','varchar(8)'),'')
/*set @datainchiderii = @parXML.value('(/parametri/@datafinalizare)[1]', 'datetime')
set @bundefacturat = ISNULL(@parXML.value('(/parametri/@bundefacturat)[1]', 'int'), 0)
*/	
begin try
	
	exec wOPGenerareTransferPiese @sesiune=@sesiune, @parXML=@parXML

	exec wOPFinalizareManopera @sesiune=@sesiune, @parXML=@parXML

	if @nrdeviz=''
	begin
		raiserror('Alegeti devizul!',11,1)
		return -1				
	end
        
	if exists (select 1 from devauto where Cod_deviz=@nrdeviz and Stare<'2' and Tip<>'B')
	begin
		raiserror('Devizul nu este finalizat!',11,1)
		return -1				
	end
        
	update devauto set Tip='B' --Data_inchiderii=@datainchiderii, Stare='2'
		where Cod_deviz=@nrdeviz
			
	UPDATE devauto set Stare=isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz=@nrdeviz 
		and tip='D'),Stare) 
		WHERE Cod_deviz=@nrdeviz
end try

begin catch 
	declare @eroare varchar(200) 
	set @eroare='wOPFinalizareDeviz (linia '+convert(varchar(20),ERROR_LINE())+')'+char(10)+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch

