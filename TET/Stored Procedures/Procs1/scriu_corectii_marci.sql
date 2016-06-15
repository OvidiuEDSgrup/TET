--***
/**	proc. pentru scriere scriu corectii marci in cursorul de corectii */
create 
procedure [dbo].[scriu_corectii_marci]
@datajos datetime, @datasus datetime, @pmarca char(6), @ploc_de_munca char(9)
As
declare @data datetime, @marca char(6), @loc_de_munca char(9), @tip_corectie_venit char(2), 
@suma_corectie float, @procent_corectie float

Declare cursor_corectii_marci Cursor For
Select c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit, c.suma_corectie, c.procent_corectie
from corectii c 
where c.data between @datajos and @datasus and c.marca<>'' and (@pmarca='' or c.marca=@pmarca) 
and (@ploc_de_munca='' or c.loc_de_munca between rtrim(@ploc_de_munca) and rtrim(@ploc_de_munca)+'ZZZ')
order by c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit

open cursor_corectii_marci
fetch next from cursor_corectii_marci into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
While @@fetch_status = 0 
Begin
	if exists (select * from curscor where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and tip_corectie_venit=@tip_corectie_venit)
		update curscor set suma_corectie = suma_corectie+@suma_corectie, 
		procent_corectie = procent_corectie+@procent_corectie,  expand_locm = 0
		where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and tip_corectie_venit=@tip_corectie_venit
	else 
		insert into curscor(Data, Marca, Loc_de_munca, tip_corectie_venit, suma_corectie, procent_corectie, expand_locm)
		select @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie, 0

	fetch next from cursor_corectii_marci into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
End
close cursor_corectii_marci
Deallocate cursor_corectii_marci
