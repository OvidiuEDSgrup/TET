--***
create procedure wOPFinalizareManopera @sesiune varchar(50), @parXML xml                
as              
declare
	@nrdeviz varchar(8), @data datetime, @docJurnal xml, @stare int
		
set @nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]','varchar(8)'),'')
set @data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901')

begin try
	if @nrdeviz=''
	begin
		raiserror('Alegeti devizul!',11,1)
		return -1				
	end
        
	if @data=''
	begin
		raiserror('Completati data!',11,1)
		return -1				
	end
        
	if not exists (select 1 from devauto where Cod_deviz=@nrdeviz and Tip='')   
	begin
		raiserror('Devizul nu mai este in lucru!',16,1)
		return -1
	end
	
	if not exists (select 1 from pozdevauto where Cod_deviz = @nrdeviz and Tip_resursa = 'M' and Stare_pozitie = '1')
	begin
		raiserror('Nu exista manopera nefinalizata pe acest deviz!', 16, 1)
		return -1
	end

	update pozdevauto set Numar_consum='2', Data_finalizarii=@data
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='M' and Stare_pozitie='1'
	
	update pozdevauto set Stare_pozitie=LEFT(Numar_consum,1)
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='M' and Stare_pozitie>='1'
		and Numar_consum<>''
	
	update pozdevauto set Numar_consum=''
		where cod_deviz=@nrdeviz and tip='D' and tip_resursa='M' and Stare_pozitie>='1'
	
	declare @datamaxfact1 datetime, @datamaxfact2 datetime
	set @datamaxfact1=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='3'),'01/01/1901') 
	set @datamaxfact2=isnull((select max(Data_facturarii) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie='2' and exists(select 1 from devauto where Cod_deviz=@nrdeviz and tip='N')),
		'01/01/1901') 
	set @datamaxfact1=(case when @datamaxfact1>@datamaxfact2 then @datamaxfact1 else @datamaxfact2 end)
	if @datamaxfact1<>'01/01/1901' 
		UPDATE devauto set Data_inchiderii=@datamaxfact1 WHERE Cod_deviz=@nrdeviz

	UPDATE devauto set Stare=isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz=@nrdeviz 
		and stare_Pozitie<>'0'),'0') 
		WHERE Cod_deviz=@nrdeviz
	
	set @stare = (select top 1 convert(int, Stare) from devauto where Cod_deviz = @nrdeviz)

	set @docJurnal = (select @nrdeviz as nrdeviz, @stare as stare, @data as data, 'Finalizat manopera' as explicatii for xml raw, type)
	exec wScriuJurnalDeviz @sesiune = @sesiune, @parXML = @docJurnal

	select 'S-a finalizat manopera pe devizul cu nr. ' + rtrim(@nrdeviz) + '.' as textMesaj for xml raw, root('Mesaje')

end try    
begin catch 
	declare @eroare varchar(500) 
	set @eroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@eroare, 16, 1) 
end catch
