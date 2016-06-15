CREATE TABLE [dbo].[webConfigGridV2_0] (
    [IdUtilizator] VARCHAR (10) NULL,
    [TipMacheta]   VARCHAR (2)  NOT NULL,
    [Meniu]        VARCHAR (2)  NOT NULL,
    [Tip]          VARCHAR (2)  NULL,
    [Subtip]       VARCHAR (2)  NULL,
    [InPozitii]    BIT          NOT NULL,
    [NumeCol]      VARCHAR (50) NULL,
    [DataField]    VARCHAR (50) NULL,
    [TipObiect]    VARCHAR (50) NULL,
    [Latime]       INT          NULL,
    [Ordine]       INT          NULL,
    [Vizibil]      BIT          NULL
) ON [WEB];

