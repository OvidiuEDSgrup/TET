﻿--***
create function NrReparatii (@masina char(20), @cCodUrm char(20), @data datetime, @fisa char(20), @pozitie int) 
returns float 
as begin 
 return 
 (isnull((select top 1 ea.valoare from elemactivitati ea, activitati a where a.masina=@masina and a.tip=ea.tip and a.fisa=ea.fisa 
 and a.data=ea.data and ea.data<=@data and ea.element=@cCodUrm 
 and (RTrim(isnull(@fisa, ''))='' or (ea.fisa<=@fisa and (isnull(@pozitie, -1)<0 or ea.fisa<@fisa or ea.numar_pozitie<=@pozitie))) 
 order by ea.data DESC, ea.fisa DESC, ea.numar_pozitie DESC), 
 isnull((select vei.valoare from valelemimpl vei where vei.masina=@masina and vei.element=@cCodUrm), 0))) 
end 
