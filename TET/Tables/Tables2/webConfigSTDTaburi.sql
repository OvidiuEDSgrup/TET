CREATE TABLE [dbo].[webConfigSTDTaburi] (
    [MeniuSursa]     VARCHAR (50)  NOT NULL,
    [TipSursa]       VARCHAR (50)  NOT NULL,
    [NumeTab]        VARCHAR (100) NOT NULL,
    [Icoana]         VARCHAR (500) NULL,
    [TipMachetaNoua] VARCHAR (20)  NULL,
    [MeniuNou]       VARCHAR (20)  NULL,
    [TipNou]         VARCHAR (20)  NULL,
    [ProcPopulare]   VARCHAR (100) NULL,
    [Ordine]         SMALLINT      NULL,
    [Vizibil]        BIT           NULL
);

