--***
CREATE procedure [dbo].[wIaPozSesizari] @sesiune varchar(50), @parXML xml
as

	declare @cod_sesizare varchar(15), @client varchar(50), @stare_sesizare varchar(20), @contact varchar(30), @sistem varchar(1)
	select
	
		@cod_sesizare = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')),
		@contact = rtrim(isnull(@parXML.value('(/row/@contact)[1]', 'varchar(30)'), '')),
		@sistem = rtrim(isnull(@parXML.value('(/row/@sistem)[1]', 'varchar(1)'), ''))
		
	set @client=(select i.denumire from Sesizari s inner join terti i on i.tert = s.Client  where cod =@cod_sesizare)

	
	select s.idsarcina ,s.IDSesizare, s.descriere_scurta as subiect,
	(case when s.stare_sarcina in (0,1) then 'Nepreluata' when s.Stare_sarcina = 2 then 'In Lucru' else 'Finalizata' end) as stare ,
	t.Descriere as utilizator ,s.Ore_realizate as ore,
	(case when Stare_sarcina in (0,1) then '#FF0000' when Stare_sarcina = 2 then '#000000' else '#00CC00' end) as culoare,
	(select aplicatie from sesizari where cod = @cod_sesizare) as aplicatie, @client as client, @sistem as sistem, @contact as contact
	
	
	from Sarcini s  left join infotert t on t.Identificator = s.ID_user  and tert =1  and Subunitate='C1'
	where s.IDSesizare = RTRIM(@cod_sesizare)
	for xml raw
