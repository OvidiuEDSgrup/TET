CREATE TABLE [dbo].[mfrep] (
    [Subunitate]      CHAR (9)   NOT NULL,
    [Nr_inv]          CHAR (13)  NOT NULL,
    [Cod_normativ]    CHAR (20)  NOT NULL,
    [Media_funct]     FLOAT (53) NOT NULL,
    [Efectuat_RK]     FLOAT (53) NOT NULL,
    [Data_ultimei_RK] DATETIME   NOT NULL,
    [Efectuat_pf]     FLOAT (53) NOT NULL,
    [Val_inlocuire]   FLOAT (53) NOT NULL,
    [Caract_1]        CHAR (15)  NOT NULL,
    [Caract_2]        CHAR (15)  NOT NULL,
    [Caract_3]        CHAR (15)  NOT NULL,
    [Foc_continuu]    BIT        NOT NULL,
    [Utilaj]          BIT        NOT NULL,
    [Tip_utilaj]      CHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Mfrep1]
    ON [dbo].[mfrep]([Subunitate] ASC, [Nr_inv] ASC);


GO
CREATE NONCLUSTERED INDEX [Mfrep2]
    ON [dbo].[mfrep]([Cod_normativ] ASC);

