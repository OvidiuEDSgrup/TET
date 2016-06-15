create procedure [dbo].[facomenzidinsalariati] 
as
insert into comenzi(Subunitate,Comanda,Tip_comanda,Descriere,Data_lansarii,Data_inchiderii,Starea_comenzii,Grup_de_comenzi,Loc_de_munca,Numar_de_inventar,Beneficiar,Loc_de_munca_beneficiar,Comanda_beneficiar,Art_calc_benef)
select '1',Marca,'T',nume,'01/01/1901','01/01/1901','L',0,personal.Loc_de_munca,'','','','',''
from personal where marca not in (select comanda from comenzi)
