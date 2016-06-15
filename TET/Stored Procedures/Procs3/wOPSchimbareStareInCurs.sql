
create procedure wOPSchimbareStareInCurs @sesiune varchar(50), @parXML xml
as

declare
	@eroare varchar(max), @subunitate varchar(10), @tip varchar(2), @numar varchar(20), @data datetime, @stare int, @xml xml

begin try

	exec luare_date_par @tip='GE',@par='SUBPRO',@val_l=null,@val_n=null,@val_a=@subunitate output

	select
		@tip = @parXML.value('(/*/@tip)[1]','varchar(2)'),
		@numar = @parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]','datetime')
	
	if (select top 1 s.denumire from JurnalDocumente j inner join StariDocumente s on s.stare=j.stare where j.tip=@tip and j.numar=@numar and j.data=@data order by j.data_operatii desc, j.idJurnal desc)='Finalizat'
		raiserror('Documentul este in starea "Finalizat".',16,1)
		
	if (select top 1 isnull(s.inCurs,0) from JurnalDocumente j inner join StariDocumente s on s.stare=j.stare where j.tip=@tip and j.numar=@numar and j.data=@data order by j.data_operatii desc, j.idJurnal desc)=1
		raiserror('Documentul este deja in starea "In curs".',16,1)

	if exists(select 1 from JurnalDocumente j inner join StariDocumente s on s.stare=j.stare and isnull(s.inCurs,0)=1 where j.tip=@tip and j.numar=@numar and j.data=@data)
		raiserror('Documentul a fost deja in starea "In curs".',16,1)

	select top 1 @stare = stare from StariDocumente where tipDocument=@tip and initializare=1

	select @xml = (select @tip as tip, @numar as numar, @data as data, 'Initializare document pentru scanare' as explicatii_stare_jurnal, @stare as stare_jurnal for xml raw('parametri'))
	exec wOPSchimbareStareDocument @sesiune=@sesiune, @parXML=@xml
	
	select top 1 @stare = stare from StariDocumente where tipDocument=@tip and inCurs=1

	if @stare is null
	begin
		select @eroare = 'Nu s-a gasit starea "In curs" pe tipul ' + @tip + ' in catalogul de stari.'
		raiserror(@eroare,16,1)
	end

	select @xml = (select @tip as tip, @numar as numar, @data as data, 'Initiere scanare' as explicatii_stare_jurnal, @stare as stare_jurnal for xml raw('parametri'))
	exec wOPSchimbareStareDocument @sesiune=@sesiune, @parXML=@xml

	declare @pozitii table(subunitate varchar(10),tip varchar(2),numar varchar(20), data datetime, cantitate float, idPozdoc int, detalii xml)
	insert into @pozitii(subunitate,tip,numar,data,cantitate,idPozdoc,detalii)
	select subunitate,tip,numar,data,convert(decimal(15,5),cantitate),idPozdoc,detalii from pozdoc where subunitate=@subunitate and tip=@tip and numar=@numar and data=@data

	update @pozitii set detalii = (select cantitate as cant_scriptica for xml raw) where detalii is null
	update @pozitii set detalii.modify('replace value of (/row/@cant_scriptica)[1] with sql:column("cantitate")') where detalii.value('count(/row/@cant_scriptica)','int') > 0
	update @pozitii set detalii.modify('insert attribute cant_scriptica {sql:column("cantitate") } into (/row)[1]') where detalii.value('count(/row/@cant_scriptica)','int') = 0

	update p
		set cantitate=0, detalii=poz.detalii
	from pozdoc p
		inner join @pozitii poz on p.idPozdoc=poz.idPozdoc

end try

begin catch
	select @eroare = error_message()+' ('+ OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare,16,1)
end catch
