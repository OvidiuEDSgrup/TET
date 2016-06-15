CREATE TABLE [dbo].[butoanePv] (
    [codButon]          VARCHAR (50)  NOT NULL,
    [activ]             BIT           NULL,
    [ordine]            INT           NOT NULL,
    [label]             VARCHAR (500) NOT NULL,
    [culoare]           VARCHAR (50)  NULL,
    [tipButon]          VARCHAR (500) NOT NULL,
    [ctrlKey]           BIT           NULL,
    [tasta]             VARCHAR (50)  NULL,
    [procesarePeServer] BIT           NULL,
    [apareInPv]         BIT           NULL,
    [apareInOperatii]   BIT           NULL,
    [tipIncasare]       VARCHAR (50)  NULL,
    [meniu]             VARCHAR (50)  NULL,
    [tip]               VARCHAR (50)  NULL,
    [subtip]            VARCHAR (50)  NULL,
    [utilizator]        VARCHAR (50)  NULL,
    CONSTRAINT [PK_butoanePv_codButon] PRIMARY KEY CLUSTERED ([codButon] ASC)
);

