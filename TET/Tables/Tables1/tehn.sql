CREATE TABLE [dbo].[tehn] (
    [Cod_tehn]      CHAR (20)  NOT NULL,
    [Denumire]      CHAR (150) NOT NULL,
    [Tip_tehn]      CHAR (1)   NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL,
    [Data1]         DATETIME   NOT NULL,
    [Data2]         DATETIME   NOT NULL,
    [Alfa1]         CHAR (20)  NOT NULL,
    [Alfa2]         CHAR (20)  NOT NULL,
    [Alfa3]         CHAR (20)  NOT NULL,
    [Alfa4]         CHAR (20)  NOT NULL,
    [Alfa5]         CHAR (20)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Val3]          FLOAT (53) NOT NULL,
    [Val4]          FLOAT (53) NOT NULL,
    [Val5]          FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [tehn1]
    ON [dbo].[tehn]([Cod_tehn] ASC);


GO
CREATE NONCLUSTERED INDEX [tehn2]
    ON [dbo].[tehn]([Denumire] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [tehn3]
    ON [dbo].[tehn]([Tip_tehn] ASC, [Cod_tehn] ASC);


GO
CREATE NONCLUSTERED INDEX [tehn4]
    ON [dbo].[tehn]([Data1] ASC);


GO
CREATE NONCLUSTERED INDEX [tehn5]
    ON [dbo].[tehn]([Data2] ASC);


GO
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

