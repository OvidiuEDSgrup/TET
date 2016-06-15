CREATE TABLE [dbo].[par_lunari_lm] (
    [Loc_de_munca]       VARCHAR (9)   NOT NULL,
    [Data]               DATETIME      NOT NULL,
    [Tip]                VARCHAR (2)   NOT NULL,
    [Parametru]          VARCHAR (9)   NOT NULL,
    [Denumire_parametru] VARCHAR (30)  NOT NULL,
    [Val_logica]         BIT           NOT NULL,
    [Val_numerica]       FLOAT (53)    NOT NULL,
    [Val_alfanumerica]   VARCHAR (200) NOT NULL,
    [Val_data]           DATETIME      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Parametru]
    ON [dbo].[par_lunari_lm]([Loc_de_munca] ASC, [Data] ASC, [Tip] ASC, [Parametru] ASC);

