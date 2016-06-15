--***
/* returneaza utilizatorul ASiS curent, cu validare. Se foloseste unde trebuie validat utilizatorul. */
create procedure wIaUtilizator (@sesiune varchar(50), @utilizator varchar(20) output)
as
-- nu putem folosi fIaUtilizator la clientii care nu au RIA - nu exista baza de date ASISRIA si da eroare.
if not exists (select 1 from sys.databases where name='asisria') and exists (select 1 from sysobjects where name='sysunic') and charindex('unipaas', APP_NAME())>0 and host_id()>0 
begin
	select top 1 @Utilizator=rtrim(utilizator) from sysunic where hostid=host_id() /*and data_iesirii is null */ order by data_intrarii desc
end
else
	set @utilizator = dbo.fIaUtilizator(@sesiune)

if @utilizator=''  -- setez utilizator=null pt. ca se verifica sa fie null in multe proceduri.
	set @utilizator=null

if @utilizator is null 
	and SUSER_NAME()!='sa' /*Pentru utilizator SA era foarte folosit in ASiS / ASiSplus. Ramane ca si compatibilitate in urma inca ceva vreme desi nu credem in el.*/
begin 
	if exists (select * from master.sys.databases where name='ASISRIA')-- uneori se evalueaza in alta ordine
		if not exists(select 1 from asisria..sesiuniRIA where token=@sesiune)
			raiserror('Autentificare esuata sau sesiunea de lucru a expirat!',11,1)
		else
			raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
	else	
		raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)
	return -1
end
else
	return 0

