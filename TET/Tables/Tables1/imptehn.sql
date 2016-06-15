CREATE TABLE [dbo].[imptehn] (
    [Cod]               CHAR (20)  NOT NULL,
    [Denumire]          CHAR (50)  NOT NULL,
    [Suprafata_neta]    BINARY (9) NOT NULL,
    [UM]                CHAR (4)   NOT NULL,
    [Coeficient_consum] FLOAT (53) NOT NULL,
    [Consum_specific]   FLOAT (53) NOT NULL,
    [Loc_de_munca]      CHAR (50)  NOT NULL,
    [Greutate]          FLOAT (53) NOT NULL,
    [di_L]              INT        NOT NULL,
    [dil]               INT        NOT NULL,
    [dig]               INT        NOT NULL,
    [db_L]              INT        NOT NULL,
    [dbl]               INT        NOT NULL,
    [dbg]               INT        NOT NULL,
    [gcons]             INT        NOT NULL,
    [volsupneta]        FLOAT (53) NOT NULL,
    [Contor]            INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[imptehn]([Contor] ASC, [Cod] ASC, [Loc_de_munca] ASC);

