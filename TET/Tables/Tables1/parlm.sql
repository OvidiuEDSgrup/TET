CREATE TABLE [dbo].[parlm] (
    [Loc_de_munca]       VARCHAR (9)   NOT NULL,
    [Tip_parametru]      VARCHAR (2)   NOT NULL,
    [Parametru]          VARCHAR (9)   NOT NULL,
    [Denumire_parametru] VARCHAR (30)  NOT NULL,
    [Val_logica]         BIT           NOT NULL,
    [Val_numerica]       FLOAT (53)    NOT NULL,
    [Val_alfanumerica]   VARCHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Parametru]
    ON [dbo].[parlm]([Loc_de_munca] ASC, [Tip_parametru] ASC, [Parametru] ASC);

