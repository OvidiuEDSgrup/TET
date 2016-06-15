--***
/* ia biserica din tabela sesiuni sesiune */
create function data_ultimului_calcul_pen (@tert varchar(13),@tip_pen varchar(1),@calcNou int=0)
returns datetime
as
begin
	return (select max(data_penalizare) from penalizarifact where tip_penalizare=@tip_pen and tert=@tert and procent_penalizare=case when  @calcNou=1 then 0.02 else procent_penalizare end)
end

