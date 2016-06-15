--***
CREATE procedure  [dbo].[wIaPozSarcini]   @sesiune varchar(50), @parXML xml
as
declare 
@cod varchar(20)
select 
	@cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''))


select i.Descriere as nume_angajat, convert(char(10),r.Data_start,101) as data_inceput, convert(char(10),
r.Data_stop,101) as data_sfarsit, rtrim(r.activitati) as activitati, 
substring(r.ore_lucrate,1,2) +':' +substring(r.ore_lucrate,3,2) as ore, 
substring(r.Ora_start,1,2) +':' +substring(r.Ora_start,3,2) as ora_inceput,substring(r.Ora_stop,1,2) +':' +substring(r.Ora_stop,3,2) as ora_sfarsit,
r.ora_start as ora,
(select proiect from Sarcini where IDSarcina = @cod) as proiect

from Raport_activitate r join Infotert i on i.Identificator = r.ID_angajat

 where IDOrdin = rtrim(@cod)

for xml raw
