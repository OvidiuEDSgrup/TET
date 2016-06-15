CREATE TABLE [dbo].[anteclc] (
    [Cod]            CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Numar]          SMALLINT   NOT NULL,
    [Val_materiale]  FLOAT (53) NOT NULL,
    [Val_manopera]   FLOAT (53) NOT NULL,
    [Coef_materiale] REAL       NOT NULL,
    [Coef_manopera]  REAL       NOT NULL,
    [Coef_CAS]       REAL       NOT NULL,
    [Chelt_gen]      REAL       NOT NULL,
    [Chelt_sectie]   REAL       NOT NULL,
    [Coef_profit]    REAL       NOT NULL,
    [Coef_adaos]     REAL       NOT NULL,
    [Cota_TVA]       SMALLINT   NOT NULL,
    [Rotunjire]      INT        NOT NULL,
    [Pret]           FLOAT (53) NOT NULL,
    [Valuta]         CHAR (9)   NOT NULL,
    [Curs]           FLOAT (53) NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Mat_fara_341]   FLOAT (53) NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Alfa1]          CHAR (13)  NOT NULL,
    [Alfa2]          CHAR (13)  NOT NULL,
    [Data_rez]       DATETIME   NOT NULL,
    [Coef_acc_munca] FLOAT (53) NOT NULL,
    [Val3]           FLOAT (53) NOT NULL,
    [Val4]           FLOAT (53) NOT NULL,
    [Val5]           FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Acalc]
    ON [dbo].[anteclc]([Cod] ASC, [Data] ASC, [Numar] ASC);

