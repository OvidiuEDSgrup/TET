CREATE TABLE [dbo].[ImpExtras] (
    [Data]         DATETIME   NOT NULL,
    [Cont_antet]   CHAR (13)  NOT NULL,
    [Cod_operatie] CHAR (3)   NOT NULL,
    [Tip]          CHAR (2)   NOT NULL,
    [Numar]        CHAR (8)   NOT NULL,
    [Tert]         CHAR (13)  NOT NULL,
    [Factura]      CHAR (20)  NOT NULL,
    [Efect]        CHAR (10)  NOT NULL,
    [Cont_coresp]  CHAR (13)  NOT NULL,
    [Suma_valuta]  FLOAT (53) NOT NULL,
    [Valuta]       CHAR (3)   NOT NULL,
    [Curs]         FLOAT (53) NOT NULL,
    [Suma]         FLOAT (53) NOT NULL,
    [Loc_de_munca] CHAR (9)   NOT NULL,
    [Explicatii]   CHAR (50)  NOT NULL,
    [Nr_pozitie]   INT        NOT NULL,
    [Aux1]         CHAR (50)  NOT NULL,
    [Aux2]         CHAR (50)  NOT NULL,
    [Aux3]         CHAR (50)  NOT NULL,
    [Aux4]         CHAR (50)  NOT NULL,
    [Aux5]         CHAR (50)  NOT NULL,
    [Aux6]         CHAR (50)  NOT NULL,
    [Aux7]         CHAR (50)  NOT NULL,
    [Aux8]         CHAR (50)  NOT NULL,
    [Aux9]         CHAR (50)  NOT NULL,
    [Aux10]        CHAR (50)  NOT NULL,
    [Aux11]        CHAR (50)  NOT NULL,
    [Aux12]        CHAR (50)  NOT NULL,
    [Expandare]    BIT        NOT NULL,
    [Stare]        SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ImpExtras]([Data] ASC, [Nr_pozitie] ASC);

