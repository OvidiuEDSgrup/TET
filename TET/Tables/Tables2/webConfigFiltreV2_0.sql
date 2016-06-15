CREATE TABLE [dbo].[webConfigFiltreV2_0] (
    [IdUtilizator] VARCHAR (10)  NULL,
    [TipMacheta]   VARCHAR (2)   NOT NULL,
    [Meniu]        VARCHAR (2)   NOT NULL,
    [Tip]          VARCHAR (2)   NOT NULL,
    [Ordine]       INT           NULL,
    [Vizibil]      BIT           NOT NULL,
    [TipObiect]    VARCHAR (50)  NULL,
    [Descriere]    VARCHAR (50)  NULL,
    [Prompt1]      VARCHAR (20)  NULL,
    [DataField1]   VARCHAR (100) NULL,
    [Interval]     BIT           NULL,
    [Prompt2]      VARCHAR (20)  NULL,
    [DataField2]   VARCHAR (100) NULL
) ON [WEB];

