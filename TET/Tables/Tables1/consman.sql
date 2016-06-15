CREATE TABLE [dbo].[consman] (
    [Data]                  DATETIME   NOT NULL,
    [Cod]                   CHAR (20)  NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Comanda]               CHAR (13)  NOT NULL,
    [Cantitate_planificata] FLOAT (53) NOT NULL,
    [Cantitate_realizata]   FLOAT (53) NOT NULL,
    [Procent_consum]        FLOAT (53) NOT NULL,
    [Parcurs]               BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[consman]([Data] ASC, [Cod] ASC, [Loc_de_munca] ASC, [Comanda] ASC);

