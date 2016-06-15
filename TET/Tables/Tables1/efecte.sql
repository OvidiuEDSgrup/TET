CREATE TABLE [dbo].[efecte] (
    [Subunitate]      CHAR (9)     NOT NULL,
    [Tip]             CHAR (1)     NOT NULL,
    [Tert]            CHAR (13)    NOT NULL,
    [Nr_efect]        VARCHAR (20) NULL,
    [Cont]            VARCHAR (20) NULL,
    [Data]            DATETIME     NOT NULL,
    [Data_scadentei]  DATETIME     NOT NULL,
    [Valoare]         FLOAT (53)   NOT NULL,
    [Valuta]          CHAR (3)     NOT NULL,
    [Curs]            FLOAT (53)   NOT NULL,
    [Valoare_valuta]  FLOAT (53)   NOT NULL,
    [Decontat]        FLOAT (53)   NOT NULL,
    [Sold]            FLOAT (53)   NOT NULL,
    [Decontat_valuta] FLOAT (53)   NOT NULL,
    [Sold_valuta]     FLOAT (53)   NOT NULL,
    [Loc_de_munca]    CHAR (9)     NOT NULL,
    [Comanda]         CHAR (40)    NOT NULL,
    [Data_decontarii] DATETIME     NOT NULL,
    [Explicatii]      CHAR (30)    NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Efecte1]
    ON [dbo].[efecte]([Subunitate] ASC, [Tip] ASC, [Tert] ASC, [Nr_efect] ASC);


GO
CREATE NONCLUSTERED INDEX [Efecte2]
    ON [dbo].[efecte]([Subunitate] ASC, [Tert] ASC, [Tip] ASC);

