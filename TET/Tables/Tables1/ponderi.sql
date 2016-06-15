CREATE TABLE [dbo].[ponderi] (
    [tip_pondere]   CHAR (1)   NOT NULL,
    [Loc_furn]      CHAR (9)   NOT NULL,
    [Comanda_Furn]  CHAR (13)  NOT NULL,
    [Loc_benef]     CHAR (9)   NOT NULL,
    [Comanda_benef] CHAR (13)  NOT NULL,
    [pondere]       FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [principal]
    ON [dbo].[ponderi]([tip_pondere] ASC, [Loc_furn] ASC, [Comanda_Furn] ASC, [Loc_benef] ASC, [Comanda_benef] ASC);

