--***
create procedure wOPDetaliiIncarcare @sesiune varchar(30), @parXML XML
as
declare @adresa varchar(50), @denlm varchar(20), @lm varchar(20), @nrtransport varchar(20), @comanda varchar(20), 
		@tert varchar(20), @datacon datetime, @sofer varchar(50), @transportator varchar(20), @observatii varchar(20)
select @adresa= isnull(@parXML.value('(/parametri/@adresa)[1]','varchar(50)'),''),
	   @denlm= isnull(@parXML.value('(/parametri/@denlm)[1]','varchar(50)'),''),
	   @nrtransport= isnull(@parXML.value('(/parametri/@nrtp)[1]','varchar(50)'),''),
	   @comanda= isnull(@parXML.value('(/parametri/@comanda)[1]','varchar(50)'),''),
	   @tert= isnull(@parXML.value('(/parametri/@tert)[1]','varchar(50)'),''),
	   @datacon= isnull(@parXML.value('(/parametri/@datacon)[1]','datetime'),'1900-01-01'),
	   @sofer = isnull(@parXML.value('(/parametri/@sofer)[1]','varchar(50)'),''),
	   @transportator = isnull(@parXML.value('(/parametri/@transportator)[1]','varchar(20)'),''),
	   @observatii= isnull(@parXML.value('(/parametri/@observatii)[1]','varchar(20)'),'')

	   
begin
if @sofer='' 
    raiserror('Completati campul sofer',16,1)
set @lm=(select max(loc_de_munca) from con where Contract=@comanda)
update terti set Adresa=@adresa where tert=@tert
update lm set Denumire=@denlm where cod=@lm
if not exists (select 1 from infotpbk where Numar_transport=@nrtransport)
  begin  
    insert into infotpBK (Numar_transport,Data_incarcarii,Data_descarcarii,Transportator,Sofer,Masina,KM,tarif,Numar_paleti,Observatii,Val1,Val2,Alfa1,Alfa2,Data1,Data2)
    values (@nrtransport,GETDATE(),GETDATE(),@transportator,@sofer,'',0,0,0,@observatii,'','','','','1901-01-01','1901-01-01')
    select @nrtransport
    update con set Mod_penalizare=@nrtransport where contract=@comanda and tert=@tert
  end
   else 
   begin
    update con set Mod_penalizare=@nrtransport where contract=@comanda and tert=@tert
    update infotpBK set Sofer=@sofer where Numar_transport=@nrtransport
   end
end



	   
