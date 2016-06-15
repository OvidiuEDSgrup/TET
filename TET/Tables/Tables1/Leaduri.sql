CREATE TABLE [dbo].[Leaduri] (
    [idLead]             INT            IDENTITY (1, 1) NOT NULL,
    [topic]              VARCHAR (2000) NULL,
    [nume]               VARCHAR (300)  NULL,
    [domeniu_activitate] VARCHAR (200)  NULL,
    [email]              VARCHAR (100)  NULL,
    [note]               VARCHAR (4000) NULL,
    [telefon]            VARCHAR (50)   NULL,
    [denumire_firma]     VARCHAR (200)  NULL,
    [data_operarii]      DATETIME       DEFAULT (getdate()) NULL,
    [stare]              VARCHAR (100)  NULL,
    [supervizor]         VARCHAR (200)  NULL,
    [detalii]            XML            NULL,
    PRIMARY KEY CLUSTERED ([idLead] ASC)
);

