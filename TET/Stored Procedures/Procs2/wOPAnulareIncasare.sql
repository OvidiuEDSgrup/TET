create procedure wOPAnulareIncasare(@sesiune varchar(50), @parXML xml) as             
begin            
 declare @anulare bit ,@tert varchar(20),@suma varchar(20), @contcasa varchar(20),@datafacturii datetime , @factura varchar(20),
		 @binar varbinary(128)
		 set @anulare=isnull(@parXML.value('(parametri/@anulare)[1]','bit'),'')
		 set @factura=isnull(@parXML.value('(parametri/@factura)[1]','varchar(20)'),'')
		 set @datafacturii=isnull(@parXML.value('(parametri/@datafacturii)[1]','datetime'),'')
		 set @tert=isnull(@parXML.value('(parametri/@tert)[1]','varchar(20)'),'')

	if @anulare=1
		begin
		  if not exists (select 1 from pozplin where subunitate='1' and data=@datafacturii and Plata_incasare='IB' and tert=@tert and Factura=@factura)
			 raiserror('Factura nu a fost vreodata incasata!',16,1)
		  else 
		     delete from pozplin where subunitate='1' and data=@datafacturii and Plata_incasare='IB' and tert=@tert and Factura=@factura
		     --set @binar=cast('modificaredocdefinitiv' as varbinary(128))
			 --set CONTEXT_INFO @binar
		     --update pozdoc set Stare='3' where Subunitate='1' and Numar=@factura and data=@datafacturii and tert=@tert 
		     --update doc set Stare='3' where Subunitate='1' and Numar=@factura and data=@datafacturii and cod_tert=@tert 
		     --set CONTEXT_INFO 0x00
			 select 'S-a efectuat anularea incasarii!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje') 
		end
    else
        select 'Anulare incasare neefectuata! Selectati "Anulare incasare" pentru a anula incasarea' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje') 
 end
		 
