--***
CREATE procedure [dbo].[wScriuPozSarcini]  @sesiune varchar(50), @parXML xml
as

declare @angajat varchar(5), @id_sarcina varchar(15), @data_start datetime, @ora_start varchar(6),
		@data_st datetime, @ora_stop varchar(6), @activitati varchar(500),@ore varchar(6),@tip_op varchar(2),
		@stare varchar(5),@update varchar(1),@datas datetime,
		@docXMLIaPozSarcini xml
		
select	@id_sarcina = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')),
		@data_start = rtrim(isnull(@parXML.value('(/row/row/@data_inceput)[1]', 'datetime'), '')),
		@ora_start = rtrim(isnull(@parXML.value('(/row/row/@ora)[1]', 'varchar(6)'), '')),
		@data_st = rtrim(isnull(@parXML.value('(/row/row/@o_data_inceput)[1]', 'datetime'), '')),
		@ora_stop = rtrim(isnull(@parXML.value('(/row/row/@ora_sfarsit)[1]', 'varchar(6)'), '')),
		@activitati = rtrim(isnull(@parXML.value('(/row/row/@activitati)[1]', 'varchar(500)'), '')),
		@ore = rtrim(isnull(@parXML.value('(/row/row/@ore)[1]', 'varchar(6)'), '')),
		@tip_op = rtrim(isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '')),
		@angajat = rtrim(isnull(@parXML.value('(/row/@cod_angajat)[1]', 'varchar(5)'), '')),
		@update = rtrim(isnull(@parXML.value('(/row/row/@update)[1]', 'varchar(1)'), ''))

if (@update like '%1%')
begin
--se face update la o acvititate existenta
	select
		@datas = rtrim(isnull(@parXML.value('(/row/row/@o_data_inceput)[1]', 'datetime'), ''))
	exec convert_ora @ore, @ore OUTPUT
	update Raport_activitate set Activitati = @activitati, Data_stop = CONVERT(datetime,getdate()), 
	    ore_lucrate =@ore
		where IDOrdin = @id_sarcina	and Data_start = @data_st and Ora_start = @ora_start 
end
else
begin
--se insereaza raport_activitate
if (@tip_op = 'RA')
	begin
		exec convert_ora @ore, @ore OUTPUT
		insert into Raport_activitate values (@angajat,@id_sarcina,@data_start,replace(convert(varchar(8),getdate(),108),':',''),CONVERT(datetime,getdate()),replace(convert(varchar(8),getdate(),108),':',''),@activitati,@ore)
		update Sarcini set Ore_realizate = isnull((select convert(varchar(6),convert(int,sum (convert(int,SUBSTRING(ore_lucrate,1,2))) + sum (convert(int,SUBSTRING(ore_lucrate,3,2)))/60) +1 )
				from Raport_activitate  where IDOrdin = @id_sarcina ),0)	
	end
	

else 
--se face update la sarcina
begin
	select 
		@stare =rtrim(isnull(@parXML.value('(/row/row/@stareAC)[1]', 'varchar(5)'), ''))
		if (@stare = '3' )-- finalizare
				update Sarcini set Stare_sarcina = @stare, data_stop = GETDATE(), ora_stop = replace(convert(varchar(8),getdate(),108),':',''),
				Ore_realizate =isnull((select convert(varchar(6),convert(int,sum (convert(int,SUBSTRING(ore_lucrate,1,2))) + sum (convert(int,SUBSTRING(ore_lucrate,3,2)))/60) +1 )
				from Raport_activitate  where IDOrdin = @id_sarcina ),0)				
				where IDSarcina = @id_sarcina
			else 
				if(@stare = '2') --luare in lucru
					update Sarcini set Stare_sarcina = @stare, data_start = GETDATE(), ora_start = replace(convert(varchar(8),getdate(),108),':','')
					,data_stop = GETDATE(), ora_stop = replace(convert(varchar(8),getdate(),108),':','')
					where IDSarcina = @id_sarcina
		
end 
end

--refresh pozitii sarcina
set @docXMLIaPozSarcini ='<row cod="'+rtrim(@id_sarcina)+'"/>'
exec wIaPozSarcini @sesiune=@sesiune, @parXML=@docXMLIaPozSarcini
