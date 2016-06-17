CREATE TABLE [dbo].[ProceduriDeRulat] (
    [idRulare]           INT            IDENTITY (1, 1) NOT NULL,
    [BD]                 VARCHAR (40)   NOT NULL,
    [procedura]          VARCHAR (50)   NOT NULL,
    [sesiune]            VARCHAR (50)   NULL,
    [parXML]             XML            NULL,
    [procent_finalizat]  SMALLINT       NULL,
    [utilizatorWindows]  VARCHAR (40)   NULL,
    [dataStart]          DATETIME       NULL,
    [dataUltimeiActiuni] DATETIME       NULL,
    [dataStop]           DATETIME       NULL,
    [statusText]         VARCHAR (8000) NULL,
    [mesajEroare]        VARCHAR (8000) NULL,
    [mesaje]             XML            NULL,
    CONSTRAINT [PK_ProceduriDeRulat_id] PRIMARY KEY CLUSTERED ([idRulare] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_dataStop]
    ON [dbo].[ProceduriDeRulat]([dataStop] ASC);

