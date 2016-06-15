CREATE TABLE [dbo].[MFnotaam] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Nr_de_inventar] CHAR (13)  NOT NULL,
    [Tip_am_lunara]  INT        NOT NULL,
    [Cont_mf]        CHAR (20)  NOT NULL,
    [Cont_am]        CHAR (20)  NOT NULL,
    [Cont_debitor]   CHAR (20)  NOT NULL,
    [Cont_creditor]  CHAR (20)  NOT NULL,
    [Loc_munca]      CHAR (9)   NOT NULL,
    [Comanda]        CHAR (40)  NOT NULL,
    [Suma]           FLOAT (53) NOT NULL,
    [Valuta]         CHAR (3)   NOT NULL,
    [Curs]           FLOAT (53) NOT NULL,
    [Suma_valuta]    FLOAT (53) NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Numar]          CHAR (8)   NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Utilizator]     CHAR (20)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Jurnal]         CHAR (3)   NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Alfa2]          CHAR (20)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Data2]          DATETIME   NOT NULL,
    [Nr_pozitie]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MFnotaam1]
    ON [dbo].[MFnotaam]([Subunitate] ASC, [Cont_mf] ASC, [Cont_am] ASC, [Nr_de_inventar] ASC, [Tip_am_lunara] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MFnotaam2]
    ON [dbo].[MFnotaam]([Subunitate] ASC, [Nr_de_inventar] ASC, [Tip_am_lunara] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [MFnotaam3]
    ON [dbo].[MFnotaam]([Subunitate] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC, [Loc_munca] ASC, [Comanda] ASC, [Valuta] ASC, [Tip_am_lunara] ASC);

