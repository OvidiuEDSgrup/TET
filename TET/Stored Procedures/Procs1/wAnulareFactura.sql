create procedure wAnulareFactura @sesiune varchar(50), @parXML xml  
as
declare @contract varchar(20), @sursa varchar(10), @termen varchar(10), @stare varchar(1), @beneficiar varchar(20), @dencontract varchar(100),
		@codnomencl varchar(10), @tert varchar(20), @tip varchar(2), @TermPeSurse int, @anularefact int ,@codtermene varchar(20)
		
exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
set @termen=ISNULL(@parXML.value('(/parametri/@termen)[1]', 'varchar(20)'), '')	
set @tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), '')	
set @codnomencl=ISNULL(@parXML.value('(/parametri/@codnomencl)[1]', 'varchar(20)'), '')
set @stare=ISNULL(@parXML.value('(/parametri/@stare)[1]', 'varchar(20)'), '')
set @contract=ISNULL(@parXML.value('(/parametri/@contract)[1]', 'varchar(20)'), '')
set @anularefact=ISNULL(@parXML.value('(/parametri/@anularefact)[1]', 'varchar(20)'), '')
set @codtermene=ISNULL(@parXML.value('(/parametri/@cod)[1]', 'varchar(20)'), '')
 
 
 if @anularefact=1
  begin 
		if @stare<>'F'
		begin
		raiserror('Eroare operatie: Nu se poate anula factura pentru acea realizare care nu este in stare F-Facturat!',16,1)
		return -1
		end
		delete from pozdoc where tip='AS'and tert=@tert and cod=@codnomencl
		delete from doc where tip='AS'  and cod_tert=@tert
		delete from pozcon  where tip='BK' and tert=@tert and cod=@codnomencl    
		delete from con  where tip='BK' and tert=@tert 
		update termene set Cant_realizata='0',Val2='0',Val1='0' where Contract=@contract and tert=@tert and termen=@termen  
		and cod=@codtermene
   end 
  else
  select 'Nu ati bifat anulare factura, factura nu v-a fi anulata' as textMesaj, 'Informare' as titluMesaj for xml raw, root('Mesaje')
      
   
