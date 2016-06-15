--***
create procedure wOPDefinitivareComenzi  @sesiune varchar(30), @parXML XML
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPDefinitivareComenziSP')
begin 
	declare @returnValue int 
	exec @returnValue = wOPDefinitivareComenziSP @sesiune, @parXML output
	return @returnValue
END

RAISERROR('Aceasta procedura nu este testata. Pentru situatii urgente, testati si dezvoltati o procedura specifica.', 11, 1)

declare @cod varchar(20), @stareneaprobate int, @contract varchar(20), @tert varchar(20), @definitivare int

   select @cod = isnull(@parXML.value('(/parametri/@cod)[1]','varchar(20)'),''),
          @stareneaprobate = isnull(@parXML.value('(/parametri/@stareneaprobate)[1]','varchar(20)'),''),
          @definitivare= isnull(@parXML.value('(/parametri/@definitivare)[1]','int'),0)	
begin try
 if @definitivare=1 
 begin
	 declare crsdefcom cursor for
	  select pc.contract, pc.tert from pozcon pc inner join con c on pc.Subunitate=c.Subunitate and pc.Tip=c.Tip and pc.Tert=c.Tert and pc.Contract=c.Contract
																	 where c.tip='bk'  and pc.cod=@cod  and c.stare=@stareneaprobate
	   open crsdefcom
	   fetch next from crsdefcom into @contract, @tert
	   while @@FETCH_STATUS=0
	   begin
		update con set stare='1' where subunitate='1' and Contract=@contract and tert=@tert
	   fetch next from crsdefcom into @contract, @tert
	   end
	 
	 select 'S-au trecut in stare de definitivare comenzile care contin codul'+rtrim(@cod)+'!' as textMesaj for xml raw, root('Mesaje')
 end
 else
  raiserror('Selectati definitivare pentru codul cu comenzile selectate',16,1)
end try 
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

   
