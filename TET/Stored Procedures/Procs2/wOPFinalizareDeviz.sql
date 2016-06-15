--***
create procedure wOPFinalizareDeviz @sesiune varchar(50), @parXML xml  
as
declare
	@nrdeviz varchar(8), @stare int, @docJurnal xml, @data datetime
	
set @nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]', 'varchar(8)'), '')

begin try
	if @nrdeviz=''
	begin
		raiserror('Alegeti devizul!',11,1)
		return -1				
	end
        
	if exists (select 1 from pozdevauto where Cod_deviz = @nrdeviz and Stare_pozitie < '2' and Tip <> 'B')
	begin
		raiserror('Pozitiile devizului nu sunt finalizate!',11,1)
		return -1				
	end
        
	update devauto
	set Tip = 'B'
	where Cod_deviz = @nrdeviz
			
	update devauto
	set Stare = isnull((select min(Stare_pozitie) from pozdevauto where Cod_deviz = @nrdeviz and tip = 'D'), Stare) 
	where Cod_deviz=@nrdeviz

	set @stare = (select top 1 convert(int, Stare) from devauto where Cod_deviz = @nrdeviz)
	set @data = (select top 1 Data_lansarii from devauto where Cod_deviz = @nrdeviz)

	/** Am pus in detalii tipul B, ca sa se stie ca starea finalizat (2) poate sa aiba  */
	set @docJurnal = (select @nrdeviz as nrdeviz, @stare as stare, @data as data, 'Finalizat deviz (bun de facturat)' as explicatii,
		(select 'B' as tip for xml raw, type) as detalii for xml raw, type)
	exec wScriuJurnalDeviz @sesiune = @sesiune, @parXML = @docJurnal

	select
		'Devizul a fost finalizat!' as textMesaj, 'Succes' as titluMesaj
	for xml raw, root('Mesaje')

end try
begin catch 
	declare @mesajEroare varchar(500) 
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1) 
end catch
