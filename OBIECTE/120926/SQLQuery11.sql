--***  
/* Procedura stocata care scrie date in parametri*/  
create procedure setare_par @tip char(2), @par char(9),   
 @denp char(30) = NULL, @val_l bit = NULL, @val_n float = NULL, @val_a varchar(200) = NULL  
as  
  
if not exists (select 1 from par where tip_parametru = @tip and parametru = @par)  
 insert into par   
 (tip_parametru, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica)  
 values  
 (@tip, @par, '', 0, 0, '')  
update par  
set denumire_parametru=(case when @denp is null then denumire_parametru else @denp end),  
 val_logica=(case when @val_l is null then val_logica else @val_l end),  
 val_numerica=(case when @val_n is null then val_numerica else @val_n end),  
 val_alfanumerica=(case when @val_a is null then val_alfanumerica else @val_a end)  
where tip_parametru=@tip and parametru=@par  