declare @cod char(20), @comanda char(20), @tert char(13), @cant float, @disponibil float

declare tmppcom cursor for
 select cod, comanda, tert, cant_comandata-cant_aprobata
 from pozcomlivrtmp
 where utilizator='OVIDIU' and cant_comandata>cant_aprobata
 order by cod, termen 
open tmppcom
fetch next from tmppcom into @cod, @comanda, @tert, @cant
while @@fetch_status = 0
begin
 set @disponibil = (select max(stoc - cant_aprobata - aprobat_alte) from comlivrtmp 
  where utilizator='OVIDIU' and cod=@cod)
 if isnull(@disponibil, 0) > 0
 begin
  set @cant = (case when @cant > @disponibil then @disponibil else @cant end)
  update pozcomlivrtmp
  set cant_aprobata = cant_aprobata + @cant
  where utilizator='OVIDIU' and cod=@cod and comanda=@comanda and tert=@tert

  update comlivrtmp
  set cant_aprobata = cant_aprobata + @cant
  where utilizator='OVIDIU' and cod=@cod
 end
 fetch next from tmppcom into @cod, @comanda, @tert, @cant
end
close tmppcom
deallocate tmppcom
