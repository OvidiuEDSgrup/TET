CREATE TABLE [dbo].[active] (
    [Subunitate]           CHAR (9)   NOT NULL,
    [Cod_activ]            CHAR (20)  NOT NULL,
    [Loc_de_munca]         CHAR (9)   NOT NULL,
    [Gestiune]             CHAR (13)  NOT NULL,
    [Tip_alfanumeric_mare] CHAR (200) NOT NULL,
    [localitate]           CHAR (40)  NOT NULL,
    [judetul]              CHAR (20)  NOT NULL,
    [suprafata_totala]     FLOAT (53) NOT NULL,
    [caracteristici]       CHAR (200) NOT NULL,
    [Suprafata_inchiriata] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[active]([Subunitate] ASC, [Cod_activ] ASC);

