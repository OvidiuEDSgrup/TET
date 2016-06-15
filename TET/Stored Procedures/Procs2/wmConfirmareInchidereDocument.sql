
create procedure wmConfirmareInchidereDocument @sesiune varchar(50), @parXML xml as

declare
	@tip varchar(2), @numar varchar(20), @data datetime

select
	@tip = @parXML.value('(/row/@tip)[1]','varchar(2)'),
	@numar = @parXML.value('(/row/@numar)[1]','varchar(20)'),
	@data = @parXML.value('(/row/@data)[1]','datetime')

select '' as cod, '' as denumire, 'Sunteti sigur ca doriti sa efectuati aceasta operatie?' as info, '' as tip, '' as numar, '' as data, '' as poza, '' as procdetalii, '' as actiune
union all
select 'da' as cod, 'Da' as denumire, '' as info, @tip as tip, @numar as numar, @data as data, 'server://assets/Imagini/Meniu/yes.png' as poza, 'wmInchidereDocument' as procdetalii, '' as actiune
union all
select 'nu' as cod, 'Nu' as denumire, '' as info, @tip as tip, @numar as numar, @data as data, 'server://assets/Imagini/Meniu/no.png' as poza, '' as procdetalii, 'back(1)' as actiune
for xml raw
