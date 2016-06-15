create procedure wOPDetaliiIncarcare_p @sesiune varchar(30), @parXML XML
as
declare @nrtransp varchar(20), @sofer varchar(20), @transportator varchar(20), @comanda varchar(20), @tert varchar(20), @data datetime,
		@numesofer varchar(20)

select @comanda= isnull(@parXML.value('(/row/@comanda)[1]','varchar(50)'),''),
	   @tert= isnull(@parXML.value('(/row/@tert)[1]','varchar(50)'),''),
	   @data= isnull(@parXML.value('(/row/@datacon)[1]','varchar(50)'),'')

select @nrtransp= c.mod_penalizare, 
       @Sofer=inf.sofer, @numesofer=p.nume from con c
       inner  join infotpbk inf on c.Mod_penalizare=inf.Numar_transport and subunitate='1' and Contract=@comanda and tert=@tert and data=@data
	   inner join personal p on p.Marca=inf.Sofer
								 
select rtrim(@nrtransp) nrtp, @sofer sofer, @numesofer densofer for xml raw
