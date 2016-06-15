--***
/* procedura pentru populare macheta de generare declaratie Intrastat */
create procedure wOPGenerareIntrastat_p @sesiune varchar(50), @parXML xml 
as  
declare @flux varchar(10), @nume_persct varchar(150), @prenume_persct varchar(50), @functie_persct varchar(50), 
	@telefon_persct varchar(50), @fax_persct varchar(50), @email_persct varchar(50), 
	@lunaalfa varchar(15), @luna int, @an int, @datajos datetime, @datasus datetime

set @flux = ISNULL(@parXML.value('(/row/@flux)[1]', 'varchar(2)'), 'I')

exec luare_date_par 'EI', 'NUMEPCT', 0, 0, @nume_persct output
exec luare_date_par 'EI', 'PRNUMEPCT', 0, 0, @prenume_persct output
exec luare_date_par 'EI', 'POZPCT', 0, 0, @functie_persct output
exec luare_date_par 'EI', 'TELPCT', 0, 0, @telefon_persct output
exec luare_date_par 'EI', 'FAXPCT', 0, 0, @fax_persct output
exec luare_date_par 'EI', 'EMAILPCT', 0, 0, @email_persct output

select rtrim(@flux) as flux, rtrim(@functie_persct) as functiepersct, rtrim(@nume_persct) as numepersct, rtrim(@prenume_persct) as prenpersct, 
	rtrim(@telefon_persct) as telpersct, rtrim(@fax_persct) as faxpersct, rtrim(@email_persct) as emailpersct
for xml raw
