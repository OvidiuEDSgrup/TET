
create procedure wmInchidereDocument @sesiune varchar(50), @parXML xml
as

begin try
	declare
		@eroare varchar(max), @tip varchar(2), @numar varchar(20), @data datetime, @stare_in_curs int, @stare int, @xml xml

	select
		@tip = @parXML.value('(/*/@tip)[1]','varchar(2)'),
		@numar = @parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]','datetime')

	select top 1 @stare_in_curs = stare from StariDocumente where tipDocument=@tip and inCurs=1
	select top 1 @stare = stare from StariDocumente where tipDocument=@tip and isnull(inCurs,0)=0 and stare > @stare_in_curs

	select @xml = (select @tip as tip, @numar as numar, @data as data, 'Finalizare stare in curs' as explicatii_stare_jurnal, isnull(@stare,0) as stare_jurnal for xml raw('parametri'))
	exec wOPSchimbareStareDocument @sesiune=@sesiune, @parXML=@xml

	select 'back(3)' as actiune for xml raw, ROOT('Mesaje')
end try

begin catch
	select @eroare = error_message()+' ('+ OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare,16,1)
end catch

