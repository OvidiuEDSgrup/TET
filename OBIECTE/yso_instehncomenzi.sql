drop trigger yso_instehncomenzi 
go
create trigger yso_instehncomenzi on tehn instead of insert as

insert tehn (Cod_tehn,Denumire,Tip_tehn,Utilizator,Data_operarii,Ora_operarii,Data1,Data2,Alfa1,Alfa2,Alfa3,Alfa4,Alfa5,Val1,Val2,Val3,Val4,Val5)
select		Cod_tehn,Denumire,Tip_tehn,Utilizator,Data_operarii,Ora_operarii,Data1,Data2,Alfa1,Alfa2,Alfa3,Alfa4,Alfa5,Val1,Val2,Val3,Val4,Val5
from inserted

insert comenzi (Subunitate,Comanda,Tip_comanda,Descriere,Data_lansarii,Data_inchiderii,Starea_comenzii,Grup_de_comenzi,Loc_de_munca,Numar_de_inventar,Beneficiar,Loc_de_munca_beneficiar,Comanda_beneficiar,Art_calc_benef)
select
'1' --Subunitate	char	9
,t.Cod_tehn --Comanda	char	20
,t.Tip_tehn --Tip_comanda	char	1
,t.Denumire --Descriere	char	80
,GETDATE() --Data_lansarii	datetime	8
,GETDATE() --Data_inchiderii	datetime	8
,'P' --Starea_comenzii	char	1
,0 --Grup_de_comenzi	bit	1
,'1' --Loc_de_munca	char	9
,CONVERT(char(13),getdate(),111) --Numar_de_inventar	char	13
,'' --Beneficiar	char	13
,'' --Loc_de_munca_beneficiar	char	9
,'' --Comanda_beneficiar	char	20
,'' --Art_calc_benef	char	200
from inserted t where t.Cod_tehn not in 
(select c.comanda from comenzi c)

