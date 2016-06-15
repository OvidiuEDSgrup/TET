CREATE TABLE [dbo].[webConfigSTDGrid] (
    [Meniu]       VARCHAR (20)   NOT NULL,
    [Tip]         VARCHAR (20)   NULL,
    [Subtip]      VARCHAR (20)   NULL,
    [InPozitii]   BIT            NOT NULL,
    [NumeCol]     VARCHAR (50)   NULL,
    [DataField]   VARCHAR (50)   NULL,
    [TipObiect]   VARCHAR (50)   NULL,
    [Latime]      INT            NULL,
    [Ordine]      INT            NULL,
    [Vizibil]     BIT            NULL,
    [modificabil] BIT            NULL,
    [formula]     VARCHAR (8000) NULL
);

