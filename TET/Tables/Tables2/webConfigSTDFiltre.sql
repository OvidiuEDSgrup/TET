CREATE TABLE [dbo].[webConfigSTDFiltre] (
    [Meniu]      VARCHAR (20)  NOT NULL,
    [Tip]        VARCHAR (20)  NOT NULL,
    [Ordine]     INT           NULL,
    [Vizibil]    BIT           NOT NULL,
    [TipObiect]  VARCHAR (50)  NULL,
    [Descriere]  VARCHAR (50)  NULL,
    [Prompt1]    VARCHAR (20)  NULL,
    [DataField1] VARCHAR (100) NULL,
    [Interval]   BIT           NULL,
    [Prompt2]    VARCHAR (20)  NULL,
    [DataField2] VARCHAR (100) NULL
);

