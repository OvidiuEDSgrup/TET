--***
/* Procedura stocata care ia date din parametri*/
create procedure luare_date_par @tip char(2), @par char(9), @val_l bit OUTPUT, @val_n float OUTPUT, @val_a varchar(200) OUTPUT
as

set @val_l = 0
set @val_n = 0
set @val_a = ''

select @val_l=val_logica, @val_n=val_numerica, @val_a=val_alfanumerica
from par
where tip_parametru = @tip and parametru = @par
