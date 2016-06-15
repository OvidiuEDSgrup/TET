CREATE TABLE [dbo].[TNivel] (
    [Hostid]     CHAR (255)     NOT NULL,
    [Nivel]      INT            NOT NULL,
    [start]      INT            NOT NULL,
    [stop]       INT            NOT NULL,
    [primulRand] INT            NULL,
    [expresie]   VARCHAR (8000) NOT NULL,
    [v1]         VARCHAR (8000) NOT NULL,
    [v2]         VARCHAR (8000) NOT NULL,
    CONSTRAINT [PK_HostidNivelStart] PRIMARY KEY CLUSTERED ([Hostid] ASC, [Nivel] ASC, [start] ASC)
);

